//! led.zig — 纯 Zig 点灯：P1.1 的 LED 以约 1Hz 闪烁（AI8051U / MCS-251）。
//!
//! SFR 地址来自**生成的 `dev` 模块**（`build/devices/device_sfr.zig`，由
//! `tools/mcs_sfr.py --emit zig` 生成）；构建时经 `--dep dev -Mdev=...` 注入，源码 `@import("dev")`。
//! 字节/位 SFR 操作用共享宏库 `mcs`（`lib/mcs251.zig`）。
//! 注意：后端对文件级 const 也发 `_<name>` 数据符号，故本地别名**勿与 `dev.sfr.*` 同名**。
//!
//! 复位入口由 `lib/crt0/crt0-mcs251.asm` 提供；CSEG 基址 0xFF0000（AI8051U 程序存储器在 FF:0000）。

const dev = @import("dev");
const m = @import("mcs");

const P1_ADDR: u8 = @intCast(dev.sfr.P1);
const P1M1_ADDR: u8 = @intCast(dev.sfr.P1M1);
const P1M0_ADDR: u8 = @intCast(dev.sfr.P1M0);

/// 约 500ms 忙等（40MHz）。
fn delay500ms() void {
    var ms: u16 = 0;
    while (ms < 100) : (ms += 1) {
        var i: u16 = 0;
        while (i < 10000) : (i += 1) {}
    }
}

export fn main() void {
    m.sfrAnd(P1M1_ADDR, ~@as(u8, 0x02)); // P1M1.1 = 0
    m.sfrOr(P1M0_ADDR, 0x02); // P1M0.1 = 1  -> P1.1 推挽输出

    while (true) {
        m.sfrWrite(P1_ADDR, 0xfd); // P1.1 = 0，LED 亮
        delay500ms();
        m.sfrWrite(P1_ADDR, 0xff); // P1.1 = 1，LED 灭
        delay500ms();
    }
}
