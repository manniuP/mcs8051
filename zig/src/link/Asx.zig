//! ASxxxx 可重定位文本输出 / SDCC `sdld` 驱动。
//!
//! 与直接产出目标字节的后端不同，本后端产出 ASxxxx 汇编文本。因此这里不做增量
//! 链接：`updateFunc` 渲染单个函数并把文本追加到 `assembly`，`flush` 一次性写入
//! 输出文件（通常为 `.asm`/`.s`），后续由 `sdas251` 汇编、`sdld` 链接。
//!
//! 目前只处理函数文本；数据（`updateNav`）与导出重命名尚未实现。

const Asx = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const Path = std.Build.Cache.Path;

const Zcu = @import("../Zcu.zig");
const InternPool = @import("../InternPool.zig");
const Compilation = @import("../Compilation.zig");
const codegen = @import("../codegen.zig");
const link = @import("../link.zig");
const AnyMir = codegen.AnyMir;

base: link.File,

/// 累积的汇编文本。各函数的文本在 `updateFunc` 中追加，`flush` 一次性落盘。
assembly: std.ArrayList(u8) = .empty,

pub fn open(
    arena: Allocator,
    comp: *Compilation,
    emit: Path,
    options: link.File.OpenOptions,
) !*Asx {
    return createEmpty(arena, comp, emit, options);
}

pub fn createEmpty(
    arena: Allocator,
    comp: *Compilation,
    emit: Path,
    options: link.File.OpenOptions,
) !*Asx {
    const io = comp.io;
    const target = &comp.root_mod.resolved_target.result;
    std.debug.assert(target.ofmt == .hex);
    const optimize_mode = comp.root_mod.optimize_mode;
    const output_mode = comp.config.output_mode;

    // 与 C 后端一致：文件在 `flush` 时截断并写入。
    const file = try emit.root_dir.handle.createFile(io, emit.sub_path, .{
        .truncate = false,
    });
    errdefer file.close(io);

    const asx = try arena.create(Asx);
    asx.* = .{
        .base = .{
            .tag = .asx,
            .comp = comp,
            .emit = emit,
            .gc_sections = options.gc_sections orelse (optimize_mode != .Debug and output_mode != .Obj),
            .print_gc_sections = options.print_gc_sections,
            .stack_size = options.stack_size orelse 0,
            .allow_shlib_undefined = options.allow_shlib_undefined orelse false,
            .file = file,
            .build_id = options.build_id,
        },
        .assembly = .empty,
    };
    return asx;
}

pub fn deinit(asx: *Asx) void {
    const gpa = asx.base.comp.gpa;
    asx.assembly.deinit(gpa);
}

/// AIR/MIR 已由 codegen 生成；这里把函数文本渲染并追加到 `assembly`。
pub fn updateFunc(
    asx: *Asx,
    pt: Zcu.PerThread,
    func_index: InternPool.Index,
    mir: *AnyMir,
) codegen.CodeGenError!void {
    const zcu = pt.zcu;
    const gpa = zcu.gpa;
    const ip = &zcu.intern_pool;
    const nav = zcu.funcInfo(func_index).owner_nav;
    // SDCC C ABI 以 `_` 前缀修饰全局符号（例如 C 的 `main` 对应 `_main`）。
    const raw_name = ip.getNav(nav).name.toSlice(ip);
    const name = try std.fmt.allocPrint(gpa, "_{s}", .{raw_name});
    defer gpa.free(name);

    var aw: std.Io.Writer.Allocating = .init(gpa);
    defer aw.deinit();
    const w = &aw.writer;

    // 函数头：代码区、全局符号与标签。
    // 使用 SDCC/ASxxxx 约定的代码区名 `CSEG`。
    w.writeAll("\t.area CSEG    (CODE)\n") catch return error.OutOfMemory;
    w.print("\t.globl {s}\n", .{name}) catch return error.OutOfMemory;
    w.print("{s}:\n", .{name}) catch return error.OutOfMemory;

    codegen.emitFunction(&asx.base, pt, zcu.navSrcLoc(nav), func_index, 0, mir, w, .none) catch |err| switch (err) {
        error.WriteFailed => return error.OutOfMemory,
        else => |e| return e,
    };

    try asx.assembly.appendSlice(gpa, aw.written());
}

/// 数据符号（全局变量/常量）尚未实现。
pub fn updateNav(
    asx: *Asx,
    pt: Zcu.PerThread,
    nav_index: InternPool.Nav.Index,
) codegen.CodeGenError!void {
    const zcu = pt.zcu;
    const gpa = zcu.gpa;
    const ip = &zcu.intern_pool;
    const name = ip.getNav(nav_index).fqn.toSlice(ip);

    // 明确标注尚未实现，避免生成静默错误的映像。
    const text = try std.fmt.allocPrint(gpa, "\t; TODO mcs backend: data symbol '{s}' not implemented\n", .{name});
    defer gpa.free(text);
    try asx.assembly.appendSlice(gpa, text);
}

/// 导出别名重命名尚未实现。
pub fn updateExports(
    asx: *Asx,
    pt: Zcu.PerThread,
    exported: Zcu.Exported,
    export_indices: []const Zcu.Export.Index,
) Allocator.Error!void {
    _ = asx;
    _ = pt;
    _ = exported;
    _ = export_indices;
}

/// 把累积的汇编文本写入输出文件。
pub fn flush(
    asx: *Asx,
    arena: Allocator,
    tid: Zcu.PerThread.Id,
    prog_node: std.Progress.Node,
) link.File.FlushError!void {
    _ = arena;
    _ = tid;
    const sub_prog_node = prog_node.start("Flush ASxxxx output", 0);
    defer sub_prog_node.end();

    const comp = asx.base.comp;
    const io = comp.io;
    const diags = &comp.link_diags;
    const text = asx.assembly.items;

    const file = asx.base.file orelse return diags.fail("ASxxxx output file is not open", .{});
    file.setLength(io, text.len) catch |err| return diags.fail("failed to allocate ASxxxx output: {t}", .{err});

    var fw = file.writer(io, &.{});
    const w = &fw.interface;
    w.writeAll(text) catch |err| switch (err) {
        error.WriteFailed => return diags.fail("failed to write '{f}': {s}", .{
            std.fmt.alt(asx.base.emit, .formatEscapeChar), @errorName(fw.err.?),
        }),
    };
    w.flush() catch |err| switch (err) {
        error.WriteFailed => return diags.fail("failed to flush '{f}': {s}", .{
            std.fmt.alt(asx.base.emit, .formatEscapeChar), @errorName(fw.err.?),
        }),
    };
}
