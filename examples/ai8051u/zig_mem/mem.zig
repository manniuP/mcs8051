//! mem.zig — 真机验证 data / idata / edata / xdata 四个空间：写入**互不相同**的模式，
//! 再逐个回读比对，结果经 UART1(P3.1, 9600) 周期打印。
//!
//! - `data`  : `linksection(".data")`  → DSEG 0x30，直接寻址（`mov dir8`）
//! - `idata` : `linksection(".idata")` → ISEG 0x80，@Ri 间接（`mov r0,#a; mov a/@r0`）
//! - `edata` : 固定地址 0x0200（16 位 MOVX @DPTR；AI8051U 的 edata 在 0x0000 起）
//! - `xdata` : `linksection(".xdata")` → XSEG 0x10000，24 位 `@dpx`
//!
//! 四个模式互不相同，任何别名/寻址错误都会让对应项 FAIL（而不是靠“灯闪”蒙混）。

const m = @import("mcs");

var v_data: u8 linksection(".data") = 0;
var v_idata: u8 linksection(".idata") = 0;
var v_xdata: u8 linksection(".xdata") = 0;

const p_edata: *volatile u8 = @ptrFromInt(0x0200); // edata 区，位于 SPX 栈(0x0100 起)之上

inline fn item(got: u8, want: u8) void {
    m.uartPutHex2(got);
    if (got == want) m.uartPuts(" ok  ") else m.uartPuts(" FAIL ");
}

fn delay() void {
    var t: u16 = 0;
    while (t < 8000) : (t += 1) {}
}

export fn main() void {
    m.uartInit(40_000_000, 9600);
    m.uartPuts("\r\nspaces (data, idata, edata, xdata):\r\n");

    while (true) {
        v_data = 0xA1;
        v_idata = 0xB2;
        p_edata.* = 0xC3;
        v_xdata = 0xD4;

        item(v_data, 0xA1);
        item(v_idata, 0xB2);
        item(p_edata.*, 0xC3);
        item(v_xdata, 0xD4);
        m.uartPuts("\r\n");

        delay();
    }
}
