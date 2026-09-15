//! led.zig — 8 位（mcs51）互操作自检测试的 Zig 侧。
//!
//! 目标：mcs51-freestanding。接口：
//!   - 单标量：led_next(u8) u8（参数/返回在 DPL）；
//!   - 指针  ：sum4([*]const u8) u8，C 侧传 `__xdata const u8 *`（2 字节），
//!     由后端经 DPTR + MOVX 间接读取。
//!
//! 指针读取用直接下标 `buf[i]`（后端已支持 mcs51 间接寻址）。

/// 返回下一个点亮位（1 表示该位点亮）：把 8 位图案循环左移一位，
/// 最高位回卷到最低位；全 0 时从 P1.0 重新开始。
export fn led_next(cur: u8) u8 {
    const had_high: bool = (cur & 0x80) != 0;
    var next: u8 = cur +% cur;
    if (had_high) next |= 1;
    if (next == 0) next = 1;
    return next;
}

/// 把 buf[0..4] 求和返回（验证 C↔Zig 的 xdata 指针互操作）。
export fn sum4(buf: [*]const u8) u8 {
    var t: u8 = 0;
    t +%= buf[0];
    t +%= buf[1];
    t +%= buf[2];
    t +%= buf[3];
    return t;
}

/// 三参数求和（验证多参数 C↔Zig 互操作；C 侧需 `--stack-auto`）。
export fn add3(a: u8, b: u8, c: u8) u8 {
    return a +% b +% c;
}

/// Zig 定义的全局变量（放 xdata），供 C 侧读写（验证全局符号互操作）。
export var counter: u8 = 0;

/// 自增全局计数并返回（验证 Zig 定义 + C 读取的全局一致）。
export fn bump() u8 {
    counter +%= 1;
    return counter;
}
