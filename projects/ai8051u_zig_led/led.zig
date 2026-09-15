//! 纯 Zig 点灯：P1.1 的 LED 以约 1Hz 闪烁（AI8051U / MCS-251）。
//!
//! 全程 Zig，无 C。复位入口由 `driver/crt0-mcs251.asm`（4 行：ejmp + 设 SPX + ecall _main）
//! 提供；链接用 sdld，CSEG 基址 0xFF0000（AI8051U 程序存储器在 FF:0000）。
//!
//! 依赖编译器对 `@ptrFromInt(0x80..0xFF)` 生成 **direct** `mov a,dir8` / `mov dir8,a`
//! （SFR 直址），见 zig/src/codegen/mcs/CodeGen.zig 的 isDirectAddr。

const P1   = @as(*volatile u8, @ptrFromInt(0x90));   // P1
const P1M1 = @as(*volatile u8, @ptrFromInt(0x91));
const P1M0 = @as(*volatile u8, @ptrFromInt(0x92));

/// 约 500ms 忙等（40MHz）。Zig 生成的循环比 C 重，故计数值按实测调。
fn delay500ms() void {
    var ms: u16 = 0;
    while (ms < 100) : (ms += 1) {
        var i: u16 = 0;
        while (i < 10000) : (i += 1) {}
    }
}

export fn main() void {
    P1M1.* &= ~@as(u8, 0x02);   // P1.1 推挽输出
    P1M0.* |= @as(u8, 0x02);

    while (true) {
        P1.* = 0xFD;            // P1.1 = 0，LED 亮
        delay500ms();
        P1.* = 0xFF;            // P1.1 = 1，LED 灭
        delay500ms();
    }
}
