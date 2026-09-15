//! cobs.zig —— 平台无关的 **COBS**（Consistent Overhead Byte Stuffing）编码器 +
//! 轻量二进制日志帧（defmt 风格）。Zig 接口。
//!
//! 设计要点：
//! - **只负责“把字节写进用户缓冲区”**：用户提供输出缓冲区指针与容量（`Encoder.init`），
//!   编码结果写在其中；如何输出（UART / USB / 环形队列 / 测试）完全由调用方决定。
//! - **零平台依赖**：不使用 SFR、内联汇编、std、堆分配；可编到 mcs51 / mcs251 / 主机。
//! - 与之等价的 C 接口见同目录 `cobs.h` / `cobs.c`（`cobs_enc_t` 句柄，字段布局对应本
//!   文件的 `Encoder`）。
//!
//! ## 可重入（推荐）
//! 状态全部在调用方持有的 `Encoder` 结构体内，可同时存在多个实例：
//! ```zig
//! const cobs = @import("cobs");
//! var buf: [128]u8 = undefined;
//! var e: cobs.Encoder = undefined;
//! e.init(&buf, buf.len);            // 或 e.initRaw(buf.ptr, buf.len)
//! e.logBegin(0x0002);
//! e.logU16(1234);
//! const n = e.logEnd();            // 写校验 + COBS 收尾；n 为可发送长度
//! send(e.data()[0..n]);            // 输出方式由用户决定
//! ```
//!
//! ## 单实例便捷 API
//! 同文件还提供绑定到模块级实例的免句柄版本（`cobs.initRaw` / `cobs.logBegin` / …），
//! 便于单编码器场景；它们就是下面 `s_enc` 的转发。多实例请用 `Encoder`。
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
//! ## 限制 / 约定
//! - 单帧原始内容需能被 `cap` 容下（COBS 最坏开销 ≈ 原始长度 + 原始长度/254 + 1）。
//!   超出时 `overflow()` 置位、`finish()/logEnd()` 返回 0；调用方应据此丢弃该帧。

/// 可重入编码器状态（与 C 版 `cobs_enc_t` 对应）。
pub const Encoder = struct {
    /// 输出缓冲区首地址（用户提供）。
    buf: [*]u8,
    /// 缓冲区容量（字节）。
    cap: u16,
    /// 已写入字节数。
    len: u16,
    /// 当前块长度码位置。
    code_pos: u16,
    /// 当前块长度码（块内字节数 + 1）。
    code: u8,
    /// 日志帧 XOR 校验累加。
    ck: u8,
    /// 缓冲区不足置位。
    overflowed: bool,

    /// 绑定输出缓冲区（指针 + 容量），并重置。
    pub fn initRaw(e: *Encoder, buf: [*]u8, cap: u16) void {
        e.buf = buf;
        e.cap = cap;
        e.reset();
    }

    /// 绑定输出缓冲区（切片形式），并重置。
    pub fn init(e: *Encoder, buf: []u8) void {
        e.initRaw(buf.ptr, @intCast(buf.len));
    }

    /// 重置为一帧开始：清长度、预留首个长度码占位、清校验。
    pub fn reset(e: *Encoder) void {
        e.len = 0;
        e.code = 1;
        e.code_pos = 0;
        e.ck = 0;
        e.overflowed = false;
        if (e.cap == 0) {
            e.overflowed = true;
            return;
        }
        e.buf[0] = 0;
        e.len = 1;
    }

    /// 追加一个原始字节，做 **COBS** 编码（遇 `0x00` / 满 254 字节即封块）。
    pub fn add(e: *Encoder, b: u8) void {
        if (b == 0) {
            e.patchCode();
            e.beginBlock(1);
            return;
        }
        if (e.code == 255) {
            e.patchCode();
            e.beginBlock(1);
        }
        if (e.len >= e.cap) {
            e.overflowed = true;
            return;
        }
        e.buf[e.len] = b;
        e.len += 1;
        e.code +%= 1;
    }

    /// 收尾：回填最后的长度码、追加 `0x00` 定界符，返回编码后总长度（含定界符）。
    /// 缓冲区不足时返回 0（并置 `overflow`）。
    pub fn finish(e: *Encoder) u16 {
        e.patchCode();
        if (e.len >= e.cap) {
            e.overflowed = true;
            return 0;
        }
        e.buf[e.len] = 0x00;
        e.len += 1;
        return if (e.overflowed) 0 else e.len;
    }

    /// 编码结果的缓冲区首地址。
    pub fn data(e: *Encoder) [*]u8 {
        return e.buf;
    }

    /// 编码结果长度（上一次 `finish`/`logEnd` 之后）。
    pub fn length(e: *Encoder) u16 {
        return e.len;
    }

    /// 是否发生过缓冲区不足。
    pub fn overflow(e: *Encoder) bool {
        return e.overflowed;
    }

    // ---- 日志帧 ----

    /// 开始一帧：重置，写 `0x7E` 与 16 位 `id`（小端）。
    pub fn logBegin(e: *Encoder, id: u16) void {
        e.reset();
        e.add(0x7e);
        const il: u8 = @truncate(id);
        const ih: u8 = @truncate(id >> 8);
        e.add(il);
        e.add(ih);
        e.ck = il ^ ih;
    }

    /// 追加一个原始字节（已计入 XOR 校验）。
    pub fn logRaw(e: *Encoder, b: u8) void {
        e.add(b);
        e.ck ^= b;
    }

    /// 追加 `u8`。
    pub fn logU8(e: *Encoder, v: u8) void {
        e.logRaw(v);
    }

    /// 追加 `u16`（小端）。
    pub fn logU16(e: *Encoder, v: u16) void {
        e.logRaw(@truncate(v));
        e.logRaw(@truncate(v >> 8));
    }

    /// 追加 `u32`（小端）。
    pub fn logU32(e: *Encoder, v: u32) void {
        e.logRaw(@truncate(v));
        e.logRaw(@truncate(v >> 8));
        e.logRaw(@truncate(v >> 16));
        e.logRaw(@truncate(v >> 24));
    }

    /// 追加无符号 LEB128（小值省字节）。
    pub fn logVar(e: *Encoder, v: u16) void {
        var x = v;
        while (true) {
            const b: u8 = @truncate(x & 0x7f);
            x >>= 7;
            if (x != 0) {
                e.logRaw(b | 0x80);
            } else {
                e.logRaw(b);
                return;
            }
        }
    }

    /// 追加运行期字节串：`LEB128(len) + 原始字节`。
    pub fn logBytes(e: *Encoder, p: [*]const u8, n: u16) void {
        e.logVar(n);
        var i: u16 = 0;
        while (i < n) : (i += 1) e.logRaw(p[i]);
    }

    /// 追加编译期字符串：`LEB128(len) + 字节`。
    pub fn logStr(e: *Encoder, comptime s: []const u8) void {
        e.logVar(@intCast(s.len));
        inline for (s) |c| e.logRaw(c);
    }

    /// 结束一帧：写 XOR 校验并 COBS 收尾（末尾 `0x00`）。返回编码后长度；不足返回 0。
    pub fn logEnd(e: *Encoder) u16 {
        e.logRaw(e.ck);
        return e.finish();
    }

    // ---- 内部 ----

    fn patchCode(e: *Encoder) void {
        if (e.code_pos < e.len) e.buf[e.code_pos] = e.code;
    }

    fn beginBlock(e: *Encoder, code: u8) void {
        if (e.len >= e.cap) {
            e.overflowed = true;
            return;
        }
        e.code_pos = e.len;
        e.buf[e.len] = 0; // 新块长度码占位
        e.len += 1;
        e.code = code;
    }
};

// ---------------------------------------------------------------------------
// 单实例便捷 API（绑定到模块级 `s_enc`；多实例请直接用 `Encoder`）
// ---------------------------------------------------------------------------

var s_enc: Encoder = undefined;

/// 绑定输出缓冲区（指针 + 容量），并重置。
pub inline fn initRaw(buf: [*]u8, cap: u16) void {
    s_enc.initRaw(buf, cap);
}

/// 绑定输出缓冲区（切片形式），并重置。
pub inline fn init(buf: []u8) void {
    s_enc.init(buf);
}

/// 重置为一帧开始：清长度、预留首个长度码占位、清校验。
pub inline fn reset() void {
    s_enc.reset();
}

/// 追加一个原始字节，做 **COBS** 编码（遇 `0x00` / 满 254 字节即封块）。
pub inline fn add(b: u8) void {
    s_enc.add(b);
}

/// 收尾：回填最后的长度码、追加 `0x00` 定界符，返回编码后总长度（含定界符）。
/// 缓冲区不足时返回 0（并置 `overflow`）。
pub inline fn finish() u16 {
    return s_enc.finish();
}

/// 一次性编码 `in[0..in_len)` 到 `out`（容量 `out_cap`）；返回长度或 0（不足）。
/// 注意：会复用并覆盖模块状态（单实例）；多实例请用 `Encoder`。
pub inline fn encode(in: [*]const u8, in_len: u16, out: [*]u8, out_cap: u16) u16 {
    s_enc.initRaw(out, out_cap);
    var i: u16 = 0;
    while (i < in_len) : (i += 1) s_enc.add(in[i]);
    return s_enc.finish();
}

/// 编码结果的缓冲区首地址。
pub inline fn data() [*]u8 {
    return s_enc.data();
}

/// 编码结果长度（上一次 `finish`/`logEnd` 之后）。
pub inline fn length() u16 {
    return s_enc.length();
}

/// 是否发生过缓冲区不足。
pub inline fn overflow() bool {
    return s_enc.overflow();
}

/// 开始一帧：重置，写 `0x7E` 与 16 位 `id`（小端）。
pub inline fn logBegin(id: u16) void {
    s_enc.logBegin(id);
}

/// 追加一个原始字节（已计入 XOR 校验）。
pub inline fn logRaw(b: u8) void {
    s_enc.logRaw(b);
}

/// 追加 `u8`。
pub inline fn logU8(v: u8) void {
    s_enc.logU8(v);
}

/// 追加 `u16`（小端）。
pub inline fn logU16(v: u16) void {
    s_enc.logU16(v);
}

/// 追加 `u32`（小端）。
pub inline fn logU32(v: u32) void {
    s_enc.logU32(v);
}

/// 追加无符号 LEB128（小值省字节）。
pub inline fn logVar(v: u16) void {
    s_enc.logVar(v);
}

/// 追加运行期字节串：`LEB128(len) + 原始字节`。
pub inline fn logBytes(p: [*]const u8, n: u16) void {
    s_enc.logBytes(p, n);
}

/// 追加编译期字符串：`LEB128(len) + 字节`。
pub inline fn logStr(comptime s: []const u8) void {
    s_enc.logStr(s);
}

/// 结束一帧：写 XOR 校验并 COBS 收尾（末尾 `0x00`）。返回编码后长度；不足返回 0。
pub inline fn logEnd() u16 {
    return s_enc.logEnd();
}
