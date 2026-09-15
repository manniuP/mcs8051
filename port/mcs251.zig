//! mcs251.zig —— AI8051U / MCS-251 底层硬件访问宏（纯 Zig，comptime 生成内联汇编）。
//!
//! 用途：封装 Zig 里不方便直接写的操作——SFR 直址、SFR 位操作、以及各数据空间
//! （`data` / `xdata` / `idata`）的手动访问。所有地址/掩码/位号都是 **comptime 常量**，
//! 直接拼进汇编文本，因此不依赖 inline asm 的操作数支持。
//!
//! 依赖编译器：mcs251 后端需支持 `asm volatile ("...")`（无操作数）与 `inline fn` 内联。
//!
//! ## 安全性 / 检查（重要）
//!
//! - **编译期检查仍在**：参数是 `comptime u8` / `comptime u3`，类型与范围由 Zig 编译期检查
//!   （如位号必须 0–7、地址必须装得下 `u8`）；写错立即编译失败。
//! - **运行期/内存安全检查不适用**：`@ptrFromInt(addr)` 是**无检查**的地址转换，
//!   本后端也不生成运行时安全检查；`asm` 文本对 Zig 透明（只有 `sdas251` 查语法）。
//!   地址/寄存器是否正确由程序员负责。
//! - 本质：这些宏操作的是**指向绝对地址（SFR / 硬件）的指针**，是 Zig 的 unsafe 逃逸口；
//!   普通变量的别名/越界/初始化保证在这里**不适用**。
//! - 建议：一律用 `*volatile`（本库已如此，防止被优化/重排）；地址保持 `comptime` 常量；
//!   不要把这类指针存进变量（会退化为普通 24 位指针，且丢失固定地址代码生成）。
//!
//! ## 用法示例
//!
//! ```zig
//! const m = @import("mcs"); // 构建时加：--dep mcs -Mmcs=<仓库>/port/mcs251.zig
//!
//! fn blinkInit() void {
//!     m.sfrAnd(0x91, 0xfd); // P1M1.1 = 0
//!     m.sfrOr(0x92, 0x02); // P1M0.1 = 1  -> P1.1 推挽输出
//! }
//!
//! fn step() void {
//!     m.bitClr(0x90, 1); // P1.1 = 0，LED 亮
//!     m.nop();
//!     m.bitSet(0x90, 1); // P1.1 = 1，LED 灭
//! }
//!
//! fn readP11() u1 {
//!     return @intCast(m.sfrPtr(0x90).* & 0x02); // 读 P1.1（字节 + 掩码）
//! }
//!
//! fn writeSpaces() void {
//!     m.dataWrite(0x30, 0x5a); // data[0x30] = 0x5a（直接寻址）
//!     m.xdataWrite(0x0100, 0xaa); // xdata[0x0100] = 0xaa（MOVX）
//!     m.idataWrite(0x40, 0x33); // idata[0x40] = 0x33（@R0 间接）
//! }
//! ```

// ---------------------------------------------------------------------------
// 内部：comptime 十六进制/十进制字符
// ---------------------------------------------------------------------------

fn hex2(comptime v: u8) [2]u8 {
    const dgt = "0123456789abcdef";
    return .{ dgt[v >> 4], dgt[v & 0x0f] };
}

fn hex4(comptime v: u16) [4]u8 {
    const dgt = "0123456789abcdef";
    return .{ dgt[(v >> 12) & 0xf], dgt[(v >> 8) & 0xf], dgt[(v >> 4) & 0xf], dgt[v & 0x0f] };
}

fn dec1(comptime v: u3) [1]u8 {
    return .{@as(u8, '0') + v};
}

// ---------------------------------------------------------------------------
// SFR / 位操作
// ---------------------------------------------------------------------------

/// 空操作 `nop`。
pub inline fn nop() void {
    asm volatile ("nop");
}

/// 写 SFR：`mov dir8,#imm`。`addr` 为 SFR 字节地址（0x80–0xFF）。
///
/// 示例：`sfrWrite(0x90, 0xfe); // P1 = 0xfe`
pub inline fn sfrWrite(comptime addr: u8, comptime val: u8) void {
    asm volatile ("mov 0x" ++ hex2(addr) ++ ",#0x" ++ hex2(val));
}

/// SFR 按位或：`orl dir8,#imm`（读-改-写，一条指令）。
///
/// 示例：`sfrOr(0x92, 0x02); // P1M0 |= 0x02`
pub inline fn sfrOr(comptime addr: u8, comptime mask: u8) void {
    asm volatile ("orl 0x" ++ hex2(addr) ++ ",#0x" ++ hex2(mask));
}

/// SFR 按位与：`anl dir8,#imm`（读-改-写）。
///
/// 示例：`sfrAnd(0x91, 0xfd); // P1M1 &= ~0x02`
pub inline fn sfrAnd(comptime addr: u8, comptime mask: u8) void {
    asm volatile ("anl 0x" ++ hex2(addr) ++ ",#0x" ++ hex2(mask));
}

/// 位置 1：`setb addr.bit`。可位寻址：SFR 位（字节地址 8 的倍数）或 RAM 0x20–0x2F。
///
/// 示例：`bitSet(0x90, 1); // P1.1 = 1`；`bitSet(0x21, 3); // RAM 0x21.3 = 1`
pub inline fn bitSet(comptime addr: u8, comptime bit: u3) void {
    asm volatile ("setb 0x" ++ hex2(addr) ++ "." ++ dec1(bit));
}

/// 位清 0：`clr addr.bit`。
///
/// 示例：`bitClr(0x90, 1); // P1.1 = 0（LED 亮）`
pub inline fn bitClr(comptime addr: u8, comptime bit: u3) void {
    asm volatile ("clr 0x" ++ hex2(addr) ++ "." ++ dec1(bit));
}

/// 位取反：`cpl addr.bit`。
///
/// 示例：`bitCpl(0x90, 1); // P1.1 翻转`
pub inline fn bitCpl(comptime addr: u8, comptime bit: u3) void {
    asm volatile ("cpl 0x" ++ hex2(addr) ++ "." ++ dec1(bit));
}

/// 取 SFR/RAM 字节的指针（`data` 直址区 0x00–0xFF），可读可写。
///
/// `addr` 为 `comptime` 常量时，解引用走 **direct**（`mov a,dir8`/`mov dir8,a`）；
/// 读某一位：`@intCast(sfrPtr(0x90).* & 0x02)`。
///
/// 示例：`sfrPtr(0x90).* = 0xfe;` / `const x = sfrPtr(0x90).*;`
pub inline fn sfrPtr(comptime addr: u8) *volatile u8 {
    return @ptrFromInt(addr);
}

// ---------------------------------------------------------------------------
// 数据空间
// ---------------------------------------------------------------------------

/// 写 `data`（片内直接 RAM 0x00–0x7F）：`mov dir8,#imm`。
///
/// 示例：`dataWrite(0x30, 0x5a);`
pub inline fn dataWrite(comptime addr: u8, comptime val: u8) void {
    asm volatile ("mov 0x" ++ hex2(addr) ++ ",#0x" ++ hex2(val));
}

/// 写 `xdata`（外部/扩展 RAM，16 位地址）：`mov dptr,#addr; mov a,#val; movx @dptr,a`。
///
/// 示例：`xdataWrite(0x0100, 0xaa);`
pub inline fn xdataWrite(comptime addr: u16, comptime val: u8) void {
    asm volatile ("mov dptr,#0x" ++ hex4(addr) ++ "\nmov a,#0x" ++ hex2(val) ++ "\nmovx @dptr,a");
}

/// 写 `idata`（间接片内 RAM，@Ri 访问）：`mov r0,#addr; mov @r0,#val`。
///
/// 注：只提供写；读需把 A 回传，当前 inline asm 不支持操作数。
///
/// 示例：`idataWrite(0x40, 0x33);`
pub inline fn idataWrite(comptime addr: u8, comptime val: u8) void {
    asm volatile ("mov r0,#0x" ++ hex2(addr) ++ "\nmov @r0,#0x" ++ hex2(val));
}

/// 取 `data` 空间指针（0x00–0x7F），走 direct 读写。
///
/// 示例：`dataPtr(0x30).* += 1;`
pub inline fn dataPtr(comptime addr: u8) *volatile u8 {
    return @ptrFromInt(addr);
}

/// 取 `xdata` 空间指针（≥0x100），走 MOVX 读写。
///
/// 示例：`xdataPtr(0x0100).* = 0xaa;`
pub inline fn xdataPtr(comptime addr: u16) *volatile u8 {
    return @ptrFromInt(addr);
}
