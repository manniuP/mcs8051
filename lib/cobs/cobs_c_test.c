/* cobs_c_test.c — 主机端往返测试（C 实现）。
 * 编译运行（用系统 zig 自带的 C 编译器，无需 MSVC）：
 *   zig cc lib/cobs/cobs_c_test.c lib/cobs/cobs.c -o cobs_c_test.exe
 *   .\cobs_c_test.exe
 */
#include <stdio.h>
#include "cobs.h"

static int decode(const unsigned char *enc, unsigned int n, unsigned char *out, unsigned int out_cap) {
    unsigned int idx = 0, o = 0;
    while (idx < n) {
        unsigned int code = enc[idx++];
        unsigned int k;
        if (code == 0) return -1;
        for (k = 1; k < code; k++) {
            if (idx >= n || o >= out_cap) return -1;
            out[o++] = enc[idx++];
        }
        if (code < 255 && idx < n) {
            if (o >= out_cap) return -1;
            out[o++] = 0;
        }
    }
    return (int)o;
}

static int roundtrip(const unsigned char *data, unsigned int n) {
    static unsigned char enc[1024];
    static unsigned char dec[1024];
    unsigned int m, i, j;
    m = cobs_encode(data, n, enc, sizeof enc);
    if (m == 0) { printf("overflow (n=%u)\n", n); return 1; }
    for (i = 0; i + 1 < m; i++) {
        if (enc[i] == 0) { printf("0x00 inside encoded stream (n=%u)\n", n); return 1; }
    }
    j = (unsigned int)decode(enc, m - 1, dec, sizeof dec); /* 去掉结尾 0x00 定界符 */
    if (j != n) { printf("len mismatch in=%u out=%d\n", n, (int)j); return 1; }
    for (i = 0; i < n; i++) {
        if (data[i] != dec[i]) { printf("byte mismatch at %u (n=%u)\n", i, n); return 1; }
    }
    return 0;
}

int main(void) {
    unsigned int seed = 1234;
    unsigned int t;
    static const unsigned char a0[] = { 0 };
    static const unsigned char a1[] = { 0, 0, 0 };
    static const unsigned char a2[] = { 0x11, 0, 0 };
    static const unsigned char a3[] = { 0x11, 0x22 };
    static const unsigned char a4[] = { 0x11, 0, 0x22 };
    static unsigned char buf[1024];

    if (roundtrip(a0, 0)) return 1; /* 空 */
    if (roundtrip(a0, 1)) return 1;
    if (roundtrip(a1, 3)) return 1;
    if (roundtrip(a2, 3)) return 1;
    if (roundtrip(a3, 2)) return 1;
    if (roundtrip(a4, 3)) return 1;

    for (t = 1; t <= 800; t++) {
        unsigned int len, i;
        seed = seed * 1664525u + 1013904223u;
        len = seed % (t + 1);
        for (i = 0; i < len; i++) {
            seed = seed * 1664525u + 1013904223u;
            buf[i] = (seed & 1) ? (unsigned char)(seed >> 8) : 0;
        }
        if (len > 260) { for (i = 0; i < len; i++) buf[i] = 0xAA; }
        if (roundtrip(buf, len)) return 1;
    }
    printf("c cobs: ALL OK\n");
    return 0;
}
