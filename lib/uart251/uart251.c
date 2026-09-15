/*
 * uart251.c — AI8051U（MCS-251）UART1 最小阻塞式发送。
 *
 * 方案（与 STC HAL 一致）：UART1 模式1（8 位可变波特率），
 * 波特率发生器用 Timer1、1T、16 位自动重载：
 *   baud = (Fosc/4) / (65536 - reload)
 *
 * 引脚 P3.0(RxD)/P3.1(TxD)。P3.1 配推挽输出。
 */

#include "config.h"        /* MAIN_Fosc + SFR（含 ai8051u_sfr.h） */
#include "uart251.h"

void uart_init(void)
{
    PCON &= ~0x80;                 /* SMOD = 0 */

    SCON  = 0x40;                  /* 模式1：8 位 UART，仅发送(REN=0) */

    AUXR &= ~0x01;                 /* S1 波特率发生器选 Timer1 */
    AUXR |=  0x40;                 /* Timer1 1T 模式 */
    TMOD  = (TMOD & 0x0F);         /* Timer1 模式0：16 位自动重载 */

    {
        unsigned int reload = (unsigned int)(65536UL - (MAIN_Fosc / 4) / UART_BAUD);
        TH1 = (unsigned char)(reload >> 8);
        TL1 = (unsigned char)reload;
    }
    TR1 = 1;                       /* 启动 Timer1 */

    P_SW1 &= 0x3f;                 /* UART1 切换到 P3.0(RxD)/P3.1(TxD) */
    P3M1 &= ~0x02;                 /* P3.1(TxD) 推挽输出 */
    P3M0 |=  0x02;
}

void uart_putc(unsigned char c)
{
    /* RI/TI 共用同一中断向量：ES=1 时 TI 会反复触发中断（而此处是轮询发送）→
     * 发送期间临时关串口中断，发完恢复（期间到达的 RI 不会丢，恢复后补触发）。 */
    unsigned char es = ES;
    ES = 0;
    SBUF = c;
    while (!TI) { }                /* 等发送完成 */
    TI = 0;
    ES = es;
}

void uart_puts(const char *s)
{
    while (*s) uart_putc((unsigned char)*s++);
}

/* ---- 接收：环形缓冲（单生产者=ISR，单消费者=主循环） ---- */

static volatile unsigned char rx_buf[UART_RX_BUFSIZE];
static volatile unsigned char rx_head;      /* ISR 写 */
static volatile unsigned char rx_tail;      /* 主循环读 */

void uart_rx_enable(void)
{
    REN = 1;                                /* SCON.4：允许接收（模式1 下 REN=1） */
    RI  = 0;
    ES  = 1;                                /* 串口中断（向量 4） */
    EA  = 1;                                /* 总中断 */
}

void uart_rx_push(unsigned char c)
{
    unsigned char next = (unsigned char)(rx_head + 1);
    if (next != rx_tail) {                  /* 满则丢弃（保留旧数据） */
        rx_buf[rx_head] = c;
        rx_head = next;
    }
}

int uart_rx_pop(unsigned char *out)
{
    if (rx_head == rx_tail) return 0;
    *out = rx_buf[rx_tail];
    rx_tail = (unsigned char)(rx_tail + 1);
    return 1;
}

unsigned int uart_rx_available(void)
{
    return (unsigned int)(unsigned char)(rx_head - rx_tail);
}
