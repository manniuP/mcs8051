//! sfr.zig — 用 Zig **comptime 宏生成内联汇编**，封装 SFR 操作（AI8051U / MCS-251）。
//!
//! 适用场景：Zig 里不方便直接做的操作，例如 SFR 的**位操作** `setb/clr/cpl`
//! （`@ptrFromInt` 只能按字节读写）。地址/掩码/位号都是 comptime 常量，直接拼进 asm 文本，
//! 因而无需 inline asm 的操作数（inputs/outputs）支持。
//!
//! 依赖：mcs 后端已支持 `asm volatile ("...")` 与 `inline fn` 的内联块。

fn hex2(comptime v: u8) [2]u8 {
    const dgt = "0123456789abcdef";
    return .{ dgt[v >> 4], dgt[v & 0x0f] };
}

fn dig(comptime v: u3) [1]u8 {
    return .{@as(u8, '0') + v};
}

/// `mov dir8,#imm`
pub inline fn write(comptime addr: u8, comptime val: u8) void {
    asm volatile ("mov 0x" ++ hex2(addr) ++ ",#0x" ++ hex2(val));
}

/// `orl dir8,#imm`
pub inline fn orMask(comptime addr: u8, comptime mask: u8) void {
    asm volatile ("orl 0x" ++ hex2(addr) ++ ",#0x" ++ hex2(mask));
}

/// `anl dir8,#imm`
pub inline fn andMask(comptime addr: u8, comptime mask: u8) void {
    asm volatile ("anl 0x" ++ hex2(addr) ++ ",#0x" ++ hex2(mask));
}

/// `setb addr.bit`（addr 为 SFR 字节地址 0x80–0xFF，bit 0–7）
pub inline fn setBit(comptime addr: u8, comptime bit: u3) void {
    asm volatile ("setb 0x" ++ hex2(addr) ++ "." ++ dig(bit));
}

/// `clr addr.bit`
pub inline fn clrBit(comptime addr: u8, comptime bit: u3) void {
    asm volatile ("clr 0x" ++ hex2(addr) ++ "." ++ dig(bit));
}

/// `cpl addr.bit`
pub inline fn cplBit(comptime addr: u8, comptime bit: u3) void {
    asm volatile ("cpl 0x" ++ hex2(addr) ++ "." ++ dig(bit));
}
