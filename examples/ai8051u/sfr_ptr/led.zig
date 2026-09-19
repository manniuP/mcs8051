//! SFR **C 风格固定地址指针**示例（AI8051U / MCS-251）：P1.1 的 LED 约 1Hz 闪烁。
//!
//! 风格：`dev.p.*`（由 `tools/mcs_sfr.py --emit zig` 生成的 `*volatile u8` 固定地址指针），
//! 写法就是 C 的 `P1M1 &= ~0x02;`（Zig 需写 `.*`，因为指针解引用）：
//!   `dev.p.P1M1.* &= ~0x02;` / `dev.p.P1M0.* |= 0x02;` / `dev.p.P1.* = 0xff;`
//!
//! `tools/mcs_opt.py` 的 **R6** 会把 `mov a,dir8 ; … anl/orl a,#imm … ; mov dir8,a`
//! 融为单条 `anl/orl dir8,#imm`（前提：A 在此后不再被读）：
//!   `dev.p.P1M1.* &= ~0x02;`  ->  `anl 0x91,#0xfd`
//!   `dev.p.P1M0.* |= 0x02;`   ->  `orl 0x92,#0x02`
//! 注意：`dev.sfr.*` / `dev.reg.*` / `dev.p.*` 三套命名空间**不要在同一 `.zig` 里引用同一寄存器**
//!       （后端按短名发 `_<name>` 符号，会同名冲突）——见 `mcs251/docs/23`。
//!
//! 对比：位指令风格 `ai8051u_sfr_bits`、寄存器对象 `ai8051u_sfr_reg`。
//! 构建：`xmake build zigsfrptr`（见 xmake.lua）。

const dev = @import("dev");

/// 约 500ms 忙等（40MHz）。
fn delay500ms() void {
    var ms: u16 = 0;
    while (ms < 100) : (ms += 1) {
        var i: u16 = 0;
        while (i < 10000) : (i += 1) {}
    }
}

export fn main() void {
    dev.p.P1M0.* |= 0x02; // C 风格 -> orl 0x92,#0x02
    dev.p.P1M1.* &= ~@as(u8, 0x02); // -> anl 0x91,#0xfd（P1.1 推挽输出）
    dev.p.P1.* = 0xff; // 初始灭

    while (true) {
        dev.p.P1.* = 0xfd; // P1.1 = 0，LED 亮
        delay500ms();
        dev.p.P1.* = 0xff; // P1.1 = 1，LED 灭
        delay500ms();
    }
}
