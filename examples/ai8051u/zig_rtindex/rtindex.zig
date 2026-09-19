//! rtindex.zig — 运行期下标跨数据空间真机验证（后端「运行期下标推广—空间」）。
//!
//! 四个空间各放一个数组，用**运行期下标** `i` 写入互异模式再回读：
//! - `data`  : `linksection(".data")`  → DSEG，`mov r0,#…; mov a/@r0`
//! - `idata` : `linksection(".idata")` → ISEG，同上
//! - `xdata` : `linksection(".xdata")` → XSEG，24 位 `@dr28`
//! - `edata` : 固定地址 `0x0200` → 16 位 `movx @dptr`
//!
//! 期望（UART1 P3.1 @9600，反复打印）：
//!   a0b0c0d0 a1b1c1d1 a2b2c2d2 a3b3c3d3
//! 任何寻址/空间错误都会让对应字节肉眼可见地不对。

const m = @import("mcs");

var d_data: [8]u8 linksection(".data") = .{0} ** 8;
var d_idata: [8]u8 linksection(".idata") = .{0} ** 8;
var d_xdata: [8]u8 linksection(".xdata") = .{0} ** 8;
const p_edata: *volatile [8]u8 = @ptrFromInt(0x0200);

fn delay() void {
    var t: u16 = 0;
    while (t < 8000) : (t += 1) {}
}

export fn main() void {
    m.uartInit(40_000_000, 9600);
    m.uartPuts("\r\nruntime index x spaces:\r\n");
    while (true) {
        var i: u8 = 0;
        while (i < 4) : (i += 1) {
            d_data[i] = 0xA0 + i;
            d_idata[i] = 0xB0 + i;
            d_xdata[i] = 0xC0 + i;
            p_edata[i] = 0xD0 + i;
        }
        i = 0;
        while (i < 4) : (i += 1) {
            m.uartPutHex2(d_data[i]);
            m.uartPutHex2(d_idata[i]);
            m.uartPutHex2(d_xdata[i]);
            m.uartPutHex2(p_edata[i]);
            m.uartPuts(" ");
        }
        m.uartPuts("\r\n");
        delay();
    }
}
