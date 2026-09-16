//! slice.zig — 编译期切片的运行期下标 / 迭代（后端「切片运行期下标」）。
//!
//! `const s: []const u8 = &arr;` 是**编译期切片值**（没有对应 AIR 指令）。本后端把
//! 它的基址解析成全局/固定地址视图：`data`/`idata` 走直接/`@r0`、`edata` 走
//! `movx @dptr`、`xdata` 走 `@dpx`；运行期下标按切片长度展开分派。
//!
//! 三个空间各放一个 `[8]u8`，写入互异模式，用运行期下标逐项读、再 `for` 求和：
//!   102030 112131 122232 132333 142434 152535 162636 172737
//!   sum=9c            （0x10..0x17 求和 = 0x9C）
//! 任何空间/寻址错误都会让对应字节肉眼可见地不对。

const m = @import("mcs");

var arr: [8]u8 linksection(".xdata") = .{0} ** 8;
var sdata: [8]u8 linksection(".data") = .{0} ** 8;
var sidata: [8]u8 linksection(".idata") = .{0} ** 8;

export fn main() void {
    m.uartInit(40_000_000, 9600);
    m.uartPuts("\r\nslice runtime idx:\r\n");
    while (true) {
        var i: u8 = 0;
        while (i < 8) : (i += 1) {
            arr[i] = 0x10 + i;
            sdata[i] = 0x20 + i;
            sidata[i] = 0x30 + i;
        }
        const sx: []const u8 = &arr;
        const sd: []const u8 = &sdata;
        const si: []const u8 = &sidata;
        // 运行期下标：xdata / data / idata 三种空间的切片
        i = 0;
        while (i < 8) : (i += 1) {
            m.uartPutHex2(sx[i]);
            m.uartPutHex2(sd[i]);
            m.uartPutHex2(si[i]);
            m.uartPuts(" ");
        }
        m.uartPuts("\r\n");
        // for 迭代（也是运行期下标）
        var sum: u8 = 0;
        for (sx) |v| sum +%= v;
        m.uartPuts("sum=");
        m.uartPutHex2(sum);
        m.uartPuts("\r\n");
        var t: u16 = 0;
        while (t < 6000) : (t += 1) {}
    }
}
