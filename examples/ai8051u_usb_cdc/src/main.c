/*---------------------------------------------------------------------*/
/* AI8051U USB-CDC 最小示例：每隔约 1 秒通过 USB-CDC（虚拟串口）打印一行。
/* 下载时 IRC 设为 24MHz（USB 用内部 48M）。
/* CDC IN 发送走设备库的 EP1： INDEX=1 -> FIFO1 写字节 -> INCSR1=INIPRDY。
/*---------------------------------------------------------------------*/

#include "usb.h"
#include "uart.h"
#include "usb_req_class.h"

/* 约 1 秒忙等（24MHz 下粗调）。 */
static void delay_1s(void)
{
    unsigned int i, j;
    for (i = 0; i < 2000; i++)
        for (j = 0; j < 2000; j++)
            ;
}

/* 通过 USB-CDC 端点 1 发送一个短字符串（< EP1IN_SIZE）。 */
static void cdc_puts(const char *s)
{
    BYTE i;
    if (DeviceState != DEVSTATE_CONFIGURED)
        return;
    IE2 &= ~0x80;              /* 关 USB 中断，避免与 ISR 争端点 */
    UsbInBusy = 1;
    usb_write_reg(INDEX, 1);
    for (i = 0; s[i] != 0; i++)
        usb_write_reg(FIFO1, (BYTE)s[i]);
    usb_write_reg(INCSR1, INIPRDY);
    IE2 |= 0x80;
}

void main()
{
    WTST = 0;      /* 指令等待 0，最快 */
    P_SW2 |= 0x80; /* 使能扩展寄存器(XFR)访问 */
    CKCON = 0;     /* 提高 XRAM 访问速度 */

    usb_init();
    EA = 1;

    while (1)
    {
        cdc_puts("hello world\r\n");
        delay_1s();
    }
}
