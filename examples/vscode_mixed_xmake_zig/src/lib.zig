//! lib.zig —— 混合工程 Zig 侧：导出给 C 调用的函数。
//!
//! `export fn` 生成 SDCC ABI 兼容符号（导出名 `_zig_calc`，由 Asx 的 trampoline 提供）。
//! 首个标量参数/返回值在 DPL/DPH/B/A，与 C 侧 `unsigned char zig_calc(unsigned char)` 对接。
export fn zig_calc(x: u8) u8 {
    return (x +% 3) ^ 0x2a;
}
