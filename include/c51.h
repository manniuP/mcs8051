/*
 * c51.h —— 8051 / 80251（SDCC）常用语法简化宏
 *
 * 目标：把 SDCC 的 C51 扩展关键字（内存段、SFR、位寻址、中断、临界区）
 *       包装成更短、更一致的宏，统一书写风格。
 *
 * 前提：这些宏只是 token 替换，最终仍展开为 SDCC 关键字，语义等价。
 *       它们只在 SDCC 下有效；其他编译器因缺少关键字会报错。
 *       宏不能替代编译器机制：地址空间、位指令、中断入口/返回由后端实现。
 *
 * 参考：
 *   sdcc-c251/doc/zh-CN/chapters/04-language.md
 *   sdcc-c251/doc/mcs251/abi.md
 */

#ifndef C51_H
#define C51_H

#if !defined(__SDCC)
#error "c51.h 仅用于 SDCC（需要 __SDCC 宏）"
#endif

/* ------------------------------------------------------------------
 * 1. 内存段（命名地址空间）别名
 *    写在类型位置。对象自身空间与所指对象空间要分开写：
 *      __xdata unsigned char * __data p;   // p 自身在 data，指向 xdata
 * ------------------------------------------------------------------ */
#define DATA    __data      /* 内部直接寻址区：最快、空间最小 */
#define IDATA   __idata     /* 内部间接寻址区 */
#define PDATA   __pdata     /* 分页外部数据窗口（8 位指针） */
#define XDATA   __xdata     /* 外部/远数据区（mcs251 为 24 位平坦空间） */
#define FAR     __far       /* 远对象/远指针 */
#define CODE    __code      /* 只读代码空间：查表常量放这里，省 RAM */
#define BIT     __bit       /* 位变量 */

/* ------------------------------------------------------------------
 * 2. SFR / 可位寻址 SFR / 绝对地址声明
 *    在文件作用域展开为一条声明，末尾要加分号。
 * ------------------------------------------------------------------ */
#define SFR(name, addr)   __sfr  __at (addr) name
#define SBIT(name, addr)  __sbit __at (addr) name
#define AT(addr)          __at (addr)

/* ------------------------------------------------------------------
 * 3. 中断服务函数与函数属性
 *    ISR(n)             只指定向量号
 *    ISR_USING(n, bank) 同时指定寄存器组（MCS-51 常用；MCS-251 不建议）
 *    NAKED              禁止自动序言/结尾，需自行管理寄存器与返回
 * ------------------------------------------------------------------ */
#define ISR(n)              __interrupt(n)
#define ISR_USING(n, bank)  __interrupt(n) __using(bank)
#define NAKED               __naked
#define REENTRANT           __reentrant

/* ------------------------------------------------------------------
 * 4. 临界区：由后端保存/恢复中断使能状态，具备嵌套语义
 *    用法：CRITICAL { ... }
 * ------------------------------------------------------------------ */
#define CRITICAL  __critical

/* ------------------------------------------------------------------
 * 5. GPIO 位操作
 *    5a 单比特（__sbit）：编译为位指令，天然原子，优先使用
 *    5b 整口按位：|= &= ^= 是读-改-写，非原子
 * ------------------------------------------------------------------ */
#define PIN_HIGH(pin)    ((pin) = 1)
#define PIN_LOW(pin)     ((pin) = 0)
#define PIN_TOGGLE(pin)  ((pin) = !(pin))
#define PIN_READ(pin)    ((pin) ? 1u : 0u)

#define PORT_SET(reg, bit)  ((reg) |=  (unsigned char)(1u << (bit)))
#define PORT_CLR(reg, bit)  ((reg) &= (unsigned char)~(1u << (bit)))
#define PORT_TOG(reg, bit)  ((reg) ^=  (unsigned char)(1u << (bit)))
#define PORT_GET(reg, bit)  (((reg) >> (bit)) & 1u)

/* ------------------------------------------------------------------
 * 6. 内联汇编：短小、经审查的序列可用
 *    用法：ASM_BEGIN nop ASM_END
 * ------------------------------------------------------------------ */
#define ASM_BEGIN  __asm
#define ASM_END    __endasm;

#endif /* C51_H */

/* ==================================================================
 * 用法示例
 * ==================================================================
 *
 * #include "c51.h"
 * #include "stc32g_sfr.h"      // 芯片 SFR 头，内部用 SFR()/SBIT() 声明
 *
 * // ---- 内存段 ----
 * XDATA unsigned char rx_buf[256];
 * CODE  const unsigned char table[4] = { 0, 1, 2, 3 };
 * XDATA unsigned char * DATA p;          // p 在 data，指向 xdata
 *
 * // ---- GPIO 位操作 ----
 * // 芯片头里：SBIT(P10, 0x90)（STC 命名不带下划线：P10 = P1.0）
 * void led_init(void) {
 *     P1M0 = 0x00; P1M1 = 0x00;          // 视芯片设置为准双向/推挽
 *     PIN_HIGH(P10);
 * }
 * void led_blink(void) { PIN_TOGGLE(P10); }
 *
 * // ---- 中断 ----
 * volatile unsigned int tick;
 * void timer0_isr(void) ISR(1) { tick++; }
 * void uart1_isr(void) ISR_USING(4, 1) { // MCS-51 用 bank1 }
 *
 * // ---- 临界区 ----
 * unsigned int read_tick(void) {
 *     unsigned int v;
 *     CRITICAL { v = tick; }             // 防止读到半更新值
 *     return v;
 * }
 */

/* ==================================================================
 * 注意事项（宏简化不代表可以忽略语义）
 * ==================================================================
 * 1. 只是替换，不改变规则：
 *    - __at 地址必须来自芯片手册，重叠由链接布局决定；
 *    - 指针对象自身空间与所指对象空间写错，会改变指针宽度和生成指令；
 *    - MCS-51 通用指针带地址空间标签；MCS-251 rev2 的 3 字节通用指针
 *      无标签，两者不可混用。
 * 2. 原子性：
 *    - PIN_* 走 __sbit，位指令天然原子；
 *    - PORT_* 走整口读-改-写，主循环与中断共享时须放进 CRITICAL，
 *      或改用 __sbit。
 * 3. 中断：
 *    - 与中断共享的多字节对象要 volatile；volatile 不提供原子性；
 *    - 中断内不要调用非可重入库函数，避免深调用和浮点；
 *    - MCS-251 不要照搬 MCS-51 的 __using bank 策略；
 *    - 与 Zig 互操作时，向量号/入口/保存集合由 SDCC 侧统一生成。
 * 4. 可重入与 overlay：
 *    - 递归、函数指针间接调用、主程序+中断共用函数需要 __reentrant
 *      或整单元 --stack-auto；
 *    - 这是 ABI，所有编译单元和运行库必须一致。本项目统一 --stack-auto。
 * 5. Zig 侧：Zig 没有预处理器，宏方案不适用；xdata/idata/code、SFR、
 *    位寻址、中断需要后端地址空间与内建支持（见 PLAN.md A.3 / B.6 / B.11）。
 */
