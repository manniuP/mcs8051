//! 纯 Zig 点灯（AI8051U / MCS-251）—— 契合「设备表驱动」的新编译器：
//!
//! - SFR 用**寄存器对象** `dev.reg.*`（由 `tools/mcs_sfr.py --emit zig` 生成到
//!   `build/devices/device_sfr.zig`）：`dev.reg.P1M1.anl(~0x02)` / `dev.reg.P1.write(0xff)`。
//! - 全局变量的**放置由编译器按设备存储表自动决定**（`MCS_DEVICE` 环境变量）：
//!   ≤2 字节 → data（直接寻址，快），其余 → 设备默认数据空间（本型号 xdata）。无需 `linksection`。
//!
//! 其它风格对照：C 风格指针 `dev.p.*`（`examples/ai8051u/sfr_ptr`）、
//! 位指令 `m.sfrAnd/bitSet`（`examples/ai8051u/sfr_bits`）。
//! 构建：`xmake build devzig`。

const dev = @import("dev");

var ticks: u16 = 0; // 2B → 自动放 data（DSEG）
var buf: [16]u8 = undefined; // 16B → 自动放 xdata（XSEG）

/// 约 500ms 忙等（40MHz）。
fn delay500ms() void {
    var ms: u16 = 0;
    while (ms < 100) : (ms += 1) {
        var i: u16 = 0;
        while (i < 10000) : (i += 1) {}
    }
}

export fn main() void {
    dev.reg.P1M1.anl(~@as(u8, 0x02)); // P1.1 推挽
    dev.reg.P1M0.orl(0x02);
    buf[0] = 0x5a; // 常量下标写 xdata 全局

    while (true) {
        ticks +%= 1;
        dev.p.P1.* = @truncate(ticks); // 运行期值走指针（dev.reg.write 仅 comptime 常量）
        delay500ms();
        dev.p.P1.* = 0xff;
        delay500ms();
    }
}
