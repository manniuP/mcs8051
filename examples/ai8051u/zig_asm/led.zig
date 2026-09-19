//! led.zig — 纯 Zig 点灯，用共享硬件宏库 `mcs`（= `lib/mcs251.zig`）做 SFR 位操作。
//!
//! SFR 地址来自生成的 `dev` 模块（`build/devices/device_sfr.zig`，`tools/mcs_sfr.py --emit zig`），
//! 构建时 `--dep dev -Mdev=...` 注入；本地别名勿与 `dev.sfr.*` 同名（后端按短名发 `_<name>` 符号）。

const dev = @import("dev");
const m = @import("mcs");

const P1_ADDR: u8 = @intCast(dev.sfr.P1);
const P1M1_ADDR: u8 = @intCast(dev.sfr.P1M1);
const P1M0_ADDR: u8 = @intCast(dev.sfr.P1M0);

fn delay500ms() void {
    var ms: u16 = 0;
    while (ms < 100) : (ms += 1) {
        var i: u16 = 0;
        while (i < 10000) : (i += 1) {}
    }
}

export fn main() void {
    m.sfrAnd(P1M1_ADDR, 0xfd); // P1M1.1 = 0
    m.sfrOr(P1M0_ADDR, 0x02); // P1M0.1 = 1  -> P1.1 推挽输出

    while (true) {
        m.bitClr(P1_ADDR, 1); // P1.1 = 0，LED 亮
        delay500ms();
        m.bitSet(P1_ADDR, 1); // P1.1 = 1，LED 灭
        delay500ms();
    }
}
