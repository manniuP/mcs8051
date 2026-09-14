pub const mem_leak_frames: u32 = 0;
pub const skip_non_native: bool = false;
pub const have_llvm: bool = false;
pub const llvm_has_m68k: bool = false;
pub const llvm_has_csky: bool = false;
pub const llvm_has_arc: bool = false;
pub const llvm_has_xtensa: bool = false;
pub const debug_gpa: bool = false;

pub const DevEnv = enum { bootstrap, core, full, c_source, ast_gen, sema, @"aarch64-linux", cbe, @"powerpc-linux", @"riscv64-linux", spirv, wasm, @"x86_64-linux" };
pub const dev: DevEnv = .full;

pub const IoMode = enum { threaded, evented };
pub const io_mode: IoMode = .threaded;

pub const ValueInterpretMode = enum { direct, by_name };
pub const value_interpret_mode: ValueInterpretMode = .direct;

pub const version: [:0]const u8 = "0.16.1-dev.0+g000000000";
pub const semver: std.SemanticVersion = .{ .major = 0, .minor = 16, .patch = 1 };

pub const enable_debug_extensions: bool = false;
pub const enable_logging: bool = false;
pub const enable_link_snapshots: bool = false;
pub const enable_tracy: bool = false;
pub const enable_tracy_callstack: bool = false;
pub const enable_tracy_allocation: bool = false;
pub const tracy_callstack_depth: u32 = 0;
pub const value_tracing: bool = false;

const std = @import("std");
