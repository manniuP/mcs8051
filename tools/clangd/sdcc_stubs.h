/*
 * sdcc_stubs.h —— 仅供 clangd/clang 解析用的 SDCC 关键字 shim。
 *
 * ⚠️ 不参与真实构建！SDCC 构建不包含本文件（真编译器自带这些关键字）。
 *    它只在编辑器（clangd）里被强制包含（见各工程 .clangd / tools/clangd/README.md），
 *    把 SDCC 扩展关键字映射成 clang 能懂的形式，消除红波浪线。
 *
 * 用法（clangd，各工程 .clangd）：
 *   CompileFlags:
 *     Add: [ '-include', <repo>/tools/clangd/sdcc_stubs.h, '-I', <repo>/lib/include ]
 */
#ifndef SDCC_STUBS_H
#define SDCC_STUBS_H

/* 让 c51.h / 芯片头的 `#ifdef __SDCC` 分支走 SDCC 路径；并标记「编辑器 shim」，
 * 供源码里用 `#ifndef __SDCC_STUB__` 把内联汇编 __asm 包起来（clang 不认 SDCC asm）。 */
#ifndef __SDCC
#define __SDCC 1
#endif
#define __SDCC_STUB__ 1

/* ---- 存储 / 地址空间限定符（写在类型位置，展开为空） -------------------- */
#define __data
#define __idata
#define __pdata
#define __xdata
#define __far
#define __near
#define __code
#define __nonbanked
#define __addressmod
#define __reentrant
#define __critical
#define __naked
#define __using(n)

/* ---- SFR / 位变量 / 绝对地址 ------------------------------------------ */
/* SFR(name,addr)  = `__sfr __at(0x80) P0`     -> `unsigned char P0;`
   SBIT(name,addr) = `__sbit __at(0x80) P00`   -> `_Bool P00;`          */
#define __sfr     unsigned char
#define __sbit    _Bool
#define __at(x)
#define sfr       unsigned char
#define sbit      _Bool
#define bit       _Bool

/* ---- 中断函数属性 ----------------------------------------------------- */
#define __interrupt(n)

/* ---- 内联汇编 ---------------------------------------------------------
 * SDCC 的 `__asm … __endasm;` clang 无法解析（内容非 C token）。这里置空，
 * 并在**源码**里用 `#ifndef __SDCC_STUB__` 把 asm 包起来（见 mcs_intrins.h / mdu.c），
 * 给编辑器一个等价空实现。 ---- */
#define __asm
#define __endasm

#endif /* SDCC_STUBS_H */
