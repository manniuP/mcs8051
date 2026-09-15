/* ptrtest.c — 验证 Zig↔C 3 字节指针互操作（MCS-251）。
 *
 * 1. C 起一个 xdata buffer，传指针给 Zig 的 fill()，让 Zig 写 "hello"。
 * 2. C 读回 buffer 内容，对比是否 == "hello"。
 * 3. C 把指针传给 Zig 的 sum()，校验 Zig 能读 C 写的。
 *
 * 结果指示（AI8051U 上电后 I/O 默认高阻输入，必须先配成输出）：
 *   - 先把 P1 配为推挽输出；
 *   - 任一步失败 -> P1 = 失败码，然后死循环：
 *       0x01 fill 返回值 != 5
 *       0x02 buffer 内容 != "hello"
 *       0x04 sum 结果 != 20
 *   - 全部通过 -> P1 = 0x00（八位全低，万用表可测到 ~0V）。
 *   - 若程序根本没跑起来，P1 保持高阻，测得浮空电压（非 0V）。
 */

#include <stdint.h>
#include "ai8051u_sfr.h"

extern uint8_t fill(uint8_t *buf);
extern uint8_t sum(const uint8_t *buf);

static volatile uint8_t test_fail;

static void fail(uint8_t code) {
    P1 = code;
    for (;;) {}
}

void main(void) {
    static __xdata uint8_t buf[8];
    uint8_t i;
    uint8_t expect[] = "hello";
    uint8_t n, s;

    /* P1 全部推挽输出，先全置高（LED 熄灭） */
    P1M1 = 0x00;
    P1M0 = 0xFF;
    P1 = 0xFF;

    /* 步骤 1：Zig fill 写入 buf */
    n = fill(buf);
    if (n != 5) fail(0x01);

    /* 步骤 2：C 读回对比 "hello" */
    for (i = 0; i < 5; i++) {
        if (buf[i] != expect[i]) fail(0x02);
    }

    /* 步骤 3：Zig sum 读 C 写的 buf[0..5] */
    s = sum(buf);
    /* h+e+l+l+o = 104+101+108+108+111 = 532 = 0x214 -> 低 8 位 = 0x14 = 20 */
    if (s != 20) fail(0x04);

    /* 成功：P1 全部拉低 */
    P1 = 0x00;
    for (;;) {}
}
