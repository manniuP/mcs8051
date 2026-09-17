const std = @import("std");

// ziglog 便携构建：纯 Zig（无 C 运行库），只用上一级的共享 toolchain/。
// 流程：[1] 自带 zig 的 MCS 后端 build-obj -> log.asm
//       [2..4] mcstools.exe（fix/opt/ir 后处理，无需 Python）
//       [5] sdas251 汇编 + sdcc 链接（crt0.asm + log.rel）-> log.ihx
//
// 用法（在本目录，用自带 zig）：见 build.cmd
//   build.cmd
//   build.cmd -Dmcs-small=true          :: -OReleaseSmall
//   build.cmd -Dcode-loc=0x0000
// 也可直接：..\toolchain\zig\bin\zig.exe build

const sdcc = "../toolchain/sdcc/bin/sdcc.exe";
const sdas = "../toolchain/sdcc/bin/sdas251.exe";
const mcstools = "../toolchain/mcstools/mcstools.exe";

pub fn build(b: *std.Build) void {
    // ziglog 仅 mcs251：mcs51 后端每个函数一块静态帧，全部落在内部 RAM 直接区（≤128B）；
    // 本示例（COBS + 多函数）的 DSEG 已 200+B，链不上（主工程 8 位 COBS 因此改用 C）。
    const arch = b.option([]const u8, "arch", "目标架构：仅支持 mcs251") orelse "mcs251";
    if (!std.mem.eql(u8, arch, "mcs251")) {
        std.debug.print(
            "error: ziglog 仅支持 mcs251（-Darch=mcs51 不可用：mcs51 Zig 静态帧超出内部 RAM 直接区 128B）\n",
            .{},
        );
        std.process.exit(2);
    }
    const code_loc = b.option([]const u8, "code-loc", "代码区基址（AI8051U = 0xff0000）") orelse "0xff0000";
    const small = b.option(bool, "mcs-small", "Zig 侧 -OReleaseSmall（默认 -ODebug）") orelse false;
    const opt: []const u8 = if (small) "-OReleaseSmall" else "-ODebug";

    // [1/5] Zig -> asm（自带 zig 由 exe 位置自寻 lib；缓存的 ZIG_GLOBAL_CACHE_DIR 由
    // build.cmd 指向便携集根目录，子进程默认继承）。
    const z = b.addSystemCommand(&.{
        b.graph.zig_exe, "build-obj", opt, "-target", "mcs251-freestanding",
        "--dep", "mcs", "--dep", "cobs",
        "-Mroot=log.zig",
        "-Mmcs=mcs251.zig",
        "-Mcobs=cobs.zig",
        "-femit-bin=log.asm",
    });
    // 设备存储表：与主工程一致（否则 ≤2B 全局会落在 xdata 而非 data，产物不同）。
    // device.json 由 tools/make_portable.ps1 生成到本目录。见 mcs251/devices/README.md。
    z.setEnvironmentVariable("MCS_DEVICE", @embedFile("device.json"));

    // [2/5][3/5][4/5] 构建层后处理（修标签重名 + 瘦身 + 死 store 消除）。
    const fix = b.addSystemCommand(&.{ mcstools, "fix", "log.asm" });
    fix.step.dependOn(&z.step);
    const optm = b.addSystemCommand(&.{ mcstools, "opt", "log.asm" });
    optm.step.dependOn(&fix.step);
    const ir = b.addSystemCommand(&.{ mcstools, "ir", "log.asm" });
    ir.step.dependOn(&optm.step);
    // overlay 对 mcs251（@spx 帧）是空操作，但主工程 postprocess_asm 会跑它（顺带把行尾写成 CRLF），
    // 加上以保持中间 .asm 与主工程逐字节一致。
    const ovl = b.addSystemCommand(&.{ mcstools, "overlay", "log.asm" });
    ovl.step.dependOn(&ir.step);

    // [5/5] asm -> rel -> ihx
    const as = b.addSystemCommand(&.{ sdas, "-plosgffw", "log.rel", "log.asm" });
    as.step.dependOn(&ovl.step);
    const crt = b.addSystemCommand(&.{ sdas, "-plosgffw", "crt0.rel", "crt0.asm" });

    const link = b.addSystemCommand(&.{
        sdcc, "-mmcs251", "--model-large", "--code-loc", code_loc,
        "--data-loc", "0x30", "--idata-loc", "0x80",
        "crt0.rel", "log.rel", "-o", "log.ihx",
    });
    link.step.dependOn(&as.step);
    link.step.dependOn(&crt.step);
    b.getInstallStep().dependOn(&link.step);
}
