/*
 * uart251.h — AI8051U（MCS-251）UART1 最小阻塞式发送。
 *
 * 默认引脚 P3.0(RxD)/P3.1(TxD)，波特率见 UART_BAUD，时钟在 uart251.c 里取 config.h 的 MAIN_Fosc。
 * TX：阻塞发送（uart_putc/uart_puts）；RX：见文末「接收」段（环形缓冲 + 使用者自备 ISR）。
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

/* ---- 接收（UART1 中断 + 环形缓冲） ----
 *
 * 平台限制：SDCC mcs251 的中断向量表**只在含 main 的编译单元生成**（见 docs/14），
 * 所以 ISR 必须写在使用者的 main 所在文件里；本库只提供环形缓冲与收发前端：
 *
 *   void uart1_isr(void) ISR(UART1_VECTOR)   // 需 #include "c51.h"
 *   {
 *       if (RI) { RI = 0; uart_rx_push(SBUF); }
 *   }
 *
 *   uart_init();          // 波特率/Timer1/引脚（TX）
 *   uart_rx_enable();     // 置 REN=1 并开 ES/EA
 *   ...
 *   if (uart_rx_pop(&c)) { ... }
 *
 * 收发共享：push 只在 ISR 里调用，pop 只在主循环里调用（单生产者/单消费者，无需临界区）。
 * 缓冲满时新字节被丢弃（不覆盖旧数据）。 */
#define UART_RX_BUFSIZE 256     /* 必须为 2 的幂（索引用无符号 char 自然回绕） */

void uart_rx_enable(void);
void uart_rx_push(unsigned char c);     /* 在 ISR 内调用（已从 SBUF 读到） */
int  uart_rx_pop(unsigned char *out);   /* 主循环取一字节：1=取到，0=空 */
unsigned int uart_rx_available(void);   /* 待取字节数（0..255） */

#endif
