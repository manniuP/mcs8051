const std = @import("std");

// USB-CDC 便携构建：只用上一级的共享 toolchain/（自带 zig + sdcc），
// 无需系统工具链，也不依赖预设环境变量。
//
// 用法（在本目录，用自带 zig）：见 build.cmd
//   build.cmd
//   build.cmd -Dcode-loc=0x0000
// 也可直接：..\toolchain\zig\bin\zig.exe build

const sdcc = "../toolchain/sdcc/bin/sdcc.exe";

pub fn build(b: *std.Build) void {
    const code_loc = b.option([]const u8, "code-loc", "代码区基址（AI8051U = 0xff0000）") orelse "0xff0000";

    // [1/2] C -> .rel（单编译单元：main + 全部 ISR，SDCC 才会生成完整中断向量表）
    const c = b.addSystemCommand(&.{
        sdcc, "-mmcs251", "--model-large",
        "-I", "include", "-I", "src",
        "-c", "src/usb_cdc_all.c", "-o", "usb_cdc_all.rel",
    });

    // [2/2] link -> .ihx
    const link = b.addSystemCommand(&.{
        sdcc, "-mmcs251", "--model-large", "--code-loc", code_loc,
        "usb_cdc_all.rel", "-o", "usb_cdc.ihx",
    });
    link.step.dependOn(&c.step);
    b.getInstallStep().dependOn(&link.step);
}
