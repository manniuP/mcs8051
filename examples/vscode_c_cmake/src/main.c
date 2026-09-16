/*
 * main.c —— 纯 C 示例（AI8051U / MCS-251）：UART1 周期打印。
 *
 * 这个工程演示：C 代码由 **CMake** 驱动 **SDCC** 构建；编辑器用 **clangd** 走
 * tools/clangd/sdcc_stubs.h 解析 SDCC 关键字（见 .clangd / compile_flags.txt）。
 */
#include "c51.h"
#include "ai8051u_sfr.h"

static void putc_(unsigned char c)
{
    SBUF = c;
    while (!(SCON & 0x02)) { } /* 等 TI */
    SCON &= (unsigned char)~0x02;
}

static void puts_(const char *s)
{
    while (*s) putc_(*(s++));
}

static void delay(void)
{
    unsigned int t = 0;
    while (t < 6000) t++;
}

void main(void)
{
    /* UART1：P3.0/P3.1，9600 @40MHz */
    P_SW1 = (unsigned char)((P_SW1 & 0x3f) | 0x00);
    P3M1 &= (unsigned char)~0x02;
    P3M0 |= 0x02; /* P3.1 推挽 */
    SCON = 0x40;
    TMOD = (unsigned char)((TMOD & 0x0f) | 0x20); /* Timer1 模式2 */
    TH1 = 0xfb;
    TL1 = 0xef;
    TR1 = 1;

    while (1) {
        puts_("\r\nhello (c + cmake)\r\n");
        delay();
    }
}
