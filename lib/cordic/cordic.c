/* cordic.c — Q15 定点 CORDIC + 整数开方（实现，见 cordic.h）。
 *
 * 平台无关：不 include config.h / stdlib，不使用 SFR；中间量用 long（32 位）防溢出。
 * 与主机 cordic_test.c（对比 libm）保持同一实现。
 */
#include "cordic.h"

/* atan(2^-i) 的 BAM 值：round(atan(2^-i) * 65536 / 2π)，i=0..14 */
static const int atan_bam[15] = {
    8192, 4836, 2555, 1297, 651, 326, 163, 81, 41, 20, 10, 5, 3, 1, 1
};

/* CORDIC 增益 K = ∏ 1/sqrt(1+2^-2i) ≈ 0.607252935，Q15 = 19898 */
#define CORDIC_K_Q15 19898L

/* Q15 饱和：结果可能到 ±32769，必须夹到 int（mcs251 上 16 位）范围，否则溢出变号 */
static int clamp16(long v)
{
    if (v > 32767L) return 32767;
    if (v < -32768L) return -32768;
    return (int)v;
}

int cordic_sincos(int ang_bam, int *sin_q15, int *cos_q15)
{
    long x = CORDIC_K_Q15;      /* 以 K 起步：旋转增益 1/K 后回到单位长 */
    long y = 0;
    long z;
    int neg = 0;
    unsigned char i;

    /* CORDIC 旋转只在 |θ|≤~90° 收敛：超出则折到 180°±，最后同时取反 */
    z = ang_bam;
    if (z > 16384) {            /* >90° */
        z -= 32768;
        neg = 1;
    } else if (z < -16384) {    /* < -90° */
        z += 32768;
        neg = 1;
    }

    for (i = 0; i < 15; i++) {
        long xs = x >> i;
        long ys = y >> i;
        if (z >= 0) {
            x -= ys;
            y += xs;
            z -= atan_bam[i];
        } else {
            x += ys;
            y -= xs;
            z += atan_bam[i];
        }
    }
    if (neg) { x = -x; y = -y; }
    *cos_q15 = clamp16(x);
    *sin_q15 = clamp16(y);
    return 0;
}

int cordic_atan2(int y_q15, int x_q15)
{
    long x = x_q15;
    long y = y_q15;
    long z = 0;
    int quad = 0;
    unsigned char i;

    if (x == 0 && y == 0) return 0;
    if (x < 0) {                 /* 折到右半平面，最后补 +180° */
        x = -x;
        y = -y;
        quad = 0x4000 * 2;       /* 0x8000 = 180° */
    }
    for (i = 0; i < 15; i++) {
        long xs = x >> i;
        long ys = y >> i;
        if (y >= 0) {
            x += ys;
            y -= xs;
            z += atan_bam[i];
        } else {
            x -= ys;
            y += xs;
            z -= atan_bam[i];
        }
    }
    z += quad;                   /* 16 位回绕即正确 BAM */
    return (int)z;
}

unsigned int cordic_mag(int x_q15, int y_q15)
{
    long x = x_q15;
    long y = y_q15;
    unsigned char i;

    if (x < 0) x = -x;
    if (y < 0) y = -y;
    for (i = 0; i < 15; i++) {
        long xs = x >> i;
        long ys = y >> i;
        if (y >= 0) {
            x += ys;
            y -= xs;
        } else {
            x -= ys;
            y += xs;
        }
    }
    /* x 已含 1/K 增益 → 乘 K 还原幅长（四舍五入） */
    return (unsigned int)((x * CORDIC_K_Q15 + 16384L) >> 15);
}

unsigned int cordic_isqrt(unsigned long v)
{
    unsigned long bit = 1UL << 30;   /* 4^15，32 位下最大 */
    unsigned long r = 0;

    while (bit > v) bit >>= 2;
    while (bit != 0) {
        if (v >= r + bit) {
            v -= r + bit;
            r = (r >> 1) + bit;
        } else {
            r >>= 1;
        }
        bit >>= 2;
    }
    return (unsigned int)r;
}
