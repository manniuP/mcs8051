/* cordic.h — Q15 定点 CORDIC（三角/向量）+ 整数开方。平台无关（无 SFR/无 libc）。
 *
 * 角度约定 **BAM**（Binary Angle Measure）：16 位 = 一整圈。
 *   0x0000 =   0°    0x4000 =  90°    0x8000 = 180°    0xC000 = -90°/270°
 * 这样角度就是 int（-32768..32767），加减/比较都不需要浮点或 π 换算。
 *
 * 分辨率 ≈ 360°/65536 ≈ 0.0055°；15 次迭代 + Q15 输出，误差约 ±3 LSB（见 cordic_test.c）。
 * 纯软件（默认 TFPU 不用），可选配 MDU/DPU 加速预/后处理。
 *
 * 用法：
 *   int s, c;
 *   cordic_sincos(0x4000, &s, &c);   // 90° → s≈+32767, c≈0
 *   int ang = cordic_atan2(y, x);    // 返回 BAM
 *   unsigned int m = cordic_mag(x, y);
 */
#ifndef CORDIC_H
#define CORDIC_H

/* 旋转模式：由角度求 sin/cos（均 Q15，约 -32767..32767）。返回 0。 */
int cordic_sincos(int ang_bam, int *sin_q15, int *cos_q15);

/* 向量模式：由 (x,y) 求幅角 atan2(y,x)，返回 BAM。x=y=0 时返回 0。 */
int cordic_atan2(int y_q15, int x_q15);

/* 向量模式：幅长 sqrt(x^2+y^2)，返回无符号整数（0..46341）。 */
unsigned int cordic_mag(int x_q15, int y_q15);

/* 整数平方根（floor(sqrt(v))）。 */
unsigned int cordic_isqrt(unsigned long v);

#endif /* CORDIC_H */
