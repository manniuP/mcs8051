//! mem.zig — 用 `linksection` 把变量放到 AI8051U 的三个数据空间（纯 Zig，无 C）。
//!
//! - `.data`  → 片内直接 RAM（DSEG，`--data-loc 0x30` 起），访问 `mov dir8`（1 字节，最快）；
//! - `.idata` → 片内间接 RAM（ISEG，`--idata-loc 0x80` 起），访问 `mov r0,#addr; mov a/@r0`；
//! - `.xdata` → 扩展 RAM（XSEG，0x10000 起），访问 MOVX（DPTR）。
//!
//! 主循环让三个计数器自增；idata 计数每 256 次翻转 P1.1（配约 2ms 忙等 → 约 1Hz）。
//! 能稳定闪烁即说明三个空间都能正常读写。

const m = @import("mcs");

var c_data: u8 linksection(".data") = 0; // DSEG 0x30
var c_idata: u8 linksection(".idata") = 0; // ISEG 0x80
var c_xdata: u8 linksection(".xdata") = 0; // XSEG 0x10000

fn delay2ms() void {
    var t: u16 = 0;
    while (t < 8000) : (t += 1) {}
}

export fn main() void {
    m.sfrAnd(0x91, 0xfd); // P1M1.1 = 0
    m.sfrOr(0x92, 0x02); // P1M0.1 = 1 -> P1.1 推挽输出

    while (true) {
        c_data +%= 1;
        c_xdata +%= c_data;
        c_idata +%= 1;
        if (c_idata == 0) m.bitCpl(0x90, 1); // 每 256 次翻转 P1.1
        delay2ms();
    }
}
