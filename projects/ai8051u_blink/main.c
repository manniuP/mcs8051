/*
 * main.c — AI8051U 流水灯 demo（C 主程序 + Zig 逻辑）
 *
 * 分工：
 *   - C（本文件）：用 STC 官方 HAL 库配置并驱动 P1，在主循环里延时；
 *   - Zig（led.zig）：只做纯计算，返回下一个流水灯图案。
 *
 * 硬件：P1.0 ~ P1.7 接 8 个 LED，低电平点亮。
 * 主频：MAIN_Fosc = 40MHz（见 config.h，可用 STC-ISP 设置）。
 * 目标：SDCC -mmcs51（AI8051U 的 8 位兼容模式）。
 */

#include "config.h"            /* 主时钟、类型定义、ai8051u_sfr.h */
#include "AI8051U_GPIO.h"      /* P1_MODE_OUT_PP 等 GPIO 宏 */
#include "AI8051U_Delay.h"     /* delay_ms */

/* Zig 后端（led.zig）导出的流水灯图案函数。
 * 接口只有 u8 参数 / u8 返回，命中 SDCC MCS-51 默认 ABI：
 * 参数放在 DPL、返回也在 DPL，双方一致，无需额外约定。 */
extern u8 led_next(u8 cur);

void main(void)
{
    u8 led = 0x01;                     /* 当前点亮位：1 表示点亮，初始 P1.0 */

    P1_MODE_OUT_PP(GPIO_Pin_All);      /* 把 P1 全部配置为推挽输出 */
    P1 = ~led;                         /* LED 低电平点亮，取反后输出 */

    while (1)
    {
        led = led_next(led);           /* Zig：计算下一个灯位（循环左移） */
        P1 = ~led;                     /* 写到 P1 */
        delay_ms(200);                 /* STC HAL：延时 200ms */
    }
}
