const std = @import("std");

// t0print 便携构建：纯 Zig，Timer0 1ms 中断里每秒经 UART1 打印一行。只用上一级的共享 toolchain/。
// 流程：[1] 自带 zig 的 MCS 后端 build-obj -> t0print.asm
//       [2..4] mcstools.exe（fix/opt/ir 后处理，无需 Python）
//       [5] sdas{251,8051} 汇编 + sdcc 链接（crt0.asm + t0print.rel）-> t0print.ihx
//
// 用法（在本目录，用自带 zig）：见 build.cmd
//   build.cmd
//   build.cmd -Darch=mcs51             :: 8 位 MCS-51（默认 mcs251 / AI8051U 32 位）
//   build.cmd -Dmcs-small=true         :: -OReleaseSmall
//   build.cmd -Dcode-loc=0x0000
// 也可直接：..\toolchain\zig\bin\zig.exe build

const sdcc = "../toolchain/sdcc/bin/sdcc.exe";
const mcstools = "../toolchain/mcstools/mcstools.exe";

pub fn build(b: *std.Build) void {
    const arch = b.option([]const u8, "arch", "目标架构：mcs251（默认）或 mcs51") orelse "mcs251";
    const mcs51 = std.mem.eql(u8, arch, "mcs51");
    const code_loc = b.option([]const u8, "code-loc", "代码区基址（mcs251 = 0xff0000）") orelse
        (if (mcs51) "0x0000" else "0xff0000");
    const small = b.option(bool, "mcs-small", "Zig 侧 -OReleaseSmall（默认 -ODebug）") orelse false;
    const opt: []const u8 = if (small) "-OReleaseSmall" else "-ODebug";

    // 按架构选：目标三元组 / 汇编器 / sdcc 模型 / 启动文件。
    const target = if (mcs51) "mcs51-freestanding" else "mcs251-freestanding";
    const sdas = if (mcs51) "../toolchain/sdcc/bin/sdas8051.exe" else "../toolchain/sdcc/bin/sdas251.exe";
    const model = if (mcs51) "-mmcs51" else "-mmcs251";
    const crt0 = if (mcs51) "crt0_mcs51.asm" else "crt0.asm";

    // [1/5] Zig -> asm（自带 zig 由 exe 位置自寻 lib；ZIG_GLOBAL_CACHE_DIR 由 build.cmd 设置并继承）。
    const z = b.addSystemCommand(&.{
        b.graph.zig_exe, "build-obj", opt, "-target", target,
        "--dep", "mcs",
        "-Mroot=t0print.zig",
        "-Mmcs=mcs251.zig",
        "-femit-bin=t0print.asm",
    });
    // 设备存储表：与主工程一致（否则 ≤2B 全局会落在 xdata 而非 data，产物不同）。
    // device.json 由 tools/make_portable.ps1 生成到本目录。见 mcs251/devices/README.md。
    z.setEnvironmentVariable("MCS_DEVICE", @embedFile("device.json"));

    // [2/5][3/5][4/5] 构建层后处理（修标签重名 + 瘦身 + 死 store 消除）。
    const fix = b.addSystemCommand(&.{ mcstools, "fix", "t0print.asm" });
    fix.step.dependOn(&z.step);
    const optm = b.addSystemCommand(&.{ mcstools, "opt", "t0print.asm" });
    optm.step.dependOn(&fix.step);
    const ir = b.addSystemCommand(&.{ mcstools, "ir", "t0print.asm" });
    ir.step.dependOn(&optm.step);
    // overlay 对 mcs251（@spx 帧）是空操作，但主工程 postprocess_asm 会跑它（顺带把行尾写成 CRLF），
    // 加上以保持中间 .asm 与主工程逐字节一致。
    const ovl = b.addSystemCommand(&.{ mcstools, "overlay", "t0print.asm" });
    ovl.step.dependOn(&ir.step);

    // [5/5] asm -> rel -> ihx
    const as = b.addSystemCommand(&.{ sdas, "-plosgffw", "t0print.rel", "t0print.asm" });
    as.step.dependOn(&ovl.step);
    const crt = b.addSystemCommand(&.{ sdas, "-plosgffw", "crt0.rel", crt0 });

    // mcs251：代码链到 AI8051U 的 FF:0000，data/idata 基址避开寄存器组。
    // mcs51：代码默认 0x0000，data/idata 用 sdcc 默认（crt0_mcs51.asm 负责 SP 与向量表）。
    const link = b.addSystemCommand(&.{ sdcc, model, "--model-large", "--code-loc", code_loc });
    if (!mcs51) {
        link.addArgs(&.{ "--data-loc", "0x30", "--idata-loc", "0x80" });
    }
    link.addArgs(&.{ "crt0.rel", "t0print.rel", "-o", "t0print.ihx" });
    link.step.dependOn(&as.step);
    link.step.dependOn(&crt.step);
    b.getInstallStep().dependOn(&link.step);
}
