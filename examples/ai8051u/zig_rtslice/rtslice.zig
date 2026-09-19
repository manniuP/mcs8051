//! rtslice.zig — 运行期切片值（`[]u8 = &全局数组`）后端自检。
//!
//! 与 `ai8051u_zig_slice`（**编译期**切片 `const s: []const u8 = &arr`）互补：本示例的
//! 切片是**运行期值**——`{ptr, len}` 描述符物化进帧槽，覆盖：
//!   1) `const s: []u8 = &buf;`（指针 + 长度写入帧）；
//!   2) `s.len`（运行期长度）；
//!   3) 运行期下标的读 / 写 `s[i]`；
//!   4) `&s[i]`（取元素指针，再解引用）；
//!   5) 切片逐项拷贝到另一个全局数组（`.data` 空间）。
//!
//! 期望：`40 41 42 43 44 45` / `s[3]=43` / `42434445`。

const m = @import("mcs");

var buf: [6]u8 = undefined;
var out: [4]u8 linksection(".data") = .{0} ** 4;

export fn main() void {
    m.uartInit(40_000_000, 9600);
    m.uartPuts("\r\nruntime slice:\r\n");
    while (true) {
        const s: []u8 = &buf;
        var i: u8 = 0;
        while (i < s.len) : (i += 1) s[i] = 0x40 +% i; // 运行期下标写
        i = 0;
        while (i < s.len) : (i += 1) { // 运行期下标读
            m.uartPutHex2(s[i]);
            m.uartPuts(" ");
        }
        m.uartPuts("\r\n");

        const p = &s[3]; // 取元素指针
        m.uartPuts("s[3]=");
        m.uartPutHex2(p.*);
        m.uartPuts("\r\n");

        const d: []u8 = &out; // 另一个全局数组（.data 空间）
        i = 0;
        while (i < d.len) : (i += 1) d[i] = s[i +% 2]; // 逐项拷贝
        i = 0;
        while (i < d.len) : (i += 1) m.uartPutHex2(d[i]);
        m.uartPuts("\r\n");

        var t: u16 = 0;
        while (t < 6000) : (t += 1) {}
    }
}
