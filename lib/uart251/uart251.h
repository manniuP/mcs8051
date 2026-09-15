/*
 * uart251.h — AI8051U（MCS-251）UART1 最小阻塞式发送。
 *
 * 默认引脚 P3.0(RxD)/P3.1(TxD)，波特率见 UART_BAUD，时钟在 uart251.c 里取 config.h 的 MAIN_Fosc。
 * 只做发送（TX），不启用接收中断/缓冲，够调试打印用。
 *
 * 注意：本头文件**不**包含 config.h（避免其 def.h 与 <stdint.h> 冲突）；
 * 若调用方已定义 UART_BAUD 则以调用方为准。
 */

#ifndef __UART251_H
#define __UART251_H

#ifndef UART_BAUD
#define UART_BAUD   9600UL      /* 串口助手请用同样波特率 */
#endif

void uart_init(void);
void uart_putc(unsigned char c);
void uart_puts(const char *s);

#endif
