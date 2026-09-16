//! hotcold.zig — 热/冷频次注解（`linksection(".hot"/".cold")`）演示。
//!
//! - **热变量** `.hot` → DSEG，直接寻址 `mov a,_sym`（快）。
//! - **冷变量** `.cold` → XSEG（xdata），`mov dpxl/… @dpx`（省 direct 区，慢无妨）。
//! - **冷函数** `.cold` → 独立 `COLD` 代码区（可与热代码分开，便于整体压缩/后置）。
//! - 热函数保持 CSEG；要真正内联请直接写 `inline fn`。
//!
//! 期望（UART1 P3.1 @9600）：`132a`
//!   hot_add(3) = 0x10+3 = 0x13；cold_work(0x2a) 写/读 cold_buf[1] = 0x2a。

const m = @import("mcs");

var hot_cnt: u8 linksection(".hot") = 0; // DSEG 直接寻址
var cold_buf: [8]u8 linksection(".cold") = .{0} ** 8; // XSEG

export fn hot_add(x: u8) linksection(".hot") u8 {
    return hot_cnt +% x;
}

export fn cold_work(x: u8) linksection(".cold") u8 {
    cold_buf[1] = x;
    return cold_buf[1];
}

export fn main() void {
    m.uartInit(40_000_000, 9600);
    hot_cnt = 0x10;
    m.uartPuts("\r\nhotcold:\r\n");
    while (true) {
        m.uartPutHex2(hot_add(3));
        m.uartPutHex2(cold_work(0x2a));
        m.uartPuts("\r\n");
        var t: u16 = 0;
        while (t < 6000) : (t += 1) {}
    }
}
