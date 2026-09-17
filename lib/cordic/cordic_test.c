/* cordic_test.c — 主机端测试：cordic.c 对比 libm（sin/cos/atan2/sqrt）。
 * 运行：
 *   zig cc lib/cordic/cordic_test.c lib/cordic/cordic.c -lm -o cordic_test.exe
 *   .\cordic_test.exe
 */
#include <stdio.h>
#include <math.h>
#include "cordic.h"

#define PI 3.14159265358979323846
#define TWO_PI (2.0 * PI)
#define SCALE 32768.0                 /* Q15 满量程 */

static int max_di16(int a, int b) { int d = a - b; return d < 0 ? -d : d; }

/* BAM 环差（wrap） */
static int bam_diff(int a, int b)
{
    int d = ((a - b) % 65536 + 65536 + 32768) % 65536 - 32768;
    return d < 0 ? -d : d;
}

static int test_sincos(int tol)
{
    int ang, worst = 0;
    for (ang = -32768; ang <= 32767; ang += 61) {
        int s, c;
        double rad = (double)ang / 65536.0 * TWO_PI;
        int es = (int)lround(sin(rad) * SCALE);
        int ec = (int)lround(cos(rad) * SCALE);
        int ds, dc;
        if (es > 32767) es = 32767; if (es < -32768) es = -32768;
        if (ec > 32767) ec = 32767; if (ec < -32768) ec = -32768;
        cordic_sincos(ang, &s, &c);
        ds = max_di16(s, es);
        dc = max_di16(c, ec);
        if (ds > worst) worst = ds;
        if (dc > worst) worst = dc;
    }
    printf("sincos: max err = %d LSB (tol %d) %s\n", worst, tol, worst <= tol ? "OK" : "FAIL");
    return worst <= tol ? 0 : 1;
}

static int test_atan2(int tol)
{
    int x, y, worst = 0;
    for (x = -32767; x <= 32767; x += 1707) {
        for (y = -32767; y <= 32767; y += 3079) {
            double e = atan2((double)y, (double)x) / TWO_PI * 65536.0;
            int ea = (int)lround(e);
            int ga, d;
            if (x == 0 && y == 0) continue;
            ga = cordic_atan2(y, x);
            d = bam_diff(ga, ea);
            if (d > worst) worst = d;
        }
    }
    printf("atan2 : max err = %d BAM (tol %d) %s\n", worst, tol, worst <= tol ? "OK" : "FAIL");
    return worst <= tol ? 0 : 1;
}

static int test_mag(int tol)
{
    int x, y, worst = 0;
    for (x = -32767; x <= 32767; x += 2311) {
        for (y = -32767; y <= 32767; y += 3571) {
            double e = sqrt((double)x * x + (double)y * y);
            int ee = (int)lround(e);
            unsigned int g = cordic_mag(x, y);
            int d = max_di16((int)g, ee);
            if (d > worst) worst = d;
        }
    }
    printf("mag   : max err = %d (tol %d) %s\n", worst, tol, worst <= tol ? "OK" : "FAIL");
    return worst <= tol ? 0 : 1;
}

static int test_isqrt(void)
{
    unsigned long v;
    int bad = 0;
    for (v = 0; v < 200000UL; v += 137) {
        unsigned int r = cordic_isqrt(v);
        if (r != (unsigned int)floor(sqrt((double)v))) bad++;
        if ((unsigned long)r * r > v) bad++;
        if ((unsigned long)(r + 1) * (r + 1) <= v) bad++;
    }
    /* 大值 + 完全平方 */
    for (v = 4000000000UL; v > 4000000000UL - 100000UL; v -= 997) {
        unsigned int r = cordic_isqrt(v);
        if ((unsigned long)r * r > v) bad++;
        if ((unsigned long)(r + 1) * (r + 1) <= v) bad++;
    }
    printf("isqrt : %s\n", bad == 0 ? "OK" : "FAIL");
    return bad == 0 ? 0 : 1;
}

int main(void)
{
    int rc = 0;
    rc |= test_sincos(12);
    rc |= test_atan2(8);
    rc |= test_mag(8);
    rc |= test_isqrt();
    printf(rc == 0 ? "cordic: ALL OK\n" : "cordic: FAIL\n");
    return rc;
}
