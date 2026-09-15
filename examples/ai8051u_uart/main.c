/*
 * main.c — UART 自检：9600bps 从 P3.1(TxD) 打印（AI8051U，MCS-251）。
 *
 * 接法：USB转TTL 的 RX 接 MCU 的 P3.1(TxD)，GND 共地。
 * 串口助手：9600 8N1。
 */

#include "config.h"
#include "uart251.h"
#include "AI8051U_Delay.h"

void main(void)
{
    WDT_CONTR = 0x00;              /* 关看门狗 */

    uart_init();
    uart_puts("AI8051U UART OK\r\n");

    while (1)
    {
        uart_puts("tick\r\n");
        delay_ms(1000);
    }
}
