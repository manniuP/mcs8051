//! isr.zig — 纯 Zig 中断演示：Timer0 中断里翻转 P1.1（约 1Hz）。
//!
//! 向量表在 `crt0.asm` 的 HOME 区（Timer0 = FF:000B → `ejmp _t0_isr`）。
//! ISR 用内联汇编：保存 ACC/PSW、每 25 次中断翻转 P1.1（计数在 IRAM 0x30）、再 reti。
//! 主程序配置 P1.1 推挽 + Timer0（模式1、12T、约 19.6ms 溢出）+ 开中断，然后死循环。

/// 中断服务程序：约 25 × 19.6ms ≈ 490ms 翻转一次 P1.1。
export fn t0_isr() void {
    asm volatile (
        \\push 0xe0
        \\push 0xd0
        \\djnz 0x30,isr_done
        \\mov 0x30,#25
        \\cpl 0x90.1
        \\isr_done:
        \\pop 0xd0
        \\pop 0xe0
        \\reti
    );
}

export fn main() void {
    asm volatile (
        \\anl 0x91,#0xfd
        \\orl 0x92,#0x02
        \\mov 0x30,#25
        \\anl 0x8e,#0x7f
        \\mov 0x89,#0x01
        \\mov 0x8c,#0x00
        \\mov 0x8a,#0x00
        \\setb 0x8c
        \\setb 0xa9
        \\setb 0xaf
    );
    while (true) {}
}
