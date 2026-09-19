//! t0print.zig — **纯 Zig**：Timer0 每 1ms 中断，在 ISR 里每秒经 UART1 打印一行。
//!
//! 对照 STC 的 C 版（Timer2 作波特率发生器 + Timer0 1ms 中断）：
//!   - UART1 初始化：SCON=0x50 / AUXR|=S1BRT(0x01) 选 Timer2 / AUXR|=T2x12(0x04) 1T /
//!     T2H:T2L=0xFFA9 / AUXR|=T2R(0x10) 启动；P3.1 推挽、P_SW1 选 P3.0/P3.1。
//!   - Timer0 初始化：AUXR|=T0x12(0x80) 1T / TMOD&=0xF0 模式0（16 位自动重载）/
//!     TH0:TL0=0x63C0（40MHz 下 1ms）/ TR0=1 / ET0=1 / EA=1。
//!   - ISR：`export fn t0_isr` 内联汇编存 ACC/PSW → `ecall _on_t0`（Zig 处理）→ 恢复 → `reti`。
//!     向量表在 `crt0.asm` 的 HOME 区（Timer0 = FF:000B → `ejmp _t0_isr`）。
//!
//! 关键点：ISR 本身是「无帧」的内联汇编（无 prologue/SPX 调整），打印逻辑放在普通 Zig 函数
//! `on_t0`，由 ISR `ecall` 调用（它有完整 prologue/epilogue + `ret`），不会破坏 ISR 的 reti 语义。

const dev = @import("dev");
const m = @import("mcs");
const builtin = @import("builtin");

const SCON_ADDR: u8 = @intCast(dev.sfr.SCON);
const AUXR_ADDR: u8 = @intCast(dev.sfr.AUXR);
const T2L_ADDR: u8 = @intCast(dev.sfr.T2L);
const T2H_ADDR: u8 = @intCast(dev.sfr.T2H);
const P_SW1_ADDR: u8 = @intCast(dev.sfr.P_SW1);
const P3M1_ADDR: u8 = @intCast(dev.sfr.P3M1);
const P3M0_ADDR: u8 = @intCast(dev.sfr.P3M0);
const TMOD_ADDR: u8 = @intCast(dev.sfr.TMOD);
const TL0_ADDR: u8 = @intCast(dev.sfr.TL0);
const TH0_ADDR: u8 = @intCast(dev.sfr.TH0);
const TCON_ADDR: u8 = @intCast(dev.sfr.TCON);
const IE_ADDR: u8 = @intCast(dev.sfr.IE);

/// 1ms 计数（全局；每 1000 次 = 1 秒）。
var tick_ms: u16 = 0;

/// UART1 初始化：模式 1、Timer2 作波特率发生器、1T、P3.1 推挽输出。
fn uartInitT2(comptime fosc: u32, comptime baud: u32) void {
    m.sfrWrite(SCON_ADDR, 0x50); // SCON：8 位 UART，REN=0（只发）
    m.sfrOr(AUXR_ADDR, 0x01); // AUXR.S1BRT=1：串口1 用 Timer2 作波特率发生器
    m.sfrOr(AUXR_ADDR, 0x04); // AUXR.T2x12=1：Timer2 1T
    const reload: u16 = @intCast(65536 - (fosc / 4 + baud / 2) / baud);
    m.sfrWrite(T2L_ADDR, @intCast(reload & 0xff)); // T2L
    m.sfrWrite(T2H_ADDR, @intCast((reload >> 8) & 0xff)); // T2H
    m.sfrOr(AUXR_ADDR, 0x10); // AUXR.T2R=1：Timer2 启动
    m.sfrAnd(P_SW1_ADDR, 0x3f); // P_SW1：UART1 选 P3.0/P3.1
    m.sfrAnd(P3M1_ADDR, ~@as(u8, 0x02)); // P3M1.1=0
    m.sfrOr(P3M0_ADDR, 0x02); // P3M0.1=1：P3.1 推挽输出
}

/// Timer0 初始化：1T、模式 0（16 位自动重载）、周期 1/hz 秒（fosc 1T）。
fn timer0Init(comptime fosc: u32, comptime hz: u32) void {
    m.sfrOr(AUXR_ADDR, 0x80); // AUXR.T0x12=1：Timer0 1T
    m.sfrAnd(TMOD_ADDR, 0xf0); // TMOD：Timer0 模式 0（16 位自动重载）
    const reload: u16 = @intCast(65536 - fosc / hz);
    m.sfrWrite(TL0_ADDR, @intCast(reload & 0xff)); // TL0
    m.sfrWrite(TH0_ADDR, @intCast((reload >> 8) & 0xff)); // TH0
    m.bitClr(TCON_ADDR, 5); // TF0 = 0
    m.bitSet(TCON_ADDR, 4); // TR0 = 1
    m.bitSet(IE_ADDR, 1); // ET0 = 1
    m.bitSet(IE_ADDR, 7); // EA = 1
}

/// 中断里要做的「活」放在普通 Zig 函数里（有帧、有 ret），由 ISR 用 `ecall` 调用。
export fn on_t0() void {
    tick_ms +%= 1;
    if (tick_ms == 1000) {
        tick_ms = 0;
        m.uartPuts("t0\r\n"); // 每秒一行
    }
}

/// Timer0 中断入口：只保存 ACC/PSW、调用 Zig 处理、恢复、reti（本身无帧）。
/// mcs251 用 4 字节 `ecall`，mcs51 用 3 字节 `lcall`（选择在编译期按目标架构定）。
export fn t0_isr() void {
    if (comptime builtin.cpu.arch == .mcs51) {
        asm volatile (
            \\push 0xe0
            \\push 0xd0
            \\lcall _on_t0
            \\pop 0xd0
            \\pop 0xe0
            \\reti
        );
    } else {
        asm volatile (
            \\push 0xe0
            \\push 0xd0
            \\ecall _on_t0
            \\pop 0xd0
            \\pop 0xe0
            \\reti
        );
    }
}

export fn main() void {
    uartInitT2(40_000_000, 115200);
    timer0Init(40_000_000, 1000); // 1ms
    while (true) {}
}
