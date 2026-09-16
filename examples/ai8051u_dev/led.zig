//! 纯 Zig 点灯（AI8051U / MCS-251）—— 契合「设备表驱动」的新编译器：
//!
//! - SFR 地址来自生成的 `dev` 模块（`device_sfr.zig`，由
//!   `tools/mcs_sfr.py --device <设备> --emit zig` 生成），不再手写数字地址；
//! - 全局变量的**放置由编译器按设备存储表自动决定**（`MCS_DEVICE` 环境变量）：
//!   ≤2 字节 → data（直接寻址，快），其余 → 设备默认数据空间（本型号 xdata）。
//!   无需任何 `linksection`。
//!
//! 构建见 `xmake build --mcs_arch=mcs251 devzig`。

const dev = @import("dev");
const m = @import("mcs");

// 避免与 `dev.sfr.*` 同名（后端数据符号按短名 `_<name>` 导出，会重名冲突）。
const P1_ADDR: u8 = @intCast(dev.sfr.P1);
const P1M1_ADDR: u8 = @intCast(dev.sfr.P1M1);
const P1M0_ADDR: u8 = @intCast(dev.sfr.P1M0);

const P1p = @as(*volatile u8, @ptrFromInt(P1_ADDR));

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
    m.sfrAnd(P1M1_ADDR, ~@as(u8, 0x02)); // P1.1 推挽
    m.sfrOr(P1M0_ADDR, 0x02);
    buf[0] = 0x5a; // 常量下标写 xdata 全局

    while (true) {
        ticks +%= 1;
        P1p.* = @truncate(ticks);
        delay500ms();
        P1p.* = 0xff;
        delay500ms();
    }
}
