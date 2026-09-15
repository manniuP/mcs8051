/* mdu.c —— MDU（32 位硬件乘除单元）实现，AI8051U / SDCC mcs251。
 *
 * 关键：**不能用普通 C 直接写 R0-R7** —— SDCC 的寄存器分配会用 R5-R7 等暂存第二个
 * 操作数，从而覆写 MDU 的第一个操作数（实测踩过）。这里改为：
 *   1) C 把两个 32 位操作数（大端）写进 data 暂存 `mdu_s[0..7]`；
 *   2) 一段**不透明 `__asm`** 把暂存搬进 R4-R7/R0-R3、写 DMAIR 触发、再把结果写回暂存；
 *   3) C 从 `mdu_s` 组装成 `unsigned long` 返回。
 * `mdu_s` 必须是 data（直接寻址，0x00-0x7F）以便 asm 用 `mov a,_mdu_s+n` 访问。
 */

#include "ai8051u_mdu.h"

/* 操作数/结果暂存：[0..3] = arg1（大端），[4..7] = arg2 / 除法余数（大端）。 */
__data unsigned char mdu_s[8];

static unsigned long mdu_get(volatile unsigned char *p)
{
    return ((unsigned long)p[0] << 24) | ((unsigned long)p[1] << 16) |
           ((unsigned long)p[2] << 8) | (unsigned long)p[3];
}

unsigned long mdu_mul32(unsigned long a, unsigned long b)
{
    mdu_s[0] = a >> 24;
    mdu_s[1] = a >> 16;
    mdu_s[2] = a >> 8;
    mdu_s[3] = a;
    mdu_s[4] = b >> 24;
    mdu_s[5] = b >> 16;
    mdu_s[6] = b >> 8;
    mdu_s[7] = b;

    __asm
        mov a,_mdu_s+0
        mov r4,a
        mov a,_mdu_s+1
        mov r5,a
        mov a,_mdu_s+2
        mov r6,a
        mov a,_mdu_s+3
        mov r7,a
        mov a,_mdu_s+4
        mov r0,a
        mov a,_mdu_s+5
        mov r1,a
        mov a,_mdu_s+6
        mov r2,a
        mov a,_mdu_s+7
        mov r3,a
        mov _DMAIR,#0x02
        mov a,r4
        mov _mdu_s+0,a
        mov a,r5
        mov _mdu_s+1,a
        mov a,r6
        mov _mdu_s+2,a
        mov a,r7
        mov _mdu_s+3,a
    __endasm;

    return mdu_get(mdu_s);
}

/* 除法核心：商 -> mdu_s[0..3]，余数 -> mdu_s[4..7]。 */
static void mdu_div_core(unsigned long a, unsigned long b)
{
    mdu_s[0] = a >> 24;
    mdu_s[1] = a >> 16;
    mdu_s[2] = a >> 8;
    mdu_s[3] = a;
    mdu_s[4] = b >> 24;
    mdu_s[5] = b >> 16;
    mdu_s[6] = b >> 8;
    mdu_s[7] = b;

    __asm
        mov a,_mdu_s+0
        mov r4,a
        mov a,_mdu_s+1
        mov r5,a
        mov a,_mdu_s+2
        mov r6,a
        mov a,_mdu_s+3
        mov r7,a
        mov a,_mdu_s+4
        mov r0,a
        mov a,_mdu_s+5
        mov r1,a
        mov a,_mdu_s+6
        mov r2,a
        mov a,_mdu_s+7
        mov r3,a
        mov _DMAIR,#0x04
        mov a,r4
        mov _mdu_s+0,a
        mov a,r5
        mov _mdu_s+1,a
        mov a,r6
        mov _mdu_s+2,a
        mov a,r7
        mov _mdu_s+3,a
        mov a,r0
        mov _mdu_s+4,a
        mov a,r1
        mov _mdu_s+5,a
        mov a,r2
        mov _mdu_s+6,a
        mov a,r3
        mov _mdu_s+7,a
    __endasm;
}

unsigned long mdu_div32u(unsigned long a, unsigned long b)
{
    mdu_div_core(a, b);
    return mdu_get(mdu_s);
}

unsigned long mdu_mod32u(unsigned long a, unsigned long b)
{
    mdu_div_core(a, b);
    return mdu_get(mdu_s + 4);
}
