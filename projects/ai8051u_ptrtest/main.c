/* ptrtest.c — 验证 Zig↔C 3 字节指针互操作（MCS-251）。
 *
 * 1. C 起一个 xdata buffer，传指针给 Zig 的 fill()，让 Zig 写 "hello"。
 * 2. C 读回 buffer 内容，对比是否 == "hello"。
 * 3. C 把指针 + 长度传给 Zig 的 sum()，校验 Zig 能读 C 写的。
 *
 * 在 8051 上没有 printf，所以失败 hang 死，成功 LED 全亮。
 */

#include <stdint.h>
#include "ai8051u_sfr.h"

extern uint8_t fill(uint8_t *buf);
extern uint8_t sum(const uint8_t *buf);

static volatile uint8_t test_fail;

void main(void) {
    static __xdata uint8_t buf[8];
    uint8_t i, ok;
    uint8_t expect[] = "hello";

    /* 步骤 1：Zig fill 写入 buf */
    uint8_t n = fill(buf);
    if (n != 5) { test_fail = 1; for(;;){} }

    /* 步骤 2：C 读回对比 "hello" */
    for (i = 0; i < 5; i++) {
        if (buf[i] != expect[i]) { test_fail = 2; for(;;){} }
    }

    /* 步骤 3：Zig sum 读 C 写的 buf[0..5] */
    uint8_t s = sum(buf);
    /* h+e+l+l+o = 104+101+108+108+111 = 532 = 0x214 -> 低 8 位 = 0x14 = 20 */
    if (s != 20) { test_fail = 3; for(;;){} }

    /* 成功：点亮 P1 全部 8 位 */
    P1 = 0x00;
    for(;;){}
}
