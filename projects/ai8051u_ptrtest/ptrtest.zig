//! ptrtest.zig — 验证 Zig↔C 之间的 3 字节指针传递。
//!
//! SDCC MCS-251 的指针是 3 字节（类型/存储段 + 16 位地址）。
//! Zig 后端把 `[*]u8` / `[]u8` 物化为 3 字节地址（见 CodeGen.zig locOf .ptr/.slice）。
//! 这个 demo 验证：C 传一个 buffer 指针给 Zig，Zig 写入内容，C 再读出来对比。
//!
//! 注意（配合当前唯一可用的 55MB 预编译 zig.exe）：
//!   1. 直接对 `[*]u8` 参数做下标（`buf[i]`）会退化为**帧内寻址** bug——写的是自己的
//!      栈帧而不是 buffer（汇编是 `mov @spx-0xN,a`，没有 DR28）。
//!   2. 改用 `(@as(*u8, @ptrCast(buf + i))).*`：先做多元素指针运算拿到新地址，再
//!      当成单元素指针解引用 `.*`，后端就走 `.ptr_rt` -> `loadPtrToDr28` 的间接寻址，
//!      生成 `mov @dr28,r3`（写）/ `mov r3,@dr28`（读）。
//!   3. 不用切片 `buf[0..5]`：切片下标会插入越界检查，产生 `Lxx` 局部标签；而后端
//!      的标签在每个函数里从 0 重新编号，多函数同文件会与 sdas251 的“标签全局”
//!      规则冲突（multiple definitions / phase error）。单指针解引用无标签，最干净。
//!
//! 详见 docs/07-调试笔记。

/// C 调用：fill(buf) -> 把 "hello" 写入 buf[0..5]，返回长度。
export fn fill(buf: [*]u8) u8 {
    (@as(*u8, @ptrCast(buf + 0))).* = 'h';
    (@as(*u8, @ptrCast(buf + 1))).* = 'e';
    (@as(*u8, @ptrCast(buf + 2))).* = 'l';
    (@as(*u8, @ptrCast(buf + 3))).* = 'l';
    (@as(*u8, @ptrCast(buf + 4))).* = 'o';
    return 5;
}

/// C 调用：sum(buf) -> 把 buf[0..5] 求和返回（验证 Zig 能读 C 写的 buffer）。
/// 长度固定为 5（后端限制，只能用固定长度索引）。
/// 注：多参数传递（SDCC `_func_PARM_N` 全局变量约定）尚未实现，先只用第一参数。
export fn sum(buf: [*]const u8) u8 {
    var total: u8 = 0;
    total +%= (@as(*const u8, @ptrCast(buf + 0))).*;
    total +%= (@as(*const u8, @ptrCast(buf + 1))).*;
    total +%= (@as(*const u8, @ptrCast(buf + 2))).*;
    total +%= (@as(*const u8, @ptrCast(buf + 3))).*;
    total +%= (@as(*const u8, @ptrCast(buf + 4))).*;
    return total;
}
