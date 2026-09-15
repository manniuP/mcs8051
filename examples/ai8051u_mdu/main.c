/* main.c —— MDU（32 位硬件乘除单元）真机验证：算几组已知结果经 UART1 打印。
 *
 * 预期（115200 8N1，P3.1 TxD）：
 *   mul  = 0x2468ACF0   (0x12345678 * 2)
 *   div  = 0x05555555   (0x10000000 / 3)
 *   mod  = 0x00000001   (0x10000000 % 3)
 *   sq   = 0x00FFE001   (4095 * 4095，12 位 ADC 满量程平方)
 *   boot 时也打印一次 0x00000002*0=0 之类可省。
 *
 * 若 MDU 未生效/结果全 0/全 F，则说明触发/寄存器搬运有问题。
 */

#include "config.h"
#include "uart251.h"
#include "AI8051U_Delay.h"
#include "ai8051u_mdu.h"

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
    WDT_CONTR = 0x00;          /* 关看门狗 */
    uart_init();

    while (1)
    {
        uart_puts("MDU mul=");
        put_hex32(mdu_mul32(0x12345678UL, 0x00000002UL));
        uart_puts(" div=");
        put_hex32(mdu_div32u(0x10000000UL, 3UL));
        uart_puts(" mod=");
        put_hex32(mdu_mod32u(0x10000000UL, 3UL));
        uart_puts(" sq=");
        put_hex32(mdu_mul32(4095UL, 4095UL));
        uart_puts("\r\n");

        delay_ms(500);
    }
}
