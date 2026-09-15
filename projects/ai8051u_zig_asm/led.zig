//! led.zig — 纯 Zig 点灯，用共享硬件宏库 `mcs`（= `port/mcs251.zig`）做 SFR 位操作。
//!
//! 构建时通过 `--dep mcs -Mmcs=<仓库>/port/mcs251.zig` 注入该模块，源码里 `@import("mcs")`。
//! 见 `mcs251.zig` 顶部的用法示例（zls 悬停可显示）。

const m = @import("mcs");

const P1 = 0x90; // P1
const P1M1 = 0x91;
const P1M0 = 0x92;

fn delay500ms() void {
    var ms: u16 = 0;
    while (ms < 100) : (ms += 1) {
        var i: u16 = 0;
        while (i < 10000) : (i += 1) {}
    }
}

export fn main() void {
    m.sfrAnd(P1M1, 0xfd); // P1M1.1 = 0
    m.sfrOr(P1M0, 0x02); // P1M0.1 = 1  -> P1.1 推挽输出

    while (true) {
        m.bitClr(P1, 1); // P1.1 = 0，LED 亮
        delay500ms();
        m.bitSet(P1, 1); // P1.1 = 1，LED 灭
        delay500ms();
    }
}
