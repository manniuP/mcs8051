/*
 * main.c — 纯 C 演示：用平台无关的 `cobs` 库把日志帧写进用户缓冲区，再经 UART1 输出。
 *
 * 与 examples/ai8051u_zig_log 发同样的帧（id 0x01..0x06），主机端用同一个 decode.ps1 解码。
 * 区别：这里是 C；`cobs` 库不改动，只调用它。
 *
 * 接法：USB转TTL 的 RX 接 MCU 的 P3.1(TxD)，GND 共地；串口 115200 8N1。
 */

#include "config.h"
#include "uart251.h"
#include "AI8051U_Delay.h"
#include "cobs.h"

static unsigned char out_buf[128];

/* 端序自检用的 u16 全局（写后读回）。 */
static volatile unsigned int g16;

static void send(const unsigned char *p, unsigned int n)
{
    unsigned int i;
    for (i = 0; i < n; i++) uart_putc(p[i]);
}

void main(void)
{
    cobs_enc_t e;
    unsigned int n = 0;

    WDT_CONTR = 0x00;                  /* 关看门狗 */
    uart_init();
    cobs_init(&e, out_buf, sizeof out_buf);

    while (1)
    {
        cobs_log_begin(&e, 0x0001);
        send(out_buf, cobs_log_end(&e));               /* boot */

        cobs_log_begin(&e, 0x0002);
        cobs_log_u16(&e, n);
        send(out_buf, cobs_log_end(&e));               /* count = n */

        cobs_log_begin(&e, 0x0003);
        cobs_log_u8(&e, 0xab);
        cobs_log_u8(&e, 0xcd);
        send(out_buf, cobs_log_end(&e));               /* xy */

        cobs_log_begin(&e, 0x0004);
        cobs_log_var(&e, n);
        send(out_buf, cobs_log_end(&e));               /* cvar（LEB128） */

        cobs_log_begin(&e, 0x0005);
        cobs_log_str(&e, "hello");
        send(out_buf, cobs_log_end(&e));               /* msg */

        g16 = n;                                       /* u16 全局写（大端） */
        cobs_log_begin(&e, 0x0006);
        cobs_log_u16(&e, g16);                         /* 读回，应等于 count */
        send(out_buf, cobs_log_end(&e));

        n++;

        delay_ms(100);                                 /* 约 10 帧组/秒 */
    }
}
