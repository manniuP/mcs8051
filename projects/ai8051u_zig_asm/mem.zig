//! mem.zig — 手动指定数据空间（`data` / `xdata` / `idata` / SFR）的访问辅助（AI8051U / MCS-251）。
//!
//! 各空间的实现方式：
//! - `data`（片内直接 RAM 0x00–0x7F）：`@ptrFromInt(a)` 走 **direct**（`mov a,dir8` / `mov dir8,a`）。
//! - `SFR`（0x80–0xFF）：同上，direct 直址。
//! - `xdata`（≥0x100，如 `0x0100` 起）：`@ptrFromInt(a)` 走 **MOVX**（DPTR）。
//! - `idata`（间接片内 RAM，@Ri 访问）：用内联汇编宏；**读**需要把 A 回传，
//!   当前 inline asm 不支持操作数，故只提供写宏（读可用 `@ptrFromInt` 的 data 路径替代）。
//!
//! 关键：`dataPtr/xdataPtr` 的地址是 `comptime` 常量，才会走上面各自的固定地址路径；
//! 一旦把指针存进变量变成运行期指针，就退化为通用（24 位）指针。

fn hex2(comptime v: u8) [2]u8 {
    const d = "0123456789abcdef";
    return .{ d[v >> 4], d[v & 0x0f] };
}

fn hex4(comptime v: u16) [4]u8 {
    const d = "0123456789abcdef";
    return .{ d[(v >> 12) & 0xf], d[(v >> 8) & 0xf], d[(v >> 4) & 0xf], d[v & 0xf] };
}

/// 写 `data`（0x00–0x7F）：`mov dir8,#imm`
pub inline fn dataWrite(comptime addr: u8, comptime val: u8) void {
    asm volatile ("mov 0x" ++ hex2(addr) ++ ",#0x" ++ hex2(val));
}

/// 写 `xdata`（16 位地址）：`mov dptr,#addr; mov a,#val; movx @dptr,a`
pub inline fn xdataWrite(comptime addr: u16, comptime val: u8) void {
    asm volatile ("mov dptr,#0x" ++ hex4(addr) ++ "\nmov a,#0x" ++ hex2(val) ++ "\nmovx @dptr,a");
}

/// 写 `idata`（间接访问）：`mov r0,#addr; mov @r0,#val`
pub inline fn idataWrite(comptime addr: u8, comptime val: u8) void {
    asm volatile ("mov r0,#0x" ++ hex2(addr) ++ "\nmov @r0,#0x" ++ hex2(val));
}

/// `data` 空间指针（0x00–0x7F）：走 direct 读写。
pub inline fn dataPtr(comptime addr: u8) *volatile u8 {
    return @ptrFromInt(addr);
}

/// `xdata` 空间指针（≥0x100）：走 MOVX 读写。
pub inline fn xdataPtr(comptime addr: u16) *volatile u8 {
    return @ptrFromInt(addr);
}
