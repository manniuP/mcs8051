/*
 * main.c —— 混合工程 C 侧（AI8051U / MCS-251）。
 *
 * 调用 Zig 侧 `zig_calc()`，把结果经 UART1 打印。C↔Zig 走 SDCC ABI：
 * 首个标量参数/返回值在 DPL/DPH/B/A；整单元 `--stack-auto`。
 */
#include "c51.h"
#include "ai8051u_sfr.h"

extern unsigned char zig_calc(unsigned char x);

static void putc_(unsigned char c)
{
    SBUF = c;
    while (!(SCON & 0x02)) { }
    SCON &= (unsigned char)~0x02;
}

static void puts_(const char *s)
{
    while (*s) putc_(*(s++));
}

static void puthex(unsigned char v)
{
    const char *h = "0123456789abcdef";
    putc_(h[v >> 4]);
    putc_(h[v & 0x0f]);
}

static void delay(void)
{
    unsigned int t = 0;
    while (t < 6000) t++;
}

void main(void)
{
    P_SW1 = (unsigned char)((P_SW1 & 0x3f) | 0x00);
    P3M1 &= (unsigned char)~0x02;
    P3M0 |= 0x02;
    SCON = 0x40;
    TMOD = (unsigned char)((TMOD & 0x0f) | 0x20);
    TH1 = 0xfb;
    TL1 = 0xef;
    TR1 = 1;

    while (1) {
        unsigned char r = zig_calc(0x05);
        puts_("zig_calc(5)=");
        puthex(r);
        puts_("\r\n");
        delay();
    }
}
