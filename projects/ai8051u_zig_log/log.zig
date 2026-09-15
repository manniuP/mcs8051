//! log.zig — 轻量二进制日志（defmt 风格）演示：设备端发帧，主机端小解码器解析。
//!
//! 帧格式：`0x7E, id_lo, id_hi, 参数…, XOR 校验`（见 `port/mcs251.zig` 的 `log`）。
//! 主机脚本 `decode.py` 用同一张 id→类型表解码。
//!
//! 本程序每秒发三条：0x0001（无参，boot）、0x0002（u16 计数）、0x0003（两个 u8）。

const m = @import("mcs");

export fn main() void {
    m.uartInit(40_000_000, 115200); // 二进制日志用 115200

    var n: u16 = 0;
    while (true) {
        m.log0(0x0001); // boot
        m.logU16(0x0002, n); // count = n
        m.logU8U8(0x0003, 0xab, 0xcd); // x=0xab y=0xcd
        n +%= 1;

        var i: u16 = 0; // 约 1s
        while (i < 60000) : (i += 1) {}
    }
}
