/*---------------------------------------------------------------------*/
/* --- Web: www.STCAI.com ---------------------------------------------*/
/*---------------------------------------------------------------------*/

#ifndef    __AI8051U_SPI_H
#define    __AI8051U_SPI_H

#include "config.h"

//========================================================================
//                               SPI设置
//========================================================================

#define SPI_SSIG_Set(n)         SPCTL = (unsigned char)((SPCTL & ~0x80) | ((n) ? 0x80 : 0))/* SS引脚功能控制 */
#define SPI_Start(n)            SPCTL = (unsigned char)((SPCTL & ~0x40) | ((n) ? 0x40 : 0))/* SPI使能控制位 */
#define SPI_FirstBit_Set(n)     SPCTL = (unsigned char)((SPCTL & ~0x20) | ((n) ? 0x20 : 0))/* 数据发送/接收顺序 MSB/LSB */
#define SPI_Mode_Set(n)         SPCTL = (unsigned char)((SPCTL & ~0x10) | ((n) ? 0x10 : 0))/* SPI主从模式设置 */
#define SPI_CPOL_Set(n)         SPCTL = (unsigned char)((SPCTL & ~0x08) | ((n) ? 0x08 : 0))/* SPI时钟极性控制 */
#define SPI_CPHA_Set(n)         SPCTL = (unsigned char)((SPCTL & ~0x04) | ((n) ? 0x04 : 0))/* SPI时钟相位控制 */
#define SPI_Clock_Select(n)     SPCTL = (SPCTL & ~0x03) | (n)    /* SPI时钟频率选择 */

#define SPI_ClearFlag()         {SPSTAT |= 0x80; SPSTAT |= 0x40;}    /* 写 1 清除 SPIF和WCOL 标志 */
#define SPI_TOIFClear()         SPITOSR = 0x80           /* 设置 CTOCF 清除超时标志位 TOIF */

#define HSSPI_Enable(n)         HSSPI_CFG2 |= 0x20       //使能SPI高速模式
#define HSSPI_Disable(n)        HSSPI_CFG2 &= ~0x20      //关闭SPI高速模式

//========================================================================
//                              定义声明
//========================================================================

#define SPI_BUF_LENTH   128
#define SPI_BUF_type    __xdata

__sbit __at(0x94) SPI_SS;
__sbit __at(0x95) SPI_MOSI;
__sbit __at(0x96) SPI_MISO;
__sbit __at(0x97) SPI_SCLK;

__sbit __at(0xA4) SPI_SS_2;
__sbit __at(0xA5) SPI_MOSI_2;
__sbit __at(0xA6) SPI_MISO_2;
__sbit __at(0xA7) SPI_SCLK_2;

__sbit __at(0xC0) SPI_SS_3;
__sbit __at(0xC1) SPI_MOSI_3;
__sbit __at(0xC2) SPI_MISO_3;
__sbit __at(0xC3) SPI_SCLK_3;

__sbit __at(0xB5) SPI_SS_4;
__sbit __at(0xB4) SPI_MOSI_4;
__sbit __at(0xB3) SPI_MISO_4;
__sbit __at(0xB2) SPI_SCLK_4;

#define SPI_Mode_Slave      0
#define SPI_Mode_Master     1
#define SPI_CPOL_Low        0
#define SPI_CPOL_High       1
#define SPI_CPHA_1Edge      0
#define SPI_CPHA_2Edge      1
#define SPI_Speed_4         0
#define SPI_Speed_8         1
#define SPI_Speed_16        2
#define SPI_Speed_2         3
#define SPI_MSB             0
#define SPI_LSB             1

#ifndef TO_SCALE_1US
#define TO_SCALE_1US       0         //超时计数时钟源：1us时钟(1MHz时钟)
#endif
#ifndef TO_SCALE_SYSCLK
#define TO_SCALE_SYSCLK    1         //超时计数时钟源：系统时钟
#endif

typedef struct
{
    u8    SPI_Enable;       //SPI启动, ENABLE,DISABLE
    u8    SPI_SSIG;         //片选位, ENABLE(忽略SS引脚功能), DISABLE(SS确定主机从机)
    u8    SPI_FirstBit;     //SPI_MSB, SPI_LSB
    u8    SPI_Mode;         //SPI_Mode_Master, SPI_Mode_Slave
    u8    SPI_CPOL;         //SPI_CPOL_High,   SPI_CPOL_Low
    u8    SPI_CPHA;         //SPI_CPHA_1Edge,  SPI_CPHA_2Edge
    u8    SPI_Speed;        //SPI_Speed_4, SPI_Speed_8, SPI_Speed_16, SPI_Speed_2

    u8    TimeOutEnable;    //从机超时使能, ENABLE,DISABLE
    u8    TimeOutINTEnable; //超时中断使能, ENABLE,DISABLE
    u8    TimeOutScale;     //超时时钟源选择, TO_SCALE_1US,TO_SCALE_SYSCLK
    u32   TimeOutTimer;     //超时时间, 1 ~ 0xffffff
} SPI_InitTypeDef;


extern __bit B_SPI_Busy;  //发送忙标志
extern __bit SPI_RxTimerOut;
extern u8  SPI_RxCnt;
extern u8  SPI_BUF_type SPI_RxBuffer[SPI_BUF_LENTH];

void SPI_Init(SPI_InitTypeDef *SPIx);
void SPI_SetMode(u8 mode);
void SPI_WriteByte(u8 dat);
u8 SPI_ReadByte(void);

#endif


