/*
 * main.c — 只点灯：P1.1 上的 LED 以 1Hz 闪烁（AI8051U，MCS-251）。
 *
 * 硬件：LED 接 P1.1，低电平点亮。
 * 主频：MAIN_Fosc = 40MHz（见 lib/stc-hal/config.h；STC-ISP 里把 IRC 设成 40MHz）。
 * 延时：STC HAL 的 delay_ms()（lib/stc-hal/AI8051U_Delay.c）。
 * 目标：SDCC -mmcs251，链接需 --code-loc 0xff0000（AI8051U 程序存储器在 FF:0000）。
 *
 * 注意：芯片上电若硬件选项自动启动了看门狗，长延时会被 WDT 复位；
 *       这里显式关闭 WDT，并直接写 P1 电平（不用读改写，避免高阻位干扰）。
 */

#include "config.h"            /* 主时钟、类型定义、ai8051u_sfr.h */
#include "AI8051U_Delay.h"     /* delay_ms */

void main(void)
{
    WDT_CONTR = 0x00;              /* 关闭看门狗（防止硬件选项上电自动启动） */

    P1M1 &= ~0x02;                 /* P1.1 推挽输出 */
    P1M0 |= 0x02;

    while (1)
    {
        P1 = 0xFD;                 /* P1.1 = 0，LED 亮 */
        delay_ms(500);
        P1 = 0xFF;                 /* P1.1 = 1，LED 灭 */
        delay_ms(500);
    }
}
