//! led.zig — 纯 Zig 点灯，用 comptime 宏生成的内联汇编做 **SFR 位操作**。
//!
//! 与 `ai8051u_zig_led` 的区别：这里用 `sfr.setBit/clrBit` 对 P1.1 做位操作
//! （Zig 本身不便表达），体现「Zig 宏 → 内联汇编」的用法。

const sfr = @import("sfr.zig");

const P1   = 0x90; // P1
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
    sfr.andMask(P1M1, 0xfd); // P1M1.1 = 0
    sfr.orMask(P1M0, 0x02); // P1M0.1 = 1  -> P1.1 推挽输出

    while (true) {
        sfr.clrBit(P1, 1); // P1.1 = 0，LED 亮
        delay500ms();
        sfr.setBit(P1, 1); // P1.1 = 1，LED 灭
        delay500ms();
    }
}
