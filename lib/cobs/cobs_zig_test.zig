//! cobs_zig_test.zig — 主机端往返测试（Zig 实现）。
//! 运行： zig run lib/cobs/cobs_zig_test.zig
const std = @import("std");
const cobs = @import("cobs.zig");

fn decode(enc: []const u8, out: []u8) ?usize {
    var idx: usize = 0;
    var o: usize = 0;
    const n = enc.len;
    while (idx < n) {
        const code: usize = enc[idx];
        idx += 1;
        if (code == 0) return null;
        var k: usize = 1;
        while (k < code) : (k += 1) {
            if (idx >= n or o >= out.len) return null;
            out[o] = enc[idx];
            o += 1;
            idx += 1;
        }
        if (code < 255 and idx < n) {
            if (o >= out.len) return null;
            out[o] = 0;
            o += 1;
        }
    }
    return o;
}

fn roundTrip(data: []const u8) !void {
    var enc_buf: [1024]u8 = undefined;
    const n = cobs.encode(data.ptr, @intCast(data.len), &enc_buf, @intCast(enc_buf.len));
    if (n == 0) return error.Overflow;
    var dec: [1024]u8 = undefined;
    const m = decode(enc_buf[0 .. n - 1], &dec) orelse return error.Decode; // 去掉结尾 0x00 定界符
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
    const m = decode(buf[0 .. n - 1], &dec) orelse return error.Decode;
    const expect = [_]u8{ 0x7e, 0x02, 0x00, 0xef, 0xbe, 0x02, 'h', 'i' };
    if (m != expect.len + 1) return error.Len;
    if (!std.mem.eql(u8, dec[0..expect.len], &expect)) return error.Frame;
    var ck: u8 = 0;
    for (expect[1..]) |b| ck ^= b; // XOR 不含起始 0x7E（与 logBegin/decode.ps1 一致）
    if (dec[expect.len] != ck) return error.Checksum;
}

pub fn main() !void {
    const cases = [_][]const u8{
        &.{}, &.{0}, &.{ 0, 0, 0 }, &.{ 0x11, 0, 0 }, &.{ 0x11, 0x22 }, &.{ 0x11, 0, 0x22 },
    };
    for (cases) |c| try roundTrip(c);
    try logRoundTrip();

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
