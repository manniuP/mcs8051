; MCS-251 最小启动代码（独立链接用）。
; 复位后从 0x0000 跳转到 __start，设置栈指针 SPX 并用 ECALL 调用 C 的 main。
; 正式工程应使用 STC 的完整启动文件，并在启动时确保内核处于 Source 模式
; （见 sdcc-c251/doc/mcs251/abi.md “Interrupt functions”）。

	.module crt0_mcs251
	.area CSEG    (CODE)
	.globl _main

	ejmp __start

__start:
	mov  spx,#0x0100
	ecall _main
	sjmp .
