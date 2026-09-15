//! cobs_zig_test.zig — 主机端往返测试（Zig 实现）。
//! 运行： zig run lib/cobs/cobs_zig_test.zig
const std = @import("std");
const cobs = @import("cobs.zig");

// 用库里的 cobs.decode 做往返校验；解出长度由调用方与期望值比对
// （cobs.decode 返回 0 既可能是空结果也可能是失败，故此处不做 null 判定）。
fn decode(enc: []const u8, out: []u8) usize {
    return cobs.decode(enc.ptr, @intCast(enc.len), out.ptr, @intCast(out.len));
}

fn roundTrip(data: []const u8) !void {
    var enc_buf: [1024]u8 = undefined;
    const n = cobs.encode(data.ptr, @intCast(data.len), &enc_buf, @intCast(enc_buf.len));
    if (n == 0) return error.Overflow;
    var dec: [1024]u8 = undefined;
    const m = decode(enc_buf[0 .. n - 1], &dec); // 去掉结尾 0x00 定界符
    if (m != data.len or !std.mem.eql(u8, data, dec[0..m])) return error.Mismatch;
    var i: usize = 0;
    while (i + 1 < n) : (i += 1) {
        if (enc_buf[i] == 0) return error.ZeroInside; // 编码流内只有末尾定界符允许 0x00
    }
}

fn logRoundTrip() !void {
    var buf: [256]u8 = undefined;
    cobs.initRaw(&buf, @intCast(buf.len));
    cobs.logBegin(0x0002);
    cobs.logU16(0xBEEF);
    cobs.logStr("hi");
    const n = cobs.logEnd();
    if (n == 0) return error.Overflow;

    var dec: [256]u8 = undefined;
    const m = decode(buf[0 .. n - 1], &dec);
    const expect = [_]u8{ 0x7e, 0x02, 0x00, 0xef, 0xbe, 0x02, 'h', 'i' };
    if (m != expect.len + 1) return error.Len;
    if (!std.mem.eql(u8, dec[0..expect.len], &expect)) return error.Frame;
    var ck: u8 = 0;
    for (expect[1..]) |b| ck ^= b; // XOR 不含起始 0x7E（与 logBegin/decode.ps1 一致）
    if (dec[expect.len] != ck) return error.Checksum;
}

/// 用可重入 `Encoder` 编码与上面 `logRoundTrip` 相同的一帧，并逐字节比较两种接口的输出。
fn encoderEqualsModule() !void {
    var buf: [256]u8 = undefined;
    var e: cobs.Encoder = undefined;
    e.init(&buf);
    e.logBegin(0x0002);
    e.logU16(0xBEEF);
    e.logStr("hi");
    const n = e.logEnd();
    if (n == 0) return error.Overflow;

    var buf2: [256]u8 = undefined;
    cobs.initRaw(&buf2, @intCast(buf2.len));
    cobs.logBegin(0x0002);
    cobs.logU16(0xBEEF);
    cobs.logStr("hi");
    const n2 = cobs.logEnd();
    if (n2 != n or !std.mem.eql(u8, buf[0..n], buf2[0..n2])) return error.EncoderMismatch;
}

/// 两个 `Encoder` 实例交叉使用，验证可重入（模块级 API 只有一个实例做不到）。
fn twoEncoders() !void {
    var b1: [64]u8 = undefined;
    var b2: [64]u8 = undefined;
    var e1: cobs.Encoder = undefined;
    var e2: cobs.Encoder = undefined;
    e1.init(&b1);
    e2.init(&b2);

    e1.logBegin(0x0001);
    e1.logU8(0xAA);
    e2.logBegin(0x0002);
    e2.logU8(0xBB);
    const n1 = e1.logEnd();
    const n2 = e2.logEnd();
    if (n1 == 0 or n2 == 0) return error.Overflow;

    var d1: [64]u8 = undefined;
    var d2: [64]u8 = undefined;
    const m1 = decode(b1[0 .. n1 - 1], &d1);
    const m2 = decode(b2[0 .. n2 - 1], &d2);
    const want1 = [_]u8{ 0x7e, 0x01, 0x00, 0xAA };
    const want2 = [_]u8{ 0x7e, 0x02, 0x00, 0xBB };
    if (m1 != want1.len + 1 or !std.mem.eql(u8, d1[0..want1.len], &want1)) return error.Frame1;
    if (m2 != want2.len + 1 or !std.mem.eql(u8, d2[0..want2.len], &want2)) return error.Frame2;
}

pub fn main() !void {
    const cases = [_][]const u8{
        &.{}, &.{0}, &.{ 0, 0, 0 }, &.{ 0x11, 0, 0 }, &.{ 0x11, 0x22 }, &.{ 0x11, 0, 0x22 },
    };
    for (cases) |c| try roundTrip(c);
    try logRoundTrip();
    try encoderEqualsModule();
    try twoEncoders();

    var seed: u32 = 1234;
    var t: u32 = 1;
    while (t <= 800) : (t += 1) {
        seed = seed *% 1664525 +% 1013904223;
        const len: usize = seed % (t + 1);
        var data: [1024]u8 = undefined;
        var i: usize = 0;
        while (i < len) : (i += 1) {
            seed = seed *% 1664525 +% 1013904223;
            data[i] = if ((seed & 1) == 0) 0 else @truncate(seed >> 8);
        }
        if (len > 260) for (data[0..len]) |*b| {
            b.* = 0xAA;
        };
        try roundTrip(data[0..len]);
    }
    std.debug.print("zig cobs: ALL OK\n", .{});
}
