//! SFR **位指令**示例（AI8051U / MCS-251）：P1.1 的 LED 约 1Hz 闪烁。
//!
//! 风格：用共享宏库 `mcs`（`lib/mcs251.zig`）直接发 SFR 指令——
//! `anl/orl dir8,#imm`（`sfrAnd/sfrOr`）、`mov dir8,#imm`（`sfrWrite`）、
//! `setb/clr dir8.bit`（`bitSet/bitClr`）。地址来自生成的 `dev` 模块（`dev.sfr.*`）。
//! 需要**单条位指令**（`setb/clr/cpl`）时必须走这条路径；对比见同级 `ai8051u_sfr_reg`。
//!
//! 构建：`xmake build zigsfrbits`（见 xmake.lua）。

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
        m.bitClr(P1_ADDR, 1); // setb/clr 位指令：P1.1 = 0，LED 亮
        delay500ms();
        m.bitSet(P1_ADDR, 1); // P1.1 = 1，LED 灭
        delay500ms();
    }
}
