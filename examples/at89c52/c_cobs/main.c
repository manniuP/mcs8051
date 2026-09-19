/* main.c —— 8 位（mcs51）COBS 日志帧编码自检（平台无关 C 版 lib/cobs）。
 *
 * 为什么 C 版能在 8 位跑通：SDCC 的 `--stack-auto` 把局部变量放**栈**上，函数间不各占
 * 一块静态 idata 帧；而 Zig mcs51 后端目前每函数一块静态 `_frkN`，函数一多就爆 256B idata。
 *
 * 本例只做「编码 + 落 XRAM」，输出与否由调用方决定（这里留给仿真 dump 验证）：
 * 编码结果写入 `__xdata out[]`，长度写入 `__xdata out_len`。
 * 用 STC15/通用 8051 仿真 dump XRAM 即可核对：
 *   raw frame = 7E 02 00 34 12 5A  ->  COBS + 00 = 03 7E 02 04 34 12 5A 00, out_len = 8
 */

#include "cobs.h"

__xdata unsigned char out[64];
__xdata unsigned int  out_len;

void main(void)
{
    cobs_enc_t e;

    cobs_init(&e, out, sizeof out);
    cobs_log_begin(&e, 0x0002);
    cobs_log_u16(&e, 0x1234);
    out_len = cobs_log_end(&e);   /* 8 */

    while (1) { }
}
