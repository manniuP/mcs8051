#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mcs_dbg.py —— MCS-251 外部调试器原型（SDCC CDB + QEMU GDB RSP）。

设计要点（第一刀）：
  - 符号来源：SDCC `--debug` 产生的 `.cdb`（**不改 SDCC**，仅读取）。
  - 执行后端：QEMU `qemu-system-mcs251 -M stc32g144k246` 的 GDB RSP
    （`-S -gdb tcp:127.0.0.1:<port>`，停机在复位点）。
  - MCS-251 语义：24 位 PC、大端、edata@0x0000 / xdata@0x10000 /
    exec-ram@0x30000 / flash@0xfc2800。
  - SFR@物理 0x01000000：**经 RSP 读不到**（QEMU 把调试地址掩到 24 位会回绕），
    故另开 QMP `xp`（物理读）读 SFR/端口；见 `Qmp`/`Qemu.read_phys`。
  - 串口：`--serial` 把 QEMU UART 输出转发到本进程 stdout（QEMU `-serial file:`）。
  - 端口：`ports` 打印 P0–P7；`x 0x1000010` 也可读 SFR（自动走物理读）。

本刀范围：源码断点 + 运行/单步 + 寄存器/内存 + 端口/串口（不含栈展开与局部变量）。

用法示例（WSL 内）：
  wsl python3 tools/mcs_dbg.py \
      --hex /tmp/sample.hex --cdb /tmp/sample.cdb \
      --qemu ~/qemu-mcs/build/qemu-system-mcs251 \
      --commands "b main; c; regs; ports; p g_sum; x 0x10000 8; q"

自测（无需 QEMU）：python3 tools/mcs_dbg.py --self-test
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
from dataclasses import dataclass, field as _field


# --------------------------------------------------------------------------
# CDB 解析
# --------------------------------------------------------------------------

def _type_size(typestr: str) -> int:
    """从类型串 `{N}...` 取字节数 N（取不到返回 1）。"""
    m = re.match(r"\{(\d+)\}", typestr)
    return int(m.group(1)) if m else 1


def _parts(mangled: str) -> list[str]:
    return mangled.split("$")


def _func_key(mangled: str) -> str:
    """函数匹配键：`G$add$0_0$0` / `Fmod$foo$1_0$2` -> `G$add` / `Fmod$foo`。"""
    p = _parts(mangled)
    return "$".join(p[:2]) if len(p) >= 2 else mangled


def _short_name(mangled: str) -> str:
    """展示名：`G$add$0_0$0` -> `add`；`Lmod.func$v$...` -> `v`。"""
    p = _parts(mangled)
    return p[1] if len(p) >= 2 else mangled


def _is_func_start(mangled: str) -> bool:
    """函数入口链接记录：`G$add$0$0`（第三段为纯数字）。
    数据符号是 `G$g_count$0_0$0`（第三段带 `_`），据此区分。"""
    p = _parts(mangled)
    return len(p) == 4 and p[2].isdigit() and p[3].isdigit()


@dataclass
class Function:
    mangled: str
    key: str
    name: str
    scope: str
    size: int
    type: str
    addrspace: str
    on_stack: int
    stack_off: int
    isr: int = 0
    intno: int = 0
    regbank: int = 0
    addr: int | None = None
    eaddr: int | None = None


@dataclass
class Symbol:
    mangled: str
    name: str
    scope: str          # `G` 全局 / `F<mod>` 文件级 / `L<mod>.<fn>` 局部
    localof: str | None
    size: int
    type: str
    addrspace: str
    on_stack: int
    stack_off: int
    regs: list[str] = _field(default_factory=list)
    addr: int | None = None


@dataclass
class CLine:
    src: str
    line: int
    level: str
    block: int
    addr: int


class Cdb:
    def __init__(self) -> None:
        self.modules: list[str] = []
        self.functions: dict[str, Function] = {}
        self.symbols: dict[str, Symbol] = {}         # 完整 mangled -> Symbol
        self.lines: dict[str, dict[int, list[int]]] = {}   # file -> line -> [addr]
        self.addr_lines: list[tuple[int, str, int]] = []   # (addr, file, line) 供反查

    # -- 解析入口 --------------------------------------------------------
    @classmethod
    def parse(cls, text: str) -> "Cdb":
        cdb = cls()
        for raw in text.splitlines():
            line = raw.strip()
            if not line or ":" not in line:
                continue
            tag = line[0]
            body = line[2:] if len(line) > 1 and line[1] == ":" else ""
            if tag == "M":
                cdb.modules.append(body)
            elif tag == "F":
                cdb._parse_func(body)
            elif tag == "S":
                cdb._parse_symbol(body)
            elif tag == "L":
                cdb._parse_linker(body)
            # `T:` 结构类型本刀暂不解析
        for sym in cdb.symbols.values():
            if sym.addr is not None:
                pass
        # 给函数补短名索引
        cdb.by_name = {f.name: f for f in cdb.functions.values()}
        return cdb

    @classmethod
    def from_file(cls, path: str) -> "Cdb":
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            return cls.parse(fh.read())

    # -- F: 函数 ---------------------------------------------------------
    def _parse_func(self, body: str) -> None:
        name, typ, rest = _split_symbol(body)
        if name is None:
            return
        fields = rest.split(",")
        # 寄存器形式：`R,0,0,[...]`（函数一般不出现）
        if fields and fields[0] == "R":
            return
        addrspace = fields[0] if len(fields) > 0 else "?"
        on_stack = int(fields[1]) if len(fields) > 1 and fields[1] else 0
        stack_off = int(fields[2]) if len(fields) > 2 and fields[2] else 0
        isr = int(fields[3]) if len(fields) > 3 and fields[3] else 0
        intno = int(fields[4]) if len(fields) > 4 and fields[4] else 0
        regbank = int(fields[5]) if len(fields) > 5 and fields[5] else 0
        fn = Function(
            mangled=name, key=_func_key(name), name=_short_name(name),
            scope=_parts(name)[0], size=_type_size(typ), type=typ,
            addrspace=addrspace, on_stack=on_stack, stack_off=stack_off,
            isr=isr, intno=intno, regbank=regbank,
        )
        self.functions[fn.key] = fn

    # -- S: 变量 ---------------------------------------------------------
    def _parse_symbol(self, body: str) -> None:
        name, typ, rest = _split_symbol(body)
        if name is None:
            return
        fields = rest.split(",")
        regs: list[str] = []
        if fields and fields[0] == "R":
            # `R,0,0,[r0,r1]`
            m = re.search(r"\[([^\]]*)\]", rest)
            if m and m.group(1):
                regs = [r for r in m.group(1).split(",") if r]
            addrspace, on_stack, stack_off = "R", 0, 0
        else:
            addrspace = fields[0] if len(fields) > 0 else "?"
            on_stack = int(fields[1]) if len(fields) > 1 and fields[1] else 0
            stack_off = int(fields[2]) if len(fields) > 2 and fields[2] else 0
        scope = _parts(name)[0]
        localof = scope[1:] if scope.startswith("L") and "." in scope else None
        sym = Symbol(
            mangled=name, name=_short_name(name), scope=scope, localof=localof,
            size=_type_size(typ), type=typ, addrspace=addrspace,
            on_stack=on_stack, stack_off=stack_off, regs=regs,
        )
        self.symbols[name] = sym

    # -- L: 链接地址记录 -------------------------------------------------
    def _parse_linker(self, body: str) -> None:
        name, sep, addr_hex = body.rpartition(":")
        if not sep:
            return
        try:
            addr = int(addr_hex, 16)
        except ValueError:
            return

        if name.startswith("C$"):
            # `C$sample.c$6$0_0$2`
            p = name.split("$")
            if len(p) >= 5:
                src, line = p[1], int(p[2])
                level = p[3]
                block = int(p[4]) if p[4].isdigit() else 0
                self.lines.setdefault(src, {}).setdefault(line, []).append(addr)
                self.addr_lines.append((addr, src, line))
            return
        if name.startswith("A$"):
            return  # 汇编行记录，本刀忽略
        # 函数出口：`XG$name$0$0`（可先建桩，Zig 无 `F:` 记录）。
        if name.startswith("X"):
            base = name[1:]
            key = _func_key(base)
            fn = self.functions.get(key)
            if fn is None:
                fn = Function(mangled=base, key=key, name=_short_name(base),
                              scope=_parts(base)[0], size=0, type="",
                              addrspace="C", on_stack=0, stack_off=0)
                self.functions[key] = fn
            fn.eaddr = addr
            return

        # 函数入口：`G$name$0$0`。
        if _is_func_start(name):
            key = _func_key(name)
            fn = self.functions.get(key)
            if fn is None:
                fn = Function(mangled=name, key=key, name=_short_name(name),
                              scope=_parts(name)[0], size=0, type="",
                              addrspace="C", on_stack=0, stack_off=0)
                self.functions[key] = fn
            fn.addr = addr
            return

        # 普通符号：全局 / 局部（可先建桩，类型未知；有 `S:` 记录时已带类型）。
        sym = self.symbols.get(name)
        if sym is None:
            scope = _parts(name)[0]
            localof = scope[1:] if scope.startswith("L") and "." in scope else None
            sym = Symbol(mangled=name, name=_short_name(name), scope=scope,
                         localof=localof, size=1, type="", addrspace="?",
                         on_stack=0, stack_off=0)
            self.symbols[name] = sym
        sym.addr = addr

    # -- 查询 -----------------------------------------------------------
    def find_function(self, name: str) -> Function | None:
        if name in self.functions:
            return self.functions[name]
        exact = self.by_name.get(name)
        if exact:
            return exact
        for fn in self.functions.values():
            if fn.name == name or fn.mangled == name:
                return fn
        return None

    def find_symbol(self, name: str) -> Symbol | None:
        if name in self.symbols:
            return self.symbols[name]
        for sym in self.symbols.values():
            if sym.name == name or sym.mangled == name:
                return sym
        return None

    def line_addr(self, src: str, line: int) -> int | None:
        addrs = self.lines.get(src, {}).get(line)
        if not addrs:
            # 允许只给基名或只给后缀匹配
            for key, table in self.lines.items():
                if key == src or key.endswith("/" + src) or src.endswith(key):
                    if line in table:
                        addrs = table[line]
                        break
        return min(addrs) if addrs else None

    def addr_to_line(self, addr: int) -> tuple[str, int] | None:
        best = None
        for a, src, line in self.addr_lines:
            if a <= addr and (best is None or a > best[0]):
                best = (a, src, line)
        return (best[1], best[2]) if best else None


def _split_symbol(body: str) -> tuple[str | None, str, str]:
    """`G$add$0_0$0({3}DF,SI:S),C,0,0` -> (name, type, rest)。

    rest 为类型串之后的字段（如 `C,0,0,0,0,0`）。
    """
    open_paren = body.find("(")
    if open_paren < 0:
        return None, "", ""
    close_paren = body.find(")", open_paren)
    if close_paren < 0:
        return None, "", ""
    name = body[:open_paren]
    typ = body[open_paren + 1:close_paren]
    rest = body[close_paren + 1:]
    if rest.startswith(","):
        rest = rest[1:]
    return name, typ, rest


# --------------------------------------------------------------------------
# GDB RSP 客户端
# --------------------------------------------------------------------------

def _rsp_escape(payload: bytes) -> bytes:
    out = bytearray()
    for b in payload:
        if b in b"#$}*":
            out += bytes((ord("}"), b ^ 0x20))
        else:
            out.append(b)
    return bytes(out)


def _rsp_unescape(payload: bytes) -> bytes:
    out = bytearray()
    i = 0
    while i < len(payload):
        b = payload[i]
        if b == ord("}"):
            i += 1
            out.append(payload[i] ^ 0x20)
        elif b == ord("*"):
            i += 1
            out.extend([out[-1]] * (payload[i] - 29))
        else:
            out.append(b)
        i += 1
    return bytes(out)


def encode_packet(text: str) -> bytes:
    payload = _rsp_escape(text.encode("ascii"))
    return b"$" + payload + b"#" + f"{sum(payload) & 0xff:02x}".encode("ascii")


class Rsp:
    def __init__(self, conn: socket.socket) -> None:
        self.conn = conn
        self.conn.settimeout(10)

    # -- 底层 -----------------------------------------------------------
    def _recv(self, n: int) -> bytes:
        data = bytearray()
        while len(data) < n:
            chunk = self.conn.recv(n - len(data))
            if not chunk:
                raise RuntimeError("QEMU 关闭了 GDB 连接")
            data += chunk
        return bytes(data)

    def _recv_packet(self) -> bytes:
        while True:
            ch = self._recv(1)
            if ch in (b"+", b"-"):
                continue
            if ch != b"$":
                continue
            body = bytearray()
            while True:
                c = self._recv(1)
                if c == b"#":
                    break
                body += c
            csum = self._recv(2)
            if f"{sum(body) & 0xff:02x}".encode("ascii").lower() != csum.lower():
                self.conn.sendall(b"-")
                continue
            self.conn.sendall(b"+")
            return _rsp_unescape(bytes(body))

    def send_packet(self, text: str) -> None:
        self.conn.sendall(encode_packet(text))

    def request(self, text: str) -> bytes:
        self.send_packet(text)
        return self._recv_packet()

    def interrupt(self) -> None:
        self.conn.sendall(b"\x03")

    def wait_stop(self) -> bytes:
        """等待一个停机应答（用于中断目标后同步）。"""
        return self._recv_packet()

    # -- 语义 -----------------------------------------------------------
    def memory(self, addr: int, length: int) -> bytes:
        out = bytearray()
        while length > 0:
            n = min(length, 0x100)
            reply = self.request(f"m{addr:x},{n:x}")
            if reply[:1] == b"E":
                raise RuntimeError(f"读内存失败 @0x{addr:x}: {reply!r}")
            out += bytes.fromhex(reply.decode("ascii"))
            addr += n
            length -= n
        return bytes(out)

    def register(self, num: int) -> bytes:
        reply = self.request(f"p{num:x}")
        if reply[:1] == b"E":
            raise RuntimeError(f"读寄存器 {num} 失败: {reply!r}")
        return bytes.fromhex(reply.decode("ascii"))

    def set_breakpoint(self, addr: int) -> None:
        reply = self.request(f"Z0,{addr:x},1")
        if reply != b"OK":
            raise RuntimeError(f"下断点失败 @0x{addr:x}: {reply!r}")

    def clear_breakpoint(self, addr: int) -> None:
        self.request(f"z0,{addr:x},1")

    def cont(self) -> bytes:
        return self.request("c")

    def step(self) -> bytes:
        return self.request("s")

    def read_xml(self, name: str) -> str:
        chunks: list[str] = []
        offset = 0
        while True:
            reply = self.request(f"qXfer:features:read:{name}:{offset:x},400")
            if not reply or reply[:1] not in (b"l", b"m"):
                raise RuntimeError(f"读取目标描述失败 {name}: {reply!r}")
            chunk = reply[1:].decode("ascii")
            chunks.append(chunk)
            offset += len(chunk)
            if reply[:1] == b"l":
                return "".join(chunks)

    def registers(self) -> dict[str, int]:
        """读取目标 XML 得到寄存器名 -> 编号（跟随 include href）。

        容错：QEMU 的 `target.xml` 用未声明的 `xi:` 前缀，不能直接 XML 解析，
        因此这里按 `<reg ...>` 标签正则解析。
        """
        numbers: dict[str, int] = {}
        pending = ["target.xml"]
        seen: set[str] = set()
        while pending:
            name = pending.pop(0)
            if name in seen:
                continue
            seen.add(name)
            text = self.read_xml(name)
            for href in re.findall(r'href=["\']([^"\']+)["\']', text):
                if href not in seen:
                    pending.append(href)
            idx = 0
            for m in re.finditer(r"<reg\b[^>]*>", text):
                attrs = dict(re.findall(
                    r'([A-Za-z_][\w.-]*)\s*=\s*"([^"]*)"', m.group(0)))
                if "name" not in attrs:
                    continue
                if "regnum" in attrs:
                    idx = int(attrs["regnum"], 0)
                numbers[attrs["name"].lower()] = idx
                idx += 1
        return numbers


# --------------------------------------------------------------------------
# QEMU 启动/停止
# --------------------------------------------------------------------------

def _free_port() -> int:
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


class Qmp:
    """QEMU QMP 客户端：用 `human-monitor-command` 跑 HMP `xp` 读**物理**内存。

    为什么不用 GDB RSP 读 SFR：QEMU 的 `mcs251_cpu_get_phys_addr_debug` 把地址
    掩到 24 位（`& 0xffffff`），而 SFR 在物理 `0x01000000`——经 RSP 读会回绕到低
    地址。`xp`（物理）不受此限制，且 CPU 运行时也能读，故用它读 P0–P7 端口。
    """

    def __init__(self, path: str) -> None:
        self.path = path
        self.sock: socket.socket | None = None
        self._buf = b""

    def connect(self, timeout: float = 5.0) -> None:
        if self.sock is not None:
            return
        deadline = time.monotonic() + timeout
        last: OSError | None = None
        while time.monotonic() < deadline:
            try:
                s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                s.settimeout(2.0)
                s.connect(self.path)
                self.sock = s
                self._read_msg()            # QMP greeting
                self._send_cmd({"execute": "qmp_capabilities"})
                return
            except OSError as exc:
                last = exc
                time.sleep(0.05)
        raise RuntimeError(f"连接 QEMU QMP 失败（{self.path}）：{last}")

    def _read_msg(self) -> dict:
        assert self.sock is not None
        while b"\n" not in self._buf:
            chunk = self.sock.recv(65536)
            if not chunk:
                raise RuntimeError("QMP 连接关闭")
            self._buf += chunk
        line, _, rest = self._buf.partition(b"\n")
        self._buf = rest
        return json.loads(line.decode("utf-8", "replace"))

    def _send_cmd(self, obj: dict) -> dict:
        assert self.sock is not None
        self.sock.sendall(json.dumps(obj).encode("utf-8") + b"\n")
        while True:
            msg = self._read_msg()
            if "event" in msg:      # 忽略异步事件
                continue
            return msg

    def hmp(self, command: str) -> str:
        self.connect()
        msg = self._send_cmd({"execute": "human-monitor-command",
                              "arguments": {"command-line": command}})
        if "error" in msg:
            raise RuntimeError(str(msg["error"]))
        return msg.get("return", "")

    def read_mem(self, addr: int, n: int) -> bytes:
        text = self.hmp(f"xp /{n}xb 0x{addr:x}")
        if "Cannot access" in text:
            raise RuntimeError(f"读物理内存失败 @0x{addr:x}")
        vals = re.findall(r"0x([0-9a-fA-F]+)", text)
        return bytes(int(v, 16) & 0xFF for v in vals)

    def close(self) -> None:
        if self.sock is not None:
            try:
                self.sock.close()
            except OSError:
                pass
            self.sock = None


class Qemu:
    def __init__(self, exe: str, machine: str, firmware: str,
                 extra: list[str] | None = None, capture_serial: bool = False,
                 on_serial=None) -> None:
        self.exe = exe
        self.machine = machine
        self.firmware = firmware
        self.extra = list(extra or [])
        self.port = _free_port()
        self.proc: subprocess.Popen | None = None
        self._tmp_hex: str | None = None
        self.capture_serial = capture_serial
        self.on_serial = on_serial
        self.qmp_path = os.path.join(
            tempfile.gettempdir(), f"mcsdbg-qmp-{os.getpid()}-{self.port}.sock")
        self._qmp: Qmp | None = None
        self._serial_path: str | None = None
        self._serial_thread: threading.Thread | None = None
        self._serial_stop = threading.Event()

    def _prepare_hex(self) -> str:
        # QEMU 仅当后缀为 .hex 时走 Intel HEX 载入器（.ihx 会被当 raw）。
        if self.firmware.lower().endswith(".hex"):
            return self.firmware
        fd, tmp = tempfile.mkstemp(suffix=".hex", prefix="mcsdbg.")
        os.close(fd)
        shutil.copyfile(self.firmware, tmp)
        self._tmp_hex = tmp
        return tmp

    def read_phys(self, addr: int, n: int) -> bytes:
        """经 QMP `xp` 读物理内存（可读 SFR；RSP 会把地址掩到 24 位读不到）。"""
        if self._qmp is None:
            self._qmp = Qmp(self.qmp_path)
        return self._qmp.read_mem(addr, n)

    def _start_serial_reader(self) -> None:
        path = self._serial_path
        assert path is not None

        def pump() -> None:
            pos = 0
            while not self._serial_stop.is_set():
                try:
                    with open(path, "rb") as f:
                        f.seek(pos)
                        data = f.read()
                    if data:
                        pos += len(data)
                        if self.on_serial is not None:
                            self.on_serial(data.decode("utf-8", "replace"))
                except (FileNotFoundError, ValueError, OSError):
                    pass
                self._serial_stop.wait(0.05)

        self._serial_thread = threading.Thread(target=pump, daemon=True)
        self._serial_thread.start()

    def start(self, timeout: float = 8.0) -> Rsp:
        hexpath = self._prepare_hex()
        cmd = [
            self.exe, "-M", self.machine, "-bios", hexpath,
            "-display", "none",
            "-qmp", f"unix:{self.qmp_path},server,nowait",
            "-S", "-gdb", f"tcp:127.0.0.1:{self.port}",
        ]
        if self.capture_serial:
            self._serial_path = os.path.join(
                tempfile.gettempdir(),
                f"mcsdbg-serial-{os.getpid()}-{self.port}.txt")
            try:
                os.unlink(self._serial_path)
            except FileNotFoundError:
                pass
            cmd += ["-serial", f"file:{self._serial_path}"]
            self._start_serial_reader()
        else:
            cmd += ["-serial", "null"]
        cmd += self.extra
        self.proc = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT)
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if self.proc.poll() is not None:
                out = self.proc.stdout.read() if self.proc.stdout else b""
                raise RuntimeError(f"QEMU 提前退出：\n{out.decode(errors='replace')}")
            try:
                conn = socket.create_connection(("127.0.0.1", self.port), 0.5)
                return Rsp(conn)
            except OSError:
                time.sleep(0.05)
        raise RuntimeError("连接 QEMU GDB 端点超时")

    def stop(self) -> None:
        self._serial_stop.set()
        if self._serial_thread is not None:
            self._serial_thread.join(timeout=1.0)
            self._serial_thread = None
        if self._qmp is not None:
            self._qmp.close()
            self._qmp = None
        if self.proc and self.proc.poll() is None:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.proc.kill()
                self.proc.wait()
        if self._tmp_hex and os.path.exists(self._tmp_hex):
            os.unlink(self._tmp_hex)
            self._tmp_hex = None
        for path in (self._serial_path, self.qmp_path):
            if path and os.path.exists(path):
                try:
                    os.unlink(path)
                except OSError:
                    pass
        self._serial_path = None


# --------------------------------------------------------------------------
# 调试器外壳
# --------------------------------------------------------------------------

class Debugger:
    # 端口数据寄存器物理地址（STC32G GPIO，SFR 物理基址 0x01000000+偏移）。
    PORTS = (("P0", 0x1000000), ("P1", 0x1000010), ("P2", 0x1000020),
             ("P3", 0x1000030), ("P4", 0x1000040), ("P5", 0x1000048),
             ("P6", 0x1000068), ("P7", 0x1000078))
    PORT_ADDR = {name.lower(): addr for name, addr in PORTS}

    def __init__(self, cdb: Cdb, rsp: Rsp, read_phys=None) -> None:
        self.cdb = cdb
        self.rsp = rsp
        self.regs = rsp.registers()
        self.breakpoints: dict[int, str] = {}
        self._pending: int | None = None   # 单步临时断点
        self.read_phys = read_phys         # 可选：QMP 物理内存读（读 SFR/端口）

    # -- 辅助 -----------------------------------------------------------
    def _reg(self, name: str) -> int | None:
        num = self.regs.get(name.lower())
        if num is None:
            return None
        raw = self.rsp.register(num)
        return int.from_bytes(raw, "big") if raw else None

    def pc(self) -> int:
        v = self._reg("pc")
        return (v & 0xFFFFFF) if v is not None else 0

    def _u32(self, base: str) -> int | None:
        """合成 SPX/DPX：4 个字节寄存器 r60..r63（大端）。"""
        out = 0
        any_ok = False
        for i in range(4):
            v = self._reg(f"{base}{i}")
            if v is None:
                return None
            out = (out << 8) | (v & 0xFF)
            any_ok = True
        return out if any_ok else None

    def decode_stop(self, reply: bytes) -> str:
        text = reply.decode("ascii", "replace")
        if text.startswith(("S", "T")):
            sig = text[1:3]
            who = self._pending if (self._pending is not None
                                    and self.pc() == self._pending) else None
            if who is not None:
                self.rsp.clear_breakpoint(who)
                self._pending = None
            src = self.cdb.addr_to_line(self.pc())
            where = f" {src[0]}:{src[1]}" if src else ""
            return f"停机 signal={sig} PC=0x{self.pc():06x} ({text}){where}"
        return f"未预期停机应答：{text!r}"

    def read_var(self, name: str) -> tuple[bytes, Symbol] | None:
        sym = self.cdb.find_symbol(name)
        if sym is None or sym.addr is None:
            return None
        data = self.rsp.memory(sym.addr, sym.size)
        return data, sym

    @staticmethod
    def format_value(data: bytes, sym: Symbol) -> str:
        # MCS-251 大端
        val = int.from_bytes(data, "big") if data else 0
        kind = sym.type
        if "SF" in kind:
            import struct
            fmt = ">f" if len(data) == 4 else ">d"
            try:
                return repr(struct.unpack(fmt, data)[0])
            except Exception:
                pass
        if "SC" in kind and len(data) == 1:
            ch = data[0]
            if 0x20 <= ch < 0x7F:
                return f"0x{val:x} ({chr(ch)!r})"
            return f"0x{val:x}"
        return f"0x{val:x} ({val})"

    # -- 端口（GPIO） ---------------------------------------------------
    def read_port(self, name: str) -> int | None:
        """读端口数据寄存器（P0–P7）。需 `read_phys`（QMP `xp`）。"""
        addr = self.PORT_ADDR.get(name.lower())
        if addr is None or self.read_phys is None:
            return None
        try:
            return self.read_phys(addr, 1)[0]
        except Exception:
            return None

    @staticmethod
    def bits(value: int) -> str:
        """`0xfd` -> `11111101`（bit7..bit0）。"""
        return format(value & 0xFF, "08b")

    def cmd_ports(self, args: list[str]) -> None:
        if self.read_phys is None:
            print("端口不可读（QEMU 未提供 QMP 物理读）")
            return
        for name, _addr in self.PORTS:
            v = self.read_port(name)
            if v is None:
                print(f"{name} = (不可读)")
            else:
                print(f"{name} = 0x{v:02x}  [{self.bits(v)}]  "
                      f"(bit7..bit0)")

    # -- 命令 -----------------------------------------------------------
    def cmd_break(self, args: list[str]) -> None:
        if not args:
            if not self.breakpoints:
                print("(无断点)")
                return
            for addr, what in sorted(self.breakpoints.items()):
                print(f"  #{addr:#010x}  {what}")
            return
        spec = args[0]
        if spec.startswith("*"):
            addr = int(spec[1:], 0)
            what = f"*{addr:#x}"
        elif ":" in spec:
            src, line = spec.rsplit(":", 1)
            addr = self.cdb.line_addr(src, int(line))
            what = spec
        elif re.fullmatch(r"0[xX][0-9a-fA-F]+|\d+", spec):
            addr = int(spec, 0)
            what = f"*{addr:#x}"
        else:
            fn = self.cdb.find_function(spec)
            if fn is None or fn.addr is None:
                print(f"找不到函数：{spec}")
                return
            addr = fn.addr
            what = f"func {spec}"
        if addr is None:
            print(f"找不到地址：{spec}")
            return
        self.rsp.set_breakpoint(addr)
        self.breakpoints[addr] = what
        print(f"断点 @0x{addr:06x}  ({what})")

    def cmd_continue(self) -> None:
        # 若当前 PC 正好在断点上，先摘断点单步跨过再恢复（裸 RSP 不会自动跳过）。
        pc = self.pc()
        if pc in self.breakpoints:
            self.rsp.clear_breakpoint(pc)
            self.rsp.step()
            self.rsp.set_breakpoint(pc)
        try:
            print(self.decode_stop(self.rsp.cont()))
        except (TimeoutError, socket.timeout):
            # 目标仍在运行（例如无断点的死循环）：发中断包并同步停机状态。
            try:
                self.rsp.interrupt()
                print("(运行中，已中断) " + self.decode_stop(self.rsp.wait_stop()))
            except (TimeoutError, socket.timeout):
                print("(运行中：超时未停机；目标可能进入无限循环)")

    def cmd_stepi(self) -> None:
        try:
            print(self.decode_stop(self.rsp.step()))
        except (TimeoutError, socket.timeout):
            print("(单步超时)")

    def cmd_regs(self) -> None:
        print(f"PC   = 0x{self.pc():06x}")
        for name in ("psw", "psw1"):
            v = self._reg(name)
            if v is not None:
                print(f"{name.upper():5}= 0x{v:02x}")
        spx = self._u32("r60")
        dpx = self._u32("r56")
        if spx is not None:
            print(f"SPX  = 0x{spx:08x}  (低 16 位即 SPH:SP = 0x{spx & 0xFFFF:04x})")
        if dpx is not None:
            print(f"DPX  = 0x{dpx:08x}")
        for row in range(4):
            cells = []
            for col in range(8):
                n = row * 8 + col
                v = self._reg(f"r{n}")
                cells.append(f"R{n:<2}=0x{(v & 0xFF) if v is not None else 0:02x}")
            print(" ".join(cells))
        src = self.cdb.addr_to_line(self.pc())
        if src:
            print(f"当前源码：{src[0]}:{src[1]}")

    def cmd_x(self, args: list[str]) -> None:
        if not args:
            print("用法：x <addr> [len]")
            return
        addr = int(args[0], 0)
        length = int(args[1], 0) if len(args) > 1 else 16
        if self.read_phys is not None and addr >= 0x1000000:
            # SFR 区（物理 0x01000000 起）经 RSP 会被掩到 24 位，改用 QMP 物理读。
            try:
                data = self.read_phys(addr, length)
            except Exception as exc:
                print(f"读物理内存失败：{exc}")
                return
        else:
            data = self.rsp.memory(addr, length)
        for off in range(0, len(data), 16):
            chunk = data[off:off + 16]
            hexs = " ".join(f"{b:02x}" for b in chunk)
            text = "".join(chr(b) if 0x20 <= b < 0x7F else "." for b in chunk)
            print(f"{addr + off:08x}  {hexs:<47}  {text}")

    def cmd_print(self, args: list[str]) -> None:
        if not args:
            print("用法：p <变量名>")
            return
        got = self.read_var(args[0])
        if got is None:
            print(f"找不到变量（或寄存器/无地址）：{args[0]}")
            return
        data, sym = got
        print(f"{sym.name} @0x{sym.addr:06x} [{sym.addrspace}] = "
              f"{self.format_value(data, sym)}")

    def cmd_syms(self, args: list[str]) -> None:
        pat = args[0] if args else ""
        for fn in sorted(self.cdb.functions.values(), key=lambda f: f.name):
            if pat and pat not in fn.name:
                continue
            if fn.addr is not None:
                print(f"F  0x{fn.addr:06x}  {fn.name}  {fn.type}")
        for sym in sorted(self.cdb.symbols.values(), key=lambda s: s.name):
            if pat and pat not in sym.name:
                continue
            if sym.addr is not None and sym.localof is None:
                print(f"S  0x{sym.addr:06x}  {sym.name}  {sym.type}")

    def cmd_lines(self, args: list[str]) -> None:
        if not args:
            print("用法：lines <file.c>")
            return
        for line in sorted(self.cdb.lines.get(args[0], {})):
            print(f"  {args[0]}:{line} -> 0x{self.cdb.line_addr(args[0], line):06x}")

    def dispatch(self, line: str) -> bool:
        line = line.split("#", 1)[0].strip()
        if not line:
            return True
        parts = line.split()
        cmd, args = parts[0], parts[1:]
        if cmd in ("q", "quit", "exit"):
            return False
        if cmd in ("b", "break"):
            self.cmd_break(args)
        elif cmd in ("c", "continue"):
            self.cmd_continue()
        elif cmd in ("si", "stepi", "s"):
            self.cmd_stepi()
        elif cmd in ("regs", "registers"):
            self.cmd_regs()
        elif cmd == "x":
            self.cmd_x(args)
        elif cmd in ("p", "print"):
            self.cmd_print(args)
        elif cmd in ("info", "syms", "funcs"):
            self.cmd_syms(args)
        elif cmd == "lines":
            self.cmd_lines(args)
        elif cmd in ("ports", "port"):
            self.cmd_ports(args)
        elif cmd == "help":
            print("命令：b <file:line|func|*addr> | c | si | regs | ports | "
                  "x <addr> [len] | p <var> | syms [pat] | lines <file> | help | q")
        else:
            print(f"未知命令：{cmd}（help 查看）")
        return True


# --------------------------------------------------------------------------
# 自测
# --------------------------------------------------------------------------

SELFTEST_CDB = """M:sample
F:G$add$0_0$0({3}DF,SI:S),C,0,0,0,0,0
F:G$main$0_0$0({3}DF,SV:S),C,0,0,0,0,0
S:G$g_count$0_0$0({1}SC:U),F,0,0
S:G$g_sum$0_0$0({2}SI:U),F,0,0
S:Lsample.add$b$1_0$1({2}SI:S),F,0,0
L:G$g_count$0_0$0:10000
L:G$g_sum$0_0$0:10001
L:Lsample.add$b$1_0$1:10003
L:C$sample.c$6$0_0$2:FC281D
L:C$sample.c$8$1_0$2:FC2836
L:G$add$0$0:FC281D
L:C$sample.c$15$2_0$5:FC28BA
L:C$sample.c$15$2_0$4:FC286B
L:XG$add$0$0:FC286A
L:G$main$0$0:FC286B
L:XG$main$0$0:FC28CA
"""


def self_test() -> int:
    failures = 0

    def check(cond: bool, what: str) -> None:
        nonlocal failures
        if cond:
            print(f"  通过  {what}")
        else:
            failures += 1
            print(f"  失败  {what}")

    cdb = Cdb.parse(SELFTEST_CDB)
    check(cdb.modules == ["sample"], "模块解析")
    add = cdb.find_function("add")
    check(add is not None and add.addr == 0xFC281D and add.eaddr == 0xFC286A,
          "函数 add 起止地址")
    check(add is not None and add.size == 3, "函数 add 类型尺寸")
    main = cdb.find_function("main")
    check(main is not None and main.addr == 0xFC286B, "函数 main 地址")
    gsum = cdb.find_symbol("g_sum")
    check(gsum is not None and gsum.addr == 0x10001 and gsum.size == 2,
          "全局 g_sum 地址/尺寸")
    b = cdb.find_symbol("b")
    check(b is not None and b.addr == 0x10003 and b.localof == "sample.add",
          "局部 b 地址/归属")
    check(cdb.line_addr("sample.c", 6) == 0xFC281D, "行 6 -> 地址")
    check(cdb.line_addr("sample.c", 15) == 0xFC286B, "多地址行取最小")
    check(cdb.addr_to_line(0xFC2836) == ("sample.c", 8), "地址反查行号")

    pkt = encode_packet("m10000,4")
    check(pkt.startswith(b"$m10000,4#"), "RSP 打包前缀")
    check(_rsp_unescape(_rsp_escape(b"a#b}c*d")) == b"a#b}c*d", "RSP 转义往返")

    print("自测：" + ("通过" if failures == 0 else f"{failures} 项失败"))
    return 1 if failures else 0


# --------------------------------------------------------------------------
# 入口
# --------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="MCS-251 外部调试器原型（CDB + QEMU RSP）")
    ap.add_argument("--hex", help="固件（.hex；.ihx 会自动复制成 .hex）")
    ap.add_argument("--cdb", help="SDCC --debug 产生的 .cdb")
    ap.add_argument("--qemu", default=os.environ.get(
        "QEMU_MCS", "qemu-system-mcs251"), help="qemu-system-mcs251 路径")
    ap.add_argument("--machine", default="stc32g144k246")
    ap.add_argument("--port", type=int, default=0, help="（保留：0=自动）")
    ap.add_argument("--commands", help="分号分隔的批量命令，执行后退出")
    ap.add_argument("--qemu-arg", action="append", default=[],
                    help="追加给 QEMU 的参数（可重复）")
    ap.add_argument("--serial", action="store_true",
                    help="把 QEMU 串口输出转发到本进程 stdout")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args(argv)

    if args.self_test:
        return self_test()
    if not args.hex or not args.cdb:
        ap.error("需要 --hex 与 --cdb（或用 --self-test）")

    def _show_serial(text: str) -> None:
        sys.stdout.write(text)
        sys.stdout.flush()

    cdb = Cdb.from_file(args.cdb)
    qemu = Qemu(args.qemu, args.machine, args.hex, args.qemu_arg,
                capture_serial=args.serial,
                on_serial=_show_serial if args.serial else None)
    rsp = None
    try:
        rsp = qemu.start()
        dbg = Debugger(cdb, rsp, qemu.read_phys)
        print(f"已连接 QEMU（{args.machine}），寄存器 {len(dbg.regs)} 个，"
              f"函数 {len(cdb.functions)} 个，PC=0x{dbg.pc():06x}")
        if args.commands:
            for cmd in args.commands.split(";"):
                if not dbg.dispatch(cmd):
                    break
        else:
            while True:
                try:
                    line = input("(mcsdbg) ")
                except EOFError:
                    break
                if not dbg.dispatch(line):
                    break
    finally:
        if rsp is not None:
            rsp.conn.close()
        qemu.stop()
    return 0


if __name__ == "__main__":
    sys.exit(main())
