//! MCS-51 / MCS-251 自举后端入口。
//!
//! 目标 ABI：SDCC MCS251 ABI revision 2（见 `sdcc-c251/doc/mcs251/abi.md`）。
//! 输出：ASxxxx 汇编文本，由 `sdas251`/`sdas8051` 汇编、`sdld` 链接。
//!
//! 当前实现范围（增量推进）：
//!   - 首个标量参数走 ABI 寄存器组；其余标量参数按 SDCC reentrant 约定从硬件栈读取；
//!   - 1~4 字节标量返回值写入 DPL/DPH/B/A，随后 `eret`/`ret`；
//!   - 1~4 字节整数二元运算 `add`/`sub`/`anl`/`orl`/`xrl`（字节 + 进位链）；
//!   - 移位 `shl`/`shr`（常量/变量计数）；取反 `.not`（整型按位 / 布尔逻辑）；
//!   - 乘法：1 字节 `mul ab`，2 字节 `mul wr,wr`，4 字节由三个 16×16 部分积合成；
//!   - 除法/取模：1 字节 `div ab`，2 字节 `div wr,wr`，3/4 字节用恢复余数法循环；
//!     有符号除法先取绝对值相除，再按符号调整（trunc/floor、rem/mod）；
//!   - 帧：MCS-251 为 SPX 栈帧；MCS-51 为静态 idata 帧（`.area DSEG` / `_frkN` / `.ds`）；
//!   - 控制流：`.block`/`.loop`/`.repeat`/`.br`/`.cond_br`/`.switch_br`/`.loop_switch_br`
//!     与整数比较（含符号）；switch 用相等/区间比较链分派；
//!   - 局部变量 `.alloc`/`.load`/`.store`；整数转换 `.intcast`/`.trunc`/`.bitcast`；
//!   - 直接调用 `.call`（含递归）：首参走寄存器组，其余栈参数逆序压栈，调用者清理；
//!     间接调用：3 字节函数指针经 push/pop 装入 DR28，`ecall @dr28`；
//!     变参调用：变参（已提升为 `c_int`）与固定栈参数一起逆序压栈；被调方用
//!     `@cVaStart`/`@cVaArg`/`@cVaCopy`/`@cVaEnd`，VaList 为 3 字节扁平指针，
//!     `va_start = SPX - (frame_size + 2 + 固定栈参数字节)`，`va_arg` 递减后用 `@DR28` 间接读取；
//!   - 数组：编译期下标直接算帧内偏移；运行期下标按常量下标展开比较链访问；
//!   - 切片：`.array_to_slice`/`.slice`/`.slice_len`/`.slice_ptr`/`.slice_elem_val`/
//!     `.slice_elem_ptr`/`.ptr_add`；编译期 `ptr`+`len` 折叠为切片视图（无存储），
//!     物化切片为 6 字节 ptr+len（3 字节扁平地址，`@DR28` 解引用），运行期下标按已知
//!     长度展开分派；指针作为标量时物化为 3 字节地址；
//!   - 聚合值拷贝：编译期聚合经 `Value.writeToMemory` 逐字节写出；运行期整块按内存序复制；
//!   - `trap`/`breakpoint`/`unreach`；
//!   - 其余 AIR 指令给出明确的编译错误，便于逐项补齐。
//!
//! 值模型：
//!   - MCS-251：`.frame` 的位移以 prologue 之后的 SPX 为基准（负）；每个运行期值占一个
//!     SPX 帧槽（大端）；首个标量参数进入时从 ABI 寄存器复制到帧槽；其余栈参数以
//!     `.incoming` 记录相对进入时 SPX 的低地址位移，待帧大小确定后换算为 `.frame`。
//!   - MCS-51：`.frame` 为静态 idata 帧内偏移（正，小端）；首个标量参数进入时从 ABI
//!     寄存器复制，其余参数进入时从硬件栈复制（`R0 = SP - (2 + Σsize)`）。
//!
//! 尚未实现：浮点；无界切片/指针的运行期下标；MCS-51 切片、变参/间接调用。

const std = @import("std");

const Air = @import("../../Air.zig");
const InternPool = @import("../../InternPool.zig");
const Type = @import("../../Type.zig");
const Value = @import("../../Value.zig");
const Zcu = @import("../../Zcu.zig");
const codegen = @import("../../codegen.zig");
const link = @import("../../link.zig");

const Mir = @import("Mir.zig");
const encode = @import("encode.zig");
const abi = @import("abi.zig");

/// 告诉 AIR 合法化阶段本后端支持哪些特性。
///
/// 返回 `null` 表示不做展开：`_safe` 运算由后端按无检查方式生成。
pub fn legalizeFeatures(_: *const std.Target) ?*const Air.Legalize.Features {
    return null;
}

/// 运行期下标的元素指针载荷。
const DynPtr = struct { base: i32, idx: i32, idx_size: u32, elem_size: u32, len: u32 };

/// 物化切片的来源（编译期已知的数组视图），按切片存储位移索引。
const SliceOrigin = struct { base: i32, off: i32, len: u32 };

/// 一个 AIR 运行期值的位置。
const MCValue = union(enum) {
    /// 尚未求值 / 无运行时值。
    none,
    /// 位于 ABI 寄存器组，从最低有效字节起。
    regs: abi.Primary,
    /// 位于累加器 A（MCS-51 的 1 字节中间结果）。
    acc,
    /// 帧槽（见文件头对 `.frame` 位移的说明）。
    frame: i32,
    /// 调用者压栈的入参（MCS-251）：相对进入时 SPX 的低地址位移。
    incoming: i32,
    /// 指向帧内对象的编译期指针：`base` 为对象最低地址位移，`off` 为字节偏移。
    /// `len` 为已知元素个数（切片视图，0 表示未知）。
    ptr: struct { base: i32, off: i32, len: u32 = 0 },
    /// 运行期下标的元素指针。
    ptr_dyn: DynPtr,
    /// 运行期绝对地址：`addr` 为存放 3 字节扁平地址的帧槽位移。
    /// `base_addr`/`off` 用于元素指针：base_addr 是源指针 addr，off 是编译期元素偏移，
    /// 在 emitElemPtr 物化时把 DR28 设为 (load(base_addr) + off) 存到 addr。
    ptr_rt: struct {
        addr: i32,
        base_addr: i32 = 0,
        off: i32 = 0,
    },
    /// 编译期切片视图（`base`+`off` 为数据地址，`len` 为元素个数）。
    slice: struct { base: i32, off: i32, len: u32 },
};

/// 一个操作数的读取位置（多出编译期立即数一种）。
const Loc = union(enum) {
    imm: u64,
    regs: abi.Primary,
    acc,
    frame: i32,
};

/// 一个 `.block`/`.loop` 的入口/出口标签。
const BlockInfo = struct {
    start: u32,
    end: u32,
};

/// 一个 `.loop_switch_br` 的分派标签与条件帧槽。
const SwitchInfo = struct {
    dispatch: u32,
    cond_disp: i32,
};

const Gen = struct {
    gpa: std.mem.Allocator,
    pt: Zcu.PerThread,
    zcu: *Zcu,
    air: *const Air,
    func_index: InternPool.Index,
    owner_nav: InternPool.Nav.Index,
    arch: std.Target.Cpu.Arch,
    ret_class: abi.Class,
    mir: Mir = .{},
    vals: []MCValue,
    next_arg: usize = 0,
    emit_arg_cursor: usize = 0,
    stack_param_bytes: u32 = 0,
    next_label: u32 = 0,
    frame_off: i32 = 0,
    frame_sym: []const u8 = &.{},
    m51_incoming: std.AutoHashMapUnmanaged(Air.Inst.Index, u32) = .empty,
    pushed: i32 = 0,
    epilogue_sites: std.ArrayListUnmanaged(usize) = .empty,
    block_info: std.AutoHashMapUnmanaged(Air.Inst.Index, BlockInfo) = .empty,
    switch_info: std.AutoHashMapUnmanaged(Air.Inst.Index, SwitchInfo) = .empty,
    extra_slots: std.AutoHashMapUnmanaged(u64, i32) = .empty,
    slice_origin: std.AutoHashMapUnmanaged(i32, SliceOrigin) = .empty,

    fn fail(gen: *Gen, comptime fmt: []const u8, args: anytype) codegen.CodeGenError {
        @branchHint(.cold);
        return gen.zcu.codegenFail(gen.owner_nav, fmt, args);
    }

    fn addInst(gen: *Gen, mnemonic: encode.Mnemonic, operands: []const encode.Operand) !void {
        try gen.mir.addInst(gen.gpa, mnemonic, operands);
    }

    fn newLabel(gen: *Gen) u32 {
        const n = gen.next_label;
        gen.next_label += 1;
        return n;
    }

    /// 函数返回指令：MCS-251 用 `eret`，MCS-51 用 `ret`。
    fn addReturn(gen: *Gen) !void {
        try gen.addInst(if (gen.arch == .mcs251) .eret else .ret, &.{});
    }

    /// `trap`：MCS-251 有 `trap` 指令；MCS-51 用死循环。
    fn addTrap(gen: *Gen) !void {
        if (gen.arch == .mcs251) {
            try gen.addInst(.trap, &.{});
        } else {
            try gen.addInst(.sjmp, &.{.{ .code = .{ .symbol = "." } }});
        }
    }

    /// 远跳转到局部标签：MCS-251 用 `ejmp`，MCS-51 用 `ljmp`。
    fn jmpFar(gen: *Gen, label: u32) !void {
        try gen.addInst(if (gen.arch == .mcs251) .ejmp else .ljmp, &.{
            .{ .code = .{ .local_label = label } },
        });
    }

    /// 置 A 为布尔常量（0/1）。
    fn setABool(gen: *Gen, value: bool) !void {
        if (value) {
            try gen.addInst(.mov, &.{
                .{ .reg = .a },
                .{ .imm = .{ .value = 1, .bits = 8 } },
            });
        } else {
            try gen.addInst(.clr, &.{.{ .reg = .a }});
        }
    }

    // --- 临时帧槽 ----------------------------------------------------------

    fn extraKey(inst: Air.Inst.Index, serial: u8) u64 {
        return (@as(u64, @intFromEnum(inst)) << 8) | serial;
    }

    fn allocExtra(gen: *Gen, inst: Air.Inst.Index, serial: u8, size: u32) !i32 {
        const disp = gen.allocFrame(size);
        try gen.extra_slots.put(gen.gpa, extraKey(inst, serial), disp);
        return disp;
    }

    fn getExtra(gen: *Gen, inst: Air.Inst.Index, serial: u8) i32 {
        return gen.extra_slots.get(extraKey(inst, serial)).?;
    }

    fn mcToLoc(v: MCValue) Loc {
        return switch (v) {
            .regs => |p| .{ .regs = p },
            .acc => .acc,
            .frame => |d| .{ .frame = d },
            .none, .incoming, .ptr, .ptr_dyn, .ptr_rt, .slice => unreachable,
        };
    }

    /// 直接装入字节到 B，不经过 A（用于 MUL AB / DIV AB）。
    fn loadByteToB(gen: *Gen, loc: Loc, i: u32, size: u32) codegen.CodeGenError!void {
        const operand: encode.Operand = switch (loc) {
            .imm => |v| .{ .imm = .{
                .value = @intCast((v >> @intCast(8 * i)) & 0xff),
                .bits = 8,
            } },
            .regs => |p| .{ .reg = byteRegToRegister(abi.byteRegisters(p)[i]) },
            .frame => |d| gen.frameOperand(gen.slotByte(d, i, size)),
            .acc => return gen.fail(
                "mcs backend: accumulator as MUL/DIV operand is not implemented yet",
                .{},
            ),
        };
        try gen.addInst(.mov, &.{ .{ .reg = .b }, operand });
    }

    // --- 帧与寻址 ----------------------------------------------------------

    /// 分配一个 `size` 字节的帧槽，返回其最低地址位移。
    fn allocFrame(gen: *Gen, size: u32) i32 {
        const s: i32 = @intCast(size);
        if (gen.arch == .mcs251) {
            gen.frame_off -= s;
            return gen.frame_off + 1;
        }
        const start = gen.frame_off;
        gen.frame_off += s;
        return start;
    }

    fn frameBytes(gen: *Gen) u32 {
        return @intCast(if (gen.arch == .mcs251) -gen.frame_off else gen.frame_off);
    }

    /// 逻辑字节 `i`（0 为最低有效字节）在槽中的字节位移。
    /// MCS-251 为大端（最高字节在低地址）；MCS-51 为小端。
    fn slotByte(gen: *Gen, disp: i32, i: u32, size: u32) i32 {
        const off: i32 = if (gen.arch == .mcs251) @intCast(size - 1 - i) else @intCast(i);
        return disp + off;
    }

    /// 一个帧槽字节的操作数。
    /// MCS-251 出 `@SPX+dis`（`pushed` 为已压栈的参数字节数）；
    /// MCS-51 出 `_frkN+off` 形式的 idata 直接地址。
    fn frameOperand(gen: *Gen, disp: i32) encode.Operand {
        if (gen.arch == .mcs251) {
            return .{ .index = .{ .base = .spx, .disp = disp - gen.pushed } };
        }
        return .{ .dir8 = .{ .symbol_off = .{ .base = gen.frame_sym, .off = disp } } };
    }

    // --- 常量与操作数求值 --------------------------------------------------

    /// 取一个编译期整数的位模式（u64），兼容有符号负值。
    fn getConstBits(gen: *Gen, ip_index: InternPool.Index) ?u64 {
        const v = Value.fromInterned(ip_index);
        if (v.isUndef(gen.zcu)) return null;
        if (v.getUnsignedInt(gen.zcu)) |u| return u;
        return switch (gen.zcu.intern_pool.indexToKey(ip_index)) {
            .int => @bitCast(v.toSignedInt(gen.zcu)),
            else => null,
        };
    }

    fn locOf(gen: *Gen, ref: Air.Inst.Ref) codegen.CodeGenError!Loc {
        if (ref.toInterned()) |ip_index| {
            const bits = gen.getConstBits(ip_index) orelse
                return gen.fail("mcs backend: unsupported constant operand", .{});
            return .{ .imm = bits };
        }
        return switch (gen.vals[@intFromEnum(ref.toIndex().?)]) {
            .none => gen.fail("mcs backend: operand has no location", .{}),
            .regs => |p| .{ .regs = p },
            .acc => .acc,
            .frame => |d| .{ .frame = d },
            .incoming => gen.fail("mcs backend: unresolved incoming parameter", .{}),
            .ptr => |p| {
                if (gen.arch != .mcs251) return gen.fail(
                    "mcs backend: pointer values on MCS-51 are not implemented yet",
                    .{},
                );
                const tmp = gen.allocFrame(3);
                try gen.materializePtrAddr(p.base, p.off);
                try gen.storeDr28ToFrame(tmp, 3);
                return .{ .frame = tmp };
            },
            .slice => |s| {
                if (gen.arch != .mcs251) return gen.fail(
                    "mcs backend: pointer values on MCS-51 are not implemented yet",
                    .{},
                );
                const tmp = gen.allocFrame(3);
                try gen.materializePtrAddr(s.base, s.off);
                try gen.storeDr28ToFrame(tmp, 3);
                return .{ .frame = tmp };
            },
            .ptr_rt => |pr| return .{ .frame = pr.addr },
            .ptr_dyn => gen.fail("mcs backend: runtime indexed pointer used as a scalar value", .{}),
        };
    }

    /// 把某位置的字节 `i` 装入累加器 A。
    fn loadByteToA(gen: *Gen, loc: Loc, i: u32, size: u32) codegen.CodeGenError!void {
        switch (loc) {
            .imm => |v| {
                const byte: u8 = @truncate(v >> @intCast(8 * i));
                try gen.addInst(.mov, &.{
                    .{ .reg = .a },
                    .{ .imm = .{ .value = byte, .bits = 8 } },
                });
            },
            .regs => |p| {
                const r = byteRegToRegister(abi.byteRegisters(p)[i]);
                if (!isRegisterA(r)) try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = r } });
            },
            .acc => {
                if (i != 0) return gen.fail(
                    "mcs backend: multi-byte accumulator operand is not implemented yet",
                    .{},
                );
            },
            .frame => |disp| {
                try gen.addInst(.mov, &.{
                    .{ .reg = .a },
                    gen.frameOperand(gen.slotByte(disp, i, size)),
                });
            },
        }
    }

    /// 把累加器 A 写入结果位置 `loc` 的字节 `i`。
    fn storeA(gen: *Gen, loc: MCValue, i: u32, size: u32) codegen.CodeGenError!void {
        switch (loc) {
            .none => return gen.fail("mcs backend: cannot store into an unset location", .{}),
            .acc => {
                if (i != 0) return gen.fail(
                    "mcs backend: cannot store a multi-byte value into the accumulator",
                    .{},
                );
            },
            .regs => |p| {
                const r = byteRegToRegister(abi.byteRegisters(p)[i]);
                if (!isRegisterA(r)) try gen.addInst(.mov, &.{ .{ .reg = r }, .{ .reg = .a } });
            },
            .frame => |disp| {
                try gen.addInst(.mov, &.{
                    gen.frameOperand(gen.slotByte(disp, i, size)),
                    .{ .reg = .a },
                });
            },
            .incoming => return gen.fail("mcs backend: unresolved incoming parameter", .{}),
            .ptr, .ptr_dyn, .ptr_rt, .slice => return gen.fail("mcs backend: cannot store into a pointer value", .{}),
        }
    }

    /// 对累加器 A 施加 `op` 与右操作数 `rhs` 的字节 `i`。
    /// `op` 取 `.add`（首字节 `add`、其余 `addc`）、`.subb`、`.anl`、`.orl`、`.xrl`。
    fn applyByte(
        gen: *Gen,
        op: encode.Mnemonic,
        rhs: Loc,
        i: u32,
        size: u32,
        first: bool,
    ) codegen.CodeGenError!void {
        const mnem: encode.Mnemonic = switch (op) {
            .add => if (first) .add else .addc,
            else => op,
        };
        const operand: encode.Operand = switch (rhs) {
            .imm => |v| .{ .imm = .{
                .value = @intCast((v >> @intCast(8 * i)) & 0xff),
                .bits = 8,
            } },
            .regs => |p| .{ .reg = byteRegToRegister(abi.byteRegisters(p)[i]) },
            .acc => .{ .reg = .a },
            .frame => |disp| blk: {
                try gen.addInst(.mov, &.{
                    .{ .reg = .{ .r = 7 } },
                    gen.frameOperand(gen.slotByte(disp, i, size)),
                });
                break :blk .{ .reg = .{ .r = 7 } };
            },
        };
        try gen.addInst(mnem, &.{ .{ .reg = .a }, operand });
    }

    /// 结果位置：所有运行期值都写入帧槽，避免固定寄存器被互相覆盖。
    fn allocResult(gen: *Gen, size: u32) MCValue {
        return .{ .frame = gen.allocFrame(size) };
    }

    // --- 第一遍：预分配帧槽 -------------------------------------------------

    fn preallocBody(gen: *Gen, body: []const Air.Inst.Index) codegen.CodeGenError!void {
        for (body) |inst| {
            const tag = gen.air.instructions.items(.tag)[@intFromEnum(inst)];
            switch (tag) {
                .block, .loop => try gen.preallocBlock(inst),
                .cond_br => {
                    const cb = gen.air.unwrapCondBr(inst);
                    try gen.preallocBody(cb.then_body);
                    try gen.preallocBody(cb.else_body);
                },
                .cmp_eq, .cmp_neq, .cmp_lt, .cmp_lte, .cmp_gt, .cmp_gte => {
                    gen.vals[@intFromEnum(inst)] = gen.allocResult(1);
                },
                .alloc => try gen.preallocAlloc(inst),
                .load => try gen.preallocLoad(inst),
                .intcast, .intcast_safe, .trunc, .bitcast => try gen.preallocCast(inst),
                .call, .call_always_tail, .call_never_tail, .call_never_inline => try gen.preallocCall(inst),
                .not => {
                    const ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
                    if (ty.hasRuntimeBits(gen.zcu)) {
                        gen.vals[@intFromEnum(inst)] = gen.allocResult(try gen.scalarSize(ty));
                    }
                },
                .bool_and, .bool_or => {
                    gen.vals[@intFromEnum(inst)] = gen.allocResult(1);
                },
                .shl, .shl_exact, .shr, .shr_exact => try gen.preallocShift(inst),
                .mul, .mul_wrap, .mul_safe => try gen.preallocMul(inst),
                .div_trunc, .div_floor, .div_exact, .mod, .rem => try gen.preallocDiv(inst),
                .switch_br => try gen.preallocSwitch(inst, false),
                .loop_switch_br => try gen.preallocSwitch(inst, true),
                .ptr_elem_ptr => try gen.preallocElemPtr(inst),
                .slice => try gen.preallocSlice(inst),
                .slice_len => {
                    const ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
                    if (ty.hasRuntimeBits(gen.zcu)) gen.vals[@intFromEnum(inst)] = gen.allocResult(try gen.scalarSize(ty));
                },
                .slice_ptr => try gen.preallocSlicePtr(inst),
                .slice_elem_val => {
                    const elem_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
                    if (elem_ty.hasRuntimeBits(gen.zcu)) gen.vals[@intFromEnum(inst)] = gen.allocResult(try gen.scalarSize(elem_ty));
                },
                .slice_elem_ptr => try gen.preallocSliceElemPtr(inst),
                .ptr_slice_len_ptr => {
                    const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
                    const base_disp = try gen.aggSrcDisp(ty_op.operand);
                    gen.vals[@intFromEnum(inst)] = .{ .ptr = .{ .base = base_disp + @as(i32, @intCast(gen.ptrBytes())), .off = 0 } };
                },
                .ptr_slice_ptr_ptr => {
                    const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
                    const base_disp = try gen.aggSrcDisp(ty_op.operand);
                    gen.vals[@intFromEnum(inst)] = .{ .ptr = .{ .base = base_disp, .off = 0 } };
                },
                .ptr_add => try gen.preallocPtrAdd(inst),
                .array_to_slice => try gen.preallocArrayToSlice(inst),
                .c_va_start, .c_va_copy => {
                    gen.vals[@intFromEnum(inst)] = gen.allocResult(3);
                },
                .c_va_arg => {
                    const arg_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
                    if (arg_ty.hasRuntimeBits(gen.zcu)) {
                        gen.vals[@intFromEnum(inst)] = gen.allocResult(try gen.scalarSize(arg_ty));
                    }
                },
                .c_va_end => {},
                .array_elem_val, .ptr_elem_val => {
                    const elem_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
                    if (elem_ty.hasRuntimeBits(gen.zcu)) {
                        gen.vals[@intFromEnum(inst)] = gen.allocResult(try gen.scalarSize(elem_ty));
                    }
                },
                .arg => try gen.preallocArg(inst),
                .add, .add_wrap, .add_safe, .sub, .sub_wrap, .sub_safe, .bit_and, .bit_or, .xor => try gen.preallocBinOp(inst),
                else => {},
            }
        }
    }

    fn preallocBlock(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const start = gen.newLabel();
        const end = gen.newLabel();
        try gen.block_info.put(gen.gpa, inst, .{ .start = start, .end = end });

        const block = gen.air.unwrapBlock(inst);
        if (block.ty.hasRuntimeBits(gen.zcu)) {
            const class = abi.classify(block.ty, gen.zcu);
            if (class.is_aggregate or class.size == 0 or class.size > 4) return gen.fail(
                "mcs backend: block result values larger than 4 bytes are not implemented yet",
                .{},
            );
            gen.vals[@intFromEnum(inst)] = gen.allocResult(class.size);
        }

        try gen.preallocBody(block.body);
    }

    fn preallocArg(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const arg_index = gen.next_arg;
        gen.next_arg += 1;

        const ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const class = abi.classify(ty, gen.zcu);
        if (class.is_aggregate or class.primary == .memory or class.size == 0) return gen.fail(
            "mcs backend: aggregate or oversized parameter is not implemented yet",
            .{},
        );

        if (arg_index == 0) {
            // 首个标量参数由 ABI 寄存器到达，进入时复制到帧槽。
            // 指针类型参数物化为 .ptr_rt（3 字节绝对地址存在 frame 中），
            // 与普通 3 字节标量区分，以便后续 deref 走间接寻址。
            if (ty.zigTypeTag(gen.zcu) == .pointer) {
                gen.vals[@intFromEnum(inst)] = .{ .ptr_rt = .{ .addr = gen.allocFrame(class.size) } };
            } else {
                gen.vals[@intFromEnum(inst)] = .{ .frame = gen.allocFrame(class.size) };
            }
            return;
        }

        if (gen.arch == .mcs251) {
            gen.stack_param_bytes += class.size;
            gen.vals[@intFromEnum(inst)] = .{
                .incoming = -@as(i32, @intCast(2 + gen.stack_param_bytes)),
            };
        } else {
            // MCS-51 栈约定（SDCC --stack-auto）：参数 2..N 由 caller 逆序压栈，
            // 第 k 个（1 基）参数位于入口 SP - (2 + Σ size(2..k-1))。
            const off = 2 + gen.stack_param_bytes;
            gen.stack_param_bytes += class.size;
            const disp = gen.allocFrame(class.size);
            gen.vals[@intFromEnum(inst)] = .{ .frame = disp };
            try gen.m51_incoming.put(gen.gpa, inst, off);
        }
    }

    fn preallocBinOp(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const lhs_ty = gen.air.typeOf(bin.lhs, &gen.zcu.intern_pool);
        const class = abi.classify(lhs_ty, gen.zcu);
        if (class.is_aggregate or class.size == 0 or class.size > 4) return;
        gen.vals[@intFromEnum(inst)] = gen.allocResult(class.size);
    }

    /// 聚合类型或切片（切片在类型标签上是 pointer，但按 6 字节值处理）。
    fn isAggOrSlice(gen: *Gen, ty: Type) bool {
        return abi.classify(ty, gen.zcu).is_aggregate or ty.isSlice(gen.zcu);
    }

    /// 标量类型大小（1~4 字节且非聚合），否则报错。
    fn scalarSize(gen: *Gen, ty: Type) codegen.CodeGenError!u32 {
        const class = abi.classify(ty, gen.zcu);
        if (class.is_aggregate or class.size == 0 or class.size > 4) return gen.fail(
            "mcs backend: only 1-4 byte scalars are implemented yet (tag={s}, size={d})",
            .{ @tagName(ty.zigTypeTag(gen.zcu)), class.size },
        );
        return class.size;
    }

    /// 局部变量 `.alloc`：为其对象分配一个帧槽，槽本身即变量的存储。
    fn preallocAlloc(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ptr_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const val_ty = ptr_ty.childType(gen.zcu);
        if (!val_ty.hasRuntimeBits(gen.zcu)) return;
        const size: u32 = @intCast(val_ty.abiSize(gen.zcu));
        if (size == 0 or size > 512) return gen.fail(
            "mcs backend: local object size is unsupported",
            .{},
        );
        gen.vals[@intFromEnum(inst)] = .{ .frame = gen.allocFrame(size) };
    }

    /// `.load`：标量分配结果帧槽；聚合分配一个临时对象槽（表示 `*T`）。
    fn preallocLoad(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const elem_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        if (!elem_ty.hasRuntimeBits(gen.zcu)) return;
        if (gen.isAggOrSlice(elem_ty)) {
            const size: u32 = @intCast(elem_ty.abiSize(gen.zcu));
            if (size == 0 or size > 512) return gen.fail(
                "mcs backend: aggregate load size is unsupported",
                .{},
            );
            gen.vals[@intFromEnum(inst)] = .{ .ptr = .{
                .base = gen.allocFrame(size),
                .off = 0,
            } };
        } else {
            gen.vals[@intFromEnum(inst)] = gen.allocResult(try gen.scalarSize(elem_ty));
        }
    }

    /// 取一个内存操作数的帧内字节位移（指向 `.alloc` 对象或编译期元素指针）。
    fn storageDisp(gen: *Gen, ref: Air.Inst.Ref) codegen.CodeGenError!i32 {
        if (ref.toInterned() != null) return gen.fail(
            "mcs backend: indirect memory access is not implemented yet",
            .{},
        );
        const idx = ref.toIndex().?;
        switch (gen.vals[@intFromEnum(idx)]) {
            .ptr => |p| return p.base + p.off,
            .slice => |s| return s.base + s.off,
            .ptr_rt => |pr| return pr.addr,
            else => {},
        }
        const tag = gen.air.instructions.items(.tag)[@intFromEnum(idx)];
        switch (tag) {
            .alloc => return switch (gen.vals[@intFromEnum(idx)]) {
                .frame => |d| d,
                else => return gen.fail("mcs backend: local variable has no storage", .{}),
            },
            .ptr_elem_ptr => return switch (gen.vals[@intFromEnum(idx)]) {
                .ptr => |p| p.base + p.off,
                else => return gen.fail("mcs backend: element pointer has no storage", .{}),
            },
            else => return gen.fail(
                "mcs backend: indirect memory access is not implemented yet",
                .{},
            ),
        }
    }

    /// 元素指针：编译期偏移直接算出帧内位移；运行期下标记录为 `.ptr_dyn`。
    fn preallocElemPtr(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty_pl = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_pl;
        const extra = gen.air.extraData(Air.Bin, ty_pl.payload).data;
        const result_ptr_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const elem_ty = result_ptr_ty.childType(gen.zcu);
        const elem_size: u32 = @intCast(elem_ty.abiSize(gen.zcu));

        const base_idx = extra.lhs.toIndex() orelse return gen.fail(
            "mcs backend: unsupported pointer base",
            .{},
        );
        const base = switch (gen.vals[@intFromEnum(base_idx)]) {
            // `@ptrCast(参数)` 的结果是 `.frame`（参数 ref 的 toIndex() 返回 null，
            // preallocCast 走默认路径分配帧槽）。当 base 是指针类型时，帧槽里存的
            // 是 3 字节指针值，应当作 `.ptr_rt` 处理（走间接寻址路径）；
            // 数组类型（`.alloc`）仍当作 `.ptr`（帧内位移）。
            .frame => |d| blk: {
                const lhs_ty = gen.air.typeOf(extra.lhs, &gen.zcu.intern_pool);
                if (lhs_ty.zigTypeTag(gen.zcu) == .pointer) {
                    break :blk @as(MCValue, .{ .ptr_rt = .{ .addr = d } });
                }
                break :blk @as(MCValue, .{ .ptr = .{ .base = d, .off = 0 } });
            },
            .ptr => |p| @as(MCValue, .{ .ptr = .{ .base = p.base, .off = p.off } }),
            .ptr_rt => |pr| @as(MCValue, .{ .ptr_rt = .{ .addr = pr.addr } }),
            else => return gen.fail("mcs backend: unsupported pointer base", .{}),
        };

        if (extra.rhs.toInterned()) |idx_ip| {
            const idx_bits = gen.getConstBits(idx_ip) orelse return gen.fail(
                "mcs backend: unsupported array index",
                .{},
            );
            const signed_idx: i64 = @bitCast(idx_bits);
            switch (base) {
                .ptr => |p| {
                    gen.vals[@intFromEnum(inst)] = .{ .ptr = .{
                        .base = p.base,
                        .off = p.off + @as(i32, @intCast(signed_idx * @as(i64, elem_size))),
                    } };
                },
                .ptr_rt => |pr| {
                    // 记录 base ptr_rt 的 addr 与最终常量偏移，留给 emitElemPtr 物化。
                    // inst.addr = new_addr（新分配的 3 字节槽，存物化后的地址）
                    // inst.base_addr = pr.addr（源指针 3 字节地址的帧槽）
                    // inst.off = 常量偏移（编译期算好）
                    const new_addr = gen.allocFrame(3);
                    gen.vals[@intFromEnum(inst)] = .{ .ptr_rt = .{
                        .addr = new_addr,
                        .base_addr = pr.addr,
                        .off = @as(i32, @intCast(signed_idx * @as(i64, elem_size))),
                    } };
                },
                else => unreachable,
            }
            return;
        }

        // 运行期下标：需要下标所在帧槽与固定数组长度。
        const idx_loc = try gen.locOf(extra.rhs);
        const idx_frame = switch (idx_loc) {
            .frame => |d| d,
            else => return gen.fail("mcs backend: runtime index has no frame slot", .{}),
        };
        const idx_size: u32 = try gen.scalarSize(gen.air.typeOf(extra.rhs, &gen.zcu.intern_pool));
        const base_child = gen.air.typeOf(extra.lhs, &gen.zcu.intern_pool).childType(gen.zcu);
        const len: u32 = switch (base_child.zigTypeTag(gen.zcu)) {
            .array => @intCast(base_child.arrayLen(gen.zcu)),
            else => return gen.fail(
                "mcs backend: runtime index requires a fixed-length array",
                .{},
            ),
        };
        gen.vals[@intFromEnum(inst)] = .{ .ptr_dyn = .{
            .base = base.ptr.base,
            .idx = idx_frame,
            .idx_size = idx_size,
            .elem_size = elem_size,
            .len = len,
        } };
    }

    /// `.slice(ptr, len)`：编译期 `ptr`+`len` 折叠为切片视图；否则物化为 6 字节值。
    fn preallocSlice(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty_pl = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_pl;
        const bin = gen.air.extraData(Air.Bin, ty_pl.payload).data;
        if (bin.lhs.toIndex()) |pi| {
            const ptr_mcv = gen.vals[@intFromEnum(pi)];
            const ptr_tag = gen.air.instructions.items(.tag)[@intFromEnum(pi)];
            if (bin.rhs.toInterned()) |len_ip| {
                if (gen.getConstBits(len_ip)) |len_bits| {
                    const len: u32 = @truncate(len_bits);
                    switch (ptr_mcv) {
                        .ptr => |p| {
                            gen.vals[@intFromEnum(inst)] = .{ .slice = .{ .base = p.base, .off = p.off, .len = len } };
                            return;
                        },
                        .frame => |d| {
                            if (ptr_tag == .alloc or ptr_tag == .ptr_elem_ptr) {
                                gen.vals[@intFromEnum(inst)] = .{ .slice = .{ .base = d, .off = 0, .len = len } };
                                return;
                            }
                        },
                        else => {},
                    }
                }
            }
        }
        const slice_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        gen.vals[@intFromEnum(inst)] = gen.allocResult(@intCast(slice_ty.abiSize(gen.zcu)));
    }

    /// `.slice_ptr`：描述符折叠为 `.ptr`（携带长度）；否则物化为 `ptr_rt`。
    fn preallocSlicePtr(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
        if (ty_op.operand.toIndex()) |si| {
            if (gen.vals[@intFromEnum(si)] == .slice) {
                const s = gen.vals[@intFromEnum(si)].slice;
                gen.vals[@intFromEnum(inst)] = .{ .ptr = .{ .base = s.base, .off = s.off, .len = s.len } };
                return;
            }
        }
        gen.vals[@intFromEnum(inst)] = .{ .ptr_rt = .{ .addr = gen.allocFrame(3) } };
    }

    /// `.slice_elem_ptr`：描述符折叠为 `.ptr`/`.ptr_dyn`；否则物化为 `ptr_rt`。
    fn preallocSliceElemPtr(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty_pl = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_pl;
        const bin = gen.air.extraData(Air.Bin, ty_pl.payload).data;
        const result_ptr_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const elem_size: u32 = @intCast(result_ptr_ty.childType(gen.zcu).abiSize(gen.zcu));
        if (bin.lhs.toIndex()) |si| {
            if (gen.vals[@intFromEnum(si)] == .slice) {
                const s = gen.vals[@intFromEnum(si)].slice;
                if (bin.rhs.toInterned()) |idx_ip| {
                    const bits = gen.getConstBits(idx_ip) orelse return gen.fail(
                        "mcs backend: unsupported slice index",
                        .{},
                    );
                    const signed: i64 = @bitCast(bits);
                    gen.vals[@intFromEnum(inst)] = .{ .ptr = .{
                        .base = s.base,
                        .off = s.off + @as(i32, @intCast(signed * @as(i64, elem_size))),
                        .len = s.len,
                    } };
                    return;
                }
                const idx_loc = try gen.locOf(bin.rhs);
                const idx_frame = switch (idx_loc) {
                    .frame => |d| d,
                    else => return gen.fail("mcs backend: runtime index has no frame slot", .{}),
                };
                const idx_size: u32 = try gen.scalarSize(gen.air.typeOf(bin.rhs, &gen.zcu.intern_pool));
                gen.vals[@intFromEnum(inst)] = .{ .ptr_dyn = .{
                    .base = s.base + s.off,
                    .idx = idx_frame,
                    .idx_size = idx_size,
                    .elem_size = elem_size,
                    .len = s.len,
                } };
                return;
            }
        }
        gen.vals[@intFromEnum(inst)] = .{ .ptr_rt = .{ .addr = gen.allocFrame(3) } };
    }

    /// `.ptr_add(ptr, i)`：编译期下标调整偏移；运行期下标在有界视图上展开。
    fn preallocPtrAdd(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty_pl = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_pl;
        const bin = gen.air.extraData(Air.Bin, ty_pl.payload).data;
        const result_ptr_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const elem_size: u32 = @intCast(result_ptr_ty.childType(gen.zcu).abiSize(gen.zcu));
        const src = if (bin.lhs.toIndex()) |li| gen.vals[@intFromEnum(li)] else MCValue.none;
        switch (src) {
            .ptr => |p| {
                if (bin.rhs.toInterned()) |idx_ip| {
                    const bits = gen.getConstBits(idx_ip) orelse return gen.fail(
                        "mcs backend: unsupported pointer offset",
                        .{},
                    );
                    const signed: i64 = @bitCast(bits);
                    gen.vals[@intFromEnum(inst)] = .{ .ptr = .{
                        .base = p.base,
                        .off = p.off + @as(i32, @intCast(signed * @as(i64, elem_size))),
                        .len = p.len,
                    } };
                    return;
                }
                if (p.len == 0) return gen.fail(
                    "mcs backend: runtime pointer offset requires a bounded slice/array",
                    .{},
                );
                const idx_loc = try gen.locOf(bin.rhs);
                const idx_frame = switch (idx_loc) {
                    .frame => |d| d,
                    else => return gen.fail("mcs backend: runtime index has no frame slot", .{}),
                };
                const idx_size: u32 = try gen.scalarSize(gen.air.typeOf(bin.rhs, &gen.zcu.intern_pool));
                gen.vals[@intFromEnum(inst)] = .{ .ptr_dyn = .{
                    .base = p.base + p.off,
                    .idx = idx_frame,
                    .idx_size = idx_size,
                    .elem_size = elem_size,
                    .len = p.len,
                } };
                return;
            },
            .ptr_rt, .frame => {
                if (bin.rhs.toInterned() == null) return gen.fail(
                    "mcs backend: runtime offset on an absolute pointer is not implemented yet",
                    .{},
                );
                gen.vals[@intFromEnum(inst)] = .{ .ptr_rt = .{ .addr = gen.allocFrame(3) } };
            },
            else => return gen.fail("mcs backend: unsupported pointer base", .{}),
        }
    }

    /// `.array_to_slice(&arr)`：编译期折叠为切片视图；否则物化。
    fn preallocArrayToSlice(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
        if (ty_op.operand.toIndex()) |oi| {
            const arr_ty = gen.air.typeOf(ty_op.operand, &gen.zcu.intern_pool).childType(gen.zcu);
            if (arr_ty.zigTypeTag(gen.zcu) == .array) {
                const len: u32 = @intCast(arr_ty.arrayLen(gen.zcu));
                const tag = gen.air.instructions.items(.tag)[@intFromEnum(oi)];
                switch (gen.vals[@intFromEnum(oi)]) {
                    .ptr => |p| {
                        gen.vals[@intFromEnum(inst)] = .{ .slice = .{ .base = p.base, .off = p.off, .len = len } };
                        return;
                    },
                    .frame => |d| {
                        if (tag == .alloc or tag == .ptr_elem_ptr) {
                            gen.vals[@intFromEnum(inst)] = .{ .slice = .{ .base = d, .off = 0, .len = len } };
                            return;
                        }
                    },
                    else => {},
                }
            }
        }
        const result_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        gen.vals[@intFromEnum(inst)] = gen.allocResult(@intCast(result_ty.abiSize(gen.zcu)));
    }

    /// `.intcast`/`.trunc`/`.bitcast`：指针↔指针时保留编译期指针描述。
    fn preallocCast(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
        const result_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        if (!result_ty.hasRuntimeBits(gen.zcu)) return;
        if (result_ty.zigTypeTag(gen.zcu) == .pointer) {
            if (ty_op.operand.toIndex()) |oi| {
                const tag = gen.air.instructions.items(.tag)[@intFromEnum(oi)];
                switch (gen.vals[@intFromEnum(oi)]) {
                    .ptr => |p| {
                        gen.vals[@intFromEnum(inst)] = .{ .ptr = .{ .base = p.base, .off = p.off, .len = p.len } };
                        return;
                    },
                    .slice => |s| {
                        gen.vals[@intFromEnum(inst)] = .{ .ptr = .{ .base = s.base, .off = s.off, .len = s.len } };
                        return;
                    },
                    .ptr_rt => |pr| {
                        // 指针↔指针 cast：保留外部地址物化位置。
                        gen.vals[@intFromEnum(inst)] = .{ .ptr_rt = .{ .addr = pr.addr } };
                        return;
                    },
                    .frame => |d| {
                        if (tag == .alloc or tag == .ptr_elem_ptr) {
                            gen.vals[@intFromEnum(inst)] = .{ .ptr = .{ .base = d, .off = 0 } };
                            return;
                        }
                    },
                    else => {},
                }
            }
        }
        gen.vals[@intFromEnum(inst)] = gen.allocResult(try gen.scalarSize(result_ty));
    }

    fn preallocCall(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ret_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        if (ret_ty.hasRuntimeBits(gen.zcu)) {
            gen.vals[@intFromEnum(inst)] = gen.allocResult(try gen.scalarSize(ret_ty));
        }
    }

    fn preallocShift(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        if (!ty.hasRuntimeBits(gen.zcu)) return;
        gen.vals[@intFromEnum(inst)] = gen.allocResult(try gen.scalarSize(ty));
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        if (bin.rhs.toInterned() == null) _ = try gen.allocExtra(inst, 0, 1);
    }

    fn preallocMul(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        if (!ty.hasRuntimeBits(gen.zcu)) return;
        const size = try gen.scalarSize(ty);
        gen.vals[@intFromEnum(inst)] = gen.allocResult(size);
        if (size == 4) {
            _ = try gen.allocExtra(inst, 0, 4); // al*bl
            _ = try gen.allocExtra(inst, 1, 4); // al*bh
            _ = try gen.allocExtra(inst, 2, 4); // ah*bl
        }
    }

    fn preallocDiv(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const lhs_ty = gen.air.typeOf(bin.lhs, &gen.zcu.intern_pool);
        const ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        if (!ty.hasRuntimeBits(gen.zcu)) return;
        const size = try gen.scalarSize(ty);
        gen.vals[@intFromEnum(inst)] = gen.allocResult(size);
        if (lhs_ty.isSignedInt(gen.zcu)) {
            _ = try gen.allocExtra(inst, 0, size); // ua = |lhs|
            _ = try gen.allocExtra(inst, 1, size); // ub = |rhs|
            _ = try gen.allocExtra(inst, 2, size); // r = |rem|
            _ = try gen.allocExtra(inst, 3, 1); // count
            _ = try gen.allocExtra(inst, 4, 1); // sign(lhs)
            _ = try gen.allocExtra(inst, 5, 1); // sign(rhs)
        } else if (size >= 3) {
            _ = try gen.allocExtra(inst, 0, size); // R
            _ = try gen.allocExtra(inst, 1, size); // Q
            _ = try gen.allocExtra(inst, 2, size); // D
            _ = try gen.allocExtra(inst, 3, 1); // count
        }
    }

    fn preallocSwitch(gen: *Gen, inst: Air.Inst.Index, is_loop: bool) codegen.CodeGenError!void {
        const sw = gen.air.unwrapSwitch(inst);
        if (is_loop) {
            const cond_ty = gen.air.typeOf(sw.operand, &gen.zcu.intern_pool);
            const size = try gen.scalarSize(cond_ty);
            const disp = gen.allocFrame(size);
            const label = gen.newLabel();
            try gen.switch_info.put(gen.gpa, inst, .{ .dispatch = label, .cond_disp = disp });
        }
        var it = sw.iterateCases();
        while (it.next()) |case| try gen.preallocBody(case.body);
        try gen.preallocBody(it.elseBody());
    }

    /// 帧大小确定后，把入参位移换算成相对 prologue 之后 SPX 的位移。
    fn resolveIncoming(gen: *Gen) void {
        const frame_size: i32 = @intCast(gen.frameBytes());
        for (gen.vals) |*v| switch (v.*) {
            .incoming => |d| v.* = .{ .frame = d - frame_size },
            else => {},
        };
    }

    // --- 第二遍：发射代码 ---------------------------------------------------

    fn emitBody(gen: *Gen, body: []const Air.Inst.Index) codegen.CodeGenError!void {
        for (body) |inst| {
            const tag = gen.air.instructions.items(.tag)[@intFromEnum(inst)];
            switch (tag) {
                .block, .loop => try gen.emitBlock(inst),
                .cond_br => try gen.emitCondBr(inst),
                .br => try gen.emitBr(inst),
                .repeat => try gen.emitRepeat(inst),
                .cmp_eq, .cmp_neq, .cmp_lt, .cmp_lte, .cmp_gt, .cmp_gte => try gen.emitCmp(inst, tag),
                .alloc => {},
                .load => try gen.emitLoad(inst),
                .store, .store_safe => try gen.emitStore(inst),
                .intcast, .intcast_safe, .trunc, .bitcast => try gen.emitCast(inst),
                .call, .call_always_tail, .call_never_tail, .call_never_inline => try gen.emitCall(inst),
                .not => try gen.emitNot(inst),
                .bool_and => try gen.emitBoolBin(inst, .anl),
                .bool_or => try gen.emitBoolBin(inst, .orl),
                .shl, .shl_exact => try gen.emitShift(inst, true),
                .shr, .shr_exact => try gen.emitShift(inst, false),
                .mul, .mul_wrap, .mul_safe => try gen.emitMul(inst),
                .div_trunc, .div_floor, .div_exact, .mod, .rem => try gen.emitDiv(inst),
                .switch_br => try gen.emitSwitch(inst, false),
                .loop_switch_br => try gen.emitSwitch(inst, true),
                .ptr_elem_ptr => try gen.emitElemPtr(inst),
                .slice => try gen.emitSlice(inst),
                .slice_len => try gen.emitSliceLen(inst),
                .slice_ptr => try gen.emitSlicePtr(inst),
                .slice_elem_val => try gen.emitSliceElemVal(inst),
                .slice_elem_ptr => try gen.emitSliceElemPtr(inst),
                .ptr_add => try gen.emitPtrAdd(inst),
                .array_to_slice => try gen.emitArrayToSlice(inst),
                .ptr_slice_len_ptr, .ptr_slice_ptr_ptr => {},
                .c_va_start => try gen.emitCVaStart(inst),
                .c_va_arg => try gen.emitCVaArg(inst),
                .c_va_copy => try gen.emitCVaCopy(inst),
                .c_va_end => {},
                .array_elem_val, .ptr_elem_val => try gen.emitArrElemVal(inst),
                else => try gen.emitInst(inst),
            }
        }
    }

    fn emitInst(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const tag = gen.air.instructions.items(.tag)[@intFromEnum(inst)];
        switch (tag) {
            .arg => try gen.emitArg(inst),

            .dbg_stmt,
            .dbg_empty_stmt,
            .dbg_inline_block,
            .dbg_var_ptr,
            .dbg_var_val,
            .dbg_arg_inline,
            => {},

            .ret, .ret_safe => try gen.airRet(inst),

            .add, .add_wrap, .add_safe => try gen.emitBinOp(inst, .add),
            .sub, .sub_wrap, .sub_safe => try gen.emitBinOp(inst, .subb),
            .bit_and => try gen.emitBinOp(inst, .anl),
            .bit_or => try gen.emitBinOp(inst, .orl),
            .xor => try gen.emitBinOp(inst, .xrl),

            .trap, .breakpoint, .unreach => try gen.addTrap(),

            .ret_load => return gen.fail("mcs backend: ret_load is not implemented yet", .{}),
            .ret_ptr => return gen.fail("mcs backend: return-by-pointer is not implemented yet", .{}),
            .ret_addr => return gen.fail("mcs backend: @returnAddress is not implemented yet", .{}),

            else => return gen.fail("mcs backend: unimplemented AIR tag '{s}'", .{@tagName(tag)}),
        }
    }

    fn emitBlock(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const tag = gen.air.instructions.items(.tag)[@intFromEnum(inst)];
        const info = gen.block_info.get(inst).?;
        if (tag == .loop) try gen.mir.addLabel(gen.gpa, info.start);
        const block = gen.air.unwrapBlock(inst);
        try gen.emitBody(block.body);
        try gen.mir.addLabel(gen.gpa, info.end);
    }

    fn emitCondBr(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const cb = gen.air.unwrapCondBr(inst);
        const then_label = gen.newLabel();
        const else_label = gen.newLabel();
        const end_label = gen.newLabel();

        try gen.emitCondIntoA(cb.condition);
        try gen.addInst(.jnz, &.{.{ .code = .{ .local_label = then_label } }});
        try gen.jmpFar(else_label);

        try gen.mir.addLabel(gen.gpa, then_label);
        try gen.emitBody(cb.then_body);
        try gen.jmpFar(end_label);

        try gen.mir.addLabel(gen.gpa, else_label);
        try gen.emitBody(cb.else_body);
        try gen.mir.addLabel(gen.gpa, end_label);
    }

    fn emitCondIntoA(gen: *Gen, ref: Air.Inst.Ref) codegen.CodeGenError!void {
        const loc = try gen.locOf(ref);
        switch (loc) {
            .imm => |v| try gen.setABool(v != 0),
            .acc => {},
            .frame => |disp| try gen.addInst(.mov, &.{
                .{ .reg = .a },
                gen.frameOperand(gen.slotByte(disp, 0, 1)),
            }),
            .regs => |p| {
                const r = byteRegToRegister(abi.byteRegisters(p)[0]);
                if (!isRegisterA(r)) try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = r } });
            },
        }
    }

    fn emitBr(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const br = gen.air.instructions.items(.data)[@intFromEnum(inst)].br;

        // `.br` 也可指向 `loop_switch_br`：写回新的分派值并跳回分派点。
        const target_tag = gen.air.instructions.items(.tag)[@intFromEnum(br.block_inst)];
        if (target_tag == .loop_switch_br) {
            const sw_info = gen.switch_info.get(br.block_inst) orelse return gen.fail(
                "mcs backend: branch to unknown switch",
                .{},
            );
            const op_ty = gen.air.typeOf(br.operand, &gen.zcu.intern_pool);
            const size = try gen.scalarSize(op_ty);
            const src = try gen.locOf(br.operand);
            try gen.moveValue(src, .{ .frame = sw_info.cond_disp }, size);
            try gen.jmpFar(sw_info.dispatch);
            return;
        }

        const info = gen.block_info.get(br.block_inst) orelse return gen.fail(
            "mcs backend: branch to unknown block",
            .{},
        );

        const op_ty = gen.air.typeOf(br.operand, &gen.zcu.intern_pool);
        if (op_ty.hasRuntimeBits(gen.zcu)) {
            const class = abi.classify(op_ty, gen.zcu);
            if (class.is_aggregate or class.size == 0 or class.size > 4) return gen.fail(
                "mcs backend: block result values larger than 4 bytes are not implemented yet",
                .{},
            );
            const src = try gen.locOf(br.operand);
            const dst = gen.vals[@intFromEnum(br.block_inst)];
            try gen.moveValue(src, dst, class.size);
        }

        try gen.jmpFar(info.end);
    }

    fn emitRepeat(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const loop_inst = gen.air.instructions.items(.data)[@intFromEnum(inst)].repeat.loop_inst;
        const info = gen.block_info.get(loop_inst) orelse return gen.fail(
            "mcs backend: repeat to unknown loop",
            .{},
        );
        try gen.jmpFar(info.start);
    }

    /// 逐字节把 `src` 移到结果位置 `dst`。
    fn moveValue(gen: *Gen, src: Loc, dst: MCValue, size: u32) codegen.CodeGenError!void {
        var i: u32 = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(src, i, size);
            try gen.storeA(dst, i, size);
        }
    }

    /// 若 `ref` 是运行期下标的元素指针，返回其描述。
    fn dynPtrOf(gen: *Gen, ref: Air.Inst.Ref) ?DynPtr {
        const idx = ref.toIndex() orelse return null;
        return switch (gen.vals[@intFromEnum(idx)]) {
            .ptr_dyn => |pd| pd,
            else => null,
        };
    }

    /// 若 `ref` 是一个运行期绝对地址（值生成型指针），返回存放 3 字节地址的帧槽。
    /// `.alloc`/`.ptr_elem_ptr` 等存储型引用的 `.frame` 不算地址。
    fn runtimeAddrOf(gen: *Gen, ref: Air.Inst.Ref) ?i32 {
        const idx = ref.toIndex() orelse return null;
        switch (gen.vals[@intFromEnum(idx)]) {
            .ptr_rt => |pr| return pr.addr,
            .frame => |d| {
                const tag = gen.air.instructions.items(.tag)[@intFromEnum(idx)];
                return switch (tag) {
                    .alloc, .ptr_elem_ptr, .ptr_slice_len_ptr, .ptr_slice_ptr_ptr => null,
                    else => d,
                };
            },
            else => return null,
        }
    }

    /// 已知来源的切片视图：描述符或已记录来源的物化切片。
    fn sliceView(gen: *Gen, ref: Air.Inst.Ref) ?SliceOrigin {
        if (ref.toIndex()) |i| {
            if (gen.vals[@intFromEnum(i)] == .slice) {
                const s = gen.vals[@intFromEnum(i)].slice;
                return .{ .base = s.base, .off = s.off, .len = s.len };
            }
        }
        const disp = gen.aggSrcDisp(ref) catch return null;
        return gen.slice_origin.get(disp);
    }

    /// 按运行期下标展开访问：对每个可能的常量下标比较并访问对应帧偏移。
    fn emitIndexedAccess(
        gen: *Gen,
        pd: DynPtr,
        size: u32,
        dst: ?MCValue,
        src: ?Loc,
    ) codegen.CodeGenError!void {
        const done = gen.newLabel();
        var j: u32 = 0;
        while (j < pd.len) : (j += 1) {
            const no_match = gen.newLabel();
            try gen.emitNeJumpImm(.{ .frame = pd.idx }, j, pd.idx_size, no_match);
            const disp = pd.base + @as(i32, @intCast(j * pd.elem_size));
            if (src) |s| {
                try gen.moveValue(s, .{ .frame = disp }, size);
            } else {
                try gen.moveValue(.{ .frame = disp }, dst.?, size);
            }
            try gen.jmpFar(done);
            try gen.mir.addLabel(gen.gpa, no_match);
        }
        // 越界：Zig 的界检查会先 panic，这里作为兜底。
        try gen.addTrap();
        try gen.mir.addLabel(gen.gpa, done);
    }

    /// 把编译期聚合值按内存顺序逐字节写入目标。
    fn emitConstAggregateStore(
        gen: *Gen,
        ptr_ref: Air.Inst.Ref,
        value: Value,
        ty: Type,
    ) codegen.CodeGenError!void {
        const size: u32 = @intCast(ty.abiSize(gen.zcu));
        const buffer = try gen.gpa.alloc(u8, size);
        defer gen.gpa.free(buffer);
        value.writeToMemory(gen.zcu, buffer) catch return gen.fail(
            "mcs backend: cannot materialize constant aggregate value",
            .{},
        );
        const base_disp = try gen.storageDisp(ptr_ref);
        for (buffer, 0..) |byte, i| {
            try gen.addInst(.mov, &.{
                .{ .reg = .a },
                .{ .imm = .{ .value = byte, .bits = 8 } },
            });
            try gen.addInst(.mov, &.{
                gen.frameOperand(base_disp + @as(i32, @intCast(i))),
                .{ .reg = .a },
            });
        }
    }

    /// 逐字节按内存顺序复制聚合对象。
    fn emitAggregateCopy(gen: *Gen, dst_disp: i32, src_disp: i32, size: u32) codegen.CodeGenError!void {
        var i: u32 = 0;
        while (i < size) : (i += 1) {
            try gen.addInst(.mov, &.{
                .{ .reg = .a },
                gen.frameOperand(src_disp + @as(i32, @intCast(i))),
            });
            try gen.addInst(.mov, &.{
                gen.frameOperand(dst_disp + @as(i32, @intCast(i))),
                .{ .reg = .a },
            });
        }
    }

    /// 取一个聚合值的存储位移。
    fn aggSrcDisp(gen: *Gen, ref: Air.Inst.Ref) codegen.CodeGenError!i32 {
        const idx = ref.toIndex() orelse return gen.fail(
            "mcs backend: aggregate source is not a runtime value",
            .{},
        );
        return switch (gen.vals[@intFromEnum(idx)]) {
            .ptr => |p| p.base + p.off,
            .ptr_rt => |pr| pr.addr,
            .frame => |d| d,
            else => gen.fail("mcs backend: aggregate source has no storage", .{}),
        };
    }

    /// 融合取数组/指针元素的标量值（等价于 `load(ptr_elem_ptr(base, i))`）。
    fn emitArrElemVal(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const result_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const size = try gen.scalarSize(result_ty);
        const base_disp = try gen.aggSrcDisp(bin.lhs);
        const dst = gen.vals[@intFromEnum(inst)];

        if (bin.rhs.toInterned()) |idx_ip| {
            const idx_bits = gen.getConstBits(idx_ip) orelse return gen.fail(
                "mcs backend: unsupported array index",
                .{},
            );
            const signed_idx: i64 = @bitCast(idx_bits);
            const off = base_disp + @as(i32, @intCast(signed_idx * @as(i64, size)));
            try gen.moveValue(.{ .frame = off }, dst, size);
            return;
        }

        const idx_loc = try gen.locOf(bin.rhs);
        const idx_frame = switch (idx_loc) {
            .frame => |d| d,
            else => return gen.fail("mcs backend: runtime index has no frame slot", .{}),
        };
        const idx_size = try gen.scalarSize(gen.air.typeOf(bin.rhs, &gen.zcu.intern_pool));
        const base_ty = gen.air.typeOf(bin.lhs, &gen.zcu.intern_pool);
        const len: u32 = switch (base_ty.zigTypeTag(gen.zcu)) {
            .array => @intCast(base_ty.arrayLen(gen.zcu)),
            .pointer => switch (base_ty.childType(gen.zcu).zigTypeTag(gen.zcu)) {
                .array => @intCast(base_ty.childType(gen.zcu).arrayLen(gen.zcu)),
                else => return gen.fail(
                    "mcs backend: runtime index requires a fixed-length array",
                    .{},
                ),
            },
            else => return gen.fail("mcs backend: unsupported element base", .{}),
        };
        try gen.emitIndexedAccess(.{
            .base = base_disp,
            .idx = idx_frame,
            .idx_size = idx_size,
            .elem_size = size,
            .len = len,
        }, size, dst, null);
    }

    fn emitLoad(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
        const elem_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        if (!elem_ty.hasRuntimeBits(gen.zcu)) return;
        if (gen.isAggOrSlice(elem_ty)) {
            const size: u32 = @intCast(elem_ty.abiSize(gen.zcu));
            const dst_disp = gen.vals[@intFromEnum(inst)].ptr.base;
            if (gen.runtimeAddrOf(ty_op.operand)) |addr| {
                try gen.derefRead(addr, size, dst_disp);
                return;
            }
            const src_disp = try gen.storageDisp(ty_op.operand);
            if (elem_ty.isSlice(gen.zcu)) {
                if (gen.slice_origin.get(src_disp)) |o| {
                    gen.slice_origin.put(gen.gpa, dst_disp, o) catch {};
                }
            }
            try gen.emitAggregateCopy(dst_disp, src_disp, size);
            return;
        }
        const size = try gen.scalarSize(elem_ty);
        if (gen.runtimeAddrOf(ty_op.operand)) |addr| {
            try gen.derefRead(addr, size, gen.vals[@intFromEnum(inst)].frame);
            return;
        }
        if (gen.dynPtrOf(ty_op.operand)) |pd| {
            try gen.emitIndexedAccess(pd, size, gen.vals[@intFromEnum(inst)], null);
            return;
        }
        if (try gen.globalSymbolOf(ty_op.operand)) |sym| {
            try gen.derefSymbolRead(sym, size, gen.vals[@intFromEnum(inst)].frame);
            return;
        }
        if (gen.fixedAddrOf(ty_op.operand)) |addr| {
            try gen.derefFixedRead(addr, size, gen.vals[@intFromEnum(inst)].frame);
            return;
        }
        const disp = try gen.storageDisp(ty_op.operand);
        try gen.moveValue(.{ .frame = disp }, gen.vals[@intFromEnum(inst)], size);
    }

    fn emitStore(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const value_ty = gen.air.typeOf(bin.rhs, &gen.zcu.intern_pool);
        if (!value_ty.hasRuntimeBits(gen.zcu)) return;
        const is_agg = gen.isAggOrSlice(value_ty);
        // 写 `undefined`：无操作。
        if (bin.rhs.toInterned()) |ip_index| {
            const v = Value.fromInterned(ip_index);
            if (v.isUndef(gen.zcu)) return;
            if (is_agg) {
                try gen.emitConstAggregateStore(bin.lhs, v, value_ty);
                return;
            }
        }
        if (is_agg) {
            // 运行期聚合拷贝。
            const size: u32 = @intCast(value_ty.abiSize(gen.zcu));
            if (size == 0 or size > 512) return gen.fail(
                "mcs backend: aggregate store size is unsupported",
                .{},
            );
            if (value_ty.isSlice(gen.zcu)) {
                if (gen.sliceView(bin.rhs)) |o| {
                    const ps = gen.ptrBytes();
                    const dst_disp = try gen.storageDisp(bin.lhs);
                    try gen.materializePtrAddr(o.base, o.off);
                    try gen.storeDr28ToFrame(dst_disp, 3);
                    var i: u32 = 0;
                    while (i < ps) : (i += 1) {
                        try gen.addInst(.mov, &.{
                            .{ .reg = .a },
                            .{ .imm = .{ .value = @intCast((o.len >> @intCast(8 * i)) & 0xff), .bits = 8 } },
                        });
                        try gen.storeA(.{ .frame = dst_disp + @as(i32, @intCast(ps)) }, i, ps);
                    }
                    gen.slice_origin.put(gen.gpa, dst_disp, o) catch {};
                    return;
                }
            }
            if (gen.runtimeAddrOf(bin.lhs)) |addr| {
                const src_disp = try gen.aggSrcDisp(bin.rhs);
                try gen.derefWrite(addr, .{ .frame = src_disp }, size);
                return;
            }
            const dst_disp = try gen.storageDisp(bin.lhs);
            const src_disp = try gen.aggSrcDisp(bin.rhs);
            if (value_ty.isSlice(gen.zcu)) {
                if (gen.slice_origin.get(src_disp)) |o| {
                    gen.slice_origin.put(gen.gpa, dst_disp, o) catch {};
                }
            }
            try gen.emitAggregateCopy(dst_disp, src_disp, size);
            return;
        }
        const class = abi.classify(value_ty, gen.zcu);
        if (class.is_aggregate or class.size == 0 or class.size > 4) return gen.fail(
            "mcs backend: aggregate or oversized store is not implemented yet",
            .{},
        );
        const size: u32 = class.size;
        const src = try gen.locOf(bin.rhs);
        if (gen.runtimeAddrOf(bin.lhs)) |addr| {
            try gen.derefWrite(addr, src, size);
            return;
        }
        if (gen.dynPtrOf(bin.lhs)) |pd| {
            try gen.emitIndexedAccess(pd, size, null, src);
            return;
        }
        if (try gen.globalSymbolOf(bin.lhs)) |sym| {
            try gen.derefSymbolWrite(sym, src, size);
            return;
        }
        if (gen.fixedAddrOf(bin.lhs)) |addr| {
            try gen.derefFixedWrite(addr, src, size);
            return;
        }
        const disp = try gen.storageDisp(bin.lhs);
        try gen.moveValue(src, .{ .frame = disp }, size);
    }

    /// `.ptr_elem_ptr`：编译期 `.ptr` 已在 prealloc 完成；仅当 base 是 `.ptr_rt` 时
    /// 物化运行期地址：DR28 = load(base_addr) + off，存到 inst.addr。
    fn emitElemPtr(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        switch (gen.vals[@intFromEnum(inst)]) {
            .ptr_rt => |pr| {
                if (pr.base_addr == 0) return; // 无 base，无需物化（参数 ptr_rt 直接用 addr）
                if (gen.arch == .mcs51) {
                    // MCS-51：16 位指针帧内小端（+0=低，+1=高），用 DPTR 做 16 位加。
                    const ps = gen.ptrBytes();
                    try gen.copyFrameBytes(pr.base_addr, pr.addr, ps);
                    if (pr.off != 0) {
                        const off: u32 = @intCast(pr.off);
                        try gen.loadPtrToDptr(.{ .frame = pr.addr }, ps);
                        try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = .dpl } });
                        try gen.addInst(.add, &.{ .{ .reg = .a }, .{ .imm = .{ .value = @intCast(off & 0xff), .bits = 8 } } });
                        try gen.addInst(.mov, &.{ .{ .reg = .dpl }, .{ .reg = .a } });
                        try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = .dph } });
                        try gen.addInst(.addc, &.{ .{ .reg = .a }, .{ .imm = .{ .value = @intCast((off >> 8) & 0xff), .bits = 8 } } });
                        try gen.addInst(.mov, &.{ .{ .reg = .dph }, .{ .reg = .a } });
                        try gen.addInst(.mov, &.{ gen.frameOperand(pr.addr + 0), .{ .reg = .dpl } });
                        try gen.addInst(.mov, &.{ gen.frameOperand(pr.addr + 1), .{ .reg = .dph } });
                    }
                    return;
                }
                // 从源指针帧槽加载 3 字节地址到 DR28。
                try gen.loadPtrToDr28(.{ .frame = pr.base_addr }, 3);
                if (pr.off != 0) {
                    try gen.addInst(.add, &.{
                        .{ .reg = .{ .dr = 7 } },
                        .{ .imm = .{ .value = @intCast(pr.off), .bits = 16 } },
                    });
                }
                try gen.storeDr28ToFrame(pr.addr, 3);
            },
            else => {}, // 编译期 .ptr 元素指针无代码
        }
    }

    /// `.intcast`/`.trunc`/`.bitcast`：按字节复制，必要时零/符号扩展。
    fn emitCast(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
        const result_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        if (!result_ty.hasRuntimeBits(gen.zcu)) return;
        // 指针↔指针：`preallocCast` 已保留编译期指针描述，无需代码。
        switch (gen.vals[@intFromEnum(inst)]) {
            .ptr, .slice, .ptr_dyn, .ptr_rt => return,
            else => {},
        }

        const operand_ty = gen.air.typeOf(ty_op.operand, &gen.zcu.intern_pool);
        const dst_size = try gen.scalarSize(result_ty);
        const dst = gen.vals[@intFromEnum(inst)];

        // 操作数是运行期指针/切片时，先物化为 3 字节地址（int<->ptr 转换）。
        var src: Loc = undefined;
        var src_size: u32 = undefined;
        var operand_is_ptr = false;
        if (ty_op.operand.toIndex()) |oi| {
            switch (gen.vals[@intFromEnum(oi)]) {
                .ptr, .ptr_rt, .ptr_dyn, .slice => operand_is_ptr = true,
                else => {},
            }
        }
        if (operand_is_ptr) {
            if (gen.arch != .mcs251) return gen.fail(
                "mcs backend: pointer casts on MCS-51 are not implemented yet",
                .{},
            );
            const ps = gen.ptrBytes();
            const tmp = gen.allocFrame(ps);
            switch (gen.vals[@intFromEnum(ty_op.operand.toIndex().?)]) {
                .ptr => |p| {
                    try gen.materializePtrAddr(p.base, p.off);
                    try gen.storeDr28ToFrame(tmp, 3);
                },
                .slice => |s| {
                    try gen.materializePtrAddr(s.base, s.off);
                    try gen.storeDr28ToFrame(tmp, 3);
                },
                .ptr_rt => |pr| try gen.copyFrameBytes(pr.addr, tmp, ps),
                .frame => |d| try gen.copyFrameBytes(d, tmp, ps),
                else => return gen.fail("mcs backend: unsupported pointer cast operand", .{}),
            }
            src = .{ .frame = tmp };
            src_size = ps;
        } else {
            src_size = try gen.scalarSize(operand_ty);
            src = try gen.locOf(ty_op.operand);
        }

        const copy = @min(src_size, dst_size);
        var i: u32 = 0;
        while (i < copy) : (i += 1) {
            try gen.loadByteToA(src, i, src_size);
            try gen.storeA(dst, i, dst_size);
        }
        if (dst_size <= src_size) return;

        if (operand_ty.isSignedInt(gen.zcu)) {
            // 取源最高字节的符号位，扩展为 0x00 / 0xFF。
            try gen.loadByteToA(src, src_size - 1, src_size);
            try gen.addInst(.rlc, &.{.{ .reg = .a }});
            try gen.addInst(.clr, &.{.{ .reg = .a }});
            try gen.addInst(.addc, &.{ .{ .reg = .a }, .{ .imm = .{ .value = 0, .bits = 8 } } });
            try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 6 } }, .{ .reg = .a } });
            try gen.addInst(.clr, &.{.{ .reg = .cy }});
            try gen.addInst(.clr, &.{.{ .reg = .a }});
            try gen.addInst(.subb, &.{ .{ .reg = .a }, .{ .reg = .{ .r = 6 } } });
        } else {
            try gen.setABool(false);
        }
        var j: u32 = src_size;
        while (j < dst_size) : (j += 1) {
            try gen.storeA(dst, j, dst_size);
        }
    }

    // --- 位运算 / 移位 / 乘除 ----------------------------------------------

    fn emitNot(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
        const ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const size = try gen.scalarSize(ty);
        const op_ty = gen.air.typeOf(ty_op.operand, &gen.zcu.intern_pool);
        const loc = try gen.locOf(ty_op.operand);
        const dst = gen.vals[@intFromEnum(inst)];

        if (op_ty.zigTypeTag(gen.zcu) == .bool) {
            try gen.loadByteToA(loc, 0, 1);
            try gen.addInst(.xrl, &.{ .{ .reg = .a }, .{ .imm = .{ .value = 1, .bits = 8 } } });
            try gen.storeA(dst, 0, 1);
            return;
        }

        var i: u32 = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(loc, i, size);
            try gen.addInst(.cpl, &.{.{ .reg = .a }});
            try gen.storeA(dst, i, size);
        }
    }

    fn emitBoolBin(gen: *Gen, inst: Air.Inst.Index, op: encode.Mnemonic) codegen.CodeGenError!void {
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const lhs = try gen.locOf(bin.lhs);
        const rhs = try gen.locOf(bin.rhs);
        const dst = gen.vals[@intFromEnum(inst)];
        try gen.loadByteToA(lhs, 0, 1);
        try gen.applyByte(op, rhs, 0, 1, false);
        try gen.storeA(dst, 0, 1);
    }

    /// 对结果位置整体左移/右移一位。
    fn shift1(gen: *Gen, dst: MCValue, size: u32, left: bool) codegen.CodeGenError!void {
        try gen.addInst(.clr, &.{.{ .reg = .cy }});
        if (left) {
            var i: u32 = 0;
            while (i < size) : (i += 1) {
                try gen.loadByteToA(mcToLoc(dst), i, size);
                try gen.addInst(.rlc, &.{.{ .reg = .a }});
                try gen.storeA(dst, i, size);
            }
        } else {
            var i: u32 = size;
            while (i > 0) {
                i -= 1;
                try gen.loadByteToA(mcToLoc(dst), i, size);
                try gen.addInst(.rrc, &.{.{ .reg = .a }});
                try gen.storeA(dst, i, size);
            }
        }
    }

    fn emitShift(gen: *Gen, inst: Air.Inst.Index, left: bool) codegen.CodeGenError!void {
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const size = try gen.scalarSize(ty);
        const lhs = try gen.locOf(bin.lhs);
        const rhs = try gen.locOf(bin.rhs);
        const dst = gen.vals[@intFromEnum(inst)];

        try gen.moveValue(lhs, dst, size);

        switch (rhs) {
            .imm => |v| {
                const bits = 8 * size;
                if (v >= bits) {
                    var i: u32 = 0;
                    while (i < size) : (i += 1) {
                        try gen.setABool(false);
                        try gen.storeA(dst, i, size);
                    }
                    return;
                }
                var k: u32 = 0;
                while (k < @as(u32, @intCast(v))) : (k += 1) try gen.shift1(dst, size, left);
            },
            else => {
                const cd = gen.getExtra(inst, 0);
                try gen.moveValue(rhs, .{ .frame = cd }, 1);
                const loop = gen.newLabel();
                const done = gen.newLabel();
                try gen.mir.addLabel(gen.gpa, loop);
                try gen.loadByteToA(.{ .frame = cd }, 0, 1);
                try gen.addInst(.jz, &.{.{ .code = .{ .local_label = done } }});
                try gen.shift1(dst, size, left);
                try gen.loadByteToA(.{ .frame = cd }, 0, 1);
                try gen.addInst(.dec, &.{.{ .reg = .a }});
                try gen.storeA(.{ .frame = cd }, 0, 1);
                try gen.jmpFar(loop);
                try gen.mir.addLabel(gen.gpa, done);
            },
        }
    }

    /// 把操作数的一个 16 位字装入 WR。
    fn loadWordToWr(gen: *Gen, loc: Loc, size: u32, low: bool, wr: u4) codegen.CodeGenError!void {
        const off: i32 = if (size == 4 and low) 2 else 0;
        switch (loc) {
            .imm => |v| {
                const word: u32 = if (size == 4 and low) @truncate(v >> 16) else @truncate(v);
                try gen.addInst(.mov, &.{
                    .{ .reg = .{ .wr = wr } },
                    .{ .imm = .{ .value = @intCast(word), .bits = 16 } },
                });
            },
            .frame => |d| {
                try gen.addInst(.mov, &.{
                    .{ .reg = .{ .wr = wr } },
                    gen.frameOperand(d + off),
                });
            },
            else => return gen.fail("mcs backend: unsupported operand for word multiply", .{}),
        }
    }

    fn storeWrToMcv(gen: *Gen, wr: u4, dst: MCValue, off: i32) codegen.CodeGenError!void {
        switch (dst) {
            .frame => |d| try gen.addInst(.mov, &.{
                gen.frameOperand(d + off),
                .{ .reg = .{ .wr = wr } },
            }),
            else => return gen.fail("mcs backend: unsupported multiply result location", .{}),
        }
    }

    fn emitMul(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const size = try gen.scalarSize(ty);
        const lhs = try gen.locOf(bin.lhs);
        const rhs = try gen.locOf(bin.rhs);
        const dst = gen.vals[@intFromEnum(inst)];

        switch (size) {
            1 => {
                try gen.loadByteToA(lhs, 0, 1);
                try gen.loadByteToB(rhs, 0, 1);
                try gen.addInst(.mul, &.{.{ .reg = .ab }});
                try gen.storeA(dst, 0, 1);
            },
            2 => {
                if (gen.arch != .mcs251) return gen.fail(
                    "mcs backend: 2-byte multiply on MCS-51 is not implemented yet",
                    .{},
                );
                try gen.loadWordToWr(lhs, 2, false, 0);
                try gen.loadWordToWr(rhs, 2, false, 1);
                try gen.addInst(.mul, &.{ .{ .reg = .{ .wr = 0 } }, .{ .reg = .{ .wr = 1 } } });
                try gen.storeWrToMcv(1, dst, 0);
            },
            4 => {
                if (gen.arch != .mcs251) return gen.fail(
                    "mcs backend: 4-byte multiply on MCS-51 is not implemented yet",
                    .{},
                );
                const pll = gen.getExtra(inst, 0);
                const plh = gen.getExtra(inst, 1);
                const phl = gen.getExtra(inst, 2);

                try gen.mulWords(lhs, true, rhs, true, pll);
                try gen.mulWords(lhs, true, rhs, false, plh);
                try gen.mulWords(lhs, false, rhs, true, phl);

                try gen.addInst(.mov, &.{ .{ .reg = .{ .wr = 0 } }, gen.frameOperand(pll + 2) });
                try gen.addInst(.mov, &.{ .{ .reg = .{ .wr = 2 } }, gen.frameOperand(pll) });
                try gen.addInst(.mov, &.{ .{ .reg = .{ .wr = 4 } }, gen.frameOperand(plh + 2) });
                try gen.addInst(.add, &.{ .{ .reg = .{ .wr = 2 } }, .{ .reg = .{ .wr = 4 } } });
                try gen.addInst(.mov, &.{ .{ .reg = .{ .wr = 4 } }, gen.frameOperand(phl + 2) });
                try gen.addInst(.add, &.{ .{ .reg = .{ .wr = 2 } }, .{ .reg = .{ .wr = 4 } } });
                try gen.storeWrToMcv(0, dst, 2);
                try gen.storeWrToMcv(2, dst, 0);
            },
            else => return gen.fail("mcs backend: multiply is only implemented for 1/2/4 bytes", .{}),
        }
    }

    fn mulWords(
        gen: *Gen,
        lhs: Loc,
        lhs_low: bool,
        rhs: Loc,
        rhs_low: bool,
        result_disp: i32,
    ) codegen.CodeGenError!void {
        try gen.loadWordToWr(lhs, 4, lhs_low, 0);
        try gen.loadWordToWr(rhs, 4, rhs_low, 1);
        try gen.addInst(.mul, &.{ .{ .reg = .{ .wr = 0 } }, .{ .reg = .{ .wr = 1 } } });
        try gen.addInst(.mov, &.{ gen.frameOperand(result_disp), .{ .reg = .{ .wr = 0 } } });
        try gen.addInst(.mov, &.{ gen.frameOperand(result_disp + 2), .{ .reg = .{ .wr = 1 } } });
    }

    fn emitDiv(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const tag = gen.air.instructions.items(.tag)[@intFromEnum(inst)];
        const want_remainder = tag == .mod or tag == .rem;
        const is_floor = tag == .div_floor or tag == .mod;
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const lhs_ty = gen.air.typeOf(bin.lhs, &gen.zcu.intern_pool);
        const ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const size = try gen.scalarSize(ty);

        if (lhs_ty.isSignedInt(gen.zcu)) {
            try gen.emitSignedDivMod(inst, size, want_remainder, is_floor);
            return;
        }

        const lhs = try gen.locOf(bin.lhs);
        const rhs = try gen.locOf(bin.rhs);
        const dst = gen.vals[@intFromEnum(inst)];

        switch (size) {
            1 => {
                try gen.loadByteToA(lhs, 0, 1);
                try gen.loadByteToB(rhs, 0, 1);
                try gen.addInst(.div, &.{.{ .reg = .ab }});
                try gen.storeA(dst, 0, 1);
                if (want_remainder) {
                    try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = .b } });
                    try gen.storeA(dst, 0, 1);
                }
            },
            2 => {
                try gen.loadWordToWr(lhs, 2, false, 0);
                try gen.loadWordToWr(rhs, 2, false, 1);
                try gen.addInst(.div, &.{ .{ .reg = .{ .wr = 0 } }, .{ .reg = .{ .wr = 1 } } });
                // 余数在 WR0，商在 WR2。
                try gen.storeWrToMcv(if (want_remainder) 0 else 1, dst, 0);
            },
            else => try gen.emitDivGeneric(inst, size, want_remainder),
        }
    }

    /// 无符号恢复余数除法核心：Q（初值为被除数）与 R 为可写帧槽，D 为只读帧槽。
    fn unsignedDivCore(
        gen: *Gen,
        size: u32,
        qD: i32,
        rD: i32,
        dD: i32,
        cD: i32,
    ) codegen.CodeGenError!void {
        var i: u32 = 0;
        while (i < size) : (i += 1) {
            try gen.setABool(false);
            try gen.storeA(.{ .frame = rD }, i, size);
        }
        try gen.addInst(.mov, &.{
            .{ .reg = .a },
            .{ .imm = .{ .value = @intCast(8 * size), .bits = 8 } },
        });
        try gen.storeA(.{ .frame = cD }, 0, 1);

        const loop = gen.newLabel();
        const have = gen.newLabel();
        const next = gen.newLabel();
        const done = gen.newLabel();

        try gen.mir.addLabel(gen.gpa, loop);

        try gen.addInst(.clr, &.{.{ .reg = .cy }});
        i = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(.{ .frame = qD }, i, size);
            try gen.addInst(.rlc, &.{.{ .reg = .a }});
            try gen.storeA(.{ .frame = qD }, i, size);
        }
        i = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(.{ .frame = rD }, i, size);
            try gen.addInst(.rlc, &.{.{ .reg = .a }});
            try gen.storeA(.{ .frame = rD }, i, size);
        }
        try gen.addInst(.clr, &.{.{ .reg = .cy }});
        i = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(.{ .frame = rD }, i, size);
            try gen.applyByte(.subb, .{ .frame = dD }, i, size, false);
            try gen.storeA(.{ .frame = rD }, i, size);
        }
        try gen.addInst(.jnc, &.{.{ .code = .{ .local_label = have } }});
        try gen.addInst(.clr, &.{.{ .reg = .cy }});
        i = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(.{ .frame = rD }, i, size);
            try gen.applyByte(.addc, .{ .frame = dD }, i, size, false);
            try gen.storeA(.{ .frame = rD }, i, size);
        }
        try gen.jmpFar(next);
        try gen.mir.addLabel(gen.gpa, have);
        try gen.loadByteToA(.{ .frame = qD }, 0, size);
        try gen.addInst(.orl, &.{
            .{ .reg = .a },
            .{ .imm = .{ .value = 1, .bits = 8 } },
        });
        try gen.storeA(.{ .frame = qD }, 0, size);
        try gen.mir.addLabel(gen.gpa, next);

        try gen.loadByteToA(.{ .frame = cD }, 0, 1);
        try gen.addInst(.dec, &.{.{ .reg = .a }});
        try gen.storeA(.{ .frame = cD }, 0, 1);
        try gen.addInst(.jz, &.{.{ .code = .{ .local_label = done } }});
        try gen.jmpFar(loop);
        try gen.mir.addLabel(gen.gpa, done);
    }

    fn emitDivGeneric(
        gen: *Gen,
        inst: Air.Inst.Index,
        size: u32,
        want_remainder: bool,
    ) codegen.CodeGenError!void {
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const lhs = try gen.locOf(bin.lhs);
        const rhs = try gen.locOf(bin.rhs);
        const dst = gen.vals[@intFromEnum(inst)];
        const rD = gen.getExtra(inst, 0);
        const qD = gen.getExtra(inst, 1);
        const dD = gen.getExtra(inst, 2);
        const cD = gen.getExtra(inst, 3);

        try gen.moveValue(lhs, .{ .frame = qD }, size);
        try gen.moveValue(rhs, .{ .frame = dD }, size);
        try gen.unsignedDivCore(size, qD, rD, dD, cD);
        try gen.moveValue(.{ .frame = if (want_remainder) rD else qD }, dst, size);
    }

    /// 取符号位（最高字节 bit7）为 0/1 存入帧槽。
    fn computeSign(gen: *Gen, loc: Loc, size: u32, sign_disp: i32) codegen.CodeGenError!void {
        try gen.loadByteToA(loc, size - 1, size);
        try gen.addInst(.anl, &.{
            .{ .reg = .a },
            .{ .imm = .{ .value = 0x80, .bits = 8 } },
        });
        try gen.addInst(.rl, &.{.{ .reg = .a }});
        try gen.storeA(.{ .frame = sign_disp }, 0, 1);
    }

    /// 帧槽内容取负（逐字节取反后加一）。
    fn negateFrame(gen: *Gen, disp: i32, size: u32) codegen.CodeGenError!void {
        var i: u32 = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(.{ .frame = disp }, i, size);
            try gen.addInst(.cpl, &.{.{ .reg = .a }});
            try gen.storeA(.{ .frame = disp }, i, size);
        }
        i = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(.{ .frame = disp }, i, size);
            try gen.addInst(if (i == 0) .add else .addc, &.{
                .{ .reg = .a },
                .{ .imm = .{ .value = if (i == 0) 1 else 0, .bits = 8 } },
            });
            try gen.storeA(.{ .frame = disp }, i, size);
        }
    }

    /// 有符号除法/取模：`|a| / |b|` 后按符号调整。
    fn emitSignedDivMod(
        gen: *Gen,
        inst: Air.Inst.Index,
        size: u32,
        want_remainder: bool,
        is_floor: bool,
    ) codegen.CodeGenError!void {
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const lhs = try gen.locOf(bin.lhs);
        const rhs = try gen.locOf(bin.rhs);
        const dst = gen.vals[@intFromEnum(inst)];
        const ua = gen.getExtra(inst, 0);
        const ub = gen.getExtra(inst, 1);
        const rD = gen.getExtra(inst, 2);
        const cD = gen.getExtra(inst, 3);
        const na = gen.getExtra(inst, 4);
        const nb = gen.getExtra(inst, 5);

        try gen.computeSign(lhs, size, na);
        try gen.moveValue(lhs, .{ .frame = ua }, size);
        {
            const pos = gen.newLabel();
            try gen.loadByteToA(.{ .frame = na }, 0, 1);
            try gen.addInst(.jz, &.{.{ .code = .{ .local_label = pos } }});
            try gen.negateFrame(ua, size);
            try gen.mir.addLabel(gen.gpa, pos);
        }
        try gen.computeSign(rhs, size, nb);
        try gen.moveValue(rhs, .{ .frame = ub }, size);
        {
            const pos = gen.newLabel();
            try gen.loadByteToA(.{ .frame = nb }, 0, 1);
            try gen.addInst(.jz, &.{.{ .code = .{ .local_label = pos } }});
            try gen.negateFrame(ub, size);
            try gen.mir.addLabel(gen.gpa, pos);
        }

        try gen.unsignedDivCore(size, ua, rD, ub, cD);

        if (!want_remainder) {
            const qdone = gen.newLabel();
            try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 7 } }, gen.frameOperand(gen.slotByte(na, 0, 1)) });
            try gen.loadByteToA(.{ .frame = nb }, 0, 1);
            try gen.addInst(.xrl, &.{ .{ .reg = .a }, .{ .reg = .{ .r = 7 } } });
            try gen.addInst(.jz, &.{.{ .code = .{ .local_label = qdone } }});
            try gen.negateFrame(ua, size);
            try gen.mir.addLabel(gen.gpa, qdone);

            if (is_floor) {
                const fdone = gen.newLabel();
                try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 7 } }, gen.frameOperand(gen.slotByte(na, 0, 1)) });
                try gen.loadByteToA(.{ .frame = nb }, 0, 1);
                try gen.addInst(.xrl, &.{ .{ .reg = .a }, .{ .reg = .{ .r = 7 } } });
                try gen.addInst(.jz, &.{.{ .code = .{ .local_label = fdone } }});
                try gen.loadByteToA(.{ .frame = rD }, 0, size);
                var i: u32 = 1;
                while (i < size) : (i += 1) try gen.applyByte(.orl, .{ .frame = rD }, i, size, false);
                try gen.addInst(.jz, &.{.{ .code = .{ .local_label = fdone } }});
                try gen.addInst(.clr, &.{.{ .reg = .cy }});
                i = 0;
                while (i < size) : (i += 1) {
                    try gen.loadByteToA(.{ .frame = ua }, i, size);
                    try gen.applyByte(.subb, .{ .imm = if (i == 0) @as(u64, 1) else 0 }, i, size, false);
                    try gen.storeA(.{ .frame = ua }, i, size);
                }
                try gen.mir.addLabel(gen.gpa, fdone);
            }
            try gen.moveValue(.{ .frame = ua }, dst, size);
            return;
        }

        const mdone = gen.newLabel();
        try gen.loadByteToA(.{ .frame = na }, 0, 1);
        try gen.addInst(.jz, &.{.{ .code = .{ .local_label = mdone } }});
        try gen.negateFrame(rD, size);
        try gen.mir.addLabel(gen.gpa, mdone);

        if (is_floor) {
            const pdone = gen.newLabel();
            try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 7 } }, gen.frameOperand(gen.slotByte(na, 0, 1)) });
            try gen.loadByteToA(.{ .frame = nb }, 0, 1);
            try gen.addInst(.xrl, &.{ .{ .reg = .a }, .{ .reg = .{ .r = 7 } } });
            try gen.addInst(.jz, &.{.{ .code = .{ .local_label = pdone } }});
            try gen.loadByteToA(.{ .frame = rD }, 0, size);
            var i: u32 = 1;
            while (i < size) : (i += 1) try gen.applyByte(.orl, .{ .frame = rD }, i, size, false);
            try gen.addInst(.jz, &.{.{ .code = .{ .local_label = pdone } }});
            i = 0;
            while (i < size) : (i += 1) {
                try gen.loadByteToA(.{ .frame = rD }, i, size);
                try gen.applyByte(.add, rhs, i, size, i == 0);
                try gen.storeA(.{ .frame = rD }, i, size);
            }
            try gen.mir.addLabel(gen.gpa, pdone);
        }
        try gen.moveValue(.{ .frame = rD }, dst, size);
    }

    // --- 调用 ---------------------------------------------------------------

    /// 编译期调用目标的符号名（SDCC C ABI 以 `_` 前缀修饰）；间接调用返回 `null`。
    fn calleeSymbolOpt(gen: *Gen, callee: Air.Inst.Ref) codegen.CodeGenError!?[]const u8 {
        const ip_index = callee.toInterned() orelse return null;
        const ip = &gen.zcu.intern_pool;
        const raw: []const u8 = switch (ip.indexToKey(ip_index)) {
            .func => |f| ip.getNav(f.owner_nav).name.toSlice(ip),
            .ptr => |p| switch (p.base_addr) {
                .nav => |nav| ip.getNav(nav).name.toSlice(ip),
                else => return null,
            },
            .@"extern" => |e| e.name.toSlice(ip),
            else => return null,
        };
        const name = try std.fmt.allocPrint(gen.gpa, "_{s}", .{raw});
        try gen.mir.addOwned(gen.gpa, name);
        return name;
    }

    /// 指针字节数（MCS-251 为 3，MCS-51 为 2）。
    fn ptrBytes(gen: *Gen) u32 {
        return @intCast(gen.zcu.getTarget().ptrBitWidth() / 8);
    }

    /// DR28 = SPX + base + off（帧内对象的绝对地址）；`base` 为帧槽位移。
    fn materializePtrAddr(gen: *Gen, base: i32, off: i32) codegen.CodeGenError!void {
        const d = base + off - gen.pushed;
        try gen.addInst(.mov, &.{ .{ .reg = .{ .dr = 7 } }, .{ .reg = .spx } });
        if (d < 0) {
            try gen.addInst(.sub, &.{
                .{ .reg = .{ .dr = 7 } },
                .{ .imm = .{ .value = @intCast(-d), .bits = 16 } },
            });
        } else if (d > 0) {
            try gen.addInst(.add, &.{
                .{ .reg = .{ .dr = 7 } },
                .{ .imm = .{ .value = @intCast(d), .bits = 16 } },
            });
        }
    }

    /// 把 `loc` 处的 2 字节 xdata 指针装入 DPTR（小端：低字节在 `loc` 偏移 0）。
    fn loadPtrToDptr(gen: *Gen, loc: Loc, size: u32) codegen.CodeGenError!void {
        try gen.loadByteToA(loc, 0, size);
        try gen.addInst(.mov, &.{ .{ .reg = .dpl }, .{ .reg = .a } });
        try gen.loadByteToA(loc, 1, size);
        try gen.addInst(.mov, &.{ .{ .reg = .dph }, .{ .reg = .a } });
    }

    /// 从帧槽 `addr_disp` 保存的绝对地址读取 `size` 字节到 `dst_disp`（内存序）。
    fn derefRead(gen: *Gen, addr_disp: i32, size: u32, dst_disp: i32) codegen.CodeGenError!void {
        if (gen.arch == .mcs51) {
            // MCS-51：16 位 xdata 指针 -> DPTR，MOVX 读，逐字节 INC DPTR。
            try gen.loadPtrToDptr(.{ .frame = addr_disp }, gen.ptrBytes());
            var j: u32 = 0;
            while (j < size) : (j += 1) {
                try gen.addInst(.movx, &.{ .{ .reg = .a }, .{ .at_dptr = {} } });
                try gen.addInst(.mov, &.{
                    gen.frameOperand(dst_disp + @as(i32, @intCast(j))),
                    .{ .reg = .a },
                });
                if (j + 1 < size) try gen.addInst(.inc, &.{.{ .reg = .dptr }});
            }
            return;
        }
        try gen.loadPtrToDr28(.{ .frame = addr_disp }, 3);
        var j: u32 = 0;
        while (j < size) : (j += 1) {
            try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 3 } }, .{ .at_dr = 7 } });
            try gen.addInst(.mov, &.{
                gen.frameOperand(dst_disp + @as(i32, @intCast(j))),
                .{ .reg = .{ .r = 3 } },
            });
            if (j + 1 < size) try gen.addInst(.add, &.{
                .{ .reg = .{ .dr = 7 } },
                .{ .imm = .{ .value = 1, .bits = 16 } },
            });
        }
    }

    /// 把 `src` 的 `size` 字节写到帧槽 `addr_disp` 保存的绝对地址（内存序）。
    fn derefWrite(gen: *Gen, addr_disp: i32, src: Loc, size: u32) codegen.CodeGenError!void {
        if (gen.arch == .mcs51) {
            // MCS-51：DPTR + MOVX 写，逐字节 INC DPTR。
            try gen.loadPtrToDptr(.{ .frame = addr_disp }, gen.ptrBytes());
            var j: u32 = 0;
            while (j < size) : (j += 1) {
                try gen.loadByteToA(src, j, size);
                try gen.addInst(.movx, &.{ .{ .at_dptr = {} }, .{ .reg = .a } });
                if (j + 1 < size) try gen.addInst(.inc, &.{.{ .reg = .dptr }});
            }
            return;
        }
        try gen.loadPtrToDr28(.{ .frame = addr_disp }, 3);
        var j: u32 = 0;
        while (j < size) : (j += 1) {
            try gen.loadByteToA(src, j, size);
            try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 3 } }, .{ .reg = .a } });
            try gen.addInst(.mov, &.{ .{ .at_dr = 7 }, .{ .reg = .{ .r = 3 } } });
            if (j + 1 < size) try gen.addInst(.add, &.{
                .{ .reg = .{ .dr = 7 } },
                .{ .imm = .{ .value = 1, .bits = 16 } },
            });
        }
    }

    /// 若 `ref` 是编译期指向全局/外部数据符号的指针，返回其 ASxxxx 符号名（`_` 前缀）。
    fn globalSymbolOf(gen: *Gen, ref: Air.Inst.Ref) codegen.CodeGenError!?[]const u8 {
        const ip_index = ref.toInterned() orelse return null;
        const ip = &gen.zcu.intern_pool;
        const raw: []const u8 = switch (ip.indexToKey(ip_index)) {
            .ptr => |p| switch (p.base_addr) {
                .nav => |nav| ip.getNav(nav).name.toSlice(ip),
                else => return null,
            },
            .@"extern" => |e| e.name.toSlice(ip),
            else => return null,
        };
        const name = try std.fmt.allocPrint(gen.gpa, "_{s}", .{raw});
        try gen.mir.addOwned(gen.gpa, name);
        return name;
    }

    /// 固定整数地址（`@ptrFromInt`）的编译期值（xdata）。
    fn fixedAddrOf(gen: *Gen, ref: Air.Inst.Ref) ?u32 {
        const ip_index = ref.toInterned() orelse return null;
        const ip = &gen.zcu.intern_pool;
        const addr: u64 = switch (ip.indexToKey(ip_index)) {
            .ptr => |p| switch (p.base_addr) {
                .int => p.byte_offset,
                else => return null,
            },
            else => return null,
        };
        return @truncate(addr);
    }

    /// 读固定 xdata 地址 `addr` 的 `size` 字节到帧槽 `dst_disp`。
    fn derefFixedRead(gen: *Gen, addr: u32, size: u32, dst_disp: i32) codegen.CodeGenError!void {
        try gen.addInst(.mov, &.{ .{ .reg = .dptr }, .{ .imm = .{ .value = @intCast(addr & 0xffff), .bits = 16 } } });
        var j: u32 = 0;
        while (j < size) : (j += 1) {
            try gen.addInst(.movx, &.{ .{ .reg = .a }, .{ .at_dptr = {} } });
            try gen.addInst(.mov, &.{
                gen.frameOperand(dst_disp + @as(i32, @intCast(j))),
                .{ .reg = .a },
            });
            if (j + 1 < size) try gen.addInst(.inc, &.{.{ .reg = .dptr }});
        }
    }

    /// 把 `src` 的 `size` 字节写固定 xdata 地址 `addr`。
    fn derefFixedWrite(gen: *Gen, addr: u32, src: Loc, size: u32) codegen.CodeGenError!void {
        try gen.addInst(.mov, &.{ .{ .reg = .dptr }, .{ .imm = .{ .value = @intCast(addr & 0xffff), .bits = 16 } } });
        var j: u32 = 0;
        while (j < size) : (j += 1) {
            try gen.loadByteToA(src, j, size);
            try gen.addInst(.movx, &.{ .{ .at_dptr = {} }, .{ .reg = .a } });
            if (j + 1 < size) try gen.addInst(.inc, &.{.{ .reg = .dptr }});
        }
    }

    /// 读全局符号 `sym`（xdata）的 `size` 字节到帧槽 `dst_disp`。
    fn derefSymbolRead(gen: *Gen, sym: []const u8, size: u32, dst_disp: i32) codegen.CodeGenError!void {
        try gen.addInst(.mov, &.{ .{ .reg = .dptr }, .{ .imm_symbol = .{ .symbol = sym } } });
        var j: u32 = 0;
        while (j < size) : (j += 1) {
            try gen.addInst(.movx, &.{ .{ .reg = .a }, .{ .at_dptr = {} } });
            try gen.addInst(.mov, &.{
                gen.frameOperand(dst_disp + @as(i32, @intCast(j))),
                .{ .reg = .a },
            });
            if (j + 1 < size) try gen.addInst(.inc, &.{.{ .reg = .dptr }});
        }
    }

    /// 把 `src` 的 `size` 字节写全局符号 `sym`（xdata）。
    fn derefSymbolWrite(gen: *Gen, sym: []const u8, src: Loc, size: u32) codegen.CodeGenError!void {
        try gen.addInst(.mov, &.{ .{ .reg = .dptr }, .{ .imm_symbol = .{ .symbol = sym } } });
        var j: u32 = 0;
        while (j < size) : (j += 1) {
            try gen.loadByteToA(src, j, size);
            try gen.addInst(.movx, &.{ .{ .at_dptr = {} }, .{ .reg = .a } });
            if (j + 1 < size) try gen.addInst(.inc, &.{.{ .reg = .dptr }});
        }
    }

    /// 复制 `size` 字节（内存序）从 `src_disp` 到 `dst_disp`。
    fn copyFrameBytes(gen: *Gen, src_disp: i32, dst_disp: i32, size: u32) codegen.CodeGenError!void {
        var i: u32 = 0;
        while (i < size) : (i += 1) {
            try gen.addInst(.mov, &.{
                .{ .reg = .a },
                gen.frameOperand(src_disp + @as(i32, @intCast(i))),
            });
            try gen.addInst(.mov, &.{
                gen.frameOperand(dst_disp + @as(i32, @intCast(i))),
                .{ .reg = .a },
            });
        }
    }

    /// `.slice(ptr, len)`：编译期折叠为 `preallocSlice` 中的视图，此处仅处理物化路径。
    fn emitSlice(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        if (gen.vals[@intFromEnum(inst)] == .slice) return;
        if (gen.arch != .mcs251) return gen.fail(
            "mcs backend: slices on MCS-51 are not implemented yet",
            .{},
        );
        const ty_pl = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_pl;
        const bin = gen.air.extraData(Air.Bin, ty_pl.payload).data;
        const ps = gen.ptrBytes();
        const dst_disp = gen.vals[@intFromEnum(inst)].frame;

        const ptr_mcv = if (bin.lhs.toIndex()) |pi| gen.vals[@intFromEnum(pi)] else MCValue.none;
        switch (ptr_mcv) {
            .ptr => |p| {
                try gen.materializePtrAddr(p.base, p.off);
                try gen.storeDr28ToFrame(dst_disp, 3);
                if (bin.rhs.toInterned()) |len_ip| {
                    if (gen.getConstBits(len_ip)) |len_bits| {
                        gen.slice_origin.put(gen.gpa, dst_disp, .{
                            .base = p.base,
                            .off = p.off,
                            .len = @truncate(len_bits),
                        }) catch {};
                    }
                }
            },
            .ptr_rt => |pr| try gen.copyFrameBytes(pr.addr, dst_disp, ps),
            .frame => |d| try gen.copyFrameBytes(d, dst_disp, ps),
            else => return gen.fail("mcs backend: unsupported slice pointer operand", .{}),
        }

        const len_loc = try gen.locOf(bin.rhs);
        try gen.moveValue(len_loc, .{ .frame = dst_disp + @as(i32, @intCast(ps)) }, ps);
    }

    /// `.slice_len`：描述符直接写常量；否则读取 len 字段。
    fn emitSliceLen(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
        const dst = gen.vals[@intFromEnum(inst)];
        const ps = gen.ptrBytes();
        if (ty_op.operand.toIndex()) |si| {
            if (gen.vals[@intFromEnum(si)] == .slice) {
                const s = gen.vals[@intFromEnum(si)].slice;
                var i: u32 = 0;
                while (i < ps) : (i += 1) {
                    try gen.addInst(.mov, &.{
                        .{ .reg = .a },
                        .{ .imm = .{ .value = @intCast((s.len >> @intCast(8 * i)) & 0xff), .bits = 8 } },
                    });
                    try gen.storeA(dst, i, ps);
                }
                return;
            }
        }
        const src_disp = try gen.aggSrcDisp(ty_op.operand);
        var i: u32 = 0;
        while (i < ps) : (i += 1) {
            try gen.loadByteToA(.{ .frame = src_disp + @as(i32, @intCast(ps)) }, i, ps);
            try gen.storeA(dst, i, ps);
        }
    }

    /// `.slice_ptr`：描述符无代码；否则读取 ptr 字段到一个 `ptr_rt`。
    fn emitSlicePtr(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        if (gen.vals[@intFromEnum(inst)] != .ptr_rt) return;
        const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
        const ps = gen.ptrBytes();
        const src_disp = try gen.aggSrcDisp(ty_op.operand);
        const addr = gen.vals[@intFromEnum(inst)].ptr_rt.addr;
        try gen.copyFrameBytes(src_disp, addr, ps);
    }

    /// 取切片元素指针到 DR28（下标需为编译期常量）。
    fn sliceElemAddress(gen: *Gen, slice_ref: Air.Inst.Ref, index: Air.Inst.Ref, elem_size: u32) codegen.CodeGenError!void {
        const ps = gen.ptrBytes();
        const slice_disp = try gen.aggSrcDisp(slice_ref);
        try gen.loadPtrToDr28(.{ .frame = slice_disp }, ps);
        const idx_ip = index.toInterned() orelse return gen.fail(
            "mcs backend: runtime slice index is not implemented yet",
            .{},
        );
        const bits = gen.getConstBits(idx_ip) orelse return gen.fail(
            "mcs backend: unsupported slice index",
            .{},
        );
        const signed: i64 = @bitCast(bits);
        const off = signed * @as(i64, elem_size);
        if (off > 0) {
            try gen.addInst(.add, &.{ .{ .reg = .{ .dr = 7 } }, .{ .imm = .{ .value = @intCast(off), .bits = 16 } } });
        } else if (off < 0) {
            try gen.addInst(.sub, &.{ .{ .reg = .{ .dr = 7 } }, .{ .imm = .{ .value = @intCast(-off), .bits = 16 } } });
        }
    }

    /// `.slice_elem_val`：读取切片元素值。
    fn emitSliceElemVal(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const elem_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const size = try gen.scalarSize(elem_ty);
        if (gen.sliceView(bin.lhs)) |v| {
            if (bin.rhs.toInterned()) |idx_ip| {
                const bits = gen.getConstBits(idx_ip) orelse return gen.fail(
                    "mcs backend: unsupported slice index",
                    .{},
                );
                const signed: i64 = @bitCast(bits);
                const off = v.off + @as(i32, @intCast(signed * @as(i64, size)));
                try gen.moveValue(.{ .frame = v.base + off }, gen.vals[@intFromEnum(inst)], size);
                return;
            }
            const idx_loc = try gen.locOf(bin.rhs);
            const idx_frame = switch (idx_loc) {
                .frame => |d| d,
                else => return gen.fail("mcs backend: runtime index has no frame slot", .{}),
            };
            const idx_size: u32 = try gen.scalarSize(gen.air.typeOf(bin.rhs, &gen.zcu.intern_pool));
            const pd = DynPtr{
                .base = v.base + v.off,
                .idx = idx_frame,
                .idx_size = idx_size,
                .elem_size = size,
                .len = v.len,
            };
            try gen.emitIndexedAccess(pd, size, gen.vals[@intFromEnum(inst)], null);
            return;
        }
        if (gen.arch != .mcs251) return gen.fail(
            "mcs backend: slices on MCS-51 are not implemented yet",
            .{},
        );
        const dst_disp = gen.vals[@intFromEnum(inst)].frame;
        try gen.sliceElemAddress(bin.lhs, bin.rhs, size);
        var j: u32 = 0;
        while (j < size) : (j += 1) {
            try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 3 } }, .{ .at_dr = 7 } });
            try gen.addInst(.mov, &.{
                gen.frameOperand(dst_disp + @as(i32, @intCast(j))),
                .{ .reg = .{ .r = 3 } },
            });
            if (j + 1 < size) try gen.addInst(.add, &.{
                .{ .reg = .{ .dr = 7 } },
                .{ .imm = .{ .value = 1, .bits = 16 } },
            });
        }
    }

    /// `.slice_elem_ptr`：描述符已折叠；否则计算绝对地址存为 `ptr_rt`。
    fn emitSliceElemPtr(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        if (gen.vals[@intFromEnum(inst)] != .ptr_rt) return;
        if (gen.arch != .mcs251) return gen.fail(
            "mcs backend: slices on MCS-51 are not implemented yet",
            .{},
        );
        const ty_pl = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_pl;
        const bin = gen.air.extraData(Air.Bin, ty_pl.payload).data;
        const result_ptr_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const elem_size: u32 = @intCast(result_ptr_ty.childType(gen.zcu).abiSize(gen.zcu));
        const addr = gen.vals[@intFromEnum(inst)].ptr_rt.addr;
        if (gen.sliceView(bin.lhs)) |v| {
            try gen.emitSliceAddrDispatch(v, bin.rhs, elem_size, addr);
            return;
        }
        try gen.sliceElemAddress(bin.lhs, bin.rhs, elem_size);
        try gen.storeDr28ToFrame(addr, 3);
    }

    /// 计算切片元素绝对地址写入 `addr_slot`：编译期下标直接算，运行期下标按长度展开分派。
    fn emitSliceAddrDispatch(
        gen: *Gen,
        v: SliceOrigin,
        index: Air.Inst.Ref,
        elem_size: u32,
        addr_slot: i32,
    ) codegen.CodeGenError!void {
        if (index.toInterned()) |idx_ip| {
            const bits = gen.getConstBits(idx_ip) orelse return gen.fail(
                "mcs backend: unsupported slice index",
                .{},
            );
            const signed: i64 = @bitCast(bits);
            try gen.materializePtrAddr(v.base, v.off + @as(i32, @intCast(signed * @as(i64, elem_size))));
            try gen.storeDr28ToFrame(addr_slot, 3);
            return;
        }
        const idx_loc = try gen.locOf(index);
        const idx_frame = switch (idx_loc) {
            .frame => |d| d,
            else => return gen.fail("mcs backend: runtime index has no frame slot", .{}),
        };
        const idx_size: u32 = try gen.scalarSize(gen.air.typeOf(index, &gen.zcu.intern_pool));
        const done = gen.newLabel();
        var j: u32 = 0;
        while (j < v.len) : (j += 1) {
            const no_match = gen.newLabel();
            try gen.emitNeJumpImm(.{ .frame = idx_frame }, j, idx_size, no_match);
            try gen.materializePtrAddr(v.base, v.off + @as(i32, @intCast(j * elem_size)));
            try gen.storeDr28ToFrame(addr_slot, 3);
            try gen.jmpFar(done);
            try gen.mir.addLabel(gen.gpa, no_match);
        }
        try gen.addTrap();
        try gen.mir.addLabel(gen.gpa, done);
    }

    /// `.ptr_add`：仅处理绝对地址 + 编译期偏移的物化路径。
    fn emitPtrAdd(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        if (gen.vals[@intFromEnum(inst)] != .ptr_rt) return;
        const ty_pl = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_pl;
        const bin = gen.air.extraData(Air.Bin, ty_pl.payload).data;
        const result_ptr_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const elem_size: u32 = @intCast(result_ptr_ty.childType(gen.zcu).abiSize(gen.zcu));
        const addr = gen.vals[@intFromEnum(inst)].ptr_rt.addr;
        const src = if (bin.lhs.toIndex()) |li| gen.vals[@intFromEnum(li)] else MCValue.none;
        const idx_ip = bin.rhs.toInterned().?;
        const bits = gen.getConstBits(idx_ip) orelse return gen.fail(
            "mcs backend: unsupported pointer offset",
            .{},
        );
        const signed: i64 = @bitCast(bits);
        const off = signed * @as(i64, elem_size);
        if (gen.arch == .mcs51) {
            // MCS-51：16 位指针帧内小端，用 DPTR 做 16 位加（负偏移按二进制补码加）。
            const ps = gen.ptrBytes();
            const src_disp: i32 = switch (src) {
                .ptr_rt => |pr| pr.addr,
                .frame => |d| d,
                else => return gen.fail("mcs backend: unsupported pointer base", .{}),
            };
            try gen.copyFrameBytes(src_disp, addr, ps);
            if (off != 0) {
                const uoff: u32 = @truncate(@as(u64, @bitCast(off)));
                try gen.loadPtrToDptr(.{ .frame = addr }, ps);
                try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = .dpl } });
                try gen.addInst(.add, &.{ .{ .reg = .a }, .{ .imm = .{ .value = @intCast(uoff & 0xff), .bits = 8 } } });
                try gen.addInst(.mov, &.{ .{ .reg = .dpl }, .{ .reg = .a } });
                try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = .dph } });
                try gen.addInst(.addc, &.{ .{ .reg = .a }, .{ .imm = .{ .value = @intCast((uoff >> 8) & 0xff), .bits = 8 } } });
                try gen.addInst(.mov, &.{ .{ .reg = .dph }, .{ .reg = .a } });
                try gen.addInst(.mov, &.{ gen.frameOperand(addr + 0), .{ .reg = .dpl } });
                try gen.addInst(.mov, &.{ gen.frameOperand(addr + 1), .{ .reg = .dph } });
            }
            return;
        }
        switch (src) {
            .ptr_rt => |pr| try gen.loadPtrToDr28(.{ .frame = pr.addr }, 3),
            .frame => |d| try gen.loadPtrToDr28(.{ .frame = d }, 3),
            else => return gen.fail("mcs backend: unsupported pointer base", .{}),
        }
        if (off > 0) {
            try gen.addInst(.add, &.{ .{ .reg = .{ .dr = 7 } }, .{ .imm = .{ .value = @intCast(off), .bits = 16 } } });
        } else if (off < 0) {
            try gen.addInst(.sub, &.{ .{ .reg = .{ .dr = 7 } }, .{ .imm = .{ .value = @intCast(-off), .bits = 16 } } });
        }
        try gen.storeDr28ToFrame(addr, 3);
    }

    /// `.array_to_slice`：描述符无代码；否则物化 ptr+len。
    fn emitArrayToSlice(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        if (gen.vals[@intFromEnum(inst)] == .slice) return;
        if (gen.arch != .mcs251) return gen.fail(
            "mcs backend: slices on MCS-51 are not implemented yet",
            .{},
        );
        const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
        const result_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const ps = gen.ptrBytes();
        const dst_disp = gen.vals[@intFromEnum(inst)].frame;
        const arr_ty = gen.air.typeOf(ty_op.operand, &gen.zcu.intern_pool).childType(gen.zcu);
        const len: u32 = @intCast(arr_ty.arrayLen(gen.zcu));

        switch (gen.vals[@intFromEnum(ty_op.operand.toIndex().?)]) {
            .ptr => |p| {
                try gen.materializePtrAddr(p.base, p.off);
                try gen.storeDr28ToFrame(dst_disp, 3);
                gen.slice_origin.put(gen.gpa, dst_disp, .{ .base = p.base, .off = p.off, .len = len }) catch {};
            },
            .ptr_rt => |pr| try gen.copyFrameBytes(pr.addr, dst_disp, ps),
            .frame => |d| try gen.copyFrameBytes(d, dst_disp, ps),
            else => return gen.fail("mcs backend: unsupported slice pointer operand", .{}),
        }
        var i: u32 = 0;
        while (i < ps) : (i += 1) {
            try gen.addInst(.mov, &.{
                .{ .reg = .a },
                .{ .imm = .{ .value = @intCast((len >> @intCast(8 * i)) & 0xff), .bits = 8 } },
            });
            try gen.storeA(.{ .frame = dst_disp + @as(i32, @intCast(ps)) }, i, ps);
        }
        _ = result_ty;
    }

    /// 把 `loc` 处的 3 字节指针装入 DR28（低字节对应 DR28 低位）。
    fn loadPtrToDr28(gen: *Gen, loc: Loc, size: u32) codegen.CodeGenError!void {
        if (size != 3) return gen.fail(
            "mcs backend: pointer value must be 3 bytes",
            .{},
        );
        // 高字节 -> R0，中 -> R1，低 -> R2。
        try gen.loadByteToA(loc, 2, size);
        try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 0 } }, .{ .reg = .a } });
        try gen.loadByteToA(loc, 1, size);
        try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 1 } }, .{ .reg = .a } });
        try gen.loadByteToA(loc, 0, size);
        try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 2 } }, .{ .reg = .a } });
        // push 0,R0,R1,R2 后 `pop dr28`（低字节在前），得到 0:R0:R1:R2。
        try gen.addInst(.push, &.{.{ .imm = .{ .value = 0, .bits = 8 } }});
        try gen.addInst(.push, &.{.{ .reg = .{ .r = 0 } }});
        try gen.addInst(.push, &.{.{ .reg = .{ .r = 1 } }});
        try gen.addInst(.push, &.{.{ .reg = .{ .r = 2 } }});
        try gen.addInst(.pop, &.{.{ .reg = .{ .dr = 7 } }});
    }

    /// 把 DR28 的低 3 字节（大端：MSB 在前）写入帧槽 `disp`。
    fn storeDr28ToFrame(gen: *Gen, disp: i32, size: u32) codegen.CodeGenError!void {
        if (size != 3) return gen.fail("mcs backend: pointer value must be 3 bytes", .{});
        try gen.addInst(.push, &.{.{ .reg = .{ .dr = 7 } }});
        try gen.addInst(.pop, &.{.{ .reg = .{ .r = 0 } }}); // 低
        try gen.addInst(.pop, &.{.{ .reg = .{ .r = 1 } }}); // 中
        try gen.addInst(.pop, &.{.{ .reg = .{ .r = 2 } }}); // 高
        try gen.addInst(.pop, &.{.{ .reg = .{ .r = 3 } }}); // 0
        try gen.addInst(.mov, &.{ gen.frameOperand(disp + 0), .{ .reg = .{ .r = 2 } } });
        try gen.addInst(.mov, &.{ gen.frameOperand(disp + 1), .{ .reg = .{ .r = 1 } } });
        try gen.addInst(.mov, &.{ gen.frameOperand(disp + 2), .{ .reg = .{ .r = 0 } } });
    }

    /// `@cVaStart`：ap = SPX - (frame_size + 2 + 已压栈固定参数字节)。
    fn emitCVaStart(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        if (gen.arch != .mcs251) return gen.fail(
            "mcs backend: variadic functions on MCS-51 are not implemented yet",
            .{},
        );
        const dst_disp = gen.vals[@intFromEnum(inst)].frame;
        const k: u32 = gen.frameBytes() + 2 + gen.stack_param_bytes;
        try gen.addInst(.mov, &.{ .{ .reg = .{ .dr = 7 } }, .{ .reg = .spx } });
        try gen.addInst(.sub, &.{
            .{ .reg = .{ .dr = 7 } },
            .{ .imm = .{ .value = @intCast(k), .bits = 16 } },
        });
        try gen.storeDr28ToFrame(dst_disp, 3);
    }

    /// `@cVaArg`：ap -= sizeof(T)；读取 T；`*ap` 也减去 sizeof(T)。
    fn emitCVaArg(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        if (gen.arch != .mcs251) return gen.fail(
            "mcs backend: variadic functions on MCS-51 are not implemented yet",
            .{},
        );
        const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
        const arg_ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const size = try gen.scalarSize(arg_ty);
        const ap_disp = try gen.storageDisp(ty_op.operand);
        const dst_disp = gen.vals[@intFromEnum(inst)].frame;

        try gen.loadPtrToDr28(.{ .frame = ap_disp }, 3);
        try gen.addInst(.sub, &.{
            .{ .reg = .{ .dr = 7 } },
            .{ .imm = .{ .value = @intCast(size), .bits = 16 } },
        });

        var j: u32 = 0;
        while (j < size) : (j += 1) {
            try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 3 } }, .{ .at_dr = 7 } });
            try gen.addInst(.mov, &.{
                gen.frameOperand(dst_disp + @as(i32, @intCast(j))),
                .{ .reg = .{ .r = 3 } },
            });
            if (j + 1 < size) try gen.addInst(.add, &.{
                .{ .reg = .{ .dr = 7 } },
                .{ .imm = .{ .value = 1, .bits = 16 } },
            });
        }

        // ap -= size（3 字节大端）。
        try gen.addInst(.clr, &.{.{ .reg = .cy }});
        var i: u32 = 0;
        while (i < 3) : (i += 1) {
            try gen.loadByteToA(.{ .frame = ap_disp }, i, 3);
            try gen.applyByte(.subb, .{ .imm = size }, i, 3, false);
            try gen.storeA(.{ .frame = ap_disp }, i, 3);
        }
    }

    /// `@cVaCopy`：复制一个 3 字节 VaList。
    fn emitCVaCopy(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const ty_op = gen.air.instructions.items(.data)[@intFromEnum(inst)].ty_op;
        const src_disp = try gen.storageDisp(ty_op.operand);
        const dst = gen.vals[@intFromEnum(inst)];
        var i: u32 = 0;
        while (i < 3) : (i += 1) {
            try gen.loadByteToA(.{ .frame = src_disp }, i, 3);
            try gen.storeA(dst, i, 3);
        }
    }

    /// 把 3 字节函数指针装入 DR28，供 `ecall @dr28` 使用（MCS-251）。
    fn loadCallTarget(gen: *Gen, ref: Air.Inst.Ref) codegen.CodeGenError!void {
        const ty = gen.air.typeOf(ref, &gen.zcu.intern_pool);
        const size = try gen.scalarSize(ty);
        const loc = try gen.locOf(ref);
        try gen.loadPtrToDr28(loc, size);
    }

    fn emitCall(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const zcu = gen.zcu;
        const ip = &zcu.intern_pool;
        const call = gen.air.unwrapCall(inst);

        const callee_ty = gen.air.typeOf(call.callee, ip);
        const fn_ty = switch (callee_ty.zigTypeTag(zcu)) {
            .@"fn" => callee_ty,
            .pointer => callee_ty.childType(zcu),
            else => return gen.fail("mcs backend: unsupported callee type", .{}),
        };
        const fn_info = zcu.typeToFunc(fn_ty) orelse return gen.fail(
            "mcs backend: unknown function type",
            .{},
        );
        _ = fn_info;

        const args = call.args;
        const symbol_opt = try gen.calleeSymbolOpt(call.callee);
        const direct = symbol_opt != null;
        const symbol: []const u8 = symbol_opt orelse &.{};

        // 1) 栈参数逆序压栈（args[0] 走寄存器组）。
        var total_pushed: u32 = 0;
        if (args.len > 1) {
            var k: usize = args.len;
            while (k > 1) {
                k -= 1;
                const arg = args[k];
                const arg_ty = gen.air.typeOf(arg, ip);
                const size = try gen.scalarSize(arg_ty);
                const loc = try gen.locOf(arg);
                if (gen.arch == .mcs251) {
                    var i: u32 = size;
                    while (i > 0) {
                        i -= 1; // 大端：先压最高字节
                        try gen.loadByteToA(loc, i, size);
                        try gen.addInst(.push, &.{.{ .dir8 = .{ .symbol = "acc" } }});
                        gen.pushed += 1;
                        total_pushed += 1;
                    }
                } else {
                    var i: u32 = 0;
                    while (i < size) : (i += 1) { // MCS-51 小端：先压最低字节
                        try gen.loadByteToA(loc, i, size);
                        try gen.addInst(.push, &.{.{ .dir8 = .{ .symbol = "acc" } }});
                        total_pushed += 1;
                    }
                }
            }
        }

        // 2) 首个标量参数装入 ABI 寄存器组。
        if (args.len > 0) {
            const arg = args[0];
            const size = try gen.scalarSize(gen.air.typeOf(arg, ip));
            const loc = try gen.locOf(arg);
            const dst_regs = abi.byteRegisters(abi.classifySize(size));
            var i: u32 = 0;
            while (i < size) : (i += 1) {
                try gen.loadByteToA(loc, i, size);
                const dr = byteRegToRegister(dst_regs[i]);
                if (!isRegisterA(dr)) try gen.addInst(.mov, &.{ .{ .reg = dr }, .{ .reg = .a } });
            }
        }

        // 3) 调用：直接用符号；间接先把目标装入 DR28。
        if (direct) {
            try gen.addInst(if (gen.arch == .mcs251) .ecall else .lcall, &.{
                .{ .code = .{ .symbol = symbol } },
            });
        } else {
            if (gen.arch != .mcs251) return gen.fail(
                "mcs backend: indirect calls on MCS-51 are not implemented yet",
                .{},
            );
            try gen.loadCallTarget(call.callee);
            try gen.addInst(.ecall, &.{.{ .at_dr = 7 }});
        }

        // 4) 退栈（调用者清理）。
        if (total_pushed != 0) {
            if (gen.arch == .mcs251) {
                try appendAdjust(&gen.mir, gen.gpa, .dec, total_pushed);
                gen.pushed -= @intCast(total_pushed);
            } else {
                try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = .sp } });
                try gen.addInst(.clr, &.{.{ .reg = .cy }});
                try gen.addInst(.subb, &.{
                    .{ .reg = .a },
                    .{ .imm = .{ .value = @intCast(total_pushed), .bits = 8 } },
                });
                try gen.addInst(.mov, &.{ .{ .reg = .sp }, .{ .reg = .a } });
            }
        }

        // 5) 返回值搬到结果位置。
        const ret_ty = fn_ty.fnReturnType(zcu);
        const dst_opt: ?MCValue = switch (gen.vals[@intFromEnum(inst)]) {
            .none => null,
            else => |v| v,
        };
        if (dst_opt) |dst| {
            if (!ret_ty.hasRuntimeBits(zcu)) return;
            const ret_class = abi.classify(ret_ty, zcu);
            if (ret_class.primary == .memory) return gen.fail(
                "mcs backend: aggregate call results are not implemented yet",
                .{},
            );
            const size: u32 = ret_class.size;
            const src_regs = abi.byteRegisters(ret_class.primary);
            if (size == 4) try gen.storeA(dst, 3, size);
            var i: u32 = 0;
            while (i < size) : (i += 1) {
                if (size == 4 and i == 3) continue;
                const sr = byteRegToRegister(src_regs[i]);
                if (!isRegisterA(sr)) try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = sr } });
                try gen.storeA(dst, i, size);
            }
        }
    }

    // --- 比较 ---------------------------------------------------------------

    fn emitCmp(gen: *Gen, inst: Air.Inst.Index, tag: Air.Inst.Tag) codegen.CodeGenError!void {
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const lhs_ty = gen.air.typeOf(bin.lhs, &gen.zcu.intern_pool);
        const class = abi.classify(lhs_ty, gen.zcu);
        if (class.is_aggregate or class.size == 0 or class.size > 4) return gen.fail(
            "mcs backend: only 1-4 byte integer comparisons are implemented yet",
            .{},
        );
        const size: u32 = class.size;
        const lhs = try gen.locOf(bin.lhs);
        const rhs = try gen.locOf(bin.rhs);
        const dst = gen.vals[@intFromEnum(inst)];

        switch (tag) {
            .cmp_eq, .cmp_neq => {
                // 逐字节异或并累加到 R6：全零即为相等。
                var i: u32 = 0;
                while (i < size) : (i += 1) {
                    try gen.loadByteToA(lhs, i, size);
                    try gen.applyByte(.xrl, rhs, i, size, false);
                    if (i == 0) {
                        try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 6 } }, .{ .reg = .a } });
                    } else {
                        try gen.addInst(.orl, &.{ .{ .reg = .a }, .{ .reg = .{ .r = 6 } } });
                        try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 6 } }, .{ .reg = .a } });
                    }
                }

                const zero_label = gen.newLabel();
                const done_label = gen.newLabel();
                try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = .{ .r = 6 } } });
                try gen.addInst(.jz, &.{.{ .code = .{ .local_label = zero_label } }});
                try gen.setABool(tag == .cmp_neq);
                try gen.jmpFar(done_label);
                try gen.mir.addLabel(gen.gpa, zero_label);
                try gen.setABool(tag == .cmp_eq);
                try gen.mir.addLabel(gen.gpa, done_label);
                try gen.storeA(dst, 0, 1);
            },
            .cmp_lt, .cmp_lte, .cmp_gt, .cmp_gte => {
                // 计算 a - b，借位 CY 表示 a < b；有符号先把两边最高字节符号位取反。
                const signed = lhs_ty.isSignedInt(gen.zcu);
                var a = lhs;
                var b = rhs;
                var invert = false;
                switch (tag) {
                    .cmp_lt => {
                        a = lhs;
                        b = rhs;
                        invert = false;
                    },
                    .cmp_gte => {
                        a = lhs;
                        b = rhs;
                        invert = true;
                    },
                    .cmp_gt => {
                        a = rhs;
                        b = lhs;
                        invert = false;
                    },
                    .cmp_lte => {
                        a = rhs;
                        b = lhs;
                        invert = true;
                    },
                    else => unreachable,
                }

                try gen.addInst(.clr, &.{.{ .reg = .cy }});
                var i: u32 = 0;
                while (i < size) : (i += 1) {
                    try gen.loadByteToA(a, i, size);
                    const msb = signed and i == size - 1;
                    if (msb) try gen.addInst(.xrl, &.{
                        .{ .reg = .a },
                        .{ .imm = .{ .value = 0x80, .bits = 8 } },
                    });
                    if (msb) {
                        try gen.subbSignFlippedByte(b, i, size);
                    } else {
                        try gen.applyByte(.subb, b, i, size, false);
                    }
                }
                try gen.addInst(.clr, &.{.{ .reg = .a }});
                try gen.addInst(.addc, &.{ .{ .reg = .a }, .{ .imm = .{ .value = 0, .bits = 8 } } });
                if (invert) try gen.addInst(.xrl, &.{
                    .{ .reg = .a },
                    .{ .imm = .{ .value = 1, .bits = 8 } },
                });
                try gen.storeA(dst, 0, 1);
            },
            else => unreachable,
        }
    }

    /// 对 A 执行 `subb A, (b_i ^ 0x80)`，用于有符号比较的最高字节。
    fn subbSignFlippedByte(gen: *Gen, b: Loc, i: u32, size: u32) codegen.CodeGenError!void {
        switch (b) {
            .imm => |v| {
                const byte: u8 = @truncate(v >> @intCast(8 * i));
                try gen.addInst(.subb, &.{
                    .{ .reg = .a },
                    .{ .imm = .{ .value = byte ^ 0x80, .bits = 8 } },
                });
            },
            .frame => |disp| {
                try gen.addInst(.mov, &.{
                    .{ .reg = .{ .r = 7 } },
                    gen.frameOperand(gen.slotByte(disp, i, size)),
                });
                try gen.addInst(.xrl, &.{
                    .{ .reg = .{ .r = 7 } },
                    .{ .imm = .{ .value = 0x80, .bits = 8 } },
                });
                try gen.addInst(.subb, &.{ .{ .reg = .a }, .{ .reg = .{ .r = 7 } } });
            },
            .regs => |p| {
                const r = byteRegToRegister(abi.byteRegisters(p)[i]);
                if (isRegisterA(r)) return gen.fail(
                    "mcs backend: accumulator as signed comparison operand is not implemented yet",
                    .{},
                );
                try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 7 } }, .{ .reg = r } });
                try gen.addInst(.xrl, &.{
                    .{ .reg = .{ .r = 7 } },
                    .{ .imm = .{ .value = 0x80, .bits = 8 } },
                });
                try gen.addInst(.subb, &.{ .{ .reg = .a }, .{ .reg = .{ .r = 7 } } });
            },
            .acc => return gen.fail(
                "mcs backend: accumulator as signed comparison operand is not implemented yet",
                .{},
            ),
        }
    }

    // --- switch -------------------------------------------------------------

    /// 条件 `!= value` 则跳到 `label`。
    fn emitNeJumpImm(
        gen: *Gen,
        cond: Loc,
        value: u64,
        size: u32,
        label: u32,
    ) codegen.CodeGenError!void {
        var i: u32 = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(cond, i, size);
            try gen.addInst(.xrl, &.{
                .{ .reg = .a },
                .{ .imm = .{ .value = @intCast((value >> @intCast(8 * i)) & 0xff), .bits = 8 } },
            });
            if (i == 0) {
                try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 6 } }, .{ .reg = .a } });
            } else {
                try gen.addInst(.orl, &.{ .{ .reg = .a }, .{ .reg = .{ .r = 6 } } });
                try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 6 } }, .{ .reg = .a } });
            }
        }
        const skip = gen.newLabel();
        try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = .{ .r = 6 } } });
        try gen.addInst(.jz, &.{.{ .code = .{ .local_label = skip } }});
        try gen.jmpFar(label);
        try gen.mir.addLabel(gen.gpa, skip);
    }

    /// 条件 `== value` 则跳到 `label`。
    fn emitEqJumpImm(
        gen: *Gen,
        cond: Loc,
        value: u64,
        size: u32,
        label: u32,
    ) codegen.CodeGenError!void {
        var i: u32 = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(cond, i, size);
            try gen.addInst(.xrl, &.{
                .{ .reg = .a },
                .{ .imm = .{ .value = @intCast((value >> @intCast(8 * i)) & 0xff), .bits = 8 } },
            });
            if (i == 0) {
                try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 6 } }, .{ .reg = .a } });
            } else {
                try gen.addInst(.orl, &.{ .{ .reg = .a }, .{ .reg = .{ .r = 6 } } });
                try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 6 } }, .{ .reg = .a } });
            }
        }
        const skip = gen.newLabel();
        try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = .{ .r = 6 } } });
        try gen.addInst(.jnz, &.{.{ .code = .{ .local_label = skip } }});
        try gen.jmpFar(label);
        try gen.mir.addLabel(gen.gpa, skip);
    }

    /// `lo <= cond <= hi` 则跳到 `label`（无符号）。
    fn emitRangeJump(
        gen: *Gen,
        cond: Loc,
        lo: u64,
        hi: u64,
        size: u32,
        label: u32,
    ) codegen.CodeGenError!void {
        const skip = gen.newLabel();
        try gen.addInst(.clr, &.{.{ .reg = .cy }});
        var i: u32 = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(cond, i, size);
            try gen.applyByte(.subb, .{ .imm = lo }, i, size, false);
        }
        try gen.addInst(.jc, &.{.{ .code = .{ .local_label = skip } }});
        try gen.addInst(.clr, &.{.{ .reg = .cy }});
        i = 0;
        while (i < size) : (i += 1) {
            try gen.addInst(.mov, &.{
                .{ .reg = .a },
                .{ .imm = .{ .value = @intCast((hi >> @intCast(8 * i)) & 0xff), .bits = 8 } },
            });
            try gen.applyByte(.subb, cond, i, size, false);
        }
        try gen.addInst(.jc, &.{.{ .code = .{ .local_label = skip } }});
        try gen.jmpFar(label);
        try gen.mir.addLabel(gen.gpa, skip);
    }

    fn emitSwitch(gen: *Gen, inst: Air.Inst.Index, is_loop: bool) codegen.CodeGenError!void {
        const sw = gen.air.unwrapSwitch(inst);
        const cond_ty = gen.air.typeOf(sw.operand, &gen.zcu.intern_pool);
        const size = try gen.scalarSize(cond_ty);
        const end_label = gen.newLabel();

        var cond: Loc = undefined;
        if (is_loop) {
            const info = gen.switch_info.get(inst).?;
            try gen.moveValue(try gen.locOf(sw.operand), .{ .frame = info.cond_disp }, size);
            try gen.mir.addLabel(gen.gpa, info.dispatch);
            cond = .{ .frame = info.cond_disp };
        } else {
            cond = try gen.locOf(sw.operand);
        }

        var labels: std.ArrayListUnmanaged(u32) = .empty;
        defer labels.deinit(gen.gpa);
        try labels.ensureTotalCapacity(gen.gpa, sw.cases_len);
        var c: u32 = 0;
        while (c < sw.cases_len) : (c += 1) labels.appendAssumeCapacity(gen.newLabel());
        const else_label = gen.newLabel();

        var it = sw.iterateCases();
        while (it.next()) |case| {
            const label = labels.items[case.idx];
            for (case.items) |item| {
                const interned = item.toInterned() orelse return gen.fail(
                    "mcs backend: non-comptime switch case is not implemented yet",
                    .{},
                );
                const v = gen.getConstBits(interned) orelse return gen.fail(
                    "mcs backend: unsupported switch case value",
                    .{},
                );
                try gen.emitEqJumpImm(cond, v, size, label);
            }
            for (case.ranges) |r| {
                const lo_i = r[0].toInterned() orelse return gen.fail("mcs backend: bad switch range", .{});
                const hi_i = r[1].toInterned() orelse return gen.fail("mcs backend: bad switch range", .{});
                const lo = gen.getConstBits(lo_i) orelse return gen.fail("mcs backend: unsupported switch range", .{});
                const hi = gen.getConstBits(hi_i) orelse return gen.fail("mcs backend: unsupported switch range", .{});
                try gen.emitRangeJump(cond, lo, hi, size, label);
            }
        }
        try gen.jmpFar(else_label);

        it = sw.iterateCases();
        while (it.next()) |case| {
            try gen.mir.addLabel(gen.gpa, labels.items[case.idx]);
            try gen.emitBody(case.body);
            try gen.jmpFar(end_label);
        }
        try gen.mir.addLabel(gen.gpa, else_label);
        try gen.emitBody(it.elseBody());
        try gen.mir.addLabel(gen.gpa, end_label);
    }

    // --- 参数与返回 ---------------------------------------------------------

    fn emitArg(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const arg_index = gen.emit_arg_cursor;
        gen.emit_arg_cursor += 1;

        const ty = gen.air.typeOfIndex(inst, &gen.zcu.intern_pool);
        const class = abi.classify(ty, gen.zcu);
        const size: u32 = class.size;

        if (arg_index == 0) {
            // 把 ABI 寄存器值写入帧槽；指针参数存到 .ptr_rt.addr 指向的 3 字节槽位。
            const mcv = gen.vals[@intFromEnum(inst)];
            const frame: MCValue = switch (mcv) {
                .ptr_rt => |pr| .{ .frame = pr.addr },
                else => mcv,
            };
            if (size == 4) try gen.storeA(frame, 3, size);
            var i: u32 = 0;
            while (i < size) : (i += 1) {
                if (size == 4 and i == 3) continue;
                try gen.loadByteToA(.{ .regs = class.primary }, i, size);
                try gen.storeA(frame, i, size);
            }
            return;
        }

        if (gen.arch == .mcs251) return; // 栈参数在内存中，直接按 `@spx` 读取

        // MCS-51：R0 = SP - (2 + Σsize)，逐字节复制到静态帧。
        const off = gen.m51_incoming.get(inst).?;
        const frame = gen.vals[@intFromEnum(inst)];
        try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .reg = .sp } });
        try gen.addInst(.clr, &.{.{ .reg = .cy }});
        try gen.addInst(.subb, &.{
            .{ .reg = .a },
            .{ .imm = .{ .value = @intCast(off), .bits = 8 } },
        });
        try gen.addInst(.mov, &.{ .{ .reg = .{ .r = 0 } }, .{ .reg = .a } });
        var i: u32 = 0;
        while (i < size) : (i += 1) {
            try gen.addInst(.mov, &.{ .{ .reg = .a }, .{ .at_ri = 0 } });
            try gen.storeA(frame, i, size);
            if (i + 1 < size) try gen.addInst(.inc, &.{.{ .reg = .{ .r = 0 } }});
        }
    }

    fn emitBinOp(gen: *Gen, inst: Air.Inst.Index, op: encode.Mnemonic) codegen.CodeGenError!void {
        const bin = gen.air.instructions.items(.data)[@intFromEnum(inst)].bin_op;
        const lhs_ty = gen.air.typeOf(bin.lhs, &gen.zcu.intern_pool);
        const class = abi.classify(lhs_ty, gen.zcu);
        if (class.is_aggregate or class.size == 0 or class.size > 4) return gen.fail(
            "mcs backend: only 1-4 byte integer arithmetic is implemented yet",
            .{},
        );
        const size: u32 = class.size;

        const lhs = try gen.locOf(bin.lhs);
        const rhs = try gen.locOf(bin.rhs);
        const dst = gen.vals[@intFromEnum(inst)];

        if (op == .subb) try gen.addInst(.clr, &.{.{ .reg = .cy }});

        var i: u32 = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(lhs, i, size);
            try gen.applyByte(op, rhs, i, size, i == 0);
            try gen.storeA(dst, i, size);
        }
    }

    fn airRet(gen: *Gen, inst: Air.Inst.Index) codegen.CodeGenError!void {
        const operand = gen.air.instructions.items(.data)[@intFromEnum(inst)].un_op;
        const ret_class = gen.ret_class;

        if (ret_class.primary == .none or ret_class.size == 0) {
            try gen.finishReturn();
            return;
        }
        if (ret_class.primary == .memory) return gen.fail(
            "mcs backend: aggregate or oversized return value is not implemented yet",
            .{},
        );

        const size: u32 = ret_class.size;
        const dst_regs = abi.byteRegisters(ret_class.primary);
        const loc = try gen.locOf(operand);

        var i: u32 = 0;
        while (i < size) : (i += 1) {
            try gen.loadByteToA(loc, i, size);
            const dr = byteRegToRegister(dst_regs[i]);
            if (!isRegisterA(dr)) try gen.addInst(.mov, &.{ .{ .reg = dr }, .{ .reg = .a } });
        }

        try gen.finishReturn();
    }

    fn finishReturn(gen: *Gen) !void {
        if (gen.frameBytes() != 0) {
            try gen.epilogue_sites.append(gen.gpa, gen.mir.items.items.len);
        }
        try gen.addReturn();
    }

    fn genBody(gen: *Gen, body: []const Air.Inst.Index) codegen.CodeGenError!void {
        try gen.preallocBody(body);
        gen.resolveIncoming();
        try gen.emitMcs51Frame();
        try gen.emitBody(body);
    }

    /// MCS-51：在函数开头声明静态 idata 帧。
    fn emitMcs51Frame(gen: *Gen) codegen.CodeGenError!void {
        if (gen.arch == .mcs251) return;
        const frame_size = gen.frameBytes();
        if (frame_size == 0) return;

        const sym = try std.fmt.allocPrint(gen.gpa, "_frk{d}", .{@intFromEnum(gen.func_index)});
        try gen.mir.addOwned(gen.gpa, sym);
        gen.frame_sym = sym;
        try gen.mir.addRaw(gen.gpa, "\t.area DSEG");

        const label = try std.fmt.allocPrint(gen.gpa, "{s}:", .{sym});
        try gen.mir.addOwned(gen.gpa, label);
        try gen.mir.addRaw(gen.gpa, label);

        const ds = try std.fmt.allocPrint(gen.gpa, "\t.ds {d}", .{frame_size});
        try gen.mir.addOwned(gen.gpa, ds);
        try gen.mir.addRaw(gen.gpa, ds);
        try gen.mir.addRaw(gen.gpa, "\t.area CSEG    (CODE)");
    }

    fn finish(gen: *Gen) !Mir {
        const frame_size = gen.frameBytes();
        var out: Mir = .{};
        errdefer out.deinit(gen.gpa);

        out.owned = gen.mir.owned;
        gen.mir.owned = .empty;

        const spx_frame = gen.arch == .mcs251 and frame_size != 0;
        if (spx_frame) try appendAdjust(&out, gen.gpa, .inc, frame_size);

        var site_idx: usize = 0;
        for (gen.mir.items.items, 0..) |item, idx| {
            if (spx_frame and
                site_idx < gen.epilogue_sites.items.len and
                gen.epilogue_sites.items[site_idx] == idx)
            {
                try appendAdjust(&out, gen.gpa, .dec, frame_size);
                site_idx += 1;
            }
            try out.items.append(gen.gpa, item);
        }

        return out;
    }
};

/// 发出 `inc/dec spx` 序列：以 4 字节为主，余下 2、1。
fn appendAdjust(mir: *Mir, gpa: std.mem.Allocator, mnemonic: encode.Mnemonic, amount: u32) !void {
    var remaining = amount;
    while (remaining >= 4) {
        try mir.addInst(gpa, mnemonic, &.{
            .{ .reg = .spx },
            .{ .imm = .{ .value = 4, .bits = 8 } },
        });
        remaining -= 4;
    }
    if (remaining >= 2) {
        try mir.addInst(gpa, mnemonic, &.{
            .{ .reg = .spx },
            .{ .imm = .{ .value = 2, .bits = 8 } },
        });
        remaining -= 2;
    }
    if (remaining != 0) {
        try mir.addInst(gpa, mnemonic, &.{.{ .reg = .spx }});
    }
}

fn byteRegToRegister(b: abi.ByteReg) encode.Register {
    return switch (b) {
        .dpl => .dpl,
        .dph => .dph,
        .b => .b,
        .a => .a,
    };
}

fn isRegisterA(r: encode.Register) bool {
    return switch (r) {
        .a => true,
        else => false,
    };
}

/// AIR -> MIR。
pub fn generate(
    bin_file: *link.File,
    pt: Zcu.PerThread,
    src_loc: Zcu.LazySrcLoc,
    func_index: InternPool.Index,
    air: *const Air,
    liveness: *const ?Air.Liveness,
) codegen.CodeGenError!Mir {
    _ = bin_file;
    _ = liveness;
    _ = src_loc;

    const zcu = pt.zcu;
    const gpa = zcu.gpa;

    const func = zcu.funcInfo(func_index);
    const func_ty = Type.fromInterned(func.ty);
    const ret_ty = func_ty.fnReturnType(zcu);

    const vals = try gpa.alloc(MCValue, air.instructions.len);
    defer gpa.free(vals);
    @memset(vals, .none);

    var gen: Gen = .{
        .gpa = gpa,
        .pt = pt,
        .zcu = zcu,
        .air = air,
        .func_index = func_index,
        .owner_nav = func.owner_nav,
        .arch = zcu.getTarget().cpu.arch,
        .ret_class = abi.classify(ret_ty, zcu),
        .vals = vals,
    };
    errdefer {
        gen.mir.deinit(gpa);
        gen.epilogue_sites.deinit(gpa);
        gen.block_info.deinit(gpa);
        gen.switch_info.deinit(gpa);
        gen.extra_slots.deinit(gpa);
        gen.m51_incoming.deinit(gpa);
    }

    try gen.genBody(air.getMainBody());

    const result = try gen.finish();
    gen.mir.deinit(gpa);
    gen.epilogue_sites.deinit(gpa);
    gen.block_info.deinit(gpa);
    gen.switch_info.deinit(gpa);
    gen.extra_slots.deinit(gpa);
    gen.m51_incoming.deinit(gpa);
    return result;
}

/// 延迟符号（编译器内置函数等）生成。
pub fn generateLazy(
    bin_file: *link.File,
    pt: Zcu.PerThread,
    src_loc: Zcu.LazySrcLoc,
    lazy_sym: link.File.LazySymbol,
    atom_index: u32,
    w: *std.Io.Writer,
    debug_output: link.File.DebugInfoOutput,
) (codegen.CodeGenError || std.Io.Writer.Error)!void {
    _ = bin_file;
    _ = src_loc;
    _ = atom_index;
    _ = w;
    _ = debug_output;
    return pt.zcu.codegenFailType(
        lazy_sym.ty,
        "mcs backend: lazy symbols (compiler builtins) are not implemented yet",
        .{},
    );
}
