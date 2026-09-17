//! irqall.zig — 列出 Ai8051U **全部中断**的 ISR（向量地址见 STC 手册 15.3）。
//!
//! 目的：验证「不触发、甚至为空」的 ISR 会不会被当死代码删掉。
//! - 每个中断一个 `export fn`（导出 → 编译期根；crt0 向量表也引用它）。
//! - **核心中断**内部做 加/减/移位/位运算（改写全局 `acc`/`acc2`，避免被当无用表达式）。
//! - **DMA / 次要中断**留空 `{}`，用来观察空函数是否保留。
//! - `main` 不使能任何中断、不触发任何中断，只死循环。
//!
//! 每个函数上方标注：向量地址 + **触发源**。

var acc: u8 = 0;
var acc2: u8 = 0;

// --- 核心中断：加 / 减 / 移位 / 位运算 -------------------------------------

/// FF:0003 INT0 — 外部中断 0：**P3.2** 引脚（IT0 选上升/下降沿或双边沿）。
export fn int0() void {
    acc = (acc +% 0x11) ^ 0x5a;
}
/// FF:000B Timer0 — **定时器 0** 溢出（TF0）。
export fn timer0() void {
    acc = (acc -% 0x07) << 1;
}
/// FF:0013 INT1 — 外部中断 1：**P3.3** 引脚。
export fn int1() void {
    acc2 = (acc2 +% 0x23) & 0x7f;
}
/// FF:001B Timer1 — **定时器 1** 溢出（TF1）。
export fn timer1() void {
    acc2 = (acc2 -% 0x05) >> 1;
}
/// FF:0023 UART1 — **串口 1** 收发：接收完成 RI 或发送完成 TI。
export fn uart1() void {
    acc = (acc | 0x80) ^ 0x0f;
}
/// FF:002B ADC — **ADC 模数转换完成**（ADC_FLAG）。
export fn adc() void {
    acc = (acc +% acc2) & 0xf0;
}
/// FF:0033 LVD — **低压检测**（LVDF，电源电压低于阈值）。
export fn lvd() void {
    acc2 = (acc2 ^ 0xff) -% 0x01;
}
/// FF:003B PCA — **PCA/CCP**：计数器溢出 CF 或比较/捕获 CCF0/1/2。
export fn pca() void {
    acc = (acc << 2) | 0x03;
}
/// FF:0043 UART2 — **串口 2** 收发（S2RI / S2TI）。
export fn uart2() void {
    acc2 = (acc2 >> 3) +% 0x40;
}
/// FF:004B SPI — **SPI 传输完成**（SPIF）。
export fn spi() void {
    acc = (acc & 0xaa) | 0x55;
}
/// FF:0053 INT2 — 外部中断 2：**P3.6** 引脚（仅下降沿）。
export fn int2() void {
    acc = acc +% 0x0a;
}
/// FF:005B INT3 — 外部中断 3：**P3.7** 引脚（仅下降沿）。
export fn int3() void {
    acc2 = acc2 -% 0x0b;
}
/// FF:0063 Timer2 — **定时器 2** 溢出（T2IF）。
export fn timer2() void {
    acc = (acc << 1) ^ 0x11;
}
/// FF:0083 INT4 — 外部中断 4：**P3.0** 引脚。
export fn int4() void {
    acc2 = (acc2 +% 0x1c) >> 2;
}
/// FF:008B UART3 — **串口 3** 收发（S3RI / S3TI）。
export fn uart3() void {
    acc = (acc -% 0x02) | 0x20;
}
/// FF:0093 UART4 — **串口 4** 收发（S4RI / S4TI）。
export fn uart4() void {
    acc2 = (acc2 & 0x0f) +% 0x30;
}
/// FF:009B Timer3 — **定时器 3** 溢出（T3IF）。
export fn timer3() void {
    acc = (acc ^ 0x3c) << 1;
}
/// FF:00A3 Timer4 — **定时器 4** 溢出（T4IF）。
export fn timer4() void {
    acc2 = (acc2 >> 1) ^ 0x77;
}
/// FF:00AB CMP — **比较器**（CMPIF，比较器输出翻转）。
export fn cmp() void {
    acc = (acc +% 0x09) -% 0x04;
}
/// FF:00C3 I2C — **I2C 总线**：主机/从机、起始、收发、停止（MSIF/STAIF/RXIF/TXIF/STOIF）。
export fn i2c() void {
    acc2 = (acc2 << 2) | 0x01;
}
/// FF:00CB USB — **USB** 事件（USB Events，EUSB）。
export fn usb() void {
    acc = (acc & 0x0f) | (acc2 << 4);
}
/// FF:00D3 PWMA — **高级 PWM 定时器 A**（PWMA_SR 任一标志）。
export fn pwma() void {
    acc2 = (acc2 +% 0xaa) ^ 0x55;
}
/// FF:00DB PWMB — **高级 PWM 定时器 B**（PWMB_SR 任一标志）。
export fn pwmb() void {
    acc = (acc -% 0x10) >> 1;
}
/// FF:0123 RTC — **实时时钟**：闹钟/日/时/分/秒/2秒/8秒/32秒（ALAIF…SEC32IF）。
export fn rtc() void {
    acc2 = (acc2 | 0x08) & 0xf7;
}
/// FF:012B P0 — **P0 端口**任意引脚的电平变化中断（P0INTF，普通 I/O 口中断）。
export fn p0() void {
    acc = acc +% 0x01;
}
/// FF:0133 P1 — **P1 端口**引脚中断（P1INTF）。
export fn p1() void {
    acc = acc -% 0x01;
}
/// FF:013B P2 — **P2 端口**引脚中断（P2INTF）。
export fn p2() void {
    acc2 = acc2 << 1;
}
/// FF:0143 P3 — **P3 端口**引脚中断（P3INTF）。
export fn p3() void {
    acc2 = acc2 >> 1;
}
/// FF:014B P4 — **P4 端口**引脚中断（P4INTF）。
export fn p4() void {
    acc = acc ^ 0xa5;
}
/// FF:0153 P5 — **P5 端口**引脚中断（P5INTF）。
export fn p5() void {
    acc2 = acc2 | 0x0f;
}
/// FF:015B P6 — **P6 端口**引脚中断（P6INTF）。
export fn p6() void {
    acc = acc & 0xf0;
}
/// FF:0163 P7 — **P7 端口**引脚中断（P7INTF）。
export fn p7() void {
    acc2 = acc2 ^ 0x5a;
}
/// FF:01F3 I2S — **I2S 音频总线**：发送空 TXE / 接收非空 RXNE / 错误 FRE·OVR·UDR。
export fn i2s() void {
    acc = (acc +% 0x33) & 0xcc;
}
/// FF:0213 QSPI — **QSPI**：模式匹配 SMF / FIFO 阈值 FTF / 传输完成 TCF / 错误 TEF。
export fn qspi() void {
    acc2 = (acc2 -% 0x22) | 0x11;
}
/// FF:021B Timer11 — **定时器 11** 溢出（T11IF）。
export fn timer11() void {
    acc = (acc << 3) -% 0x01;
}

// --- DMA / 次要中断：**空函数**（观察是否被保留）-----------------------------

/// FF:017B DMA_M2M — **DMA 存储器→存储器**搬运完成（M2MIF）。
export fn dma_m2m() void {}
/// FF:0183 DMA_ADC — **DMA 搬运 ADC** 结果完成（ADCIF）。
export fn dma_adc() void {}
/// FF:018B DMA_SPI — **DMA 搬运 SPI** 数据完成（SPIIF）。
export fn dma_spi() void {}
/// FF:0193 DMA_UR1T — **DMA 搬运串口 1 发送**完成（UR1TIF）。
export fn dma_ur1t() void {}
/// FF:019B DMA_UR1R — **DMA 搬运串口 1 接收**完成（UR1RIF）。
export fn dma_ur1r() void {}
/// FF:01A3 DMA_UR2T — **DMA 搬运串口 2 发送**完成（UR2TIF）。
export fn dma_ur2t() void {}
/// FF:01AB DMA_UR2R — **DMA 搬运串口 2 接收**完成（UR2RIF）。
export fn dma_ur2r() void {}
/// FF:01B3 DMA_UR3T — **DMA 搬运串口 3 发送**完成（UR3TIF）。
export fn dma_ur3t() void {}
/// FF:01BB DMA_UR3R — **DMA 搬运串口 3 接收**完成（UR3RIF）。
export fn dma_ur3r() void {}
/// FF:01C3 DMA_UR4T — **DMA 搬运串口 4 发送**完成（UR4TIF）。
export fn dma_ur4t() void {}
/// FF:01CB DMA_UR4R — **DMA 搬运串口 4 接收**完成（UR4RIF）。
export fn dma_ur4r() void {}
/// FF:01D3 LCM — **TFT 彩屏 DMA** 搬运完成（LCMIF）。
export fn lcm() void {}
/// FF:01DB LCMIF — **TFT 彩屏接口**中断（LCMIFIF）。
export fn lcmif() void {}
/// FF:01E3 DMA_I2CT — **DMA 搬运 I2C 发送**完成（I2CTIF）。
export fn dma_i2ct() void {}
/// FF:01EB DMA_I2CR — **DMA 搬运 I2C 接收**完成（I2CRIF）。
export fn dma_i2cr() void {}
/// FF:01FB DMA_I2ST — **DMA 搬运 I2S 发送**完成（I2STIF）。
export fn dma_i2st() void {}
/// FF:0203 DMA_I2SR — **DMA 搬运 I2S 接收**完成（I2SRIF）。
export fn dma_i2sr() void {}
/// FF:020B DMA_QSPI — **DMA 搬运 QSPI** 完成（QSPIIF）。
export fn dma_qspi() void {}
/// FF:0243 DMA_PWMAT — **DMA 搬运高级 PWM A 发送**完成（PWMATIF）。
export fn dma_pwmat() void {}
/// FF:024B DMA_PWMAR — **DMA 搬运高级 PWM A 接收**完成（PWMARIF）。
export fn dma_pwmar() void {}

export fn main() void {
    // 不使能、不触发任何中断。
    while (true) {}
}
