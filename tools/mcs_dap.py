#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mcs_dap.py —— MCS-251 的 VSCode 调试适配器（DAP over stdio）。

复用 `tools/mcs_dbg.py` 的 CDB 解析与 QEMU GDB RSP 客户端；VSCode 侧由
`tools/vscode-mcs251` 扩展把本脚本（通常在 WSL 里）拉起来。

支持：源码行断点、继续、单步（指令级/按行）、寄存器查看、全局变量求值、
暂停、断开；**串口输出转发**（launch 的 `serial`，默认开 → 调试控制台）；
**端口 GPIO 查看**（作用域「端口 (GPIO)」显示 P0–P7 及每位；可 evaluate `p1`/`p1.1`）。
不含栈展开与局部变量（后续里程碑）。

约定：`hex`/`cdb` 用 Windows 路径（扩展从 VSCode 传来），本脚本内部转成 WSL
路径（`/mnt/<盘>/...`）给 QEMU 与文件读取；返回给 VSCode 的源码路径仍是 Windows 路径。
"""

from __future__ import annotations

import json
import os
import re
import sys
import threading
import traceback

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from mcs_dbg import Cdb, Qemu, Debugger  # noqa: E402


def to_wsl_path(path: str) -> str:
    """`E:\\a\\b` / `E:/a/b` -> `/mnt/e/a/b`；已是 `/...` 则原样。"""
    m = re.match(r"^([A-Za-z]):[\\/](.*)$", path)
    if m:
        return "/mnt/" + m.group(1).lower() + "/" + m.group(2).replace("\\", "/")
    return path.replace("\\", "/")


def basename_any(path: str) -> str:
    """同时认 Windows/Unix 分隔符的文件基名（WSL 里 `os.path.basename` 不切 `\\`）。"""
    return re.split(r"[\\/]", path)[-1]


class Conn:
    """DAP 的 Content-Length 帧读写。"""

    def __init__(self) -> None:
        self._in = sys.stdin.buffer
        self._out = sys.stdout.buffer
        self._wlock = threading.Lock()

    def read(self) -> dict | None:
        headers: dict[str, str] = {}
        while True:
            line = self._in.readline()
            if not line:
                return None
            line = line.strip()
            if not line:
                break
            key, _, value = line.decode("ascii", "replace").partition(":")
            headers[key.strip().lower()] = value.strip()
        length = int(headers.get("content-length", "0"))
        body = self._in.read(length)
        if not body:
            return None
        return json.loads(body.decode("utf-8"))

    def write(self, msg: dict) -> None:
        data = json.dumps(msg, ensure_ascii=False).encode("utf-8")
        with self._wlock:
            self._out.write(b"Content-Length: %d\r\n\r\n" % len(data))
            self._out.write(data)
            self._out.flush()


class Session:
    def __init__(self, conn: Conn) -> None:
        self.conn = conn
        self.seq = 0
        self.cdb: Cdb | None = None
        self.qemu: Qemu | None = None
        self.dbg: Debugger | None = None
        self.stop_on_entry = False
        self.paths_by_base: dict[str, str] = {}      # 基名 -> 完整路径（供 stackTrace）
        self.bp_by_path: dict[str, list[int]] = {}   # 路径 -> 已设断点地址
        self.run_lock = threading.Lock()
        self.running = False
        self.terminated = False

    # -- 发消息 ---------------------------------------------------------
    def _seq(self) -> int:
        self.seq += 1
        return self.seq

    def event(self, name: str, body: dict | None = None) -> None:
        self.conn.write({"seq": self._seq(), "type": "event", "event": name,
                         "body": body or {}})

    def response(self, req: dict, body: dict | None = None,
                 success: bool = True, message: str = "") -> None:
        msg = {"seq": self._seq(), "type": "response",
               "request_seq": req.get("seq"), "success": success,
               "command": req.get("command")}
        if body is not None:
            msg["body"] = body
        if message:
            msg["message"] = message
        self.conn.write(msg)

    def emit(self, text: str, category: str = "console") -> None:
        self.event("output", {"category": category, "output": text})

    def output(self, text: str) -> None:
        self.emit(text + "\n")

    # -- 主循环 ---------------------------------------------------------
    def run(self) -> None:
        while not self.terminated:
            req = self.conn.read()
            if req is None:
                break
            try:
                self.handle(req)
            except Exception:
                self.response(req, success=False,
                              message=traceback.format_exc().strip().splitlines()[-1])
                self.output(traceback.format_exc())

    def handle(self, req: dict) -> None:
        cmd = req.get("command")
        fn = getattr(self, "on_" + cmd, None)
        if fn is None:
            self.response(req, success=False, message=f"未支持的命令：{cmd}")
            return
        fn(req)

    # -- 生命周期 -------------------------------------------------------
    def on_initialize(self, req: dict) -> None:
        self.response(req, {
            "supportsConfigurationDoneRequest": True,
            "supportsEvaluateForHovers": True,
            "supportsTerminateRequest": True,
            "supportsFunctionBreakpoints": False,
            "supportsSetVariable": False,
        })

    def on_launch(self, req: dict) -> None:
        args = req.get("arguments", {})
        hexp = to_wsl_path(args["hex"])
        cdbp = to_wsl_path(args["cdb"])
        default_qemu = os.path.expanduser(
            os.environ.get("QEMU_MCS", "~/qemu-mcs/build/qemu-system-mcs251"))
        qemu = args.get("qemu") or default_qemu
        if not os.path.exists(qemu):
            qemu = "qemu-system-mcs251"  # 退回 PATH 查找
        machine = args.get("machine", "stc32g144k246")
        self.stop_on_entry = bool(args.get("stopOnEntry", False))
        # 串口默认转发到「调试控制台」，跑 t0print/uart_echo 时能看到 UART 输出。
        serial = args.get("serial", True)

        self.cdb = Cdb.from_file(cdbp)
        self.qemu = Qemu(qemu, machine, hexp, capture_serial=bool(serial),
                         on_serial=lambda t: self.emit(t, "stdout"))
        rsp = self.qemu.start()
        self.dbg = Debugger(self.cdb, rsp, self.qemu.read_phys)
        self.response(req)
        self.event("initialized")

    def on_configurationDone(self, req: dict) -> None:
        self.response(req)
        self.start_run("entry" if self.stop_on_entry else "continue")

    def on_disconnect(self, req: dict) -> None:
        self.response(req)
        self.shutdown()

    def on_terminate(self, req: dict) -> None:
        self.response(req)
        self.shutdown()

    def shutdown(self) -> None:
        if self.qemu is not None:
            self.qemu.stop()
            self.qemu = None
        self.event("terminated")
        self.terminated = True

    # -- 断点 -----------------------------------------------------------
    def on_setBreakpoints(self, req: dict) -> None:
        args = req.get("arguments", {})
        path = args.get("source", {}).get("path", "")
        base = basename_any(path)
        if path:
            self.paths_by_base[base] = path
        # 先清掉该文件旧断点
        for addr in self.bp_by_path.get(path, []):
            self.dbg.rsp.clear_breakpoint(addr)
        new_addrs: list[int] = []
        result = []
        for bp in args.get("breakpoints", []):
            line = int(bp.get("line", 0))
            addr = self.cdb.line_addr(base, line) if self.cdb else None
            if addr is None:
                result.append({"verified": False, "line": line,
                               "message": "CDB 中没有该行的地址"})
                continue
            if addr not in new_addrs:
                self.dbg.rsp.set_breakpoint(addr)
                new_addrs.append(addr)
            result.append({"verified": True, "line": line})
        self.bp_by_path[path] = new_addrs
        self.response(req, {"breakpoints": result})

    # -- 运行控制 -------------------------------------------------------
    def on_continue(self, req: dict) -> None:
        self.response(req, {"allThreadsContinued": True})
        self.start_run("continue")

    def on_next(self, req: dict) -> None:
        self.response(req)
        self.start_run("step")

    def on_stepIn(self, req: dict) -> None:
        self.response(req)
        self.start_run("step")

    def on_stepOut(self, req: dict) -> None:
        # 尚无栈展开，暂按单步处理。
        self.response(req)
        self.start_run("step")

    def on_pause(self, req: dict) -> None:
        self.response(req)
        try:
            self.dbg.rsp.interrupt()
            self.dbg.rsp.wait_stop()
        except Exception:
            pass
        self.send_stopped("pause")

    def start_run(self, kind: str) -> None:
        if self.dbg is None:
            return
        if not self.run_lock.acquire(blocking=False):
            return
        self.running = True
        t = threading.Thread(target=self._run, args=(kind,), daemon=True)
        t.start()

    def _run(self, kind: str) -> None:
        try:
            if kind == "entry":
                self.send_stopped("entry")
                return
            if kind == "continue":
                pc = self.dbg.pc()
                # 从断点地址继续：先单步跨过，避免原地死循环。
                if pc in self._all_bp_addrs():
                    self.dbg.rsp.clear_breakpoint(pc)
                    self.dbg.rsp.step()
                    self.dbg.rsp.set_breakpoint(pc)
                self.dbg.rsp.cont()
                self.send_stopped("breakpoint")
                return
            # 单步：走到源码行变化为止。
            start = self.cdb.addr_to_line(self.dbg.pc())
            for _ in range(4000):
                self.dbg.rsp.step()
                if self.cdb.addr_to_line(self.dbg.pc()) != start:
                    break
            self.send_stopped("step")
        except Exception as exc:  # 超时等
            self.output(f"运行控制异常：{exc}")
            self.send_stopped("pause")
        finally:
            self.running = False
            self.run_lock.release()

    def _all_bp_addrs(self) -> set[int]:
        out: set[int] = set()
        for addrs in self.bp_by_path.values():
            out.update(addrs)
        return out

    def send_stopped(self, reason: str) -> None:
        self.event("stopped", {"reason": reason, "threadId": 1,
                               "allThreadsStopped": True})

    # -- 查看 -----------------------------------------------------------
    def on_threads(self, req: dict) -> None:
        self.response(req, {"threads": [{"id": 1, "name": "AI8051U"}]})

    def _func_at(self, pc: int):
        for fn in self.cdb.functions.values():
            if fn.addr is not None and fn.addr <= pc and (
                    fn.eaddr is None or pc < fn.eaddr):
                return fn
        return None

    def on_stackTrace(self, req: dict) -> None:
        pc = self.dbg.pc()
        fn = self._func_at(pc)
        frame = {"id": 1, "name": fn.name if fn else f"0x{pc:06x}",
                 "line": 1, "column": 1}
        where = self.cdb.addr_to_line(pc)
        if where:
            base, line = where
            frame["line"] = line
            frame["column"] = 1
            path = self.paths_by_base.get(base)
            if path:
                frame["source"] = {"name": base, "path": path}
        self.response(req, {"stackFrames": [frame], "totalFrames": 1})

    def on_scopes(self, req: dict) -> None:
        self.response(req, {"scopes": [
            {"name": "寄存器", "variablesReference": 1, "expensive": False},
            {"name": "端口 (GPIO)", "variablesReference": 2, "expensive": False},
        ]})

    def _register_items(self) -> list[dict]:
        d = self.dbg
        items = [{"name": "PC", "value": f"0x{d.pc():06x}", "variablesReference": 0}]
        for name in ("psw", "psw1"):
            v = d._reg(name)
            if v is not None:
                items.append({"name": name.upper(), "value": f"0x{v:02x}",
                              "variablesReference": 0})
        spx, dpx = d._u32("r60"), d._u32("r56")
        if spx is not None:
            items.append({"name": "SPX", "value": f"0x{spx:08x}", "variablesReference": 0})
        if dpx is not None:
            items.append({"name": "DPX", "value": f"0x{dpx:08x}", "variablesReference": 0})
        for n in range(32):
            v = d._reg(f"r{n}")
            items.append({"name": f"R{n}", "value": f"0x{(v or 0) & 0xFF:02x}",
                          "variablesReference": 0})
        return items

    def _port_items(self) -> list[dict]:
        d = self.dbg
        items = []
        for i, (name, _addr) in enumerate(Debugger.PORTS):
            v = d.read_port(name)
            if v is None:
                items.append({"name": name, "value": "(不可读)",
                              "variablesReference": 0})
            else:
                items.append({"name": name,
                              "value": f"0x{v:02x}  {d.bits(v)}",
                              "variablesReference": 3 + i})
        return items

    def _port_bit_items(self, idx: int) -> list[dict]:
        name, _addr = Debugger.PORTS[idx]
        v = self.dbg.read_port(name)
        items = []
        for b in range(7, -1, -1):
            bit = 0 if v is None else (v >> b) & 1
            items.append({"name": f"{name}.{b}", "value": "1" if bit else "0",
                          "variablesReference": 0})
        return items

    def on_variables(self, req: dict) -> None:
        ref = req.get("arguments", {}).get("variablesReference", 1)
        if ref == 2:
            self.response(req, {"variables": self._port_items()})
        elif 3 <= ref < 3 + len(Debugger.PORTS):
            self.response(req, {"variables": self._port_bit_items(ref - 3)})
        else:
            self.response(req, {"variables": self._register_items()})

    def on_evaluate(self, req: dict) -> None:
        expr = req.get("arguments", {}).get("expression", "").strip()
        d = self.dbg
        low = expr.lower().lstrip("$")
        if low == "pc":
            self.response(req, {"result": f"0x{d.pc():06x}", "variablesReference": 0})
            return
        # 端口：p1 / port1 / p1.3（位）
        m = re.fullmatch(r"(?:port)?(p[0-7])\.(\d)", low)
        if m:
            v = d.read_port(m.group(1))
            b = int(m.group(2))
            if v is None or not 0 <= b <= 7:
                self.response(req, {"result": "(端口不可读)", "variablesReference": 0})
            else:
                self.response(req, {"result": "1" if (v >> b) & 1 else "0",
                                    "variablesReference": 0})
            return
        m = re.fullmatch(r"(?:port)?(p[0-7])", low)
        if m:
            v = d.read_port(m.group(1))
            if v is None:
                self.response(req, {"result": "(端口不可读)", "variablesReference": 0})
            else:
                self.response(req, {"result": f"0x{v:02x}  {d.bits(v)}",
                                    "variablesReference": 0})
            return
        if re.fullmatch(r"r\d+", low):
            v = d._reg(low)
            self.response(req, {"result": f"0x{(v or 0) & 0xFF:02x}", "variablesReference": 0})
            return
        got = d.read_var(expr)
        if got is None:
            self.response(req, {"result": "（暂无法求值）", "variablesReference": 0})
            return
        data, sym = got
        self.response(req, {"result": d.format_value(data, sym), "variablesReference": 0})

    def on_setVariable(self, req: dict) -> None:
        self.response(req, success=False, message="暂不支持写变量")


def main() -> int:
    Session(Conn()).run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
