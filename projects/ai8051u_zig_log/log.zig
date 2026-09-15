//! log.zig — 轻量二进制日志（defmt 风格）演示：设备端发帧，主机端小解码器解析。
//!
//! 帧格式：`0x7E, id_lo, id_hi, 参数…, XOR 校验`（见 `port/mcs251.zig`）。
//! 参数编码：u8/u16/u32 小端；`logVar`=LEB128；`logStr`=`LEB128(len)+字节`。
//! 主机脚本 `decode.ps1` 用同一张 id→类型表解码。
//!
//! 每秒发五条：0x01 无参、0x02 u16、0x03 两 u8、0x04 LEB128 变长、0x05 短字符串。

const m = @import("mcs");

export fn main() void {
    m.uartInit(40_000_000, 115200); // 二进制日志用 115200

    var n: u16 = 0;
    while (true) {
        m.logBegin(0x0001);
        m.logEnd(); // boot

        m.logBegin(0x0002);
        m.logU16(n);
        m.logEnd(); // count = n（u16 小端）

        m.logBegin(0x0003);
        m.logU8(0xab);
        m.logU8(0xcd);
        m.logEnd(); // x=0xab y=0xcd

        m.logBegin(0x0004);
        m.logVar(n);
        m.logEnd(); // count（LEB128 变长）

        m.logBegin(0x0005);
        m.logStr("hello");
        m.logEnd(); // msg="hello"

        n +%= 1;

        var i: u16 = 0; // 约 1s
        while (i < 60000) : (i += 1) {}
    }
}
