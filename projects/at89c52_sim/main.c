/*
 * main.c — AT89C52 风格的自检测试（C 主程序 + Zig 逻辑），用于 ucsim 软件仿真。
 *
 * 只用标准 8051 SFR（不依赖任何 STC AI8051U 专有寄存器），可被 ucsim 的
 * s51 核直接执行。测试两项 C<->Zig 互操作：
 *   1) 单标量：连续调用 led_next(u8) 八次，比对流水灯序列；
 *   2) 指针  ：C 传 __xdata 缓冲区给 Zig 的 sum4([*]const u8)，比对求和结果。
 * 结果写入 XRAM，供 ucsim 用 `dump xram` 读出。
 *
 * XRAM 约定（放在高位，避免与 SDCC 的 XSEG 放置区重叠）：
 *   0x8000 status   —— 0xAA = 全部通过；0x55 = 有失败
 *   0x8001 failcode —— 失败码（0 无失败；1..8 灯序；0x20 指针）
 *   0x8002 seq[8]   —— led_next() 实际返回的 8 个值
 *   0x8010 pbuf[4]  —— 传给 sum4 的缓冲区
 */

#include <stdint.h>

typedef unsigned char u8;

__sfr __at(0x90) P1;                 /* 标准 P1，仅用于点亮标记 */

extern u8 led_next(u8 cur);          /* Zig 提供（led.zig） */
extern u8 sum4(__xdata const u8 *buf);
extern u8 add3(u8 a, u8 b, u8 c);
extern u8 counter;                   /* Zig 定义的全局 */
extern u8 bump(void);
extern void wr_fixed(u8 v);          /* 固定 xdata 地址（@ptrFromInt） */
extern u8 rd_fixed(void);

__xdata __at(0x8000) volatile u8 status;
__xdata __at(0x8001) volatile u8 failcode;
__xdata __at(0x8002) volatile u8 seq[8];
__xdata __at(0x8010) u8 pbuf[4];

static const u8 expected[8] = { 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x01 };

void main(void)
{
    u8 led = 0x01;
    u8 i;

    status = 0x00;
    failcode = 0x00;

    for (i = 0; i < 8; i++) {
        led = led_next(led);
        seq[i] = led;
        if (led != expected[i]) {
            failcode = (u8)(i + 1);
            break;
        }
    }

    /* 指针互操作：C 写缓冲区，Zig 读取求和（1+2+3+4=10）。 */
    pbuf[0] = 1; pbuf[1] = 2; pbuf[2] = 3; pbuf[3] = 4;
    if (failcode == 0 && sum4(pbuf) != 10) {
        failcode = 0x20;
    }

    /* 多参数互操作：add3(1,2,3)=6（C 需 --stack-auto）。 */
    if (failcode == 0 && add3(1, 2, 3) != 6) {
        failcode = 0x30;
    }

    /* 全局变量互操作：Zig 定义 counter，C 读写；bump() 自增返回。 */
    counter = 0;
    if (failcode == 0 && bump() != 1) {
        failcode = 0x40;
    }
    if (failcode == 0 && counter != 1) {
        failcode = 0x41;
    }

    /* 固定地址互操作：Zig 经 @ptrFromInt 读写 0x8020。 */
    wr_fixed(0x5a);
    if (failcode == 0 && rd_fixed() != 0x5a) {
        failcode = 0x50;
    }

    status = (failcode == 0) ? 0xAA : 0x55;
    P1 = (u8)~led;

    for (;;) {
    }
}
