/* ai8051u_mdu.h —— AI8051U 的 MDU（32 位硬件乘除单元）C 接口。
 *
 * 手册 §36：触发寄存器 DMAIR @ 0xED，**必须用立即数写**（`mov DMAIR,#op`）；
 * 操作数在寄存器组 R4-R7（arg1）与 R0-R3（arg2），均**大端**（R4/R0 = MSB）；
 * 乘/除结果在 R4-R7；除法余数在 R0-R3；除零返回 0xFFFFFFFF。
 *
 * 指令码：0x02 = 32 位乘法（3 clk）；0x04 = 32 位无符号除法（19 clk）。
 * 有符号除法指令码见手册 §36.3.3（暂未实现）。
 *
 * 用法（C，SDCC mcs251）：
 *   #include "ai8051u_mdu.h"
 *   unsigned long p = mdu_mul32(0x12345678UL, 2UL);   // -> 0x2468ACF0
 *   unsigned long q = mdu_div32u(0x10000000UL, 3UL);  // -> 0x05555555
 *   unsigned long r = mdu_mod32u(0x10000000UL, 3UL);  // -> 1
 *
 * 实现见 lib/mdu/mdu.c；**仿真不建模 MDU → 只能真机验证**。
 */
#ifndef AI8051U_MDU_H
#define AI8051U_MDU_H

#include "c51.h" /* SFR() 宏 */

/* MDU 触发寄存器（手册 §36.1）。 */
SFR(DMAIR, 0xED);

/* 32 位乘法：返回 a*b 的低 32 位。 */
unsigned long mdu_mul32(unsigned long a, unsigned long b);

/* 32 位无符号除法：返回商 a/b（除零 -> 0xFFFFFFFF）。 */
unsigned long mdu_div32u(unsigned long a, unsigned long b);

/* 32 位无符号取余：返回 a%b（除零时余数为被除数，规范见手册）。 */
unsigned long mdu_mod32u(unsigned long a, unsigned long b);

/* 32 位有符号除法：返回商 a/b（除零 -> 0xFFFFFFFF）。指令码 0x06。 */
long mdu_div32s(long a, long b);

/* 32 位有符号取余：返回余数 a%b（符号随被除数，C 语义）。 */
long mdu_mod32s(long a, long b);

#endif /* AI8051U_MDU_H */
