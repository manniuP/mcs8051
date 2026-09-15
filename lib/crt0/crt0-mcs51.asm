; MCS-51 最小启动代码（独立链接用）。
; 复位后从 0x0000 跳转到 __start，设置栈指针并调用 C 的 main（符号 `_main`）。
; 本文件只用于把 Zig 后端产物链接成可加载的 Intel HEX；正式工程应使用
; STC/SDCC 的完整启动与中断向量表。

	.module crt0_mcs51
	.area CSEG    (CODE)
	.globl _main

	ljmp __start

__start:
	mov  sp,#0x30
	lcall _main
	sjmp .
