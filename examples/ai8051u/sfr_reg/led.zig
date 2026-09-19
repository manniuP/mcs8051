//! SFR **寄存器对象（新格式）**示例（AI8051U / MCS-251）：P1.1 的 LED 约 1Hz 闪烁。
//!
//! 风格：`dev.reg.*` 按寄存器名调用，最接近 C 的写法——
//!   `dev.reg.P1M1.anl(~0x02)` / `dev.reg.P1M0.orl(0x02)` / `dev.reg.P1.clr(1)` / `dev.reg.P1.set(1)`。
//! `Reg` 由 `tools/mcs_sfr.py --emit zig` 生成（`build/devices/device_sfr.zig`）。
//! 说明：`and`/`or` 是 Zig 关键字，故位与/位或方法名为 `anl`/`orl`；位操作用 `set/clr/cpl`。
//! 对比：位指令风格见 `ai8051u_sfr_bits`，C 风格固定地址指针见 `ai8051u_sfr_ptr`。
//! 注意：三套命名空间（`sfr`/`reg`/`p`）在同一个 `.zig` 里**不要引用同一寄存器**
//!       （后端按短名发 `_<name>` 符号，会同名冲突）——见 `mcs251/docs/23`。
//!
//! 构建：`xmake build zigsfrreg`（见 xmake.lua）。

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
    dev.reg.P1M1.anl(~@as(u8, 0x02)); // P1M1.1 = 0
    dev.reg.P1M0.orl(0x02); // P1M0.1 = 1  -> P1.1 推挽输出

    while (true) {
        dev.reg.P1.clr(1); // clr 位指令：P1.1 = 0，LED 亮
        delay500ms();
        dev.reg.P1.set(1); // P1.1 = 1，LED 灭
        delay500ms();
    }
}
