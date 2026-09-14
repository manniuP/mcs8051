const std = @import("std");
const builtin = std.builtin;
const BufMap = std.BufMap;
const mem = std.mem;
const fs = std.fs;
const InstallDirectoryOptions = std.Build.InstallDirectoryOptions;
const assert = std.debug.assert;
const Io = std.Io;

const DevEnv = @import("src/dev.zig").Env;

const zig_version: std.SemanticVersion = .{ .major = 0, .minor = 16, .patch = 1 };
const stack_size = 46 * 1024 * 1024;

const IoMode = enum { threaded, evented };
const ValueInterpretMode = enum { direct, by_name };

pub fn build(b: *std.Build) !void {
    const only_c = b.option(bool, "only-c", "Translate the Zig compiler to C code, with only the C backend enabled") orelse false;
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .ofmt = if (only_c) .c else null,
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const single_threaded = b.option(bool, "single-threaded", "Build artifacts that run in single threaded mode");
    _ = b.option(bool, "use-zig-libcxx", "If libc++ is needed, use zig's bundled version, don't try to integrate with the system") orelse false;
    const flat = b.option(bool, "flat", "Put files into the installation prefix in a manner suited for upstream distribution rather than a posix file system hierarchy standard") orelse false;
    const no_bin = b.option(bool, "no-bin", "skip emitting compiler binary") orelse false;
    const skip_install_lib_files = b.option(bool, "no-lib", "skip copying of lib/ files and langref to installation prefix. Useful for development") orelse only_c;

    const static_llvm = b.option(bool, "static-llvm", "Disable integration with system-installed LLVM, Clang, LLD, and libc++") orelse false;
    const enable_llvm = b.option(bool, "enable-llvm", "Build self-hosted compiler with LLVM backend enabled") orelse static_llvm;
    const llvm_has_m68k = b.option(bool, "llvm-has-m68k", "...") orelse false;
    const llvm_has_csky = b.option(bool, "llvm-has-csky", "...") orelse false;
    const llvm_has_arc = b.option(bool, "llvm-has-arc", "...") orelse false;
    const llvm_has_xtensa = b.option(bool, "llvm-has-xtensa", "...") orelse false;

    const debug_gpa = b.option(bool, "debug-allocator", "Force the compiler to use DebugAllocator") orelse false;
    _ = b.option(bool, "force-link-libc", "Force self-hosted compiler to link libc") orelse (enable_llvm or only_c);
    const sanitize_thread = b.option(bool, "sanitize-thread", "Enable thread-sanitization") orelse false;
    const strip = b.option(bool, "strip", "Omit debug information");
    const valgrind = b.option(bool, "valgrind", "Enable valgrind integration");
    const pie = b.option(bool, "pie", "Produce a Position Independent Executable");
    const io_mode = b.option(IoMode, "io-mode", "How the compiler performs IO") orelse .threaded;
    const value_interpret_mode = b.option(ValueInterpretMode, "value-interpret-mode", "...") orelse .direct;
    const value_tracing = b.option(bool, "value-tracing", "...") orelse false;

    const mem_leak_frames: u32 = b.option(u32, "mem-leak-frames", "...") orelse blk: {
        if (strip == true) break :blk @as(u32, 0);
        if (optimize != .Debug) break :blk 0;
        break :blk 4;
    };

    const is_debug = optimize == .Debug;
    const enable_debug_extensions = b.option(bool, "debug-extensions", "Enable commands and options useful for debugging the compiler") orelse is_debug;
    const enable_logging = b.option(bool, "log", "Enable debug logging in the compiler") orelse is_debug;
    const enable_link_snapshots = b.option(bool, "link-snapshots", "Save binary snapshots of the compiler state after link operations") orelse false;

    const tracy = b.option([]const u8, "tracy", "Enable Tracy integration");
    const tracy_callstack = b.option(bool, "tracy-callstack", "...") orelse (tracy != null);
    const tracy_allocation = b.option(bool, "tracy-allocation", "...") orelse (tracy != null);
    const tracy_callstack_depth: u32 = b.option(u32, "tracy-callstack-depth", "...") orelse 10;

    const entitlements = b.option([]const u8, "entitlements", "...");

    const skip_non_native = b.option(bool, "skip-non-native", "...") orelse false;

    // Version string
    const opt_version_string = b.option([]const u8, "version-string", "Override Zig version string");
    const version_slice = if (opt_version_string) |version| version else v: {
        const version_string = b.fmt("{d}.{d}.{d}", .{ zig_version.major, zig_version.minor, zig_version.patch });
        var code: u8 = undefined;
        _ = b.runAllowFail(&[_][]const u8{
            "git",        "-C",    b.build_root.path orelse ".",
            "--git-dir",  ".git",  "describe",
            "--match",    "*.*.*", "--tags",
            "--abbrev=9",
        }, &code, .ignore) catch break :v version_string;
        break :v version_string;
    };
    const version = try b.allocator.dupeZ(u8, version_slice);

    const exe = addCompilerStep(b, .{
        .optimize = optimize,
        .target = target,
        .strip = strip,
        .valgrind = valgrind,
        .sanitize_thread = sanitize_thread,
        .single_threaded = single_threaded,
    });
    exe.pie = pie;
    exe.entitlements = entitlements;
    exe.use_new_linker = b.option(bool, "new-linker", "Use the new linker");

    const use_llvm = b.option(bool, "use-llvm", "Use the llvm backend");
    exe.use_llvm = use_llvm;
    exe.use_lld = use_llvm;

    const exe_options = b.addOptions();
    exe.root_module.addOptions("build_options", exe_options);

    exe_options.addOption(u32, "mem_leak_frames", mem_leak_frames);
    exe_options.addOption(bool, "skip_non_native", skip_non_native);
    exe_options.addOption(bool, "have_llvm", enable_llvm);
    exe_options.addOption(bool, "llvm_has_m68k", llvm_has_m68k);
    exe_options.addOption(bool, "llvm_has_csky", llvm_has_csky);
    exe_options.addOption(bool, "llvm_has_arc", llvm_has_arc);
    exe_options.addOption(bool, "llvm_has_xtensa", llvm_has_xtensa);
    exe_options.addOption(bool, "debug_gpa", debug_gpa);
    exe_options.addOption(DevEnv, "dev", if (only_c) .bootstrap else .full);
    exe_options.addOption(IoMode, "io_mode", io_mode);
    exe_options.addOption(ValueInterpretMode, "value_interpret_mode", value_interpret_mode);
    exe_options.addOption([:0]const u8, "version", version);

    const semver = try std.SemanticVersion.parse(version);
    exe_options.addOption(std.SemanticVersion, "semver", semver);

    exe_options.addOption(bool, "enable_debug_extensions", enable_debug_extensions);
    exe_options.addOption(bool, "enable_logging", enable_logging);
    exe_options.addOption(bool, "enable_link_snapshots", enable_link_snapshots);
    exe_options.addOption(bool, "enable_tracy", tracy != null);
    exe_options.addOption(bool, "enable_tracy_callstack", tracy_callstack);
    exe_options.addOption(bool, "enable_tracy_allocation", tracy_allocation);
    exe_options.addOption(u32, "tracy_callstack_depth", tracy_callstack_depth);
    exe_options.addOption(bool, "value_tracing", value_tracing);

    if (no_bin) {
        b.getInstallStep().dependOn(&exe.step);
    } else {
        const install_exe = b.addInstallArtifact(exe, .{
            .dest_dir = if (flat) .{ .override = .prefix } else .default,
        });
        b.getInstallStep().dependOn(&install_exe.step);
    }

    const test_step = b.step("test", "Run all the tests");
    test_step.dependOn(&exe.step);

    if (!skip_install_lib_files) {
        b.installDirectory(.{
            .source_dir = b.path("lib"),
            .install_dir = if (flat) .prefix else .lib,
            .install_subdir = if (flat) "lib" else "zig",
            .exclude_extensions = &[_][]const u8{
                ".gz",
                ".zoo",
                ".tar.zst",
            },
            .blank_extensions = &[_][]const u8{
                "test.zig",
            },
        });
    }
}

const AddCompilerModOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    strip: ?bool,
    sanitize_thread: ?bool,
    single_threaded: ?bool,
    valgrind: ?bool,
};

fn addCompilerMod(b: *std.Build, options: AddCompilerModOptions) *std.Build.Module {
    const compiler_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = options.target,
        .optimize = options.optimize,
        .strip = options.strip,
        .sanitize_thread = options.sanitize_thread,
        .single_threaded = options.single_threaded,
        .valgrind = options.valgrind,
    });

    const aro_mod = b.createModule(.{
        .root_source_file = b.path("lib/compiler/aro/aro.zig"),
    });

    compiler_mod.addImport("aro", aro_mod);

    return compiler_mod;
}

fn addCompilerStep(b: *std.Build, options: AddCompilerModOptions) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "zig",
        .max_rss = 8_000_000_000,
        .root_module = addCompilerMod(b, options),
    });
    exe.stack_size = stack_size;

    const function_data_sections = options.target.result.cpu.arch.isArm() or options.target.result.cpu.arch.isPowerPC();
    exe.link_function_sections = function_data_sections;
    exe.link_data_sections = function_data_sections;

    return exe;
}
