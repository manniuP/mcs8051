//! uart_echo.zig — 纯 Zig：**UART1 接收中断回环**（收到什么字节就原样回发）。
//!
//! 对应 STC 的 `void Uart1_Isr(void) interrupt 4 { if(TI)TI=0; if(RI)RI=0; }`：
//! 这里在 RI 分支里**读 SBUF（自动清 RI）再回写**，实现回显；TI 分支清 TI。
//!
//! - UART1 中断号 4，向量在 `crt0.asm` 的 HOME 区 `FF:0023` → `ejmp _uart_isr`。
//! - ISR `uart_isr` 是**无帧**内联汇编（存 ACC/PSW → `ecall _on_uart` → 恢复 → `reti`）；
//!   逻辑 `on_uart` 是普通 Zig 函数（有帧、正常 `ret`）。**切勿**把带局部量的 Zig 代码直接写进
//!   ISR，否则 `reti` 会跳过 epilogue 导致 SPX 泄漏（见 `docs/20`）。
//! - 波特率 115200@40MHz：Timer2 作发生器、1T（同 STC 例程 `T2H:T2L=0xFFA9`）。

const m = @import("mcs");
const builtin = @import("builtin");

/// UART1 初始化：模式1、REN=1、Timer2 作波特率发生器、开 UART1 中断。
fn uartInitT2(comptime fosc: u32, comptime baud: u32) void {
    m.sfrWrite(0x98, 0x50); // SCON：模式1，REN=1（允许接收）
    m.sfrOr(0x8e, 0x01); // AUXR.S1BRT=1：串口1 用 Timer2 作波特率发生器
    m.sfrOr(0x8e, 0x04); // AUXR.T2x12=1：Timer2 1T
    const reload: u16 = @intCast(65536 - (fosc / 4 + baud / 2) / baud);
    m.sfrWrite(0xd7, @intCast(reload & 0xff)); // T2L
    m.sfrWrite(0xd6, @intCast((reload >> 8) & 0xff)); // T2H
    m.sfrOr(0x8e, 0x10); // AUXR.T2R=1：Timer2 启动
    m.sfrAnd(0xa2, 0x3f); // P_SW1：UART1 选 P3.0(RxD)/P3.1(TxD)
    m.sfrAnd(0xb1, ~@as(u8, 0x03)); // P3M1.0/P3M1.1 = 0
    m.sfrOr(0xb2, 0x02); // P3M0.1=1：P3.1 推挽（TxD）；P3.0 保持准双向（RxD）
    m.bitSet(0xa8, 4); // IE.ES = 1：允许 UART1 中断
    m.bitSet(0xa8, 7); // IE.EA = 1：总中断
}

// 发送环形缓冲：解决「PC 连续突发、上一字节还没发完又写 SBUF 会丢字节」。
var ring: [64]u8 = undefined;
var r_head: u8 = 0; // 写指针
var r_tail: u8 = 0; // 读指针
var tx_busy: u8 = 0;

/// UART1 中断里要做的「活」（普通 Zig 函数，有帧、正常 ret）。
export fn on_uart() void {
    // TI=1：上一字节发送完成 —— 有排队就发下一个，否则置空闲。
    if ((m.sfrPtr(0x98).* & 0x02) != 0) {
        m.sfrAnd(0x98, ~@as(u8, 0x02)); // 清 TI
        if (r_head != r_tail) {
            m.sfrPtr(0x99).* = ring[r_tail];
            r_tail +%= 1;
        } else {
            tx_busy = 0;
        }
    }
    // RI=1：收到一个字节 —— 发送空闲则直接回，否则入队。
    if ((m.sfrPtr(0x98).* & 0x01) != 0) {
        const b = m.sfrPtr(0x99).*; // 读 SBUF
        m.sfrAnd(0x98, ~@as(u8, 0x01)); // 显式清 RI（读 SBUF 本已清，双保险；某些仿真模型不自动清）
        if (tx_busy == 0) {
            m.sfrPtr(0x99).* = b; // 回写 SBUF → 回显
            tx_busy = 1;
        } else {
            const h = r_head +% 1;
            if (h != r_tail) { // 未满
                ring[r_head] = b;
                r_head = h;
            }
        }
    }
}

/// UART1 中断入口（中断号 4；向量 FF:0023，mcs51 为 0x0023）：无帧，只存 ACC/PSW、
/// 调用 Zig 处理、reti。mcs251 用 4 字节 `ecall`，mcs51 用 3 字节 `lcall`。
export fn uart_isr() void {
    if (comptime builtin.cpu.arch == .mcs51) {
        asm volatile (
            \\push 0xe0
            \\push 0xd0
            \\lcall _on_uart
            \\pop 0xd0
            \\pop 0xe0
            \\reti
        );
    } else {
        asm volatile (
            \\push 0xe0
            \\push 0xd0
            \\ecall _on_uart
            \\pop 0xd0
            \\pop 0xe0
            \\reti
        );
    }
}

export fn main() void {
    uartInitT2(40_000_000, 115200);
    while (true) {}
}
