//! bench.zig — 读取延迟 / 运行延迟 的周期测量（Timer0 1T 自由计数），UART 打印，实机用。
//!
//! 原理：Timer0 模式0（16 位自动重装载）、`AUXR.T0x12=1`（1T，每时钟 +1）、重装值 0
//! → 自由计数（模 65536）。测一段代码前后读 `TH0/TL0` 之差即该段**时钟周期数**。
//!
//! 输出（UART1 P3.1 @9600，16 进制）：
//!   bench
//!   rd d=xxxx i=xxxx e=xxxx x=xxxx     ← N 次“读”的总周期（d=data,i=idata,e=edata,x=xdata）
//!   exe o0=xxxx o5=xxxx                ← N 次调用 O0/O5 函数的总周期
//!
//! 每次测量含循环开销（同一基线，可横向比较）。数值若为 0 或异常，多因单次测量
//! 超过 65536 周期回绕——调小 N 即可。真机上把两行连起来看相对差异。

const m = @import("mcs");

var v_data: u8 linksection(".data") = 0;
var v_idata: u8 linksection(".idata") = 0;
var v_edata: u8 linksection(".edata") = 0;
var v_xdata: u8 linksection(".xdata") = 0;
var sink: u8 linksection(".data") = 0; // 防读被优化掉

fn t0Init() void {
    m.sfrAnd(0x89, 0xF0); // TMOD: T0 模式0（16 位自动重装）、C/T=0、GATE=0
    m.sfrOr(0x8E, 0x80); // AUXR.T0x12 = 1  → 1T（每时钟 +1）
    m.sfrAnd(0x88, 0xEF); // TCON.TR0 = 0（停止）
    m.sfrWrite(0x8C, 0x00); // TH0 = 0（同时写 RL_TH0）
    m.sfrWrite(0x8A, 0x00); // TL0 = 0（同时写 RL_TL0）
    m.sfrOr(0x88, 0x10); // TCON.TR0 = 1（自由计数）
}

fn t0Now() u16 {
    // 稳健读：TL0, TH0, TL0；若 TL0 在读数期间变化则重读 TH0（处理溢出边界）。
    const l0: u16 = m.sfrPtr(0x8A).*;
    var h: u16 = m.sfrPtr(0x8C).*;
    const l1: u16 = m.sfrPtr(0x8A).*;
    if (l1 != l0) h = m.sfrPtr(0x8C).*;
    return (h << 8) | l1;
}

/// 空循环基线（与各测量同 NREAD 次循环），供扣减循环开销。
fn benchNop() u16 {
    var i: u16 = 0;
    const t = t0Now();
    while (i < NREAD) : (i += 1) {}
    return t0Now() -% t;
}

const NREAD: u16 = 500;
const NEXEC: u16 = 100;

fn benchData() u16 {
    var acc: u8 = 0;
    var i: u16 = 0;
    const t = t0Now();
    while (i < NREAD) : (i += 1) acc +%= v_data;
    const d = t0Now() -% t;
    sink = acc;
    return d;
}

fn benchIdata() u16 {
    var acc: u8 = 0;
    var i: u16 = 0;
    const t = t0Now();
    while (i < NREAD) : (i += 1) acc +%= v_idata;
    const d = t0Now() -% t;
    sink = acc;
    return d;
}

fn benchEdata() u16 {
    var acc: u8 = 0;
    var i: u16 = 0;
    const t = t0Now();
    while (i < NREAD) : (i += 1) acc +%= v_edata;
    const d = t0Now() -% t;
    sink = acc;
    return d;
}

fn benchXdata() u16 {
    var acc: u8 = 0;
    var i: u16 = 0;
    const t = t0Now();
    while (i < NREAD) : (i += 1) acc +%= v_xdata;
    const d = t0Now() -% t;
    sink = acc;
    return d;
}

// 同一函数体，只有 O 等级标签不同：Ofast=速度优先 / Os=体积优先。
// （真机验证「周期数随标签走」时可临时互换两标签，见 README §B。）
fn accFast(n: u8) linksection(".Ofast") u8 {
    var s: u8 = 0;
    var i: u8 = 0;
    while (i < n) : (i += 1) s +%= i;
    return s;
}

fn accSmall(n: u8) linksection(".Os") u8 {
    var s: u8 = 0;
    var i: u8 = 0;
    while (i < n) : (i += 1) s +%= i;
    return s;
}

fn benchExec0() u16 {
    var acc: u8 = 0;
    var i: u16 = 0;
    const t = t0Now();
    while (i < NEXEC) : (i += 1) acc +%= accFast(4);
    const d = t0Now() -% t;
    sink = acc;
    return d;
}

fn benchExec5() u16 {
    var acc: u8 = 0;
    var i: u16 = 0;
    const t = t0Now();
    while (i < NEXEC) : (i += 1) acc +%= accSmall(4);
    const d = t0Now() -% t;
    sink = acc;
    return d;
}

fn putU16(v: u16) void {
    m.uartPutHex2(@intCast((v >> 8) & 0xff));
    m.uartPutHex2(@intCast(v & 0xff));
}

export fn main() void {
    m.uartInit(40_000_000, 9600);
    t0Init();
    v_data = 0x5a;
    v_idata = 0x5a;
    v_edata = 0x5a;
    v_xdata = 0x5a;
    _ = benchData(); // 预热

    m.uartPuts("\r\nbench\r\n");
    while (true) {
        const n = benchNop();
        const d = benchData();
        const ii = benchIdata();
        const e = benchEdata();
        const x = benchXdata();
        const o0 = benchExec0();
        const o5 = benchExec5();
        m.uartPuts("nop=");
        putU16(n);
        m.uartPuts("\r\nrd d=");
        putU16(d);
        m.uartPuts(" i=");
        putU16(ii);
        m.uartPuts(" e=");
        putU16(e);
        m.uartPuts(" x=");
        putU16(x);
        m.uartPuts("\r\nexe o0=");
        putU16(o0);
        m.uartPuts(" o5=");
        putU16(o5);
        m.uartPuts("\r\n");
        var t: u16 = 0;
        while (t < 6000) : (t += 1) {}
    }
}

