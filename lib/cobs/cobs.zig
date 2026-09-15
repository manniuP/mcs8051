//! cobs.zig —— 平台无关的 **COBS**（Consistent Overhead Byte Stuffing）编码器 +
//! 轻量二进制日志帧（defmt 风格）。Zig 接口。
//!
//! 设计要点：
//! - **只负责“把字节写进用户缓冲区”**：用户提供输出缓冲区指针与容量（`init`），编码结果
//!   写在其中；如何输出（UART / USB / 环形队列 / 测试）完全由调用方决定。
//! - **零平台依赖**：不使用 SFR、内联汇编、std、堆分配；可编到 mcs51 / mcs251 / 主机。
//! - 与之等价的 C 接口见同目录 `cobs.h` / `cobs.c`（C 版为可重入的“结构体 + 显式句柄”
//!   形式；本 Zig 版因**当前后端尚不支持结构体字段访问**，采用**单实例模块状态**）。
//!
//! ## 单实例限制（重要）
//! 本接口用模块级变量保存一份编码器状态，**同一时刻只支持一个编码器**。若要多个实例，
//! 等后端支持结构体字段访问后，可把状态改为调用方持有的 `Encoder` 结构体（与 C 版对齐）。
//!
//! ## COBS 简述
//! 编码后**不出现 `0x00`**，因此可用单个 `0x00` 作为帧定界符（帧同步、抗错位）。
//! 每块最多 254 个非零字节：先写一个“长度码” = 本块字节数 + 1，再写本块字节；
//! 遇 `0x00` 即封块（该零不写出，由长度码隐含）。本实现直接在用户缓冲区里“先占位、
//! 后回填”长度码，单趟、无第二缓冲区。
//!
//! ## 日志帧格式（原始字节，随后整体 COBS，再以 `0x00` 结束）
//! ```text
//! 0x7E, id_lo, id_hi, 参数…, XOR 校验
//! ```
//! 参数：`u8`=1B、`u16`=2B 小端、`u32`=4B 小端、`logVar`=无符号 LEB128、
//! `logStr`/`logBytes`=`LEB128(len)+原始字节`。主机端 `examples/ai8051u_zig_log/decode.ps1`
//! 按同一张表先 COBS 解码再解析。
//!
//! ## 用法（Zig）
//! ```zig
//! const cobs = @import("cobs");
//! var buf: [128]u8 = undefined;
//! cobs.initRaw(&buf, buf.len);      // 绑定用户缓冲区
//!
//! cobs.logBegin(0x0002);            // 每帧开始：重置 + 写 id
//! cobs.logU16(1234);
//! const n = cobs.logEnd();          // 写校验 + COBS 收尾；n 为可发送长度
//! send(cobs.data()[0..n]);          // 输出方式由用户决定
//! ```
//!
//! ## 限制 / 约定
//! - 单帧原始内容需能被 `cap` 容下（COBS 最坏开销 ≈ 原始长度 + 原始长度/254 + 1）。
//!   超出时 `overflow()` 置位、`finish()/logEnd()` 返回 0；调用方应据此丢弃该帧。
//! - 非可重入（见上“单实例限制”）。

// 模块级状态（单实例）。
var s_buf: [*]u8 = undefined;
var s_cap: u16 = 0;
var s_len: u16 = 0;
var s_code_pos: u16 = 0;
var s_code: u8 = 1;
var s_ck: u8 = 0;
var s_overflow: bool = false;

/// 绑定输出缓冲区（指针 + 容量），并重置。
pub inline fn initRaw(buf: [*]u8, cap: u16) void {
    s_buf = buf;
    s_cap = cap;
    reset();
}

/// 绑定输出缓冲区（切片形式），并重置。
pub inline fn init(buf: []u8) void {
    initRaw(buf.ptr, @intCast(buf.len));
}

/// 重置为一帧开始：清长度、预留首个长度码占位、清校验。
pub inline fn reset() void {
    s_len = 0;
    s_code = 1;
    s_code_pos = 0;
    s_ck = 0;
    s_overflow = false;
    if (s_cap == 0) {
        s_overflow = true;
        return;
    }
    s_buf[0] = 0;
    s_len = 1;
}

/// 追加一个原始字节，做 **COBS** 编码（遇 `0x00` / 满 254 字节即封块）。
pub inline fn add(b: u8) void {
    if (b == 0) {
        patchCode();
        beginBlock(1);
        return;
    }
    if (s_code == 255) {
        patchCode();
        beginBlock(1);
    }
    if (s_len >= s_cap) {
        s_overflow = true;
        return;
    }
    s_buf[s_len] = b;
    s_len += 1;
    s_code +%= 1;
}

/// 收尾：回填最后的长度码、追加 `0x00` 定界符，返回编码后总长度（含定界符）。
/// 缓冲区不足时返回 0（并置 `overflow`）。
pub inline fn finish() u16 {
    patchCode();
    if (s_len >= s_cap) {
        s_overflow = true;
        return 0;
    }
    s_buf[s_len] = 0x00;
    s_len += 1;
    return if (s_overflow) 0 else s_len;
}

/// 一次性编码 `in[0..in_len)` 到 `out`（容量 `out_cap`）；返回长度或 0（不足）。
/// 注意：会复用并覆盖模块状态（单实例）。
pub inline fn encode(in: [*]const u8, in_len: u16, out: [*]u8, out_cap: u16) u16 {
    initRaw(out, out_cap);
    var i: u16 = 0;
    while (i < in_len) : (i += 1) add(in[i]);
    return finish();
}

/// 编码结果的缓冲区首地址。
pub inline fn data() [*]u8 {
    return s_buf;
}

/// 编码结果长度（上一次 `finish`/`logEnd` 之后）。
pub inline fn length() u16 {
    return s_len;
}

/// 是否发生过缓冲区不足。
pub inline fn overflow() bool {
    return s_overflow;
}

// ---------------------------------------------------------------------------
// 内部
// ---------------------------------------------------------------------------

inline fn patchCode() void {
    if (s_code_pos < s_len) s_buf[s_code_pos] = s_code;
}

inline fn beginBlock(code: u8) void {
    if (s_len >= s_cap) {
        s_overflow = true;
        return;
    }
    s_code_pos = s_len;
    s_buf[s_len] = 0; // 新块长度码占位
    s_len += 1;
    s_code = code;
}

// ---------------------------------------------------------------------------
// 轻量二进制日志帧（在 COBS 之上）
// ---------------------------------------------------------------------------

/// 开始一帧：重置，写 `0x7E` 与 16 位 `id`（小端）。
pub inline fn logBegin(id: u16) void {
    reset();
    add(0x7e);
    const il: u8 = @truncate(id);
    const ih: u8 = @truncate(id >> 8);
    add(il);
    add(ih);
    s_ck = il ^ ih;
}

/// 追加一个原始字节（已计入 XOR 校验）。
pub inline fn logRaw(b: u8) void {
    add(b);
    s_ck ^= b;
}

/// 追加 `u8`。
pub inline fn logU8(v: u8) void {
    logRaw(v);
}

/// 追加 `u16`（小端）。
pub inline fn logU16(v: u16) void {
    logRaw(@truncate(v));
    logRaw(@truncate(v >> 8));
}

/// 追加 `u32`（小端）。
pub inline fn logU32(v: u32) void {
    logRaw(@truncate(v));
    logRaw(@truncate(v >> 8));
    logRaw(@truncate(v >> 16));
    logRaw(@truncate(v >> 24));
}

/// 追加无符号 LEB128（小值省字节）。
pub inline fn logVar(v: u16) void {
    var x = v;
    while (true) {
        const b: u8 = @truncate(x & 0x7f);
        x >>= 7;
        if (x != 0) {
            logRaw(b | 0x80);
        } else {
            logRaw(b);
            return;
        }
    }
}

/// 追加运行期字节串：`LEB128(len) + 原始字节`。
pub inline fn logBytes(p: [*]const u8, n: u16) void {
    logVar(n);
    var i: u16 = 0;
    while (i < n) : (i += 1) logRaw(p[i]);
}

/// 追加编译期字符串：`LEB128(len) + 字节`。
pub inline fn logStr(comptime s: []const u8) void {
    logVar(@intCast(s.len));
    inline for (s) |c| logRaw(c);
}

/// 结束一帧：写 XOR 校验并 COBS 收尾（末尾 `0x00`）。返回编码后长度；不足返回 0。
pub inline fn logEnd() u16 {
    logRaw(s_ck);
    return finish();
}
