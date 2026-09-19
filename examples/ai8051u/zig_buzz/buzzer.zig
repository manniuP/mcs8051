//! buzzer.zig — 无源蜂鸣器（P3.6，低电平触发）+ xdata 乐谱，Timer0 中断发声。
//!
//! 乐谱以「Timer0 重载值 hi/lo + 半周期数 ticks(16 位)」四字节/音符存在 **xdata 数组**里；
//! 播放时逐个读出：hi/lo 写 TH0/TL0（模式0 = 16 位自动重载，12T），T0 中断翻转 P3.6 并
//! 在 IRAM 0x30/0x31 做 16 位计数，达到 ticks 即换音符（ticks 按 1/f 取 → 等时值），
//! 音符之间留一个短间隙便于分辨重复音。
//!
//! 时钟 40MHz。1=523Hz（中央C）。重载值 = 65536 − (40e6/12)/(2f)。

const dev = @import("dev");
const m = @import("mcs");

const TCON_ADDR: u8 = @intCast(dev.sfr.TCON);
const TMOD_ADDR: u8 = @intCast(dev.sfr.TMOD);
const TH0_ADDR: u8 = @intCast(dev.sfr.TH0);
const TL0_ADDR: u8 = @intCast(dev.sfr.TL0);
const AUXR_ADDR: u8 = @intCast(dev.sfr.AUXR);
const IE_ADDR: u8 = @intCast(dev.sfr.IE);
const P3_ADDR: u8 = @intCast(dev.sfr.P3);
const P3M1_ADDR: u8 = @intCast(dev.sfr.P3M1);
const P3M0_ADDR: u8 = @intCast(dev.sfr.P3M0);

const N = 16;
var score: [4 * N]u8 linksection(".xdata") = undefined; // 每音符：hi, lo, t_hi, t_lo

const p_lo: *volatile u8 = @ptrFromInt(0x30); // ISR 16 位计数低字节
const p_hi: *volatile u8 = @ptrFromInt(0x31); // 高字节

// 重载值 = 65536 − (40e6/12)/(2f)。1=523Hz（中央C），半音按用户表。
const R_DO = 0xF38D; // 1  = 523
const R_DOS = 0xF440; // 1# = 554
const R_RE = 0xF4E9; // 2  = 587
const R_RES = 0xF588; // 2# = 622
const R_MI = 0xF61F; // 3  = 659
const R_FA = 0xF6AC; // 4  = 698
const R_FAS = 0xF734; // 4# = 740
const R_SO = 0xF7B2; // 5  = 784
const R_SOS = 0xF82A; // 5# = 831
const R_LA = 0xF89A; // 6  = 880
const R_LAS = 0xF904; // 6# = 932
const R_SI = 0xF969; // 7  = 988
const R_DO_LOW = 0xE727; // 低音 1 = 262
const R_SI_HIGH = 0xFCC5; // 高音 7 = 1976
const R_REST = 0xFFFF;

/// 等时值 ≈0.5s：半周期数 ≈ 1.0·f。
const Note = struct { r: u16, ticks: u16 };

/// 小星星：do do so so la la so | fa fa mi mi re re do | (休 休)
const tune = [_]Note{
    .{ .r = R_DO, .ticks = 524 }, .{ .r = R_DO, .ticks = 524 },
    .{ .r = R_SO, .ticks = 784 }, .{ .r = R_SO, .ticks = 784 },
    .{ .r = R_LA, .ticks = 880 }, .{ .r = R_LA, .ticks = 880 },
    .{ .r = R_SO, .ticks = 784 },
    .{ .r = R_FA, .ticks = 698 }, .{ .r = R_FA, .ticks = 698 },
    .{ .r = R_MI, .ticks = 660 }, .{ .r = R_MI, .ticks = 660 },
    .{ .r = R_RE, .ticks = 588 }, .{ .r = R_RE, .ticks = 588 },
    .{ .r = R_DO, .ticks = 524 },
    .{ .r = R_REST, .ticks = 600 }, .{ .r = R_REST, .ticks = 600 },
};

/// Timer0 中断：16 位计数 + 翻转 P3.6（模式0 自动重载）。
export fn t0_isr() void {
    asm volatile (
        \\push 0xe0
        \\push 0xd0
        \\inc 0x30
        \\mov a,0x30
        \\jnz t0_isr_skip
        \\inc 0x31
        \\t0_isr_skip:
        \\cpl 0xb0.6
        \\pop 0xd0
        \\pop 0xe0
        \\reti
    );
}

inline fn busy(comptime n: u32) void {
    var i: u32 = 0;
    while (i < n) : (i += 1) {}
}

/// 播放一个音符（inline：绕开后端多参数只传第一个的限制）。
inline fn playNote(hi: u8, lo: u8, t_hi: u8, t_lo: u8) void {
    if (hi == 0xff) { // 休止
        busy(300000);
        return;
    }
    p_lo.* = 0;
    p_hi.* = 0;
    m.sfrPtr(TH0_ADDR).* = hi; // TH0
    m.sfrPtr(TL0_ADDR).* = lo; // TL0
    m.bitSet(TCON_ADDR, 4); // TR0 = 1
    while (true) {
        const h = p_hi.*;
        const l = p_lo.*;
        if (h > t_hi or (h == t_hi and l >= t_lo)) break;
    }
    m.bitClr(TCON_ADDR, 4); // TR0 = 0
    m.bitSet(P3_ADDR, 6); // P3.6 = 1（停声）
    busy(2000); // 音符间小间隙
}

export fn main() void {
    m.sfrAnd(P3M1_ADDR, ~@as(u8, 0x40)); // P3M1.6 = 0
    m.sfrOr(P3M0_ADDR, 0x40); // P3M0.6 = 1（推挽）
    m.bitSet(P3_ADDR, 6); // P3.6 = 1

    m.sfrWrite(TMOD_ADDR, 0x00); // TMOD：Timer0 模式0（16 位自动重载）
    m.sfrAnd(AUXR_ADDR, 0x7f); // AUXR.7=0 → Timer0 12T
    m.bitClr(TCON_ADDR, 4); // TR0 = 0
    m.bitSet(IE_ADDR, 1); // ET0 = 1
    m.bitSet(IE_ADDR, 7); // EA  = 1

    // 写乐谱进 xdata（每音符 hi,lo,t_hi,t_lo）
    inline for (tune, 0..) |nt, i| {
        score[4 * i] = @intCast(nt.r >> 8);
        score[4 * i + 1] = @intCast(nt.r & 0xff);
        score[4 * i + 2] = @intCast(nt.ticks >> 8);
        score[4 * i + 3] = @intCast(nt.ticks & 0xff);
    }

    while (true) {
        inline for (0..N) |i| playNote(
            score[4 * i],
            score[4 * i + 1],
            score[4 * i + 2],
            score[4 * i + 3],
        );
        busy(200000);
    }
}
