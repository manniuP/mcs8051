; 纯 Zig 程序 + 中断向量表（8 位 MCS-51：sdas8051 汇编 + sdcc 链接用）。
;
; 经典 8051 中断向量按 8 字节间隔：
;   0000 复位(3B) / 0003 INT0 / 000B Timer0 / 0013 INT1 / 001B Timer1 / 0023 UART1 ...
; 复位与 UART1 入口都用 3 字节 `ljmp`（mcs51 没有 mcs251 的 4 字节 `ejmp`）。
;
; 空声明 PSEG/ISEG/BSEG：满足 sdcc 生成的 .lk 对这些区的 `-b`（否则报 No definition of area）。

	.module crt0
	.area PSEG    (PAG,XDATA)
	.area DSEG    (DATA)
	.area ISEG    (DATA)
	.area BSEG    (BIT)
	.area HOME    (CODE)

	.globl _main
	.globl _uart_isr

__interrupt_vect:
	ljmp	__start		; 0000 复位（3 字节）
	reti
	.ds	7		; 0003 INT0
	reti
	.ds	7		; 000B Timer0
	reti
	.ds	7		; 0013 INT1
	reti
	.ds	7		; 001B Timer1
	ljmp	_uart_isr	; 0023 UART1 中断入口（3 字节）
	.ds	5

__start:
	mov	sp,#0x7f
	lcall	_main
	sjmp	.
