; 纯 Zig 程序 + 中断向量表（sdcc 链接用，供 ai8051u_zig_t0print）。
;
; AI8051U 程序存储器在 FF:0000–FFFF，中断向量按经典 8 字节间隔：
;   FF:0000 复位(3B) / 0003 INT0 / 000B Timer0 / 0013 INT1 / 001B Timer1 / 0023 UART1 ...
; 复位用 3 字节 `ljmp`，避免占用 FF:0003（INT0 入口）。
;
; 空声明 PSEG/ISEG/BSEG：满足 sdcc 生成的 .lk 对这些区的 `-b`（否则报 No definition of area）。

	.module crt0
	.area PSEG    (PAG,XDATA)
	.area DSEG    (DATA)
	.area ISEG    (DATA)
	.area BSEG    (BIT)
	.area HOME    (CODE)

	.globl _main
	.globl _t0_isr

__interrupt_vect:
	ljmp	__start		; FF:0000 复位（3 字节）
	reti
	.ds	7		; FF:0003 INT0
	ejmp	_t0_isr		; FF:000B Timer0 中断入口（4 字节）
	.ds	4
	reti
	.ds	7		; FF:0013 INT1
	reti
	.ds	7		; FF:001B Timer1
	reti
	.ds	7		; FF:0023 UART1（本示例用查询发送，不使能 ES，留 reti 兜底）

__start:
	mov	spx,#0x0100
	ecall	_main
	sjmp	.
