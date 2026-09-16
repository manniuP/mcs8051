const std = @import("std");

// 混合工程 C + Zig 的 **独立** build.zig 构建：编排 SDCC（C）+ MCS zig 编译器（Zig）+ sdas + 链接。
//
// 用法（在本目录执行）：
//   zig build                      # 产物 app.ihx
//   zig build -Dmcs-small=true     # Zig 侧走 -OReleaseSmall
//   zig build -Dmcs-zig=<路径>     # 指定 MCS zig 编译器
//
// 它只做「编排」，本身用系统 zig（宿主机）跑；实际编译各步用 addSystemCommand 调外部工具，
// 故与同目录的 xmake.lua **互不干扰**，各自都能独立完成整套构建。

const paths = struct {
    const sdcc = "../../tools/sdcc-mcs251-windows-x64/sdcc-mcs251/bin/sdcc.exe";
    const sdas = "../../tools/sdcc-mcs251-windows-x64/sdcc-mcs251/bin/sdas251.exe";
    const inc = "../../lib/include";
    const zig_lib = "../../compiler/lib";
};

pub fn build(b: *std.Build) void {
    const mcs_zig = b.option([]const u8, "mcs-zig", "MCS 自举 zig 编译器（默认 ../../compiler/zig-out/bin/zig.exe）") orelse
        "../../compiler/zig-out/bin/zig.exe";
    const small = b.option(bool, "mcs-small", "Zig 侧 -OReleaseSmall（默认 -ODebug）") orelse false;
    const zig_opt: []const u8 = if (small) "-OReleaseSmall" else "-ODebug";

    // [1] C -> .rel
    const c = b.addSystemCommand(&.{
        paths.sdcc, "-mmcs251", "--model-large", "--stack-auto",
        "-I", paths.inc, "-c", "src/main.c", "-o", "main.rel",
    });

    // [2] Zig -> .asm
    const z = b.addSystemCommand(&.{
        mcs_zig, "build-obj", zig_opt, "-target", "mcs251-freestanding",
        "-femit-bin=lib.asm", "src/lib.zig",
    });
    z.setEnvironmentVariable("ZIG_LIB_DIR", paths.zig_lib);

    // [3] asm 后处理（修标签重名 + 局部瘦身）
    const fix = b.addSystemCommand(&.{ "python", "../../tools/fix_mcs_labels.py", "lib.asm" });
    fix.step.dependOn(&z.step);
    const optm = b.addSystemCommand(&.{ "python", "../../tools/mcs_opt.py", "lib.asm" });
    optm.step.dependOn(&fix.step);
    const ir = b.addSystemCommand(&.{ "python", "../../tools/mcs_ir.py", "lib.asm" });
    ir.step.dependOn(&optm.step);

    // [4] asm -> .rel
    const as = b.addSystemCommand(&.{ paths.sdas, "-plosgffw", "lib.rel", "lib.asm" });
    as.step.dependOn(&ir.step);

    // [5] link -> .ihx
    const link = b.addSystemCommand(&.{
        paths.sdcc, "-mmcs251", "--model-large", "--code-loc", "0xff0000",
        "--data-loc", "0x30", "--idata-loc", "0x80",
        "main.rel", "lib.rel", "-o", "app.ihx",
    });
    link.step.dependOn(&c.step);
    link.step.dependOn(&as.step);

    b.getInstallStep().dependOn(&link.step);
}
