//! log.zig — 轻量二进制日志演示（defmt 风格）。
//!
//! 职责分离：
//! - **`cobs` 库**（`lib/cobs/`，平台无关）：只把日志帧写进**用户提供的缓冲区**并做 COBS，
//!   以单个 `0x00` 结束；不接触任何硬件。
//! - **本程序**：提供缓冲区、决定如何输出（这里经 UART1 发送）。换成 USB/环形队列/存 Flash
//!   只需改 `send()`。
//!
//! 原始帧：`0x7E, id_lo, id_hi, 参数…, XOR`；参数 u8/u16/u32 小端、LEB128、字符串。
//! 主机端 `decode.ps1` 先按 `0x00` 切帧、COBS 解码，再按 id→类型表解析。
//!
//! 每秒发六条：0x01 无参、0x02 u16、0x03 两 u8、0x04 LEB128、0x05 短字符串、
//! 0x06 u16 全局自检（写 u16 全局再读回，验证后端大端落盘）。

const m = @import("mcs"); // AI8051U / MCS-251 硬件宏（UART）
const cobs = @import("cobs"); // 平台无关 COBS + 日志帧（单实例）

/// 用户提供的输出缓冲区（xdata）；编码结果写在这里。
var out_buf: [128]u8 = undefined;

/// 端序自检用的 u16 全局（写后读回）。
var g16: u16 = 0;

/// 输出当前编码帧（输出方式由用户决定；此处走 UART1）。
fn send() void {
    var i: u16 = 0;
    const n = cobs.length();
    const p = cobs.data();
    while (i < n) : (i += 1) m.uartPutc(p[i]);
}

export fn main() void {
    m.uartInit(40_000_000, 115200);
    cobs.initRaw(&out_buf, out_buf.len);

    var n: u16 = 0;
    while (true) {
        cobs.logBegin(0x0001);
        _ = cobs.logEnd();
        send(); // boot

        cobs.logBegin(0x0002);
        cobs.logU16(n);
        _ = cobs.logEnd();
        send(); // count = n

        cobs.logBegin(0x0003);
        cobs.logU8(0xab);
        cobs.logU8(0xcd);
        _ = cobs.logEnd();
        send(); // x=0xab y=0xcd

        cobs.logBegin(0x0004);
        cobs.logVar(n);
        _ = cobs.logEnd();
        send(); // count（LEB128）

        cobs.logBegin(0x0005);
        cobs.logStr("hello");
        _ = cobs.logEnd();
        send(); // msg="hello"

        g16 = n; // u16 全局写（大端）
        cobs.logBegin(0x0006);
        cobs.logU16(g16); // 读回，应等于 count
        _ = cobs.logEnd();
        send();

        n +%= 1;

        var i: u16 = 0; // 约几十毫秒
        while (i < 60000) : (i += 1) {}
    }
}
