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

/// 固定 xdata 地址读/写（验证 `@ptrFromInt`）。
export fn wr_fixed(v: u8) void {
    (@as(*volatile u8, @ptrFromInt(0x8020))).* = v;
}

export fn rd_fixed() u8 {
    return (@as(*volatile u8, @ptrFromInt(0x8020))).*;
}

/// 普通 u8/u16 全局（xdata）。运行期赋值（freestanding 下全局初始化器不生效）。
var gx: u8 = 0;
var gy: u16 = 0;

/// 综合算术：u16 加/移位 + 全局 u8/u16 读写 + u8 截断/异或 —— 覆盖 8 位的多字节读写。
/// 期望值：0x0100+0x00FF=0x01FF；<<1=0x03FE；>>2=0x00FF；
/// (0xFF ^ gx=3)=0xFC；+ @truncate(gy=0x1234)=0xFC+0x34=0x30。
export fn mix_test() u8 {
    gx = 3;
    gy = 0x1234;
    var v: u16 = 0x0100;
    v +%= 0x00FF;
    v <<= 1;
    v >>= 2;
    var r: u8 = @as(u8, @truncate(v)) ^ gx;
    r +%= @as(u8, @truncate(gy));
    return r;
}
