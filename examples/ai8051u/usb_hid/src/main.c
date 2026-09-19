/*---------------------------------------------------------------------*/
/* --- Web: www.STCAI.com ---------------------------------------------*/
/*---------------------------------------------------------------------*/

/* HID(Human Interface Device) 协议范例 —— SDCC 移植版。
 *
 * 原例程：主机经 EP1 OUT 发报告，设备原路回显（见 usb.c 的 usb_out_ep1）。
 * 本板**没有按键**，改为**持续输出**：设备配置完成后，主循环周期性往 EP1 IN
 * 发 64 字节报告（内容 = 递增计数器的模式），供主机（如 STC-ISP 的 HID 收发测试）
 * 持续观察设备上报。
 *
 * 说明：
 *   - IVT 只在含 main 的模块生成，故本工程用单编译单元 usb_hid_all.c（见 docs/14）；
 *   - ISR 共享变量已加 volatile；
 *   - 时钟：本板 IRC 40MHz（USB 用内部 IRC48M，与 FOSC 无关）。
 */

#include "usb.h"

void main()
{
    BYTE i;
    BYTE n = 0;
    unsigned int d;

    WTST = 0;         /* 指令等待：0 = 最快 */
    P_SW2 |= 0x80;    /* EAXFR=1：允许访问扩展寄存器(XFR)（EAXFR 是位掩码，非可位寻址）*/
    CKCON = 0;        /* 提高访问 XRAM 速度 */

    usb_init();
    EA = 1;

    while (1)
    {
        if (DeviceState == DEVSTATE_CONFIGURED)
        {
            IE2 &= ~0x80;                 /* 访问 USB 寄存器时关 USB 中断，避免与 ISR 抢 USBADR */
            usb_write_reg(INDEX, 1);
            if (!(usb_read_reg(INCSR1) & INIPRDY))
            {
                for (i = 0; i < 64; i++) UsbBuffer[i] = (BYTE)(n + i);
                usb_bulk_intr_in(UsbBuffer, 64, 1);   /* EP1 IN 发一帧 64 字节报告 */
                n++;
            }
            IE2 |= 0x80;

            for (d = 0; d < 20000; d++) { }          /* 简单节流 */
        }
    }
}
