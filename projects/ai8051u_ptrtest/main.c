/* ptrtest.c — 验证 Zig↔C 3 字节指针互操作（MCS-251），结果经 UART1(P3.1, 9600) 每秒打印。
 *
 * 1. C 起一个 xdata buffer，传指针给 Zig 的 fill()，让 Zig 写 "hello"。
 * 2. C 读回 buffer 内容，对比是否 == "hello"。
 * 3. C 把指针传给 Zig 的 sum()，校验 Zig 能读 C 写的。
 *
 * 输出示例：fill=P buffer=P sum=P  RESULT: PASS
 * 同时 P1 指示：成功 P1=0xFF（灯灭）；失败 P1=失败码（0x01/0x02/0x04）。
 */

#include <stdint.h>
#include "ai8051u_sfr.h"
#include "uart251.h"

extern uint8_t fill(uint8_t *buf);
extern uint8_t sum(const uint8_t *buf);
extern void delay_ms(unsigned int ms);   /* port/stc-hal/AI8051U_Delay.c */

void main(void) {
    static __xdata uint8_t buf[8];
    uint8_t i, n, s, failcode;
    uint8_t expect[] = "hello";

    WDT_CONTR = 0x00;              /* 关看门狗 */

    P1M1 = 0x00;                   /* P1 推挽输出 */
    P1M0 = 0xFF;
    P1 = 0xFF;

    uart_init();
    uart_puts("\r\nptrtest: C<->Zig 3-byte pointer (MCS-251)\r\n");

    while (1) {
        failcode = 0;

        n = fill(buf);
        if (n != 5) failcode = 0x01;

        for (i = 0; i < 5 && failcode == 0; i++) {
            if (buf[i] != expect[i]) failcode = 0x02;
        }

        s = sum(buf);
        /* h+e+l+l+o = 532 -> 低 8 位 = 20 */
        if (failcode == 0 && s != 20) failcode = 0x04;

        uart_puts("fill=");    uart_putc((failcode == 0x01) ? 'F' : 'P');
        uart_puts(" buffer="); uart_putc((failcode == 0x02) ? 'F' : 'P');
        uart_puts(" sum=");    uart_putc((failcode == 0x04) ? 'F' : 'P');
        if (failcode) uart_puts("  RESULT: FAIL\r\n");
        else          uart_puts("  RESULT: PASS\r\n");

        P1 = failcode ? failcode : 0xFF;

        delay_ms(1000);
    }
}
