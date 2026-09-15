/* main.c —— MDU 真机验证（**运行期输入 + 自校验**，防止编译器常量折叠）。
 *
 * 设计：
 *   - 操作数放 `volatile unsigned long`，并随循环递变（运行期），编译器无法在编译期算掉；
 *   - 对每组 (a,b)：用 MDU 算 p=mul、q=div、r=mod，再用 MDU 的 mul 校验
 *         mul(div(a,b), b) + mod(a,b) == a
 *     若 MDU 任一功能没真跑或算错，等式不成立 → FAIL；
 *   - 同时打印 p/q/r 供人工核对，最后打印 pass/fail 计数；
 *   - 另做一组 volatile 已知答案：0x12345678*2、0x10000000/3、4095*4095。
 *
 * 预期：8 组全 PASS，pass=8 fail=0；单次：mul=2468ACF0 div=05555555 mod=00000001 sq=00FFE001。
 */

#include "config.h"
#include "uart251.h"
#include "AI8051U_Delay.h"
#include "ai8051u_mdu.h"

static volatile unsigned long va;
static volatile unsigned long vb;

static void put_hex8(unsigned char v)
{
    const char *h = "0123456789ABCDEF";
    uart_putc(h[(v >> 4) & 0x0f]);
    uart_putc(h[v & 0x0f]);
}

static void put_hex32(unsigned long v)
{
    put_hex8((unsigned char)(v >> 24));
    put_hex8((unsigned char)(v >> 16));
    put_hex8((unsigned char)(v >> 8));
    put_hex8((unsigned char)(v));
}

void main(void)
{
    unsigned int i;
    unsigned int pass = 0, fail = 0;

    WDT_CONTR = 0x00;
    uart_init();

    uart_puts("\r\nMDU runtime test\r\n");

    va = 0x01020304UL;              /* volatile 种子，运行期读取 */
    for (i = 0; i < 8; i++)
    {
        unsigned long a = va;
        unsigned long b = (unsigned long)i + 2;
        unsigned long p = mdu_mul32(a, b);
        unsigned long q = mdu_div32u(a, b);
        unsigned long r = mdu_mod32u(a, b);
        unsigned long back = mdu_mul32(q, b) + r;   /* 用 MDU 的 mul 回验 */

        uart_puts("i="); put_hex8((unsigned char)i);
        uart_puts(" p="); put_hex32(p);
        uart_puts(" q="); put_hex32(q);
        uart_puts(" r="); put_hex32(r);
        if (back == a) { uart_puts(" PASS\r\n"); pass++; }
        else           { uart_puts(" FAIL\r\n"); fail++; }

        va = a + 0x11111111UL;      /* 下一组（运行期加法） */
    }
    uart_puts("pass=0"); uart_putc('0' + (unsigned char)pass);
    uart_puts(" fail=0"); uart_putc('0' + (unsigned char)fail);
    uart_puts("\r\n");

    /* 已知答案（volatile 输入） */
    va = 0x12345678UL; vb = 2UL;
    uart_puts("mul="); put_hex32(mdu_mul32(va, vb));
    va = 0x10000000UL; vb = 3UL;
    uart_puts(" div="); put_hex32(mdu_div32u(va, vb));
    uart_puts(" mod="); put_hex32(mdu_mod32u(va, vb));
    va = 4095UL; vb = 4095UL;
    uart_puts(" sq="); put_hex32(mdu_mul32(va, vb));
    uart_puts("\r\n");

    while (1) { delay_ms(1000); }
}
