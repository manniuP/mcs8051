/*
 * mcs_intrins.h —— Keil <intrins.h> 的 SDCC 兼容实现
 *
 * HAL 源码里只用到 _nop_()；其余内建函数按 Keil 语义给出等价宏，便于移植更多代码。
 * 旋转宏内已对移位数取模，避免移位量等于位宽时的未定义行为。
 */

#ifndef MCS_INTRINS_H
#define MCS_INTRINS_H

/* _nop_() 必须是“表达式”而非语句：STC 头里的 NOP2() NOP1(),NOP1() 依赖逗号表达式 */
#ifdef __SDCC_STUB__
/* clangd shim：clang 不认 SDCC 内联汇编，给个空实现（仅编辑器可见） */
static void mcs_nop_impl(void) {}
#else
static void mcs_nop_impl(void) { __asm NOP __endasm; }
#endif
#define _nop_()  mcs_nop_impl()

/* 测试并清零：返回原值，随后将该位清零（Keil 语义近似） */
#define _testbit_(b)  (!(b) ? 0 : ((b) = 0, 1))

/* 8 位循环左右移 */
#define _crol_(a, n) ((unsigned char)(((unsigned char)(a) << ((n) & 7)) | \
                                      ((unsigned char)(a) >> ((8 - ((n) & 7)) & 7))))
#define _cror_(a, n) ((unsigned char)(((unsigned char)(a) >> ((n) & 7)) | \
                                      ((unsigned char)(a) << ((8 - ((n) & 7)) & 7))))

/* 16 位循环左右移 */
#define _irol_(a, n) ((unsigned int)(((unsigned int)(a) << ((n) & 15)) | \
                                     ((unsigned int)(a) >> ((16 - ((n) & 15)) & 15))))
#define _iror_(a, n) ((unsigned int)(((unsigned int)(a) >> ((n) & 15)) | \
                                     ((unsigned int)(a) << ((16 - ((n) & 15)) & 15))))

/* 32 位循环左右移 */
#define _lrol_(a, n) ((unsigned long)(((unsigned long)(a) << ((n) & 31)) | \
                                      ((unsigned long)(a) >> ((32 - ((n) & 31)) & 31))))
#define _lror_(a, n) ((unsigned long)(((unsigned long)(a) >> ((n) & 31)) | \
                                      ((unsigned long)(a) << ((32 - ((n) & 31)) & 31))))

#endif /* MCS_INTRINS_H */
