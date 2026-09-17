; crt0 + **全中断向量表**（Ai8051U）。向量地址见 STC 手册 15.3。
; 每个向量 8 字节间隔：`ejmp _sym`（4 字节）+ `.ds 4`；稀疏处按地址补 `.ds`。
; 复位 FF:0000 用 3 字节 `ljmp`，正好让出 FF:0003 给 INT0。
; 所有 ISR 由 isr 模块 `export fn` 提供（导出符号 `_<name>`）。
; 空声明 PSEG/ISEG/BSEG 以满足 sdcc 生成的 .lk。

	.module crt0
	.area PSEG    (PAG,XDATA)
	.area DSEG    (DATA)
	.area ISEG    (DATA)
	.area BSEG    (BIT)
	.area HOME    (CODE)

	.globl _main

__interrupt_vect:
	ljmp	__start		; FF:0000 复位
	ejmp	_int0		; FF:0003 INT0 — 外部中断0（P3.2）
	.ds	4
	ejmp	_timer0		; FF:000B Timer0 — 定时器0溢出
	.ds	4
	ejmp	_int1		; FF:0013 INT1 — 外部中断1（P3.3）
	.ds	4
	ejmp	_timer1		; FF:001B Timer1 — 定时器1溢出
	.ds	4
	ejmp	_uart1		; FF:0023 UART1 — 串口1 收RI/发TI
	.ds	4
	ejmp	_adc		; FF:002B ADC — ADC 转换完成
	.ds	4
	ejmp	_lvd		; FF:0033 LVD — 低压检测
	.ds	4
	ejmp	_pca		; FF:003B PCA — PCA/CCP（CF/CCF0-2）
	.ds	4
	ejmp	_uart2		; FF:0043 UART2 — 串口2 收/发
	.ds	4
	ejmp	_spi		; FF:004B SPI — SPI 传输完成（SPIF）
	.ds	4
	ejmp	_int2		; FF:0053 INT2 — 外部中断2（P3.6，下降沿）
	.ds	4
	ejmp	_int3		; FF:005B INT3 — 外部中断3（P3.7，下降沿）
	.ds	4
	ejmp	_timer2		; FF:0063 Timer2 — 定时器2溢出
	.ds	28
	ejmp	_int4		; FF:0083 INT4 — 外部中断4（P3.0）
	.ds	4
	ejmp	_uart3		; FF:008B UART3 — 串口3 收/发
	.ds	4
	ejmp	_uart4		; FF:0093 UART4 — 串口4 收/发
	.ds	4
	ejmp	_timer3		; FF:009B Timer3 — 定时器3溢出
	.ds	4
	ejmp	_timer4		; FF:00A3 Timer4 — 定时器4溢出
	.ds	4
	ejmp	_cmp		; FF:00AB CMP — 比较器
	.ds	20
	ejmp	_i2c		; FF:00C3 I2C — I2C 总线（起/收/发/停）
	.ds	4
	ejmp	_usb		; FF:00CB USB — USB 事件
	.ds	4
	ejmp	_pwma		; FF:00D3 PWMA — 高级PWM A
	.ds	4
	ejmp	_pwmb		; FF:00DB PWMB — 高级PWM B
	.ds	68
	ejmp	_rtc		; FF:0123 RTC — 实时时钟（闹钟/日/时/分/秒…）
	.ds	4
	ejmp	_p0		; FF:012B P0 — P0 端口引脚中断
	.ds	4
	ejmp	_p1		; FF:0133 P1 — P1 端口引脚中断
	.ds	4
	ejmp	_p2		; FF:013B P2 — P2 端口引脚中断
	.ds	4
	ejmp	_p3		; FF:0143 P3 — P3 端口引脚中断
	.ds	4
	ejmp	_p4		; FF:014B P4 — P4 端口引脚中断
	.ds	4
	ejmp	_p5		; FF:0153 P5 — P5 端口引脚中断
	.ds	4
	ejmp	_p6		; FF:015B P6 — P6 端口引脚中断
	.ds	4
	ejmp	_p7		; FF:0163 P7 — P7 端口引脚中断
	.ds	20
	ejmp	_dma_m2m	; FF:017B DMA_M2M — DMA 存储器→存储器
	.ds	4
	ejmp	_dma_adc	; FF:0183 DMA_ADC — DMA 搬运 ADC
	.ds	4
	ejmp	_dma_spi	; FF:018B DMA_SPI — DMA 搬运 SPI
	.ds	4
	ejmp	_dma_ur1t	; FF:0193 DMA_UR1T — DMA 串口1 发送
	.ds	4
	ejmp	_dma_ur1r	; FF:019B DMA_UR1R — DMA 串口1 接收
	.ds	4
	ejmp	_dma_ur2t	; FF:01A3 DMA_UR2T — DMA 串口2 发送
	.ds	4
	ejmp	_dma_ur2r	; FF:01AB DMA_UR2R — DMA 串口2 接收
	.ds	4
	ejmp	_dma_ur3t	; FF:01B3 DMA_UR3T — DMA 串口3 发送
	.ds	4
	ejmp	_dma_ur3r	; FF:01BB DMA_UR3R — DMA 串口3 接收
	.ds	4
	ejmp	_dma_ur4t	; FF:01C3 DMA_UR4T — DMA 串口4 发送
	.ds	4
	ejmp	_dma_ur4r	; FF:01CB DMA_UR4R — DMA 串口4 接收
	.ds	4
	ejmp	_lcm		; FF:01D3 LCM — TFT彩屏 DMA
	.ds	4
	ejmp	_lcmif		; FF:01DB LCMIF — TFT彩屏接口
	.ds	4
	ejmp	_dma_i2ct	; FF:01E3 DMA_I2CT — DMA I2C 发送
	.ds	4
	ejmp	_dma_i2cr	; FF:01EB DMA_I2CR — DMA I2C 接收
	.ds	4
	ejmp	_i2s		; FF:01F3 I2S — I2S 音频总线
	.ds	4
	ejmp	_dma_i2st	; FF:01FB DMA_I2ST — DMA I2S 发送
	.ds	4
	ejmp	_dma_i2sr	; FF:0203 DMA_I2SR — DMA I2S 接收
	.ds	4
	ejmp	_dma_qspi	; FF:020B DMA_QSPI — DMA QSPI
	.ds	4
	ejmp	_qspi		; FF:0213 QSPI — QSPI（模式/FIFO/完成/错误）
	.ds	4
	ejmp	_timer11	; FF:021B Timer11 — 定时器11溢出
	.ds	36
	ejmp	_dma_pwmat	; FF:0243 DMA_PWMAT — DMA 高级PWM A 发送
	.ds	4
	ejmp	_dma_pwmar	; FF:024B DMA_PWMAR — DMA 高级PWM A 接收
	.ds	4

__start:
	mov	spx,#0x0100
	ecall	_main
	sjmp	.
