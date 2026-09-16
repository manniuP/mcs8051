#!/usr/bin/env python3
"""mcs_ir.py —— 消费后端 IR 提示（`; vN ...`）做值级优化，并删掉提示。

后端在每条 AIR 指令前输出：`; v<inst> <tag> <操作数…> [-> @spx<disp>]`。
本工具夹在 `mcs_opt.py` 之后、`sdas` 之前：

  1) **死 store 消除**：`mov @spx<d>,X` 若 `@spx<d>` 在该函数其后**再也不出现**
     （不读也不写），说明该帧槽是死值 → 删掉这条 store（计算保留，供后续从 A 取用）；
  2) 删掉所有 IR 提示注释。

安全：只删「本函数其后没有任何 `@spx<d>` 出现」的 store；函数边界按全局标号 `_sym:` 划分。
IR 提示注释本身也算 `@spx<d>`，扫描时跳过注释行，避免自证。

用法：python tools/mcs_ir.py <a.asm> [b.asm ...]   /   --self-test
"""
import re
import sys
from pathlib import Path

TRACE_RE = re.compile(r"^\s*;\s*v(\d+)\s+(\S+)(.*)$")
MEM_RE = re.compile(r"@spx(?P<off>-?0x[0-9a-fA-F]+|-?\d+)?")
STORE_RE = re.compile(r"^\s*mov\s+@spx(?P<off>-?0x[0-9a-fA-F]+|-?\d+)?\s*,")
GFUNC_RE = re.compile(r"^_\w+:\s*$")


def norm_slot(off):
    return "@spx%+d" % (0 if off is None else int(off, 0))


def optimize(lines):
    func_starts = [i for i, ln in enumerate(lines) if GFUNC_RE.match(ln)]

    def func_span(i):
        start = 0
        for b in func_starts:
            if b <= i:
                start = b
            else:
                break
        end = len(lines)
        for b in func_starts:
            if b > i:
                end = b
                break
        return start, end

    delete = set()
    for i, ln in enumerate(lines):
        sm = STORE_RE.match(ln)
        if not sm:
            continue
        slot = norm_slot(sm.group("off"))
        start, end = func_span(i)
        # 关键：扫**整个函数**（含本 store 之前的代码）——循环回边会让“本的 store 之后的读”
        # 出现在地址更小处；只看后面会误删循环变量。此槽在别处任何出现都算“有人用”。
        used = False
        for j in range(start, end):
            if j == i or lines[j].lstrip().startswith(";"):
                continue
            if any(norm_slot(m.group("off")) == slot for m in MEM_RE.finditer(lines[j])):
                used = True
                break
        if not used:
            delete.add(i)

    out = []
    for i, ln in enumerate(lines):
        if i in delete:
            continue
        if TRACE_RE.match(ln.rstrip("\n")):
            continue
        out.append(ln)
    return out


def _self_test():
    src = (
        "        add spx,#0x0003\n"
        "; v0 arg -> @spx0\n"
        "        mov a,dpl\n"
        "        mov @spx,a\n"              # 死 store（@spx0 全函数仅此一处）
        "; v2 add_wrap v0 c -> @spx-1\n"
        "        add a,#0x03\n"
        "        mov @spx-0x1,a\n"          # 死 store
        "; v3 xor v2 c -> @spx-2\n"
        "        xrl a,#0x2a\n"
        "        mov @spx-0x2,a\n"          # 死 store
        "; v5 ret_safe\n"
        "        mov dpl,a\n"
        "        sub spx,#0x0003\n"
        "        eret\n"
    )
    txt = "".join(optimize(src.splitlines(keepends=True)))
    assert "mov @spx,a" not in txt, txt
    assert "mov @spx-0x1,a" not in txt, txt
    assert "mov @spx-0x2,a" not in txt, txt
    assert "add a,#0x03" in txt and "xrl a,#0x2a" in txt and "mov dpl,a" in txt, txt
    assert ";" not in txt, txt

    # 槽被后面读 -> 保留 store
    src2 = (
        "; v2 add v0 c -> @spx-1\n"
        "        add a,#0x03\n"
        "        mov @spx-0x1,a\n"
        "; v3 ret v2\n"
        "        mov a,@spx-0x1\n"
        "        mov dpl,a\n"
    )
    txt2 = "".join(optimize(src2.splitlines(keepends=True)))
    assert "mov @spx-0x1,a" in txt2, txt2

    # 循环回边：store 在循环尾、read 在循环头（地址更小）-> 必须保留
    src3 = (
        "_f:\n"
        "        mov @spx-0x1,a\n"          # 循环尾：i = i+1（store 在 read 之后）
        "        mov a,@spx-0x1\n"          # 循环头：读 i（跳回）
        "        eret\n"
    )
    txt3 = "".join(optimize(src3.splitlines(keepends=True)))
    assert "mov @spx-0x1,a" in txt3, txt3
    print("mcs_ir: self-test OK")


def main(argv):
    if len(argv) > 1 and argv[1] == "--self-test":
        _self_test()
        return 0
    for p in argv[1:]:
        path = Path(p)
        lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
        path.write_text("".join(optimize(lines)), encoding="utf-8", newline="")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
