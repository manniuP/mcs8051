#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""decode.py — 解析轻量二进制日志帧（COBS + 0x00 定界 + LEB128/字符串）。

与同目录 decode.ps1 **等价**（帧表/校验一致），用 Python+pyserial，供 ziglog / ccobs /
usbcdcobs(CDC) 通用。

原始帧：0x7E, id_lo, id_hi, 参数…, XOR（XOR 从 id_lo 到参数末）；整帧 COBS 后以单个 0x00 结束。

用法：
  python decode.py -p COM8               # 读 8 秒
  python decode.py -p COM8 -s 5
  python decode.py -p COM8 -b 115200     # baud 对 CDC 无效，忽略即可
"""

from __future__ import annotations

import argparse
import sys
import time

for _s in (sys.stdout, sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

TABLE = {
    0x0001: ("boot", []),
    0x0002: ("count", ["u16"]),
    0x0003: ("xy", ["u8", "u8"]),
    0x0004: ("cvar", ["var"]),
    0x0005: ("msg", ["str"]),
    0x0006: ("g16", ["u16"]),
}


def cobs_decode(enc: bytes):
    out = bytearray()
    i, n = 0, len(enc)
    while i < n:
        code = enc[i]
        i += 1
        if code == 0:
            return None
        for _ in range(code - 1):
            if i >= n:
                return None
            out.append(enc[i])
            i += 1
        if code < 255 and i < n:
            out.append(0)
    return bytes(out)


def read_frame(fr: bytes) -> bool:
    if len(fr) < 4 or fr[0] != 0x7E:
        return False
    fid = fr[1] | (fr[2] << 8)
    entry = TABLE.get(fid)
    if not entry:
        return False
    name, args = entry

    p = 3
    ck = fr[1] ^ fr[2]
    vals = []
    for t in args:
        if t == "str":
            ln = shift = 0
            while True:
                if p >= len(fr):
                    return False
                x = fr[p]; ck ^= x; p += 1
                ln |= (x & 0x7F) << shift; shift += 7
                if not (x & 0x80):
                    break
            if p + ln > len(fr):
                return False
            s = bytearray()
            for _ in range(ln):
                ck ^= fr[p]; s.append(fr[p]); p += 1
            vals.append('"' + s.decode("utf-8", "replace") + '"')
        elif t == "var":
            v = shift = 0
            while True:
                if p >= len(fr):
                    return False
                x = fr[p]; ck ^= x; p += 1
                v |= (x & 0x7F) << shift; shift += 7
                if not (x & 0x80):
                    break
            vals.append(str(v))
        else:
            nb = {"u8": 1, "u16": 2, "u32": 4}[t]
            if p + nb > len(fr):
                return False
            v = 0
            for k in range(nb):
                ck ^= fr[p]; v |= fr[p] << (8 * k); p += 1
            vals.append(str(v))

    if p >= len(fr) or ck != fr[p]:
        return False
    print(f"[0x{fid:04x}] {name:<6} {', '.join(vals)}")
    return True


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="轻量二进制日志帧解码（COBS）")
    ap.add_argument("-p", "--port", default="COM8")
    ap.add_argument("-b", "--baud", type=int, default=115200)
    ap.add_argument("-s", "--seconds", type=float, default=8.0)
    args = ap.parse_args(argv)

    import serial  # 延迟导入

    sp = serial.Serial(args.port, args.baud, timeout=0.1)
    print(f"reading {args.port} @ {args.baud} for {args.seconds}s ...")
    buf = bytearray()
    end = time.time() + args.seconds
    while time.time() < end:
        chunk = sp.read(4096)
        if chunk:
            buf += chunk
    sp.close()

    ok = bad = 0
    chunk = bytearray()
    for b in buf:
        if b == 0x00:
            if chunk:
                fr = cobs_decode(bytes(chunk))
                if fr is not None and read_frame(fr):
                    ok += 1
                else:
                    bad += 1
                chunk.clear()
        else:
            chunk.append(b)
    print(f"frames ok={ok} bad={bad} bytes={len(buf)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
