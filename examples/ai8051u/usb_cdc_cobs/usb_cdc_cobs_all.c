/* usb_cdc_cobs_all.c —— 在 USB-CDC 上输出 COBS 轻量日志帧。
 *
 * 目的：摆脱 UART 线——把 lib/cobs 的日志帧直接从 USB-CDC(虚拟串口) 发给主机，
 * 主机用 examples/ai8051u/zig_log/decode.ps1（-Port <CDC口>）解码。
 *
 * 单编译单元：SDCC（mcs251）只在**定义了 main 的模块**里生成中断向量表，
 * 故把 usb_isr/uart2_isr 所在模块（uart.c/usb.c/...）全部 #include 进来；
 * 这些源码在 ../usb_cdc/src/，用 `-I` 指向其目录即可解析其头文件。
 *
 * 帧格式与 ziglog/ccobs 相同：0x7E,id_lo,id_hi,参数…,XOR，整帧 COBS 后以 0x00 结束。
 *   id 0x0002 -> u16（计数）     id 0x0005 -> str（"hello"）
 *
 * 输出路径：cobs 编码进 frame_buf -> 塞进 CDC 发送环形缓冲 TxBuffer ->
 *           uart_polling() 把 TxBuffer 送进 EP1 IN。如何送完全由本文件决定。
 */

#include "usb.h"
#include "uart.h"
#include "usb_req_class.h"
#include "cobs.h"

/* 并入全部含中断服务函数的模块（IVT 需要在含 main 的模块生成）。 */
#include "../usb_cdc/src/uart.c"
#include "../usb_cdc/src/usb.c"
#include "../usb_cdc/src/usb_desc.c"
#include "../usb_cdc/src/usb_req_std.c"
#include "../usb_cdc/src/usb_req_class.c"
#include "../usb_cdc/src/usb_req_vendor.c"
#include "../usb_cdc/src/util.c"

static unsigned char frame_buf[96];
static cobs_enc_t enc;
static unsigned int counter = 0;

/* 把 n 字节塞进 USB-CDC 发送环形缓冲；空间不够时推进 uart_polling() 腾空间。 */
static void cdc_send(const unsigned char *p, unsigned int n)
{
    unsigned int i;
    for (i = 0; i < n; i++)
    {
        while ((unsigned char)(TxWptr - TxRptr) >= 250)
            uart_polling();
        TxBuffer[TxWptr++] = p[i];
    }
}

static void send_one_frame(void)
{
    unsigned int len;

    cobs_init(&enc, frame_buf, sizeof(frame_buf));
    cobs_log_begin(&enc, 0x0002);
    cobs_log_u16(&enc, counter);
    len = cobs_log_end(&enc);
    if (len != 0)
        cdc_send(frame_buf, len);

    cobs_init(&enc, frame_buf, sizeof(frame_buf));
    cobs_log_begin(&enc, 0x0005);
    cobs_log_str(&enc, "hello");
    len = cobs_log_end(&enc);
    if (len != 0)
        cdc_send(frame_buf, len);

    counter++;
}

void main(void)
{
    unsigned int i;

    WTST = 0;         /* 指令取指不等待 */
    P_SW2 |= 0x80;    /* 使能扩展 SFR(XFR) 访问（EAXFR 是位掩码常量，不能直接赋值） */
    CKCON = 0;        /* 片内 XRAM 最快访问 */

    uart_init();
    usb_init();
    EA = 1;

    for (;;)
    {
        if (DeviceState == DEVSTATE_CONFIGURED)
            send_one_frame();
        for (i = 0; i < 20000; i++)
            uart_polling();   /* 抽出时间送 CDC + 保持 UART2 通路 */
    }
}
