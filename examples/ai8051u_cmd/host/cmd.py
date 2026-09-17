#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""cmd.py — 主机端：给 AI8051U 的 `cmd` 固件下发 COBS 命令帧并解析回包。

帧格式（与 lib/cobs 一致）：
  原始：0x7E, id_lo, id_hi, 参数…, XOR      （XOR 从 id_lo 到参数末，不含 0x7E）
  线上：整帧 COBS 编码后以 0x00 定界。

命令（发）/ 应答（收，id | 0x8000）：
  0x0001 ping  —                      → 0x8001 u16 0x1234
  0x0002 mul   — u32 a, u32 b         → 0x8002 u32 (a*b)
  0x0003 div   — u32 a, u32 b         → 0x8003 u32 q, u32 r
  0x0004 led   — u8 on                → 0x8004 u8 状态
  0x0005 echo  — 原始字节             → 0x8005 原样
  板子上电自报：0x0001 u16 0x1234

用法：
  python cmd.py --selftest                 # 无硬件：COBS/帧往返自测
  python cmd.py -p COM8 monitor            # 只打印板子发来的帧
  python cmd.py -p COM8 ping
  python cmd.py -p COM8 mul 0x12345678 2
  python cmd.py -p COM8 div 1000 7
  python cmd.py -p COM8 led 1
  python cmd.py -p COM8 echo hello
  python cmd.py -p COM8 watch mul 6 7      # 保持串口，持续打印

依赖：pyserial（pip install pyserial）。
"""

from __future__ import annotations

import argparse
import socket
import struct
import sys
import time

for _s in (sys.stdout, sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass


# --------------------------------------------------------------------------- #
# COBS（与 lib/cobs 一致）
# --------------------------------------------------------------------------- #
def cobs_encode(data: bytes) -> bytes:
    out = bytearray()
    code_idx = 0
    out.append(0)          # 占位
    code = 1
    for b in data:
        if b == 0:
            out[code_idx] = code
            code_idx = len(out)
            out.append(0)
            code = 1
        else:
            if code == 255:
                out[code_idx] = code
                code_idx = len(out)
                out.append(0)
                code = 1
            out.append(b)
            code += 1
    out[code_idx] = code
    out.append(0x00)       # 定界符
    return bytes(out)


def cobs_decode(encoded: bytes) -> bytes:
    out = bytearray()
    i = 0
    n = len(encoded)
    while i < n:
        code = encoded[i]
        i += 1
        if code == 0:
            raise ValueError("COBS 流内出现 0x00")
        for _ in range(code - 1):
            if i >= n:
                raise ValueError("COBS 截断")
            out.append(encoded[i])
            i += 1
        if code < 255 and i < n:
            out.append(0)
    return bytes(out)


# --------------------------------------------------------------------------- #
# 帧
# --------------------------------------------------------------------------- #
def build_frame(cmd_id: int, params: bytes = b"") -> bytes:
    raw = bytearray([0x7E, cmd_id & 0xFF, (cmd_id >> 8) & 0xFF])
    raw += params
    ck = 0
    for b in raw[1:]:
        ck ^= b
    raw.append(ck)
    return cobs_encode(bytes(raw))


def parse_frame(raw: bytes):
    """返回 (id, payload) 或 None。"""
    if len(raw) < 4 or raw[0] != 0x7E:
        return None
    ck = 0
    for b in raw[1:-1]:
        ck ^= b
    if ck != raw[-1]:
        return None
    cid = raw[1] | (raw[2] << 8)
    return cid, raw[3:-1]


def u32(v: int) -> bytes:
    return struct.pack("<I", v & 0xFFFFFFFF)


def describe(cid: int, p: bytes) -> str:
    if cid == 0x0001 and len(p) == 2:
        return f"boot  magic=0x{struct.unpack('<H', p)[0]:04X}"
    if cid == 0x8001 and len(p) == 2:
        return f"pong  magic=0x{struct.unpack('<H', p)[0]:04X}"
    if cid == 0x8002 and len(p) == 4:
        return f"mul   ={struct.unpack('<I', p)[0]} (0x{struct.unpack('<I', p)[0]:08X})"
    if cid == 0x8003 and len(p) == 8:
        q, r = struct.unpack("<II", p)
        return f"div   q={q} (0x{q:08X})  r={r}"
    if cid == 0x8004 and len(p) == 1:
        return f"led   state={p[0]}"
    if cid == 0x8005:
        try:
            return f"echo  \"{p.decode('utf-8')}\""
        except UnicodeDecodeError:
            return f"echo  {p.hex(' ')}"
    if cid == 0x7FFF and len(p) == 3:
        return f"err   unknown id=0x{p[0] | (p[1] << 8):04X} code=0x{p[2]:02X}"
    if cid == 0x8010 and len(p) == 4:
        c, s = struct.unpack("<hh", p)
        return f"cos={c} ({c / 32768:.4f})  sin={s} ({s / 32768:.4f})"
    if cid == 0x8011 and len(p) == 2:
        a = struct.unpack("<h", p)[0]
        return f"atan2={a} BAM ({a / 65536 * 360:.3f}°)"
    if cid == 0x8012 and len(p) == 2:
        return f"sqrt={struct.unpack('<H', p)[0]}"
    if cid == 0x8013 and len(p) == 2:
        return f"mag={struct.unpack('<H', p)[0]}"
    return f"id=0x{cid:04X} payload={p.hex(' ')}"


# --------------------------------------------------------------------------- #
# 传输：真实串口 或 QEMU 的 TCP 串口
# --------------------------------------------------------------------------- #
class TcpPort:
    """把 QEMU 的 socket serial（-chardev socket,...）当串口用（pyserial 风格子集）。"""

    def __init__(self, host: str, port: int):
        self.sock = socket.create_connection((host, port), timeout=3)
        self.sock.settimeout(0.05)

    def read(self, n: int) -> bytes:
        try:
            return self.sock.recv(n)
        except socket.timeout:
            return b""

    def write(self, data) -> int:
        self.sock.sendall(bytes(data))
        return len(data)

    def flush(self):
        pass

    def reset_input_buffer(self):
        self.sock.settimeout(0)
        try:
            while self.sock.recv(4096):
                pass
        except Exception:
            pass
        self.sock.settimeout(0.05)

    def close(self):
        self.sock.close()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()


def open_port(port: str, baud: int):
    import serial  # 延迟导入：--selftest 不需要
    return serial.Serial(port, baud, timeout=0.05)


def open_transport(args):
    if args.tcp:
        host, _, p = args.tcp.partition(":")
        return TcpPort(host or "127.0.0.1", int(p or 5555))
    return open_port(args.port, args.baud)


def read_frames(ser, seconds: float):
    """在 seconds 内读串口，按 0x00 切帧，yield 解码后的原始帧。"""
    buf = bytearray()
    deadline = time.time() + seconds
    while time.time() < deadline:
        chunk = ser.read(256)
        if chunk:
            buf += chunk
            while True:
                idx = buf.find(0x00)
                if idx < 0:
                    break
                payload = bytes(buf[:idx])
                del buf[: idx + 1]
                if payload:
                    try:
                        raw = cobs_decode(payload)
                    except ValueError:
                        continue
                    parsed = parse_frame(raw)
                    if parsed:
                        yield parsed


def print_frame(cid: int, p: bytes):
    print(f"  <- id=0x{cid:04X}  {describe(cid, p)}   [{p.hex(' ')}]")


def send_frame(ser, frame: bytes, gap: float):
    ser.reset_input_buffer()
    if gap > 0:
        # QEMU 串口不建模位时序：整块灌会覆盖 SBUF → 逐字节喂
        for b in frame:
            ser.write(bytes([b]))
            time.sleep(gap)
    else:
        ser.write(frame)
    ser.flush()


def request(ser, cmd_id: int, params: bytes, reply_id: int, wait: float, gap: float):
    """发一帧，等指定 reply_id 的载荷（不打印，命中即返回），返回 bytes 或 None。"""
    send_frame(ser, build_frame(cmd_id, params), gap)
    deadline = time.time() + wait
    buf = bytearray()
    while time.time() < deadline:
        chunk = ser.read(256)
        if not chunk:
            continue
        buf += chunk
        while 0x00 in buf:
            i = buf.index(0)
            payload = bytes(buf[:i])
            del buf[: i + 1]
            if not payload:
                continue
            try:
                raw = cobs_decode(payload)
            except ValueError:
                continue
            pf = parse_frame(raw)
            if pf and pf[0] == reply_id:
                return pf[1]
    return None


def transact(ser, cmd_id: int, params: bytes, reply_ids, wait: float, gap: float = 0.0) -> bool:
    frame = build_frame(cmd_id, params)
    print(f"  -> id=0x{cmd_id:04X}  {params.hex(' ') if params else '(no params)'}")
    send_frame(ser, frame, gap)
    got = False
    for cid, p in read_frames(ser, wait):
        print_frame(cid, p)
        if cid in reply_ids:
            got = True
    if not got:
        print("  (无匹配回包)")
    return got


def selftest() -> int:
    # COBS 已知向量
    cases = [b"", b"\x00", b"\x00\x00\x00", b"\x11\x00\x00", b"\x11\x22", b"\x11\x00\x22"]
    for c in cases:
        enc = cobs_encode(c)
        dec = cobs_decode(enc[:-1])  # 去掉定界符
        assert dec == c, (c, dec)
    import random
    rnd = random.Random(1234)
    for _ in range(2000):
        n = rnd.randrange(0, 300)
        data = bytes(0 if rnd.random() < 0.3 else rnd.randrange(1, 256) for _ in range(n))
        enc = cobs_encode(data)
        assert 0x00 not in enc[:-1], data
        assert cobs_decode(enc[:-1]) == data
    # 帧往返
    f = build_frame(0x0002, u32(0x12345678) + u32(0xDEADBEEF))
    assert f[-1] == 0x00 and 0x00 not in f[:-1]
    cid, p = parse_frame(cobs_decode(f[:-1]))
    assert cid == 0x0002 and p == u32(0x12345678) + u32(0xDEADBEEF)
    print("selftest OK（COBS + 帧往返，2000 组随机）")
    return 0


# --------------------------------------------------------------------------- #
def cordic_verify(ser, wait: float, gap: float, count: int = 40) -> int:
    """随机向量跑 MCU 的 CORDIC（0x10-0x13），与 Python math 对拍。"""
    import math
    import random

    rnd = random.Random(7)
    bad = checked = 0

    def bam_diff(a, b):
        d = (a - b) % 65536
        return min(d, 65536 - d)

    for _ in range(count):
        ang = rnd.randrange(-32768, 32768)
        p = request(ser, 0x0010, struct.pack("<h", ang), 0x8010, wait, gap)
        if not p or len(p) != 4:
            print(f"  cossin 无回包 ang={ang}"); bad += 1
        else:
            c, s = struct.unpack("<hh", p)
            rad = ang / 65536 * 2 * math.pi
            ec, es = round(math.cos(rad) * 32768), round(math.sin(rad) * 32768)
            if max(abs(c - ec), abs(s - es)) > 16:
                print(f"  cossin FAIL ang={ang} (cos {c}/{ec} sin {s}/{es})"); bad += 1
            checked += 1

        y, x = rnd.randrange(-32767, 32768), rnd.randrange(-32767, 32768)
        p = request(ser, 0x0011, struct.pack("<hh", y, x), 0x8011, wait, gap)
        if not p or len(p) != 2:
            print("  atan2 无回包"); bad += 1
        else:
            g = struct.unpack("<h", p)[0]
            e = round(math.atan2(y, x) / (2 * math.pi) * 65536)
            if bam_diff(g, e) > 12:
                print(f"  atan2 FAIL y={y} x={x} ({g}/{e})"); bad += 1
            checked += 1

        p = request(ser, 0x0013, struct.pack("<hh", x, y), 0x8013, wait, gap)
        if p and len(p) == 2:
            g, e = struct.unpack("<H", p)[0], round(math.hypot(x, y))
            if abs(g - e) > 12:
                print(f"  mag FAIL x={x} y={y} ({g}/{e})"); bad += 1
            checked += 1

    for _ in range(10):
        v = rnd.randrange(0, 0xFFFFFFFF)
        p = request(ser, 0x0012, u32(v), 0x8012, wait, gap)
        if p and len(p) == 2:
            g, e = struct.unpack("<H", p)[0], math.isqrt(v)
            if g != e:
                print(f"  sqrt FAIL v={v} ({g}/{e})"); bad += 1
            checked += 1

    print(f"cordic verify: {checked} checks, {bad} bad -> {'PASS' if bad == 0 else 'FAIL'}")
    return 1 if bad else 0


# --------------------------------------------------------------------------- #
def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="AI8051U UART 命令下发（COBS 帧）")
    ap.add_argument("-p", "--port", help="串口，如 COM8")
    ap.add_argument("--tcp", help="改用 TCP 串口（QEMU），如 127.0.0.1:5555")
    ap.add_argument("-b", "--baud", type=int, default=115200)
    ap.add_argument("-w", "--wait", type=float, default=1.0, help="等回包秒数")
    ap.add_argument("--gap", type=float, default=None,
                    help="发送字节间隔秒（QEMU 用，默认 TCP 下 0.003、串口 0）")
    ap.add_argument("--selftest", action="store_true", help="无硬件自测")
    sub = ap.add_subparsers(dest="cmd", required=False)
    sub.add_parser("monitor", help="只打印板子发来的帧")
    sub.add_parser("ping")
    p_mul = sub.add_parser("mul"); p_mul.add_argument("a"); p_mul.add_argument("b")
    p_div = sub.add_parser("div"); p_div.add_argument("a"); p_div.add_argument("b")
    p_led = sub.add_parser("led"); p_led.add_argument("state", choices=["0", "1"])
    p_echo = sub.add_parser("echo"); p_echo.add_argument("text")
    sub.add_parser("cordictest", help="随机向量对拍 CORDIC（对比 Python math）")
    p_cs = sub.add_parser("cossin", help="i16 角(BAM) → cos/sin Q15"); p_cs.add_argument("angle")
    p_at = sub.add_parser("atan2", help="atan2(y,x) → BAM"); p_at.add_argument("y"); p_at.add_argument("x")
    p_sq = sub.add_parser("sqrt", help="整数开方 u32→u16"); p_sq.add_argument("v")
    p_mg = sub.add_parser("mag", help="幅长 sqrt(x²+y²)"); p_mg.add_argument("x"); p_mg.add_argument("y")
    p_watch = sub.add_parser("watch")
    p_watch.add_argument("sub", choices=["ping", "mul", "div", "led", "echo"])
    p_watch.add_argument("args", nargs="*")

    args = ap.parse_args(argv)

    if args.selftest:
        return selftest()
    if not args.port and not args.tcp:
        ap.error("需要 -p/--port 或 --tcp（或用 --selftest）")

    gap = args.gap if args.gap is not None else (0.003 if args.tcp else 0.0)
    dest = args.tcp if args.tcp else f"{args.port} @ {args.baud}"

    with open_transport(args) as ser:
        if args.cmd is None or args.cmd == "monitor":
            print(f"监听 {dest} ...（Ctrl+C 退出）")
            try:
                while True:
                    for cid, p in read_frames(ser, 1.0):
                        print_frame(cid, p)
            except KeyboardInterrupt:
                return 0

        if args.cmd == "ping":
            transact(ser, 0x0001, b"", {0x8001}, args.wait, gap)
        elif args.cmd == "mul":
            transact(ser, 0x0002, u32(int(args.a, 0)) + u32(int(args.b, 0)), {0x8002}, args.wait, gap)
        elif args.cmd == "div":
            transact(ser, 0x0003, u32(int(args.a, 0)) + u32(int(args.b, 0)), {0x8003}, args.wait, gap)
        elif args.cmd == "led":
            transact(ser, 0x0004, bytes([int(args.state)]), {0x8004}, args.wait, gap)
        elif args.cmd == "echo":
            transact(ser, 0x0005, args.text.encode("utf-8"), {0x8005}, args.wait, gap)
        elif args.cmd == "cossin":
            p = request(ser, 0x0010, struct.pack("<h", int(args.angle, 0)), 0x8010, args.wait, gap)
            print_frame(0x8010, p) if p else print("  (无匹配回包)")
        elif args.cmd == "atan2":
            p = request(ser, 0x0011, struct.pack("<hh", int(args.y, 0), int(args.x, 0)),
                        0x8011, args.wait, gap)
            print_frame(0x8011, p) if p else print("  (无匹配回包)")
        elif args.cmd == "sqrt":
            p = request(ser, 0x0012, u32(int(args.v, 0)), 0x8012, args.wait, gap)
            print_frame(0x8012, p) if p else print("  (无匹配回包)")
        elif args.cmd == "mag":
            p = request(ser, 0x0013, struct.pack("<hh", int(args.x, 0), int(args.y, 0)),
                        0x8013, args.wait, gap)
            print_frame(0x8013, p) if p else print("  (无匹配回包)")
        elif args.cmd == "cordictest":
            return cordic_verify(ser, args.wait, gap)
        elif args.cmd == "watch":
            fn = {"ping": 0x0001, "mul": 0x0002, "div": 0x0003, "led": 0x0004, "echo": 0x0005}[args.sub]
            if args.sub == "ping":
                params = b""
            elif args.sub in ("mul", "div"):
                params = u32(int(args.args[0], 0)) + u32(int(args.args[1], 0))
            elif args.sub == "led":
                params = bytes([int(args.args[0])])
            else:
                params = args.args[0].encode("utf-8")
            print("持续下发（Ctrl+C 退出）...")
            try:
                while True:
                    transact(ser, fn, params, {fn | 0x8000}, args.wait, gap)
                    time.sleep(0.2)
            except KeyboardInterrupt:
                return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
