//! ptrtest.zig — 验证 Zig↔C 之间的 3 字节指针传递。
//!
//! SDCC MCS-251 的指针是 3 字节（类型/存储段 + 16 位地址）。
//! Zig 后端把 `[*]u8` / `[]u8` 物化为 3 字节地址（见 CodeGen.zig locOf .ptr/.slice）。
//! 这个 demo 验证：C 传一个 buffer 指针给 Zig，Zig 写入内容，C 再读出来对比。
//!
//! 注：直接索引参数指针（不做 @ptrCast + 栈槽中转），绕开预编译 zig.exe
//! 的帧槽寻址 bug；写入/读取都应生成经 DPTR/DR28 的间接寻址。

/// C 调用：fill(buf) -> 把 "hello" 写入 buf[0..5]，返回长度。
export fn fill(buf: [*]u8) u8 {
    buf[0] = 'h';
    buf[1] = 'e';
    buf[2] = 'l';
    buf[3] = 'l';
    buf[4] = 'o';
    return 5;
}

/// C 调用：sum(buf) -> 把 buf[0..5] 求和返回（验证 Zig 能读 C 写的 buffer）。
/// 长度固定为 5（后端限制，只能用固定长度索引）。
/// 注：多参数传递（SDCC `_func_PARM_N` 全局变量约定）尚未实现，先只用第一参数。
export fn sum(buf: [*]const u8) u8 {
    var s: u8 = 0;
    s +%= buf[0];
    s +%= buf[1];
    s +%= buf[2];
    s +%= buf[3];
    s +%= buf[4];
    return s;
}
