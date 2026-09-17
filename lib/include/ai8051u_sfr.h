/*
 * ai8051u_sfr.h —— AI8051U（MCS-251 核）SFR / XFR / 位定义（SDCC 版）
 *
 * 由 tools/keil2sdcc.py 从 STC 官方 Keil 头文件自动生成，请勿手改。
 * 源文件: AI8051U.keil.h
 *
 * 约定：
 *   - 直接 SFR（0x80-0xFF）用 SFR()/SBIT()，定义见 c51.h。
 *   - 扩展 SFR（XFR，0x7E:xxxx）用 __xdata 指针；访问前必须 EAXFR=1。
 *   - 基址不是 8 的倍数的 SFR 位，SDCC 无法位寻址，已退化为掩码 #define，
 *     代码需用 |=、&= 等字节位操作，不能写 NAME = 1。
 */

#ifndef AI8051U_SFR_H
#define AI8051U_SFR_H

#include "c51.h"
#include "mcs_intrins.h"
#include <stdio.h>

/* SDCC <stdio.h> 经 compiler.h 已定义零参数 NOP()，此处解除，改用下面的 NOP(n) */
#undef NOP


/////////////////////////////////////////////////


//修正编译器的LCALL 0x0000异常

/////////////////////////////////////////////////

SFR(P0, 0x80);
SBIT(P00, 0x80);
SBIT(P01, 0x81);
SBIT(P02, 0x82);
SBIT(P03, 0x83);
SBIT(P04, 0x84);
SBIT(P05, 0x85);
SBIT(P06, 0x86);
SBIT(P07, 0x87);

SFR(SP, 0x81);
SFR(DPL, 0x82);
SFR(DPH, 0x83);
SFR(DPXL, 0x84);
SFR(SPH, 0x85);

SFR(PCON, 0x87);
#define SMOD 0x80  /* PCON^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define SMOD0 0x40  /* PCON^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define LVDF 0x20  /* PCON^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define POF 0x10  /* PCON^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define GF1 0x08  /* PCON^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define GF0 0x04  /* PCON^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PD 0x02  /* PCON^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define IDL 0x01  /* PCON^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(TCON, 0x88);
SBIT(TF1, 0x8F);
SBIT(TR1, 0x8E);
SBIT(TF0, 0x8D);
SBIT(TR0, 0x8C);
SBIT(IE1, 0x8B);
SBIT(IT1, 0x8A);
SBIT(IE0, 0x89);
SBIT(IT0, 0x88);

SFR(TMOD, 0x89);
#define T1_GATE 0x80  /* TMOD^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T1_CT 0x40  /* TMOD^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T1_M1 0x20  /* TMOD^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T1_M0 0x10  /* TMOD^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T0_GATE 0x08  /* TMOD^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T0_CT 0x04  /* TMOD^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T0_M1 0x02  /* TMOD^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T0_M0 0x01  /* TMOD^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(TL0, 0x8a);
SFR(TL1, 0x8b);
SFR(TH0, 0x8c);
SFR(TH1, 0x8d);

SFR(AUXR, 0x8e);
#define T0x12 0x80  /* AUXR^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T1x12 0x40  /* AUXR^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S1M0x6 0x20  /* AUXR^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T2R 0x10  /* AUXR^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T2_CT 0x08  /* AUXR^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T2x12 0x04  /* AUXR^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define EXTRAM 0x02  /* AUXR^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S1BRT 0x01  /* AUXR^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(INTCLKO, 0x8f);
#define EX4 0x40  /* INTCLKO^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define EX3 0x20  /* INTCLKO^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define EX2 0x10  /* INTCLKO^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T2CLKO 0x04  /* INTCLKO^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T1CLKO 0x02  /* INTCLKO^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T0CLKO 0x01  /* INTCLKO^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(P1, 0x90);
SBIT(P10, 0x90);
SBIT(P11, 0x91);
SBIT(P12, 0x92);
SBIT(P13, 0x93);
SBIT(P14, 0x94);
SBIT(P15, 0x95);
SBIT(P16, 0x96);
SBIT(P17, 0x97);

SFR(P1M1, 0x91);
SFR(P1M0, 0x92);
SFR(P0M1, 0x93);
SFR(P0M0, 0x94);
SFR(P2M1, 0x95);
SFR(P2M0, 0x96);

SFR(AUXR2, 0x97);
#define RAMTINY 0x80  /* AUXR2^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CPUMODE 0x40  /* AUXR2^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define RAMEXE 0x20  /* AUXR2^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CANFD 0x10  /* AUXR2^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CANSEL 0x08  /* AUXR2^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CAN2EN 0x04  /* AUXR2^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CANEN 0x02  /* AUXR2^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define LINEN 0x01  /* AUXR2^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(SCON, 0x98);
SBIT(SM0, 0x9F);
SBIT(SM1, 0x9E);
SBIT(SM2, 0x9D);
SBIT(REN, 0x9C);
SBIT(TB8, 0x9B);
SBIT(RB8, 0x9A);
SBIT(TI, 0x99);
SBIT(RI, 0x98);

SFR(SBUF, 0x99);

SFR(S2CON, 0x9a);
#define S2SM0 0x80  /* S2CON^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S2SM1 0x40  /* S2CON^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S2SM2 0x20  /* S2CON^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S2REN 0x10  /* S2CON^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S2TB8 0x08  /* S2CON^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S2RB8 0x04  /* S2CON^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S2TI 0x02  /* S2CON^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S2RI 0x01  /* S2CON^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(S2BUF, 0x9b);

SFR(IRCBAND, 0x9d);
#define USBCKS 0x80  /* IRCBAND^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define USBCKS2 0x40  /* IRCBAND^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define HIRCSEL1 0x02  /* IRCBAND^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define HIRCSEL0 0x01  /* IRCBAND^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(LIRTRIM, 0x9e);
SFR(IRTRIM, 0x9f);

SFR(P2, 0xa0);
SBIT(P20, 0xA0);
SBIT(P21, 0xA1);
SBIT(P22, 0xA2);
SBIT(P23, 0xA3);
SBIT(P24, 0xA4);
SBIT(P25, 0xA5);
SBIT(P26, 0xA6);
SBIT(P27, 0xA7);

SFR(BUS_SPEED, 0xa1);

SFR(P_SW1, 0xa2);
#define S1_S1 0x80  /* P_SW1^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S1_S0 0x40  /* P_SW1^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CAN_S1 0x20  /* P_SW1^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CAN_S0 0x10  /* P_SW1^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define SPI_S1 0x08  /* P_SW1^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define SPI_S0 0x04  /* P_SW1^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define LIN_S1 0x02  /* P_SW1^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define LIN_S0 0x01  /* P_SW1^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(VRTRIM, 0xa6);

SFR(IE, 0xa8);
SBIT(EA, 0xAF);
SBIT(ELVD, 0xAE);
SBIT(EADC, 0xAD);
SBIT(ES, 0xAC);
SBIT(ET1, 0xAB);
SBIT(EX1, 0xAA);
SBIT(ET0, 0xA9);
SBIT(EX0, 0xA8);

SFR(SADDR, 0xa9);
SFR(WKTCL, 0xaa);
SFR(WKTCH, 0xab);

SFR(S3CON, 0xac);
#define S3SM0 0x80  /* S3CON^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S3ST3 0x40  /* S3CON^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S3SM2 0x20  /* S3CON^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S3REN 0x10  /* S3CON^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S3TB8 0x08  /* S3CON^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S3RB8 0x04  /* S3CON^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S3TI 0x02  /* S3CON^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S3RI 0x01  /* S3CON^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(S3BUF, 0xad);
SFR(TA, 0xae);

SFR(IE2, 0xaf);
#define EUSB 0x80  /* IE2^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define ET4 0x40  /* IE2^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define ET3 0x20  /* IE2^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define ES4 0x10  /* IE2^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define ES3 0x08  /* IE2^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define ET2 0x04  /* IE2^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define ESPI 0x02  /* IE2^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define ES2 0x01  /* IE2^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(P3, 0xb0);
SBIT(P30, 0xB0);
SBIT(P31, 0xB1);
SBIT(P32, 0xB2);
SBIT(P33, 0xB3);
SBIT(P34, 0xB4);
SBIT(P35, 0xB5);
SBIT(P36, 0xB6);
SBIT(P37, 0xB7);

SBIT(RD, 0xB7);
SBIT(WR, 0xB6);
SBIT(T1, 0xB5);
SBIT(T0, 0xB4);
SBIT(INT1, 0xB3);
SBIT(INT0, 0xB2);
SBIT(TXD, 0xB1);
SBIT(RXD, 0xB0);

SFR(P3M1, 0xb1);
SFR(P3M0, 0xb2);
SFR(P4M1, 0xb3);
SFR(P4M0, 0xb4);

SFR(IP2, 0xb5);
#define PUSB 0x80  /* IP2^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PI2C 0x40  /* IP2^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PCMP 0x20  /* IP2^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PX4 0x10  /* IP2^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PPWMB 0x08  /* IP2^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PPWMA 0x04  /* IP2^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PSPI 0x02  /* IP2^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PS2 0x01  /* IP2^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(IP2H, 0xb6);
#define PUSBH 0x80  /* IP2H^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PI2CH 0x40  /* IP2H^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PCMPH 0x20  /* IP2H^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PX4H 0x10  /* IP2H^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PPWMBH 0x08  /* IP2H^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PPWMAH 0x04  /* IP2H^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PSPIH 0x02  /* IP2H^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PS2H 0x01  /* IP2H^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(IPH, 0xb7);
#define PPCAH 0x80  /* IPH^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PLVDH 0x40  /* IPH^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PADCH 0x20  /* IPH^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PSH 0x10  /* IPH^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PT1H 0x08  /* IPH^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PX1H 0x04  /* IPH^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PT0H 0x02  /* IPH^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PX0H 0x01  /* IPH^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(IP, 0xb8);
SBIT(PPCA, 0xBF);
SBIT(PLVD, 0xBE);
SBIT(PADC, 0xBD);
SBIT(PS, 0xBC);
SBIT(PT1, 0xBB);
SBIT(PX1, 0xBA);
SBIT(PT0, 0xB9);
SBIT(PX0, 0xB8);

SFR(SADEN, 0xb9);

SFR(P_SW2, 0xba);
#define EAXFR 0x80  /* P_SW2^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define I2C_S1 0x20  /* P_SW2^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define I2C_S0 0x10  /* P_SW2^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CMPO_S 0x08  /* P_SW2^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S4_S 0x04  /* P_SW2^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S3_S 0x02  /* P_SW2^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S2_S 0x01  /* P_SW2^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(P_SW3, 0xbb);
#define I2S_S1 0x80  /* P_SW3^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define I2S_S0 0x40  /* P_SW3^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S2SPI_S1 0x20  /* P_SW3^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S2SPI_S0 0x10  /* P_SW3^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S1SPI_S1 0x08  /* P_SW3^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S1SPI_S0 0x04  /* P_SW3^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CAN2_S1 0x02  /* P_SW3^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CAN2_S0 0x01  /* P_SW3^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(ADC_CONTR, 0xbc);
#define ADC_POWER 0x80  /* ADC_CONTR^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define ADC_START 0x40  /* ADC_CONTR^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define ADC_FLAG 0x20  /* ADC_CONTR^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define ADC_EPWMT 0x10  /* ADC_CONTR^4: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(ADC_RES, 0xbd);
SFR(ADC_RESL, 0xbe);

SFR(P_SW4, 0xbf);
#define QSPI_S1 0x02  /* P_SW4^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define QSPI_S0 0x01  /* P_SW4^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(P4, 0xc0);
SBIT(P40, 0xC0);
SBIT(P41, 0xC1);
SBIT(P42, 0xC2);
SBIT(P43, 0xC3);
SBIT(P44, 0xC4);
SBIT(P45, 0xC5);
SBIT(P46, 0xC6);
SBIT(P47, 0xC7);

SFR(WDT_CONTR, 0xc1);
#define WDT_FLAG 0x80  /* WDT_CONTR^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define EN_WDT 0x20  /* WDT_CONTR^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CLR_WDT 0x10  /* WDT_CONTR^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define IDL_WDT 0x08  /* WDT_CONTR^3: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(IAP_DATA, 0xc2);
SFR(IAP_ADDRH, 0xc3);
SFR(IAP_ADDRL, 0xc4);
SFR(IAP_CMD, 0xc5);
SFR(IAP_TRIG, 0xc6);

SFR(IAP_CONTR, 0xc7);
#define IAPEN 0x80  /* IAP_CONTR^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define SWBS 0x40  /* IAP_CONTR^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define SWRST 0x20  /* IAP_CONTR^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CMD_FAIL 0x10  /* IAP_CONTR^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define SWBS2 0x08  /* IAP_CONTR^3: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(P5, 0xc8);
SBIT(P50, 0xC8);
SBIT(P51, 0xC9);
SBIT(P52, 0xCA);
SBIT(P53, 0xCB);
SBIT(P54, 0xCC);
SBIT(P55, 0xCD);
SBIT(P56, 0xCE);
SBIT(P57, 0xCF);

SFR(P5M1, 0xc9);
SFR(P5M0, 0xca);
SFR(P6M1, 0xcb);
SFR(P6M0, 0xcc);

SFR(SPSTAT, 0xcd);
#define SPIF 0x80  /* SPSTAT^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define WCOL 0x40  /* SPSTAT^6: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(SPCTL, 0xce);
#define SSIG 0x80  /* SPCTL^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define SPEN 0x40  /* SPCTL^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define DORD 0x20  /* SPCTL^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define MSTR 0x10  /* SPCTL^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CPOL 0x08  /* SPCTL^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CPHA 0x04  /* SPCTL^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define SPR1 0x02  /* SPCTL^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define SPR0 0x01  /* SPCTL^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(SPDAT, 0xcf);

SFR(PSW, 0xd0);
SBIT(CY, 0xD7);
SBIT(AC, 0xD6);
SBIT(F0, 0xD5);
SBIT(RS1, 0xD4);
SBIT(RS0, 0xD3);
SBIT(OV, 0xD2);
SBIT(F1, 0xD1);
SBIT(P, 0xD0);

SFR(PSW1, 0xd1);
#define N 0x20  /* PSW1^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define Z 0x02  /* PSW1^1: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(T4H, 0xd2);
SFR(T4L, 0xd3);
SFR(T3H, 0xd4);
SFR(T3L, 0xd5);
SFR(T2H, 0xd6);
SFR(T2L, 0xd7);

SFR(TH4, 0xd2);
SFR(TL4, 0xd3);
SFR(TH3, 0xd4);
SFR(TL3, 0xd5);
SFR(TH2, 0xd6);
SFR(TL2, 0xd7);

SFR(USBCLK, 0xdc);

SFR(T3T4M, 0xdd);
SFR(T4T3M, 0xdd);
#define T4R 0x80  /* T4T3M^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T4_CT 0x40  /* T4T3M^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T4x12 0x20  /* T4T3M^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T4CLKO 0x10  /* T4T3M^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T3R 0x08  /* T4T3M^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T3_CT 0x04  /* T4T3M^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T3x12 0x02  /* T4T3M^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T3CLKO 0x01  /* T4T3M^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(ADCCFG, 0xde);
#define RESFMT 0x20  /* ADCCFG^5: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(IP3, 0xdf);
#define PI2S 0x08  /* IP3^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PRTC 0x04  /* IP3^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PS4 0x02  /* IP3^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PS3 0x01  /* IP3^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(ACC, 0xe0);
SFR(P7M1, 0xe1);
SFR(P7M0, 0xe2);
SFR(DPS, 0xe3);

SFR(CMPCR1, 0xe6);
#define CMPEN 0x80  /* CMPCR1^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CMPIF 0x40  /* CMPCR1^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PIE 0x20  /* CMPCR1^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define NIE 0x10  /* CMPCR1^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CMPOE 0x02  /* CMPCR1^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define CMPRES 0x01  /* CMPCR1^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(CMPCR2, 0xe7);
#define INVCMPO 0x80  /* CMPCR2^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define DISFLT 0x40  /* CMPCR2^6: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(P6, 0xe8);
SBIT(P60, 0xE8);
SBIT(P61, 0xE9);
SBIT(P62, 0xEA);
SBIT(P63, 0xEB);
SBIT(P64, 0xEC);
SBIT(P65, 0xED);
SBIT(P66, 0xEE);
SBIT(P67, 0xEF);

SFR(WTST, 0xe9);
SFR(CKCON, 0xea);
SFR(MXAX, 0xeb);
SFR(USBDAT, 0xec);
SFR(DMAIR, 0xed);

SFR(IP3H, 0xee);
#define PI2SH 0x08  /* IP3H^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PRTCH 0x04  /* IP3H^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PS4H 0x02  /* IP3H^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PS3H 0x01  /* IP3H^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(AUXINTIF, 0xef);
#define INT4IF 0x40  /* AUXINTIF^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define INT3IF 0x20  /* AUXINTIF^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define INT2IF 0x10  /* AUXINTIF^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T4IF 0x04  /* AUXINTIF^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T3IF 0x02  /* AUXINTIF^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define T2IF 0x01  /* AUXINTIF^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(B, 0xf0);
SBIT(B0, 0xF0);
SBIT(B1, 0xF1);
SBIT(B2, 0xF2);
SBIT(B3, 0xF3);
SBIT(B4, 0xF4);
SBIT(B5, 0xF5);
SBIT(B6, 0xF6);
SBIT(B7, 0xF7);

SFR(USBCON, 0xf4);
#define ENUSB 0x80  /* USBCON^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define ENUSBRST 0x40  /* USBCON^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PS2M 0x20  /* USBCON^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PUEN 0x10  /* USBCON^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define PDEN 0x08  /* USBCON^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define DFREC 0x04  /* USBCON^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define DP 0x02  /* USBCON^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define DM 0x01  /* USBCON^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(IAP_TPS, 0xf5);
SFR(IAP_ADDRE, 0xf6);

SFR(P7, 0xf8);
SBIT(P70, 0xF8);
SBIT(P71, 0xF9);
SBIT(P72, 0xFA);
SBIT(P73, 0xFB);
SBIT(P74, 0xFC);
SBIT(P75, 0xFD);
SBIT(P76, 0xFE);
SBIT(P77, 0xFF);

SFR(USBADR, 0xfc);

SFR(S4CON, 0xfd);
#define S4SM0 0x80  /* S4CON^7: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S4ST4 0x40  /* S4CON^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S4SM2 0x20  /* S4CON^5: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S4REN 0x10  /* S4CON^4: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S4TB8 0x08  /* S4CON^3: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S4RB8 0x04  /* S4CON^2: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S4TI 0x02  /* S4CON^1: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define S4RI 0x01  /* S4CON^0: 基址非8倍数，SDCC不可位寻址，用掩码 */

SFR(S4BUF, 0xfe);

SFR(RSTCFG, 0xff);
#define ENLVR 0x40  /* RSTCFG^6: 基址非8倍数，SDCC不可位寻址，用掩码 */
#define P47RST 0x10  /* RSTCFG^4: 基址非8倍数，SDCC不可位寻址，用掩码 */

/////////////////////////////////////////////////
//
//如下特殊功能寄存器位于扩展RAM区域
//访问这些寄存器,需先将EAXFR设置为1,才可正常读写
//    EAXFR = 1;
//或者
//    P_SW2 |= 0x80;
///////////////////////////////////////////////////

/////////////////////////////////////////////////
//7E:FF00H-7E:FFFFH
/////////////////////////////////////////////////



/////////////////////////////////////////////////
//7E:FE00H-7E:FEFFH
/////////////////////////////////////////////////

#define     CLKSEL                  (*(volatile unsigned char __xdata *)0x7efe00)
#define     CLKDIV                  (*(volatile unsigned char __xdata *)0x7efe01)
#define     HIRCCR                  (*(volatile unsigned char __xdata *)0x7efe02)
#define     XOSCCR                  (*(volatile unsigned char __xdata *)0x7efe03)
#define     IRC32KCR                (*(volatile unsigned char __xdata *)0x7efe04)
#define     MCLKOCR                 (*(volatile unsigned char __xdata *)0x7efe05)
#define     IRCDB                   (*(volatile unsigned char __xdata *)0x7efe06)
#define     IRC48MCR                (*(volatile unsigned char __xdata *)0x7efe07)
#define     X32KCR                  (*(volatile unsigned char __xdata *)0x7efe08)
#define     HSCLKDIV                (*(volatile unsigned char __xdata *)0x7efe0b)

#define     P0PU                    (*(volatile unsigned char __xdata *)0x7efe10)
#define     P1PU                    (*(volatile unsigned char __xdata *)0x7efe11)
#define     P2PU                    (*(volatile unsigned char __xdata *)0x7efe12)
#define     P3PU                    (*(volatile unsigned char __xdata *)0x7efe13)
#define     P4PU                    (*(volatile unsigned char __xdata *)0x7efe14)
#define     P5PU                    (*(volatile unsigned char __xdata *)0x7efe15)
#define     P6PU                    (*(volatile unsigned char __xdata *)0x7efe16)
#define     P7PU                    (*(volatile unsigned char __xdata *)0x7efe17)
#define     P0NCS                   (*(volatile unsigned char __xdata *)0x7efe18)
#define     P1NCS                   (*(volatile unsigned char __xdata *)0x7efe19)
#define     P2NCS                   (*(volatile unsigned char __xdata *)0x7efe1a)
#define     P3NCS                   (*(volatile unsigned char __xdata *)0x7efe1b)
#define     P4NCS                   (*(volatile unsigned char __xdata *)0x7efe1c)
#define     P5NCS                   (*(volatile unsigned char __xdata *)0x7efe1d)
#define     P6NCS                   (*(volatile unsigned char __xdata *)0x7efe1e)
#define     P7NCS                   (*(volatile unsigned char __xdata *)0x7efe1f)
#define     P0SR                    (*(volatile unsigned char __xdata *)0x7efe20)
#define     P1SR                    (*(volatile unsigned char __xdata *)0x7efe21)
#define     P2SR                    (*(volatile unsigned char __xdata *)0x7efe22)
#define     P3SR                    (*(volatile unsigned char __xdata *)0x7efe23)
#define     P4SR                    (*(volatile unsigned char __xdata *)0x7efe24)
#define     P5SR                    (*(volatile unsigned char __xdata *)0x7efe25)
#define     P6SR                    (*(volatile unsigned char __xdata *)0x7efe26)
#define     P7SR                    (*(volatile unsigned char __xdata *)0x7efe27)
#define     P0DR                    (*(volatile unsigned char __xdata *)0x7efe28)
#define     P1DR                    (*(volatile unsigned char __xdata *)0x7efe29)
#define     P2DR                    (*(volatile unsigned char __xdata *)0x7efe2a)
#define     P3DR                    (*(volatile unsigned char __xdata *)0x7efe2b)
#define     P4DR                    (*(volatile unsigned char __xdata *)0x7efe2c)
#define     P5DR                    (*(volatile unsigned char __xdata *)0x7efe2d)
#define     P6DR                    (*(volatile unsigned char __xdata *)0x7efe2e)
#define     P7DR                    (*(volatile unsigned char __xdata *)0x7efe2f)
#define     P0IE                    (*(volatile unsigned char __xdata *)0x7efe30)
#define     P1IE                    (*(volatile unsigned char __xdata *)0x7efe31)
#define     P2IE                    (*(volatile unsigned char __xdata *)0x7efe32)
#define     P3IE                    (*(volatile unsigned char __xdata *)0x7efe33)
#define     P4IE                    (*(volatile unsigned char __xdata *)0x7efe34)
#define     P5IE                    (*(volatile unsigned char __xdata *)0x7efe35)
#define     P6IE                    (*(volatile unsigned char __xdata *)0x7efe36)
#define     P7IE                    (*(volatile unsigned char __xdata *)0x7efe37)
#define     P0PD                    (*(volatile unsigned char __xdata *)0x7efe40)
#define     P1PD                    (*(volatile unsigned char __xdata *)0x7efe41)
#define     P2PD                    (*(volatile unsigned char __xdata *)0x7efe42)
#define     P3PD                    (*(volatile unsigned char __xdata *)0x7efe43)
#define     P4PD                    (*(volatile unsigned char __xdata *)0x7efe44)
#define     P5PD                    (*(volatile unsigned char __xdata *)0x7efe45)
#define     P6PD                    (*(volatile unsigned char __xdata *)0x7efe46)
#define     P7PD                    (*(volatile unsigned char __xdata *)0x7efe47)
#define     P0BP                    (*(volatile unsigned char __xdata *)0x7efe48)
#define     P1BP                    (*(volatile unsigned char __xdata *)0x7efe49)
#define     P2BP                    (*(volatile unsigned char __xdata *)0x7efe4a)
#define     P3BP                    (*(volatile unsigned char __xdata *)0x7efe4b)
#define     P4BP                    (*(volatile unsigned char __xdata *)0x7efe4c)
#define     P5BP                    (*(volatile unsigned char __xdata *)0x7efe4d)
#define     P6BP                    (*(volatile unsigned char __xdata *)0x7efe4e)
#define     P7BP                    (*(volatile unsigned char __xdata *)0x7efe4f)

#define     LCMIFCFG                (*(volatile unsigned char __xdata *)0x7efe50)
#define     LCMIFCFG2               (*(volatile unsigned char __xdata *)0x7efe51)
#define     LCMIFCR                 (*(volatile unsigned char __xdata *)0x7efe52)
#define     LCMIFSTA                (*(volatile unsigned char __xdata *)0x7efe53)
#define     LCMIFDATL               (*(volatile unsigned char __xdata *)0x7efe54)
#define     LCMIFDATH               (*(volatile unsigned char __xdata *)0x7efe55)
#define     LCMIFPSCR               (*(volatile unsigned char __xdata *)0x7efe56)

#define     RTCCR                   (*(volatile unsigned char __xdata *)0x7efe60)
#define     RTCCFG                  (*(volatile unsigned char __xdata *)0x7efe61)
#define     RTCIEN                  (*(volatile unsigned char __xdata *)0x7efe62)
#define     RTCIF                   (*(volatile unsigned char __xdata *)0x7efe63)
#define     ALAHOUR                 (*(volatile unsigned char __xdata *)0x7efe64)
#define     ALAMIN                  (*(volatile unsigned char __xdata *)0x7efe65)
#define     ALASEC                  (*(volatile unsigned char __xdata *)0x7efe66)
#define     ALASSEC                 (*(volatile unsigned char __xdata *)0x7efe67)
#define     INIYEAR                 (*(volatile unsigned char __xdata *)0x7efe68)
#define     INIMONTH                (*(volatile unsigned char __xdata *)0x7efe69)
#define     INIDAY                  (*(volatile unsigned char __xdata *)0x7efe6a)
#define     INIHOUR                 (*(volatile unsigned char __xdata *)0x7efe6b)
#define     INIMIN                  (*(volatile unsigned char __xdata *)0x7efe6c)
#define     INISEC                  (*(volatile unsigned char __xdata *)0x7efe6d)
#define     INISSEC                 (*(volatile unsigned char __xdata *)0x7efe6e)
#define     INIWEEK                 (*(volatile unsigned char __xdata *)0x7efe6f)
#define     WEEK                    (*(volatile unsigned char __xdata *)0x7efe6f)
#define     YEAR                    (*(volatile unsigned char __xdata *)0x7efe70)
#define     MONTH                   (*(volatile unsigned char __xdata *)0x7efe71)
#define     DAY                     (*(volatile unsigned char __xdata *)0x7efe72)
#define     HOUR                    (*(volatile unsigned char __xdata *)0x7efe73)
#define     MIN                     (*(volatile unsigned char __xdata *)0x7efe74)
#define     SEC                     (*(volatile unsigned char __xdata *)0x7efe75)
#define     SSEC                    (*(volatile unsigned char __xdata *)0x7efe76)

#define     T11CR                   (*(volatile unsigned char __xdata *)0x7efe78)
#define     T11PS                   (*(volatile unsigned char __xdata *)0x7efe79)
#define     T11H                    (*(volatile unsigned char __xdata *)0x7efe7a)
#define     T11L                    (*(volatile unsigned char __xdata *)0x7efe7b)

#define     I2CCFG                  (*(volatile unsigned char __xdata *)0x7efe80)
#define     I2CMSCR                 (*(volatile unsigned char __xdata *)0x7efe81)
#define     I2CMSST                 (*(volatile unsigned char __xdata *)0x7efe82)
#define     I2CSLCR                 (*(volatile unsigned char __xdata *)0x7efe83)
#define     I2CSLST                 (*(volatile unsigned char __xdata *)0x7efe84)
#define     I2CSLADR                (*(volatile unsigned char __xdata *)0x7efe85)
#define     I2CTXD                  (*(volatile unsigned char __xdata *)0x7efe86)
#define     I2CRXD                  (*(volatile unsigned char __xdata *)0x7efe87)
#define     I2CMSAUX                (*(volatile unsigned char __xdata *)0x7efe88)
#define     I2CPSCR                 (*(volatile unsigned char __xdata *)0x7efe89)

#define     SPI_CLKDIV              (*(volatile unsigned char __xdata *)0x7efe90)
#define     PWMA_CLKDIV             (*(volatile unsigned char __xdata *)0x7efe91)
#define     PWMB_CLKDIV             (*(volatile unsigned char __xdata *)0x7efe92)
#define     TFPU_CLKDIV             (*(volatile unsigned char __xdata *)0x7efe93)
#define     I2S_CLKDIV              (*(volatile unsigned char __xdata *)0x7efe94)

#define     RSTFLAG                 (*(volatile unsigned char __xdata *)0x7efe99)
#define     RSTCR0                  (*(volatile unsigned char __xdata *)0x7efe9a)
#define     RSTCR1                  (*(volatile unsigned char __xdata *)0x7efe9b)
#define     RSTCR2                  (*(volatile unsigned char __xdata *)0x7efe9c)
#define     RSTCR3                  (*(volatile unsigned char __xdata *)0x7efe9d)
#define     RSTCR4                  (*(volatile unsigned char __xdata *)0x7efe9e)
#define     RSTCR5                  (*(volatile unsigned char __xdata *)0x7efe9f)

#define     TM0PS                   (*(volatile unsigned char __xdata *)0x7efea0)
#define     TM1PS                   (*(volatile unsigned char __xdata *)0x7efea1)
#define     TM2PS                   (*(volatile unsigned char __xdata *)0x7efea2)
#define     TM3PS                   (*(volatile unsigned char __xdata *)0x7efea3)
#define     TM4PS                   (*(volatile unsigned char __xdata *)0x7efea4)
#define     ADCTIM                  (*(volatile unsigned char __xdata *)0x7efea8)
#define     ADCEXCFG                (*(volatile unsigned char __xdata *)0x7efead)
#define     CMPEXCFG                (*(volatile unsigned char __xdata *)0x7efeae)

#define     PWMA_ETRPS              (*(volatile unsigned char __xdata *)0x7efeb0)
#define     PWMA_ENO                (*(volatile unsigned char __xdata *)0x7efeb1)
#define     PWMA_PS                 (*(volatile unsigned char __xdata *)0x7efeb2)
#define     PWMA_IOAUX              (*(volatile unsigned char __xdata *)0x7efeb3)
#define     PWMB_ETRPS              (*(volatile unsigned char __xdata *)0x7efeb4)
#define     PWMB_ENO                (*(volatile unsigned char __xdata *)0x7efeb5)
#define     PWMB_PS                 (*(volatile unsigned char __xdata *)0x7efeb6)
#define     PWMB_IOAUX              (*(volatile unsigned char __xdata *)0x7efeb7)
#define     PWMA_PS2                (*(volatile unsigned char __xdata *)0x7efeb8)
#define     PWMA_RCRH               (*(volatile unsigned char __xdata *)0x7efeb9)
#define     PWMB_RCRH               (*(volatile unsigned char __xdata *)0x7efeba)

#define     PWMA_CR1                (*(volatile unsigned char __xdata *)0x7efec0)
#define     PWMA_CR2                (*(volatile unsigned char __xdata *)0x7efec1)
#define     PWMA_SMCR               (*(volatile unsigned char __xdata *)0x7efec2)
#define     PWMA_ETR                (*(volatile unsigned char __xdata *)0x7efec3)
#define     PWMA_IER                (*(volatile unsigned char __xdata *)0x7efec4)
#define     PWMA_SR1                (*(volatile unsigned char __xdata *)0x7efec5)
#define     PWMA_SR2                (*(volatile unsigned char __xdata *)0x7efec6)
#define     PWMA_EGR                (*(volatile unsigned char __xdata *)0x7efec7)
#define     PWMA_CCMR1              (*(volatile unsigned char __xdata *)0x7efec8)
#define     PWMA_CCMR2              (*(volatile unsigned char __xdata *)0x7efec9)
#define     PWMA_CCMR3              (*(volatile unsigned char __xdata *)0x7efeca)
#define     PWMA_CCMR4              (*(volatile unsigned char __xdata *)0x7efecb)
#define     PWMA_CCER1              (*(volatile unsigned char __xdata *)0x7efecc)
#define     PWMA_CCER2              (*(volatile unsigned char __xdata *)0x7efecd)
#define     PWMA_CNTRH              (*(volatile unsigned char __xdata *)0x7efece)
#define     PWMA_CNTRL              (*(volatile unsigned char __xdata *)0x7efecf)
#define     PWMA_PSCRH              (*(volatile unsigned char __xdata *)0x7efed0)
#define     PWMA_PSCRL              (*(volatile unsigned char __xdata *)0x7efed1)
#define     PWMA_ARRH               (*(volatile unsigned char __xdata *)0x7efed2)
#define     PWMA_ARRL               (*(volatile unsigned char __xdata *)0x7efed3)
#define     PWMA_RCR                (*(volatile unsigned char __xdata *)0x7efed4)
#define     PWMA_CCR1H              (*(volatile unsigned char __xdata *)0x7efed5)
#define     PWMA_CCR1L              (*(volatile unsigned char __xdata *)0x7efed6)
#define     PWMA_CCR2H              (*(volatile unsigned char __xdata *)0x7efed7)
#define     PWMA_CCR2L              (*(volatile unsigned char __xdata *)0x7efed8)
#define     PWMA_CCR3H              (*(volatile unsigned char __xdata *)0x7efed9)
#define     PWMA_CCR3L              (*(volatile unsigned char __xdata *)0x7efeda)
#define     PWMA_CCR4H              (*(volatile unsigned char __xdata *)0x7efedb)
#define     PWMA_CCR4L              (*(volatile unsigned char __xdata *)0x7efedc)
#define     PWMA_BKR                (*(volatile unsigned char __xdata *)0x7efedd)
#define     PWMA_DTR                (*(volatile unsigned char __xdata *)0x7efede)
#define     PWMA_OISR               (*(volatile unsigned char __xdata *)0x7efedf)

#define     PWMB_CR1                (*(volatile unsigned char __xdata *)0x7efee0)
#define     PWMB_CR2                (*(volatile unsigned char __xdata *)0x7efee1)
#define     PWMB_SMCR               (*(volatile unsigned char __xdata *)0x7efee2)
#define     PWMB_ETR                (*(volatile unsigned char __xdata *)0x7efee3)
#define     PWMB_IER                (*(volatile unsigned char __xdata *)0x7efee4)
#define     PWMB_SR1                (*(volatile unsigned char __xdata *)0x7efee5)
#define     PWMB_SR2                (*(volatile unsigned char __xdata *)0x7efee6)
#define     PWMB_EGR                (*(volatile unsigned char __xdata *)0x7efee7)
#define     PWMB_CCMR1              (*(volatile unsigned char __xdata *)0x7efee8)
#define     PWMB_CCMR2              (*(volatile unsigned char __xdata *)0x7efee9)
#define     PWMB_CCMR3              (*(volatile unsigned char __xdata *)0x7efeea)
#define     PWMB_CCMR4              (*(volatile unsigned char __xdata *)0x7efeeb)
#define     PWMB_CCER1              (*(volatile unsigned char __xdata *)0x7efeec)
#define     PWMB_CCER2              (*(volatile unsigned char __xdata *)0x7efeed)
#define     PWMB_CNTRH              (*(volatile unsigned char __xdata *)0x7efeee)
#define     PWMB_CNTRL              (*(volatile unsigned char __xdata *)0x7efeef)
#define     PWMB_PSCRH              (*(volatile unsigned char __xdata *)0x7efef0)
#define     PWMB_PSCRL              (*(volatile unsigned char __xdata *)0x7efef1)
#define     PWMB_ARRH               (*(volatile unsigned char __xdata *)0x7efef2)
#define     PWMB_ARRL               (*(volatile unsigned char __xdata *)0x7efef3)
#define     PWMB_RCR                (*(volatile unsigned char __xdata *)0x7efef4)
#define     PWMB_CCR5H              (*(volatile unsigned char __xdata *)0x7efef5)
#define     PWMB_CCR5L              (*(volatile unsigned char __xdata *)0x7efef6)
#define     PWMB_CCR6H              (*(volatile unsigned char __xdata *)0x7efef7)
#define     PWMB_CCR6L              (*(volatile unsigned char __xdata *)0x7efef8)
#define     PWMB_CCR7H              (*(volatile unsigned char __xdata *)0x7efef9)
#define     PWMB_CCR7L              (*(volatile unsigned char __xdata *)0x7efefa)
#define     PWMB_CCR8H              (*(volatile unsigned char __xdata *)0x7efefb)
#define     PWMB_CCR8L              (*(volatile unsigned char __xdata *)0x7efefc)
#define     PWMB_BKR                (*(volatile unsigned char __xdata *)0x7efefd)
#define     PWMB_DTR                (*(volatile unsigned char __xdata *)0x7efefe)
#define     PWMB_OISR               (*(volatile unsigned char __xdata *)0x7efeff)

/////////////////////////////////////////////////
//7E:FD00H-7E:FDFFH
/////////////////////////////////////////////////

#define     P0INTE                  (*(volatile unsigned char __xdata *)0x7efd00)
#define     P1INTE                  (*(volatile unsigned char __xdata *)0x7efd01)
#define     P2INTE                  (*(volatile unsigned char __xdata *)0x7efd02)
#define     P3INTE                  (*(volatile unsigned char __xdata *)0x7efd03)
#define     P4INTE                  (*(volatile unsigned char __xdata *)0x7efd04)
#define     P5INTE                  (*(volatile unsigned char __xdata *)0x7efd05)
#define     P6INTE                  (*(volatile unsigned char __xdata *)0x7efd06)
#define     P7INTE                  (*(volatile unsigned char __xdata *)0x7efd07)
#define     P0INTF                  (*(volatile unsigned char __xdata *)0x7efd10)
#define     P1INTF                  (*(volatile unsigned char __xdata *)0x7efd11)
#define     P2INTF                  (*(volatile unsigned char __xdata *)0x7efd12)
#define     P3INTF                  (*(volatile unsigned char __xdata *)0x7efd13)
#define     P4INTF                  (*(volatile unsigned char __xdata *)0x7efd14)
#define     P5INTF                  (*(volatile unsigned char __xdata *)0x7efd15)
#define     P6INTF                  (*(volatile unsigned char __xdata *)0x7efd16)
#define     P7INTF                  (*(volatile unsigned char __xdata *)0x7efd17)
#define     P0IM0                   (*(volatile unsigned char __xdata *)0x7efd20)
#define     P1IM0                   (*(volatile unsigned char __xdata *)0x7efd21)
#define     P2IM0                   (*(volatile unsigned char __xdata *)0x7efd22)
#define     P3IM0                   (*(volatile unsigned char __xdata *)0x7efd23)
#define     P4IM0                   (*(volatile unsigned char __xdata *)0x7efd24)
#define     P5IM0                   (*(volatile unsigned char __xdata *)0x7efd25)
#define     P6IM0                   (*(volatile unsigned char __xdata *)0x7efd26)
#define     P7IM0                   (*(volatile unsigned char __xdata *)0x7efd27)
#define     P0IM1                   (*(volatile unsigned char __xdata *)0x7efd30)
#define     P1IM1                   (*(volatile unsigned char __xdata *)0x7efd31)
#define     P2IM1                   (*(volatile unsigned char __xdata *)0x7efd32)
#define     P3IM1                   (*(volatile unsigned char __xdata *)0x7efd33)
#define     P4IM1                   (*(volatile unsigned char __xdata *)0x7efd34)
#define     P5IM1                   (*(volatile unsigned char __xdata *)0x7efd35)
#define     P6IM1                   (*(volatile unsigned char __xdata *)0x7efd36)
#define     P7IM1                   (*(volatile unsigned char __xdata *)0x7efd37)
#define     P0WKUE                  (*(volatile unsigned char __xdata *)0x7efd40)
#define     P1WKUE                  (*(volatile unsigned char __xdata *)0x7efd41)
#define     P2WKUE                  (*(volatile unsigned char __xdata *)0x7efd42)
#define     P3WKUE                  (*(volatile unsigned char __xdata *)0x7efd43)
#define     P4WKUE                  (*(volatile unsigned char __xdata *)0x7efd44)
#define     P5WKUE                  (*(volatile unsigned char __xdata *)0x7efd45)
#define     P6WKUE                  (*(volatile unsigned char __xdata *)0x7efd46)
#define     P7WKUE                  (*(volatile unsigned char __xdata *)0x7efd47)

#define     CCAPM2                  (*(volatile unsigned char __xdata *)0x7efd50)
#define     CCAP2L                  (*(volatile unsigned char __xdata *)0x7efd51)
#define     CCAP2H                  (*(volatile unsigned char __xdata *)0x7efd52)
#define     PCA_PWM2                (*(volatile unsigned char __xdata *)0x7efd53)
#define     CCAPM3                  (*(volatile unsigned char __xdata *)0x7efd54)
#define     CCAP3L                  (*(volatile unsigned char __xdata *)0x7efd55)
#define     CCAP3H                  (*(volatile unsigned char __xdata *)0x7efd56)
#define     PCA_PWM3                (*(volatile unsigned char __xdata *)0x7efd57)
#define     CCAPM0                  (*(volatile unsigned char __xdata *)0x7efd58)
#define     CCAP0L                  (*(volatile unsigned char __xdata *)0x7efd59)
#define     CCAP0H                  (*(volatile unsigned char __xdata *)0x7efd5a)
#define     PCA_PWM0                (*(volatile unsigned char __xdata *)0x7efd5b)
#define     CCAPM1                  (*(volatile unsigned char __xdata *)0x7efd5c)
#define     CCAP1L                  (*(volatile unsigned char __xdata *)0x7efd5d)
#define     CCAP1H                  (*(volatile unsigned char __xdata *)0x7efd5e)
#define     PCA_PWM1                (*(volatile unsigned char __xdata *)0x7efd5f)

#define     PINIPL                  (*(volatile unsigned char __xdata *)0x7efd60)
#define     PINIPH                  (*(volatile unsigned char __xdata *)0x7efd61)

#define     CCON                    (*(volatile unsigned char __xdata *)0x7efd64)
#define     CL                      (*(volatile unsigned char __xdata *)0x7efd65)
#define     CH                      (*(volatile unsigned char __xdata *)0x7efd66)
#define     CMOD                    (*(volatile unsigned char __xdata *)0x7efd67)

#define     UR1TOCR                 (*(volatile unsigned char __xdata *)0x7efd70)
#define     UR1TOSR                 (*(volatile unsigned char __xdata *)0x7efd71)
#define     UR1TOTH                 (*(volatile unsigned char __xdata *)0x7efd72)
#define     UR1TOTL                 (*(volatile unsigned char __xdata *)0x7efd73)
#define     UR2TOCR                 (*(volatile unsigned char __xdata *)0x7efd74)
#define     UR2TOSR                 (*(volatile unsigned char __xdata *)0x7efd75)
#define     UR2TOTH                 (*(volatile unsigned char __xdata *)0x7efd76)
#define     UR2TOTL                 (*(volatile unsigned char __xdata *)0x7efd77)
#define     UR3TOCR                 (*(volatile unsigned char __xdata *)0x7efd78)
#define     UR3TOSR                 (*(volatile unsigned char __xdata *)0x7efd79)
#define     UR3TOTH                 (*(volatile unsigned char __xdata *)0x7efd7a)
#define     UR3TOTL                 (*(volatile unsigned char __xdata *)0x7efd7b)
#define     UR4TOCR                 (*(volatile unsigned char __xdata *)0x7efd7c)
#define     UR4TOSR                 (*(volatile unsigned char __xdata *)0x7efd7d)
#define     UR4TOTH                 (*(volatile unsigned char __xdata *)0x7efd7e)
#define     UR4TOTL                 (*(volatile unsigned char __xdata *)0x7efd7f)
#define     SPITOCR                 (*(volatile unsigned char __xdata *)0x7efd80)
#define     SPITOSR                 (*(volatile unsigned char __xdata *)0x7efd81)
#define     SPITOTH                 (*(volatile unsigned char __xdata *)0x7efd82)
#define     SPITOTL                 (*(volatile unsigned char __xdata *)0x7efd83)
#define     I2CTOCR                 (*(volatile unsigned char __xdata *)0x7efd84)
#define     I2CTOSR                 (*(volatile unsigned char __xdata *)0x7efd85)
#define     I2CTOTH                 (*(volatile unsigned char __xdata *)0x7efd86)
#define     I2CTOTL                 (*(volatile unsigned char __xdata *)0x7efd87)

#define     UR1TOTE                 (*(volatile unsigned char __xdata *)0x7efd88)
#define     UR2TOTE                 (*(volatile unsigned char __xdata *)0x7efd89)
#define     UR3TOTE                 (*(volatile unsigned char __xdata *)0x7efd8a)
#define     UR4TOTE                 (*(volatile unsigned char __xdata *)0x7efd8b)
#define     SPITOTE                 (*(volatile unsigned char __xdata *)0x7efd8c)
#define     I2CTOTE                 (*(volatile unsigned char __xdata *)0x7efd8d)

#define     I2SCR                   (*(volatile unsigned char __xdata *)0x7efd98)
#define     I2SSR                   (*(volatile unsigned char __xdata *)0x7efd99)
#define     I2SDRH                  (*(volatile unsigned char __xdata *)0x7efd9a)
#define     I2SDRL                  (*(volatile unsigned char __xdata *)0x7efd9b)
#define     I2SPRH                  (*(volatile unsigned char __xdata *)0x7efd9c)
#define     I2SPRL                  (*(volatile unsigned char __xdata *)0x7efd9d)
#define     I2SCFGH                 (*(volatile unsigned char __xdata *)0x7efd9e)
#define     I2SCFGL                 (*(volatile unsigned char __xdata *)0x7efd9f)
#define     I2SMD                   (*(volatile unsigned char __xdata *)0x7efda0)
#define     I2SMCKDIV               (*(volatile unsigned char __xdata *)0x7efda1)

#define     CRECR                   (*(volatile unsigned char __xdata *)0x7efda8)
#define     CRECNTH                 (*(volatile unsigned char __xdata *)0x7efda9)
#define     CRECNTL                 (*(volatile unsigned char __xdata *)0x7efdaa)
#define     CRERES                  (*(volatile unsigned char __xdata *)0x7efdab)

#define     S2CFG                   (*(volatile unsigned char __xdata *)0x7efdb4)
#define     S2ADDR                  (*(volatile unsigned char __xdata *)0x7efdb5)
#define     S2ADEN                  (*(volatile unsigned char __xdata *)0x7efdb6)
#define     USARTCR1                (*(volatile unsigned char __xdata *)0x7efdc0)
#define     USARTCR2                (*(volatile unsigned char __xdata *)0x7efdc1)
#define     USARTCR3                (*(volatile unsigned char __xdata *)0x7efdc2)
#define     USARTCR4                (*(volatile unsigned char __xdata *)0x7efdc3)
#define     USARTCR5                (*(volatile unsigned char __xdata *)0x7efdc4)
#define     USARTGTR                (*(volatile unsigned char __xdata *)0x7efdc5)
#define     USARTBRH                (*(volatile unsigned char __xdata *)0x7efdc6)
#define     USARTBRL                (*(volatile unsigned char __xdata *)0x7efdc7)
#define     USART2CR1               (*(volatile unsigned char __xdata *)0x7efdc8)
#define     USART2CR2               (*(volatile unsigned char __xdata *)0x7efdc9)
#define     USART2CR3               (*(volatile unsigned char __xdata *)0x7efdca)
#define     USART2CR4               (*(volatile unsigned char __xdata *)0x7efdcb)
#define     USART2CR5               (*(volatile unsigned char __xdata *)0x7efdcc)
#define     USART2GTR               (*(volatile unsigned char __xdata *)0x7efdcd)
#define     USART2BRH               (*(volatile unsigned char __xdata *)0x7efdce)
#define     USART2BRL               (*(volatile unsigned char __xdata *)0x7efdcf)

#define     CHIPID                  ( (volatile unsigned char __xdata *)0x7efde0)

#define     CHIPID0                 (*(volatile unsigned char __xdata *)0x7efde0)
#define     CHIPID1                 (*(volatile unsigned char __xdata *)0x7efde1)
#define     CHIPID2                 (*(volatile unsigned char __xdata *)0x7efde2)
#define     CHIPID3                 (*(volatile unsigned char __xdata *)0x7efde3)
#define     CHIPID4                 (*(volatile unsigned char __xdata *)0x7efde4)
#define     CHIPID5                 (*(volatile unsigned char __xdata *)0x7efde5)
#define     CHIPID6                 (*(volatile unsigned char __xdata *)0x7efde6)
#define     CHIPID7                 (*(volatile unsigned char __xdata *)0x7efde7)
#define     CHIPID8                 (*(volatile unsigned char __xdata *)0x7efde8)
#define     CHIPID9                 (*(volatile unsigned char __xdata *)0x7efde9)
#define     CHIPID10                (*(volatile unsigned char __xdata *)0x7efdea)
#define     CHIPID11                (*(volatile unsigned char __xdata *)0x7efdeb)
#define     CHIPID12                (*(volatile unsigned char __xdata *)0x7efdec)
#define     CHIPID13                (*(volatile unsigned char __xdata *)0x7efded)
#define     CHIPID14                (*(volatile unsigned char __xdata *)0x7efdee)
#define     CHIPID15                (*(volatile unsigned char __xdata *)0x7efdef)
#define     CHIPID16                (*(volatile unsigned char __xdata *)0x7efdf0)
#define     CHIPID17                (*(volatile unsigned char __xdata *)0x7efdf1)
#define     CHIPID18                (*(volatile unsigned char __xdata *)0x7efdf2)
#define     CHIPID19                (*(volatile unsigned char __xdata *)0x7efdf3)
#define     CHIPID20                (*(volatile unsigned char __xdata *)0x7efdf4)
#define     CHIPID21                (*(volatile unsigned char __xdata *)0x7efdf5)
#define     CHIPID22                (*(volatile unsigned char __xdata *)0x7efdf6)
#define     CHIPID23                (*(volatile unsigned char __xdata *)0x7efdf7)
#define     CHIPID24                (*(volatile unsigned char __xdata *)0x7efdf8)
#define     CHIPID25                (*(volatile unsigned char __xdata *)0x7efdf9)
#define     CHIPID26                (*(volatile unsigned char __xdata *)0x7efdfa)
#define     CHIPID27                (*(volatile unsigned char __xdata *)0x7efdfb)
#define     CHIPID28                (*(volatile unsigned char __xdata *)0x7efdfc)
#define     CHIPID29                (*(volatile unsigned char __xdata *)0x7efdfd)
#define     CHIPID30                (*(volatile unsigned char __xdata *)0x7efdfe)
#define     CHIPID31                (*(volatile unsigned char __xdata *)0x7efdff)

/////////////////////////////////////////////////
//7E:FC00H-7E:FCFFH
/////////////////////////////////////////////////



/////////////////////////////////////////////////
//7E:FB00H-7E:FBFFH
/////////////////////////////////////////////////

#define     CHIPIDX                 ( (volatile unsigned char __xdata *)0x7efbd0)

#define     CHIPIDX0                (*(volatile unsigned char __xdata *)0x7efbd0)
#define     CHIPIDX1                (*(volatile unsigned char __xdata *)0x7efbd1)
#define     CHIPIDX2                (*(volatile unsigned char __xdata *)0x7efbd2)
#define     CHIPIDX3                (*(volatile unsigned char __xdata *)0x7efbd3)
#define     CHIPIDX4                (*(volatile unsigned char __xdata *)0x7efbd4)
#define     CHIPIDX5                (*(volatile unsigned char __xdata *)0x7efbd5)
#define     CHIPIDX6                (*(volatile unsigned char __xdata *)0x7efbd6)
#define     CHIPIDX7                (*(volatile unsigned char __xdata *)0x7efbd7)
#define     CHIPIDX8                (*(volatile unsigned char __xdata *)0x7efbd8)
#define     CHIPIDX9                (*(volatile unsigned char __xdata *)0x7efbd9)
#define     CHIPIDX10               (*(volatile unsigned char __xdata *)0x7efbda)
#define     CHIPIDX11               (*(volatile unsigned char __xdata *)0x7efbdb)
#define     CHIPIDX12               (*(volatile unsigned char __xdata *)0x7efbdc)
#define     CHIPIDX13               (*(volatile unsigned char __xdata *)0x7efbdd)
#define     CHIPIDX14               (*(volatile unsigned char __xdata *)0x7efbde)
#define     CHIPIDX15               (*(volatile unsigned char __xdata *)0x7efbdf)
#define     CHIPIDX16               (*(volatile unsigned char __xdata *)0x7efbe0)
#define     CHIPIDX17               (*(volatile unsigned char __xdata *)0x7efbe1)
#define     CHIPIDX18               (*(volatile unsigned char __xdata *)0x7efbe2)
#define     CHIPIDX19               (*(volatile unsigned char __xdata *)0x7efbe3)
#define     CHIPIDX20               (*(volatile unsigned char __xdata *)0x7efbe4)
#define     CHIPIDX21               (*(volatile unsigned char __xdata *)0x7efbe5)
#define     CHIPIDX22               (*(volatile unsigned char __xdata *)0x7efbe6)
#define     CHIPIDX23               (*(volatile unsigned char __xdata *)0x7efbe7)
#define     CHIPIDX24               (*(volatile unsigned char __xdata *)0x7efbe8)
#define     CHIPIDX25               (*(volatile unsigned char __xdata *)0x7efbe9)
#define     CHIPIDX26               (*(volatile unsigned char __xdata *)0x7efbea)
#define     CHIPIDX27               (*(volatile unsigned char __xdata *)0x7efbeb)
#define     CHIPIDX28               (*(volatile unsigned char __xdata *)0x7efbec)
#define     CHIPIDX29               (*(volatile unsigned char __xdata *)0x7efbed)
#define     CHIPIDX30               (*(volatile unsigned char __xdata *)0x7efbee)
#define     CHIPIDX31               (*(volatile unsigned char __xdata *)0x7efbef)

#define     HSPWMA_CFG              (*(volatile unsigned char __xdata *)0x7efbf0)
#define     HSPWMA_ADR              (*(volatile unsigned char __xdata *)0x7efbf1)
#define     HSPWMA_DAT              (*(volatile unsigned char __xdata *)0x7efbf2)
#define     HSPWMA_ADRH             (*(volatile unsigned char __xdata *)0x7efbf3)
#define     HSPWMB_CFG              (*(volatile unsigned char __xdata *)0x7efbf4)
#define     HSPWMB_ADR              (*(volatile unsigned char __xdata *)0x7efbf5)
#define     HSPWMB_DAT              (*(volatile unsigned char __xdata *)0x7efbf6)
#define     HSPWMB_ADRH             (*(volatile unsigned char __xdata *)0x7efbf7)
#define     HSSPI_CFG               (*(volatile unsigned char __xdata *)0x7efbf8)
#define     HSSPI_CFG2              (*(volatile unsigned char __xdata *)0x7efbf9)
#define     HSSPI_STA               (*(volatile unsigned char __xdata *)0x7efbfa)
#define     HSSPI_PSCR              (*(volatile unsigned char __xdata *)0x7efbfb)

/////////////////////////////////////////////////
//7E:FA00H-7E:FAFFH
/////////////////////////////////////////////////

#define     DMA_M2M_CFG             (*(volatile unsigned char __xdata *)0x7efa00)
#define     DMA_M2M_CR              (*(volatile unsigned char __xdata *)0x7efa01)
#define     DMA_M2M_STA             (*(volatile unsigned char __xdata *)0x7efa02)
#define     DMA_M2M_AMT             (*(volatile unsigned char __xdata *)0x7efa03)
#define     DMA_M2M_DONE            (*(volatile unsigned char __xdata *)0x7efa04)
#define     DMA_M2M_TXAH            (*(volatile unsigned char __xdata *)0x7efa05)
#define     DMA_M2M_TXAL            (*(volatile unsigned char __xdata *)0x7efa06)
#define     DMA_M2M_RXAH            (*(volatile unsigned char __xdata *)0x7efa07)
#define     DMA_M2M_RXAL            (*(volatile unsigned char __xdata *)0x7efa08)

#define     DMA_ADC_CFG             (*(volatile unsigned char __xdata *)0x7efa10)
#define     DMA_ADC_CR              (*(volatile unsigned char __xdata *)0x7efa11)
#define     DMA_ADC_STA             (*(volatile unsigned char __xdata *)0x7efa12)
#define     DMA_ADC_AMT             (*(volatile unsigned char __xdata *)0x7efa13)
#define     DMA_ADC_DONE            (*(volatile unsigned char __xdata *)0x7efa14)
#define     DMA_ADC_RXAH            (*(volatile unsigned char __xdata *)0x7efa17)
#define     DMA_ADC_RXAL            (*(volatile unsigned char __xdata *)0x7efa18)
#define     DMA_ADC_CFG2            (*(volatile unsigned char __xdata *)0x7efa19)
#define     DMA_ADC_CHSW0           (*(volatile unsigned char __xdata *)0x7efa1a)
#define     DMA_ADC_CHSW1           (*(volatile unsigned char __xdata *)0x7efa1b)
#define     DMA_ADC_ITVH            (*(volatile unsigned char __xdata *)0x7efa1e)
#define     DMA_ADC_ITVL            (*(volatile unsigned char __xdata *)0x7efa1f)

#define     DMA_SPI_CFG             (*(volatile unsigned char __xdata *)0x7efa20)
#define     DMA_SPI_CR              (*(volatile unsigned char __xdata *)0x7efa21)
#define     DMA_SPI_STA             (*(volatile unsigned char __xdata *)0x7efa22)
#define     DMA_SPI_AMT             (*(volatile unsigned char __xdata *)0x7efa23)
#define     DMA_SPI_DONE            (*(volatile unsigned char __xdata *)0x7efa24)
#define     DMA_SPI_TXAH            (*(volatile unsigned char __xdata *)0x7efa25)
#define     DMA_SPI_TXAL            (*(volatile unsigned char __xdata *)0x7efa26)
#define     DMA_SPI_RXAH            (*(volatile unsigned char __xdata *)0x7efa27)
#define     DMA_SPI_RXAL            (*(volatile unsigned char __xdata *)0x7efa28)
#define     DMA_SPI_CFG2            (*(volatile unsigned char __xdata *)0x7efa29)
#define     DMA_SPI_ITVH            (*(volatile unsigned char __xdata *)0x7efa2e)
#define     DMA_SPI_ITVL            (*(volatile unsigned char __xdata *)0x7efa2f)

#define     DMA_UR1T_CFG            (*(volatile unsigned char __xdata *)0x7efa30)
#define     DMA_UR1T_CR             (*(volatile unsigned char __xdata *)0x7efa31)
#define     DMA_UR1T_STA            (*(volatile unsigned char __xdata *)0x7efa32)
#define     DMA_UR1T_AMT            (*(volatile unsigned char __xdata *)0x7efa33)
#define     DMA_UR1T_DONE           (*(volatile unsigned char __xdata *)0x7efa34)
#define     DMA_UR1T_TXAH           (*(volatile unsigned char __xdata *)0x7efa35)
#define     DMA_UR1T_TXAL           (*(volatile unsigned char __xdata *)0x7efa36)
#define     DMA_UR1R_CFG            (*(volatile unsigned char __xdata *)0x7efa38)
#define     DMA_UR1R_CR             (*(volatile unsigned char __xdata *)0x7efa39)
#define     DMA_UR1R_STA            (*(volatile unsigned char __xdata *)0x7efa3a)
#define     DMA_UR1R_AMT            (*(volatile unsigned char __xdata *)0x7efa3b)
#define     DMA_UR1R_DONE           (*(volatile unsigned char __xdata *)0x7efa3c)
#define     DMA_UR1R_RXAH           (*(volatile unsigned char __xdata *)0x7efa3d)
#define     DMA_UR1R_RXAL           (*(volatile unsigned char __xdata *)0x7efa3e)

#define     DMA_UR2T_CFG            (*(volatile unsigned char __xdata *)0x7efa40)
#define     DMA_UR2T_CR             (*(volatile unsigned char __xdata *)0x7efa41)
#define     DMA_UR2T_STA            (*(volatile unsigned char __xdata *)0x7efa42)
#define     DMA_UR2T_AMT            (*(volatile unsigned char __xdata *)0x7efa43)
#define     DMA_UR2T_DONE           (*(volatile unsigned char __xdata *)0x7efa44)
#define     DMA_UR2T_TXAH           (*(volatile unsigned char __xdata *)0x7efa45)
#define     DMA_UR2T_TXAL           (*(volatile unsigned char __xdata *)0x7efa46)
#define     DMA_UR2R_CFG            (*(volatile unsigned char __xdata *)0x7efa48)
#define     DMA_UR2R_CR             (*(volatile unsigned char __xdata *)0x7efa49)
#define     DMA_UR2R_STA            (*(volatile unsigned char __xdata *)0x7efa4a)
#define     DMA_UR2R_AMT            (*(volatile unsigned char __xdata *)0x7efa4b)
#define     DMA_UR2R_DONE           (*(volatile unsigned char __xdata *)0x7efa4c)
#define     DMA_UR2R_RXAH           (*(volatile unsigned char __xdata *)0x7efa4d)
#define     DMA_UR2R_RXAL           (*(volatile unsigned char __xdata *)0x7efa4e)

#define     DMA_UR3T_CFG            (*(volatile unsigned char __xdata *)0x7efa50)
#define     DMA_UR3T_CR             (*(volatile unsigned char __xdata *)0x7efa51)
#define     DMA_UR3T_STA            (*(volatile unsigned char __xdata *)0x7efa52)
#define     DMA_UR3T_AMT            (*(volatile unsigned char __xdata *)0x7efa53)
#define     DMA_UR3T_DONE           (*(volatile unsigned char __xdata *)0x7efa54)
#define     DMA_UR3T_TXAH           (*(volatile unsigned char __xdata *)0x7efa55)
#define     DMA_UR3T_TXAL           (*(volatile unsigned char __xdata *)0x7efa56)
#define     DMA_UR3R_CFG            (*(volatile unsigned char __xdata *)0x7efa58)
#define     DMA_UR3R_CR             (*(volatile unsigned char __xdata *)0x7efa59)
#define     DMA_UR3R_STA            (*(volatile unsigned char __xdata *)0x7efa5a)
#define     DMA_UR3R_AMT            (*(volatile unsigned char __xdata *)0x7efa5b)
#define     DMA_UR3R_DONE           (*(volatile unsigned char __xdata *)0x7efa5c)
#define     DMA_UR3R_RXAH           (*(volatile unsigned char __xdata *)0x7efa5d)
#define     DMA_UR3R_RXAL           (*(volatile unsigned char __xdata *)0x7efa5e)

#define     DMA_UR4T_CFG            (*(volatile unsigned char __xdata *)0x7efa60)
#define     DMA_UR4T_CR             (*(volatile unsigned char __xdata *)0x7efa61)
#define     DMA_UR4T_STA            (*(volatile unsigned char __xdata *)0x7efa62)
#define     DMA_UR4T_AMT            (*(volatile unsigned char __xdata *)0x7efa63)
#define     DMA_UR4T_DONE           (*(volatile unsigned char __xdata *)0x7efa64)
#define     DMA_UR4T_TXAH           (*(volatile unsigned char __xdata *)0x7efa65)
#define     DMA_UR4T_TXAL           (*(volatile unsigned char __xdata *)0x7efa66)
#define     DMA_UR4R_CFG            (*(volatile unsigned char __xdata *)0x7efa68)
#define     DMA_UR4R_CR             (*(volatile unsigned char __xdata *)0x7efa69)
#define     DMA_UR4R_STA            (*(volatile unsigned char __xdata *)0x7efa6a)
#define     DMA_UR4R_AMT            (*(volatile unsigned char __xdata *)0x7efa6b)
#define     DMA_UR4R_DONE           (*(volatile unsigned char __xdata *)0x7efa6c)
#define     DMA_UR4R_RXAH           (*(volatile unsigned char __xdata *)0x7efa6d)
#define     DMA_UR4R_RXAL           (*(volatile unsigned char __xdata *)0x7efa6e)

#define     DMA_LCM_CFG             (*(volatile unsigned char __xdata *)0x7efa70)
#define     DMA_LCM_CR              (*(volatile unsigned char __xdata *)0x7efa71)
#define     DMA_LCM_STA             (*(volatile unsigned char __xdata *)0x7efa72)
#define     DMA_LCM_AMT             (*(volatile unsigned char __xdata *)0x7efa73)
#define     DMA_LCM_DONE            (*(volatile unsigned char __xdata *)0x7efa74)
#define     DMA_LCM_TXAH            (*(volatile unsigned char __xdata *)0x7efa75)
#define     DMA_LCM_TXAL            (*(volatile unsigned char __xdata *)0x7efa76)
#define     DMA_LCM_RXAH            (*(volatile unsigned char __xdata *)0x7efa77)
#define     DMA_LCM_RXAL            (*(volatile unsigned char __xdata *)0x7efa78)
#define     DMA_LCM_ITVH            (*(volatile unsigned char __xdata *)0x7efa7e)
#define     DMA_LCM_ITVL            (*(volatile unsigned char __xdata *)0x7efa7f)

#define     DMA_M2M_AMTH            (*(volatile unsigned char __xdata *)0x7efa80)
#define     DMA_M2M_DONEH           (*(volatile unsigned char __xdata *)0x7efa81)
#define     DMA_ADC_AMTH            (*(volatile unsigned char __xdata *)0x7efa82)
#define     DMA_ADC_DONEH           (*(volatile unsigned char __xdata *)0x7efa83)
#define     DMA_SPI_AMTH            (*(volatile unsigned char __xdata *)0x7efa84)
#define     DMA_SPI_DONEH           (*(volatile unsigned char __xdata *)0x7efa85)
#define     DMA_LCM_AMTH            (*(volatile unsigned char __xdata *)0x7efa86)
#define     DMA_LCM_DONEH           (*(volatile unsigned char __xdata *)0x7efa87)
#define     DMA_UR1T_AMTH           (*(volatile unsigned char __xdata *)0x7efa88)
#define     DMA_UR1T_DONEH          (*(volatile unsigned char __xdata *)0x7efa89)
#define     DMA_UR1R_AMTH           (*(volatile unsigned char __xdata *)0x7efa8a)
#define     DMA_UR1R_DONEH          (*(volatile unsigned char __xdata *)0x7efa8b)
#define     DMA_UR2T_AMTH           (*(volatile unsigned char __xdata *)0x7efa8c)
#define     DMA_UR2T_DONEH          (*(volatile unsigned char __xdata *)0x7efa8d)
#define     DMA_UR2R_AMTH           (*(volatile unsigned char __xdata *)0x7efa8e)
#define     DMA_UR2R_DONEH          (*(volatile unsigned char __xdata *)0x7efa8f)
#define     DMA_UR3T_AMTH           (*(volatile unsigned char __xdata *)0x7efa90)
#define     DMA_UR3T_DONEH          (*(volatile unsigned char __xdata *)0x7efa91)
#define     DMA_UR3R_AMTH           (*(volatile unsigned char __xdata *)0x7efa92)
#define     DMA_UR3R_DONEH          (*(volatile unsigned char __xdata *)0x7efa93)
#define     DMA_UR4T_AMTH           (*(volatile unsigned char __xdata *)0x7efa94)
#define     DMA_UR4T_DONEH          (*(volatile unsigned char __xdata *)0x7efa95)
#define     DMA_UR4R_AMTH           (*(volatile unsigned char __xdata *)0x7efa96)
#define     DMA_UR4R_DONEH          (*(volatile unsigned char __xdata *)0x7efa97)

#define     DMA_I2CT_CFG            (*(volatile unsigned char __xdata *)0x7efa98)
#define     DMA_I2CT_CR             (*(volatile unsigned char __xdata *)0x7efa99)
#define     DMA_I2CT_STA            (*(volatile unsigned char __xdata *)0x7efa9a)
#define     DMA_I2CT_AMT            (*(volatile unsigned char __xdata *)0x7efa9b)
#define     DMA_I2CT_DONE           (*(volatile unsigned char __xdata *)0x7efa9c)
#define     DMA_I2CT_TXAH           (*(volatile unsigned char __xdata *)0x7efa9d)
#define     DMA_I2CT_TXAL           (*(volatile unsigned char __xdata *)0x7efa9e)
#define     DMA_I2CR_CFG            (*(volatile unsigned char __xdata *)0x7efaa0)
#define     DMA_I2CR_CR             (*(volatile unsigned char __xdata *)0x7efaa1)
#define     DMA_I2CR_STA            (*(volatile unsigned char __xdata *)0x7efaa2)
#define     DMA_I2CR_AMT            (*(volatile unsigned char __xdata *)0x7efaa3)
#define     DMA_I2CR_DONE           (*(volatile unsigned char __xdata *)0x7efaa4)
#define     DMA_I2CR_RXAH           (*(volatile unsigned char __xdata *)0x7efaa5)
#define     DMA_I2CR_RXAL           (*(volatile unsigned char __xdata *)0x7efaa6)

#define     DMA_I2CT_AMTH           (*(volatile unsigned char __xdata *)0x7efaa8)
#define     DMA_I2CT_DONEH          (*(volatile unsigned char __xdata *)0x7efaa9)
#define     DMA_I2CR_AMTH           (*(volatile unsigned char __xdata *)0x7efaaa)
#define     DMA_I2CR_DONEH          (*(volatile unsigned char __xdata *)0x7efaab)
#define     DMA_I2C_CR              (*(volatile unsigned char __xdata *)0x7efaad)
#define     DMA_I2C_ST1             (*(volatile unsigned char __xdata *)0x7efaae)
#define     DMA_I2C_ST2             (*(volatile unsigned char __xdata *)0x7efaaf)

#define     DMA_I2ST_CFG            (*(volatile unsigned char __xdata *)0x7efab0)
#define     DMA_I2ST_CR             (*(volatile unsigned char __xdata *)0x7efab1)
#define     DMA_I2ST_STA            (*(volatile unsigned char __xdata *)0x7efab2)
#define     DMA_I2ST_AMT            (*(volatile unsigned char __xdata *)0x7efab3)
#define     DMA_I2ST_DONE           (*(volatile unsigned char __xdata *)0x7efab4)
#define     DMA_I2ST_TXAH           (*(volatile unsigned char __xdata *)0x7efab5)
#define     DMA_I2ST_TXAL           (*(volatile unsigned char __xdata *)0x7efab6)
#define     DMA_I2SR_CFG            (*(volatile unsigned char __xdata *)0x7efab8)
#define     DMA_I2SR_CR             (*(volatile unsigned char __xdata *)0x7efab9)
#define     DMA_I2SR_STA            (*(volatile unsigned char __xdata *)0x7efaba)
#define     DMA_I2SR_AMT            (*(volatile unsigned char __xdata *)0x7efabb)
#define     DMA_I2SR_DONE           (*(volatile unsigned char __xdata *)0x7efabc)
#define     DMA_I2SR_RXAH           (*(volatile unsigned char __xdata *)0x7efabd)
#define     DMA_I2SR_RXAL           (*(volatile unsigned char __xdata *)0x7efabe)

#define     DMA_I2ST_AMTH           (*(volatile unsigned char __xdata *)0x7efac0)
#define     DMA_I2ST_DONEH          (*(volatile unsigned char __xdata *)0x7efac1)
#define     DMA_I2SR_AMTH           (*(volatile unsigned char __xdata *)0x7efac2)
#define     DMA_I2SR_DONEH          (*(volatile unsigned char __xdata *)0x7efac3)
#define     DMA_I2C_ITVH            (*(volatile unsigned char __xdata *)0x7efac4)
#define     DMA_I2C_ITVL            (*(volatile unsigned char __xdata *)0x7efac5)
#define     DMA_I2S_ITVH            (*(volatile unsigned char __xdata *)0x7efac6)
#define     DMA_I2S_ITVL            (*(volatile unsigned char __xdata *)0x7efac7)
#define     DMA_UR1_ITVH            (*(volatile unsigned char __xdata *)0x7efac8)
#define     DMA_UR1_ITVL            (*(volatile unsigned char __xdata *)0x7efac9)
#define     DMA_UR2_ITVH            (*(volatile unsigned char __xdata *)0x7efaca)
#define     DMA_UR2_ITVL            (*(volatile unsigned char __xdata *)0x7efacb)
#define     DMA_UR3_ITVH            (*(volatile unsigned char __xdata *)0x7efacc)
#define     DMA_UR3_ITVL            (*(volatile unsigned char __xdata *)0x7efacd)
#define     DMA_UR4_ITVH            (*(volatile unsigned char __xdata *)0x7eface)
#define     DMA_UR4_ITVL            (*(volatile unsigned char __xdata *)0x7efacf)

#define     DMA_QSPI_CFG            (*(volatile unsigned char __xdata *)0x7efad0)
#define     DMA_QSPI_CR             (*(volatile unsigned char __xdata *)0x7efad1)
#define     DMA_QSPI_STA            (*(volatile unsigned char __xdata *)0x7efad2)
#define     DMA_QSPI_AMT            (*(volatile unsigned char __xdata *)0x7efad3)
#define     DMA_QSPI_DONE           (*(volatile unsigned char __xdata *)0x7efad4)
#define     DMA_QSPI_TXAH           (*(volatile unsigned char __xdata *)0x7efad5)
#define     DMA_QSPI_TXAL           (*(volatile unsigned char __xdata *)0x7efad6)
#define     DMA_QSPI_RXAH           (*(volatile unsigned char __xdata *)0x7efad7)
#define     DMA_QSPI_RXAL           (*(volatile unsigned char __xdata *)0x7efad8)
#define     DMA_QSPI_AMTH           (*(volatile unsigned char __xdata *)0x7efadb)
#define     DMA_QSPI_DONEH          (*(volatile unsigned char __xdata *)0x7efadc)
#define     DMA_QSPI_ITVH           (*(volatile unsigned char __xdata *)0x7efade)
#define     DMA_QSPI_ITVL           (*(volatile unsigned char __xdata *)0x7efadf)

#define     DMA_P2P_CR1             (*(volatile unsigned char __xdata *)0x7efaf0)
#define     DMA_P2P_CR2             (*(volatile unsigned char __xdata *)0x7efaf1)
#define     DMA_ARB_CFG             (*(volatile unsigned char __xdata *)0x7efaf8)
#define     DMA_ARB_STA             (*(volatile unsigned char __xdata *)0x7efaf9)

/////////////////////////////////////////////////
//7E:F900H-7E:F9FFH
/////////////////////////////////////////////////

#define     QSPI_CR1                (*(volatile unsigned char __xdata *)0x7ef900)
#define     QSPI_CR2                (*(volatile unsigned char __xdata *)0x7ef901)
#define     QSPI_CR3                (*(volatile unsigned char __xdata *)0x7ef902)
#define     QSPI_CR4                (*(volatile unsigned char __xdata *)0x7ef903)
#define     QSPI_DCR1               (*(volatile unsigned char __xdata *)0x7ef904)
#define     QSPI_DCR2               (*(volatile unsigned char __xdata *)0x7ef905)
#define     QSPI_SR1                (*(volatile unsigned char __xdata *)0x7ef906)
#define     QSPI_SR2                (*(volatile unsigned char __xdata *)0x7ef907)
#define     QSPI_FCR                (*(volatile unsigned char __xdata *)0x7ef908)
#define     QSPI_HCR1               (*(volatile unsigned char __xdata *)0x7ef909)
#define     QSPI_HCR2               (*(volatile unsigned char __xdata *)0x7ef90a)
#define     QSPI_DLR1               (*(volatile unsigned char __xdata *)0x7ef910)
#define     QSPI_DLR2               (*(volatile unsigned char __xdata *)0x7ef911)
#define     QSPI_CCR1               (*(volatile unsigned char __xdata *)0x7ef914)
#define     QSPI_CCR2               (*(volatile unsigned char __xdata *)0x7ef915)
#define     QSPI_CCR3               (*(volatile unsigned char __xdata *)0x7ef916)
#define     QSPI_CCR4               (*(volatile unsigned char __xdata *)0x7ef917)
#define     QSPI_AR1                (*(volatile unsigned char __xdata *)0x7ef918)
#define     QSPI_AR2                (*(volatile unsigned char __xdata *)0x7ef919)
#define     QSPI_AR3                (*(volatile unsigned char __xdata *)0x7ef91a)
#define     QSPI_AR4                (*(volatile unsigned char __xdata *)0x7ef91b)
#define     QSPI_ABR                (*(volatile unsigned char __xdata *)0x7ef91c)
#define     QSPI_DR                 (*(volatile unsigned char __xdata *)0x7ef920)
#define     QSPI_PSMKR1             (*(volatile unsigned char __xdata *)0x7ef924)
#define     QSPI_PSMAR1             (*(volatile unsigned char __xdata *)0x7ef928)
#define     QSPI_PIR1               (*(volatile unsigned char __xdata *)0x7ef92c)
#define     QSPI_PIR2               (*(volatile unsigned char __xdata *)0x7ef92d)

#define     PWMA_ENO2               (*(volatile unsigned char __xdata *)0x7ef930)
#define     PWMA_IOAUX2             (*(volatile unsigned char __xdata *)0x7ef931)
#define     PWMA_CR3                (*(volatile unsigned char __xdata *)0x7ef932)
#define     PWMA_SR3                (*(volatile unsigned char __xdata *)0x7ef933)
#define     PWMA_CCER3              (*(volatile unsigned char __xdata *)0x7ef934)
#define     PWMA_CCMR1X             (*(volatile unsigned char __xdata *)0x7ef938)
#define     PWMA_CCMR2X             (*(volatile unsigned char __xdata *)0x7ef939)
#define     PWMA_CCMR3X             (*(volatile unsigned char __xdata *)0x7ef93a)
#define     PWMA_CCMR4X             (*(volatile unsigned char __xdata *)0x7ef93b)
#define     PWMA_CCMR5              (*(volatile unsigned char __xdata *)0x7ef93c)
#define     PWMA_CCMR5X             (*(volatile unsigned char __xdata *)0x7ef93d)
#define     PWMA_CCMR6              (*(volatile unsigned char __xdata *)0x7ef93e)
#define     PWMA_CCMR6X             (*(volatile unsigned char __xdata *)0x7ef93f)
#define     PWMA_CCR5H              (*(volatile unsigned char __xdata *)0x7ef940)
#define     PWMA_CCR5L              (*(volatile unsigned char __xdata *)0x7ef941)
#define     PWMA_CCR5X              (*(volatile unsigned char __xdata *)0x7ef942)
#define     PWMA_CCR6H              (*(volatile unsigned char __xdata *)0x7ef943)
#define     PWMA_CCR6L              (*(volatile unsigned char __xdata *)0x7ef944)
#define     PWMA_DER                (*(volatile unsigned char __xdata *)0x7ef948)
#define     PWMA_DBA                (*(volatile unsigned char __xdata *)0x7ef949)
#define     PWMA_DBL                (*(volatile unsigned char __xdata *)0x7ef94a)
#define     PWMA_DMACR              (*(volatile unsigned char __xdata *)0x7ef94b)

#define     DMA_PWMAT_CFG           (*(volatile unsigned char __xdata *)0x7ef980)
#define     DMA_PWMAT_CR            (*(volatile unsigned char __xdata *)0x7ef981)
#define     DMA_PWMAT_STA           (*(volatile unsigned char __xdata *)0x7ef982)
#define     DMA_PWMAT_AMTH          (*(volatile unsigned char __xdata *)0x7ef984)
#define     DMA_PWMAT_AMT           (*(volatile unsigned char __xdata *)0x7ef985)
#define     DMA_PWMAT_DONEH         (*(volatile unsigned char __xdata *)0x7ef986)
#define     DMA_PWMAT_DONE          (*(volatile unsigned char __xdata *)0x7ef987)
#define     DMA_PWMAT_TXAH          (*(volatile unsigned char __xdata *)0x7ef988)
#define     DMA_PWMAT_TXAL          (*(volatile unsigned char __xdata *)0x7ef989)
#define     DMA_PWMA_ITVH           (*(volatile unsigned char __xdata *)0x7ef98e)
#define     DMA_PWMA_ITVL           (*(volatile unsigned char __xdata *)0x7ef98f)

#define     DMA_PWMAR_CFG           (*(volatile unsigned char __xdata *)0x7ef990)
#define     DMA_PWMAR_CR            (*(volatile unsigned char __xdata *)0x7ef991)
#define     DMA_PWMAR_STA           (*(volatile unsigned char __xdata *)0x7ef992)
#define     DMA_PWMAR_AMTH          (*(volatile unsigned char __xdata *)0x7ef994)
#define     DMA_PWMAR_AMT           (*(volatile unsigned char __xdata *)0x7ef995)
#define     DMA_PWMAR_DONEH         (*(volatile unsigned char __xdata *)0x7ef996)
#define     DMA_PWMAR_DONE          (*(volatile unsigned char __xdata *)0x7ef997)
#define     DMA_PWMAR_RXAH          (*(volatile unsigned char __xdata *)0x7ef998)
#define     DMA_PWMAR_RXAL          (*(volatile unsigned char __xdata *)0x7ef999)

/////////////////////////////////////////////////
//USB Control Regiter
/////////////////////////////////////////////////

#define     USBBASE                 0
#define     FADDR                   (USBBASE + 0)
#define     UPDATE                  0x80
#define     POWER                   (USBBASE + 1)
#define     ISOUD                   0x80
#define     USBRST                  0x08
#define     USBRSU                  0x04
#define     USBSUS                  0x02
#define     ENSUS                   0x01
#define     INTRIN1                 (USBBASE + 2)
#define     EP5INIF                 0x20
#define     EP4INIF                 0x10
#define     EP3INIF                 0x08
#define     EP2INIF                 0x04
#define     EP1INIF                 0x02
#define     EP0IF                   0x01
#define     INTROUT1                (USBBASE + 4)
#define     EP5OUTIF                0x20
#define     EP4OUTIF                0x10
#define     EP3OUTIF                0x08
#define     EP2OUTIF                0x04
#define     EP1OUTIF                0x02
#define     INTRUSB                 (USBBASE + 6)
#define     SOFIF                   0x08
#define     RSTIF                   0x04
#define     RSUIF                   0x02
#define     SUSIF                   0x01
#define     INTRIN1E                (USBBASE + 7)
#define     EP5INIE                 0x20
#define     EP4INIE                 0x10
#define     EP3INIE                 0x08
#define     EP2INIE                 0x04
#define     EP1INIE                 0x02
#define     EP0IE                   0x01
#define     INTROUT1E               (USBBASE + 9)
#define     EP5OUTIE                0x20
#define     EP4OUTIE                0x10
#define     EP3OUTIE                0x08
#define     EP2OUTIE                0x04
#define     EP1OUTIE                0x02
#define     INTRUSBE                (USBBASE + 11)
#define     SOFIE                   0x08
#define     RSTIE                   0x04
#define     RSUIE                   0x02
#define     SUSIE                   0x01
#define     FRAME1                  (USBBASE + 12)
#define     FRAME2                  (USBBASE + 13)
#define     INDEX                   (USBBASE + 14)
#define     INMAXP                  (USBBASE + 16)
#define     CSR0                    (USBBASE + 17)
#define     SSUEND                  0x80
#define     SOPRDY                  0x40
#define     SDSTL                   0x20
#define     SUEND                   0x10
#define     DATEND                  0x08
#define     STSTL                   0x04
#define     IPRDY                   0x02
#define     OPRDY                   0x01
#define     INCSR1                  (USBBASE + 17)
#define     INCLRDT                 0x40
#define     INSTSTL                 0x20
#define     INSDSTL                 0x10
#define     INFLUSH                 0x08
#define     INUNDRUN                0x04
#define     INFIFONE                0x02
#define     INIPRDY                 0x01
#define     INCSR2                  (USBBASE + 18)
#define     INAUTOSET               0x80
#define     INISO                   0x40
#define     INMODEIN                0x20
#define     INMODEOUT               0x00
#define     INENDMA                 0x10
#define     INFCDT                  0x08
#define     OUTMAXP                 (USBBASE + 19)
#define     OUTCSR1                 (USBBASE + 20)
#define     OUTCLRDT                0x80
#define     OUTSTSTL                0x40
#define     OUTSDSTL                0x20
#define     OUTFLUSH                0x10
#define     OUTDATERR               0x08
#define     OUTOVRRUN               0x04
#define     OUTFIFOFUL              0x02
#define     OUTOPRDY                0x01
#define     OUTCSR2                 (USBBASE + 21)
#define     OUTAUTOCLR              0x80
#define     OUTISO                  0x40
#define     OUTENDMA                0x20
#define     OUTDMAMD                0x10
#define     COUNT0                  (USBBASE + 22)
#define     OUTCOUNT1               (USBBASE + 22)
#define     OUTCOUNT2               (USBBASE + 23)
#define     FIFO0                   (USBBASE + 32)
#define     FIFO1                   (USBBASE + 33)
#define     FIFO2                   (USBBASE + 34)
#define     FIFO3                   (USBBASE + 35)
#define     FIFO4                   (USBBASE + 36)
#define     FIFO5                   (USBBASE + 37)
#define     UTRKCTL                 (USBBASE + 48)
#define     UTRKSTS                 (USBBASE + 49)

/////////////////////////////////////////////////
//Interrupt Vector
/////////////////////////////////////////////////

#define     INT0_VECTOR             0       //0003H
#define     TMR0_VECTOR             1       //000BH
#define     INT1_VECTOR             2       //0013H
#define     TMR1_VECTOR             3       //001BH
#define     UART1_VECTOR            4       //0023H
#define     ADC_VECTOR              5       //002BH
#define     LVD_VECTOR              6       //0033H
#define     PCA_VECTOR              7       //003BH
#define     UART2_VECTOR            8       //0043H
#define     SPI_VECTOR              9       //004BH
#define     INT2_VECTOR             10      //0053H
#define     INT3_VECTOR             11      //005BH
#define     TMR2_VECTOR             12      //0063H
#define     USER_VECTOR             13      //006BH
#define     INT4_VECTOR             16      //0083H
#define     UART3_VECTOR            17      //008BH
#define     UART4_VECTOR            18      //0093H
#define     TMR3_VECTOR             19      //009BH
#define     TMR4_VECTOR             20      //00A3H
#define     CMP_VECTOR              21      //00ABH
#define     I2C_VECTOR              24      //00C3H
#define     USB_VECTOR              25      //00CBH
#define     PWMA_VECTOR             26      //00D3H
#define     PWMB_VECTOR             27      //00DBH

#define     RTC_VECTOR              36      //0123H
#define     P0INT_VECTOR            37      //012BH
#define     P1INT_VECTOR            38      //0133H
#define     P2INT_VECTOR            39      //013BH
#define     P3INT_VECTOR            40      //0143H
#define     P4INT_VECTOR            41      //014BH
#define     P5INT_VECTOR            42      //0153H
#define     P6INT_VECTOR            43      //015BH
#define     P7INT_VECTOR            44      //0163H
#define     DMA_M2M_VECTOR          47      //017BH
#define     DMA_ADC_VECTOR          48      //0183H
#define     DMA_SPI_VECTOR          49      //018BH
#define     DMA_UR1T_VECTOR         50      //0193H
#define     DMA_UR1R_VECTOR         51      //019BH
#define     DMA_UR2T_VECTOR         52      //01A3H
#define     DMA_UR2R_VECTOR         53      //01ABH
#define     DMA_UR3T_VECTOR         54      //01B3H
#define     DMA_UR3R_VECTOR         55      //01BBH
#define     DMA_UR4T_VECTOR         56      //01C3H
#define     DMA_UR4R_VECTOR         57      //01CBH
#define     DMA_LCM_VECTOR          58      //01D3H
#define     LCM_VECTOR              59      //01DBH
#define     DMA_I2CT_VECTOR         60      //01E3H
#define     DMA_I2CR_VECTOR         61      //01EBH
#define     I2S_VECTOR              62      //01F3H
#define     DMA_I2ST_VECTOR         63      //01FBH
#define     DMA_I2SR_VECTOR         64      //0203H
#define     DMA_QSPI_VECTOR         65      //020BH
#define     QSPI_VECTOR             66      //0213H
#define     TMR11_VECTOR            67      //021BH
#define     DMA_PWMAT_VECTOR        72      //0243H
#define     DMA_PWMAR_VECTOR        73      //024BH

/////////////////////////////////////////////////

#define EAXSFR()  (P_SW2 |= EAXFR)   /* 使能 XFR 访问（SDCC 无位寻址，改字节操作） */
#define EAXRAM()  (P_SW2 &= ~EAXFR)  /* 恢复 RAM 访问 */

/////////////////////////////////////////////////
#define NOP1()  _nop_()
#define NOP2()  NOP1(),NOP1()
#define NOP3()  NOP2(),NOP1()
#define NOP4()  NOP3(),NOP1()
#define NOP5()  NOP4(),NOP1()
#define NOP6()  NOP5(),NOP1()
#define NOP7()  NOP6(),NOP1()
#define NOP8()  NOP7(),NOP1()
#define NOP9()  NOP8(),NOP1()
#define NOP10() NOP9(),NOP1()
#define NOP11() NOP10(),NOP1()
#define NOP12() NOP11(),NOP1()
#define NOP13() NOP12(),NOP1()
#define NOP14() NOP13(),NOP1()
#define NOP15() NOP14(),NOP1()
#define NOP16() NOP15(),NOP1()
#define NOP17() NOP16(),NOP1()
#define NOP18() NOP17(),NOP1()
#define NOP19() NOP18(),NOP1()
#define NOP20() NOP19(),NOP1()
#define NOP21() NOP20(),NOP1()
#define NOP22() NOP21(),NOP1()
#define NOP23() NOP22(),NOP1()
#define NOP24() NOP23(),NOP1()
#define NOP25() NOP24(),NOP1()
#define NOP26() NOP25(),NOP1()
#define NOP27() NOP26(),NOP1()
#define NOP28() NOP27(),NOP1()
#define NOP29() NOP28(),NOP1()
#define NOP30() NOP29(),NOP1()
#define NOP31() NOP30(),NOP1()
#define NOP32() NOP31(),NOP1()
#define NOP33() NOP32(),NOP1()
#define NOP34() NOP33(),NOP1()
#define NOP35() NOP34(),NOP1()
#define NOP36() NOP35(),NOP1()
#define NOP37() NOP36(),NOP1()
#define NOP38() NOP37(),NOP1()
#define NOP39() NOP38(),NOP1()
#define NOP40() NOP39(),NOP1()
#define NOP(N)  NOP##N()


/////////////////////////////////////////////////





#endif /* AI8051U_SFR_H */
