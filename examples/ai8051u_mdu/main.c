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

    /* 最早的可观察点：先猛打一串，再 P1.1 闪 3 下（串口/引脚 任一能活就说明在跑）。 */
    uart_puts("\r\n\r\nBOOT!!! AI8051U MDU\r\n");
    P1M0 = 0x00; P1M1 = 0x00;      /* P1 准双向 */
    for (i = 0; i < 6; i++) { P1 ^= 0x02; delay_ms(120); }
    uart_puts("alive\r\n");

    uart_puts("MDU runtime test\r\n");

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

    /* 有符号除法：与 C 软件参考（SDCC 运行库的 / 和 %）比对，运行期 volatile 输入 */
    {
        unsigned int k, sp = 0, sf = 0;
        volatile long sa, sb;
        for (k = 0; k < 6; k++)
        {
            sa = (long)((k & 1) ? -0x10000000L : 0x10000000L) + (long)k * 12345L;
            sb = (long)((k & 2) ? -3L : 3L);
            {
                long q = mdu_div32s(sa, sb);
                long r = mdu_mod32s(sa, sb);
                long rq = sa / sb;      /* C 软件参考 */
                long rr = sa % sb;
                uart_puts("s"); put_hex8((unsigned char)k);
                uart_puts(" q="); put_hex32((unsigned long)q);
                uart_puts(" r="); put_hex32((unsigned long)r);
                if (q == rq && r == rr) { uart_puts(" PASS\r\n"); sp++; }
                else                    { uart_puts(" FAIL\r\n"); sf++; }
            }
        }
        uart_puts("signed pass=0"); uart_putc('0' + (unsigned char)sp);
        uart_puts(" fail=0"); uart_putc('0' + (unsigned char)sf);
        uart_puts("\r\n");
    }

    while (1) { delay_ms(1000); }
}
