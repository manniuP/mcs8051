/*---------------------------------------------------------------------*/
/* --- Web: www.STCAI.com ---------------------------------------------*/
/*---------------------------------------------------------------------*/

#include "usb.h"
#include "uart.h"
#include "usb_req_class.h"

volatile BOOL UartBusy;

void uart_init()
{
    P_SW2 |= 0x01;
    P4M0 &= ~0x0c;
    P4M1 &= ~0x0c;
    P4M0 |= 0x08;   /* P4.3(TXD2) 推挽输出：回环/高速下驱动更干净 */
    P4M1 &= ~0x08;

    S2CON = 0x50;
    T2L = BR(115200);
    T2H = BR(115200) >> 8;
    AUXR |= 0x04;
    AUXR |= 0x10;
    IP2 |= 0x01;    //提高串口2中断优先级，防止数据丢失
    IE2 |= 0x01;

    LineCoding.dwDTERate = 0x00c20100;  //115200
    LineCoding.bCharFormat = 0;
    LineCoding.bParityType = 0;
    LineCoding.bDataBits = 8;
}

void uart2_isr() __interrupt(UART2_VECTOR)
{
    if ((S2CON & 0x02))
    {
        S2CON &= ~0x02;
        UartBusy = 0;
    }

    if ((S2CON & 0x01))
    {
        S2CON &= ~0x01;
        TxBuffer[TxWptr++] = S2BUF;
    }
}

void uart_set_parity(BYTE parity)
{
    switch (parity)
    {
    case NONE_PARITY:
        S2CON = 0x50;
        break;
    case ODD_PARITY:
    case EVEN_PARITY:
    case MARK_PARITY:
        S2CON = 0xda;
        break;
    case SPACE_PARITY:
        S2CON = 0xd2;
        break;
    }
}

void uart_set_baud(DWORD baud)
{
    WORD temp;

    switch (baud)
    {
    case 300:
        T2L = BR(300);
        T2H = BR(300) >> 8;
        break;
    case 600:
        T2L = BR(600);
        T2H = BR(600) >> 8;
        break;
    case 1200:
        T2L = BR(1200);
        T2H = BR(1200) >> 8;
        break;
    case 2400:
        T2L = BR(2400);
        T2H = BR(2400) >> 8;
        break;
    case 4800:
        T2L = BR(4800);
        T2H = BR(4800) >> 8;
        break;
    case 9600:
        T2L = BR(9600);
        T2H = BR(9600) >> 8;
        break;
    case 14400:
        T2L = BR(14400);
        T2H = BR(14400) >> 8;
        break;
    case 19200:
        T2L = BR(19200);
        T2H = BR(19200) >> 8;
        break;
    case 28800:
        T2L = BR(28800);
        T2H = BR(28800) >> 8;
        break;
    case 38400:
        T2L = BR(38400);
        T2H = BR(38400) >> 8;
        break;
    case 57600:
        T2L = BR(57600);
        T2H = BR(57600) >> 8;
        break;
    case 115200:
        T2L = BR(115200);
        T2H = BR(115200) >> 8;
        break;
    case 230400:
        T2L = BR(230400);
        T2H = BR(230400) >> 8;
        break;
    case 460800:
        T2L = BR(460800);
        T2H = BR(460800) >> 8;
        break;
    default:
        temp = (WORD)BR(baud);
        T2L = temp;
        T2H = temp >> 8;
        break;
    }
}

void uart_polling()
{
    BYTE dat;
    BYTE cnt;

    if (DeviceState != DEVSTATE_CONFIGURED)
        return;

#ifdef USB_CDC_DIRECT_ECHO
    /* 调试：USB 数据直接回显（不经 UART2），用于隔离 USB 数据通路与 UART2。 */
    while (RxRptr != RxWptr)
    {
        TxBuffer[TxWptr++] = RxBuffer[RxRptr++];
    }
    return;
#endif

    if (!UsbInBusy && (TxRptr != TxWptr))
    {
        IE2 &= ~0x80;
        UsbInBusy = 1;
        usb_write_reg(INDEX, 1);
        cnt = 0;
        while (TxRptr != TxWptr)
        {
            usb_write_reg(FIFO1, TxBuffer[TxRptr++]);
            cnt++;
            if (cnt == EP1IN_SIZE) break;
        }
        usb_write_reg(INCSR1, INIPRDY);
        IE2 |= 0x80;
    }

    if (!UartBusy && (RxRptr != RxWptr))
    {
        dat = RxBuffer[RxRptr++];
        UartBusy = 1;
        switch (LineCoding.bParityType)
        {
        case NONE_PARITY:
        case SPACE_PARITY:
            S2CON &= ~0x08;
            break;
        case ODD_PARITY:
            ACC = dat;
            S2CON = (unsigned char)((S2CON & ~0x08) | ((!P) ? 0x08 : 0));
            break;
        case EVEN_PARITY:
            ACC = dat;
            S2CON = (unsigned char)((S2CON & ~0x08) | ((P) ? 0x08 : 0));
            break;
        case MARK_PARITY:
            S2CON |= 0x08;
            break;
        }
        S2BUF = dat;

        while (UartBusy);
    }

    if (UsbOutBusy)
    {
        IE2 &= ~0x80;
        if (RxWptr - RxRptr < 256 - EP1OUT_SIZE)
        {
            UsbOutBusy = 0;
            usb_write_reg(INDEX, 1);
            usb_write_reg(OUTCSR1, 0);
        }
        IE2 |= 0x80;
    }
}

