/*---------------------------------------------------------------------*/
/* --- Web: www.STCAI.com ---------------------------------------------*/
/*---------------------------------------------------------------------*/

#ifndef __AI8051U_NVIC_H
#define __AI8051U_NVIC_H

#include "config.h"

//========================================================================
//                              定义声明
//========================================================================

#define     FALLING_EDGE        1    //产生下降沿中断
#define     RISING_EDGE         2    //产生上升沿中断

//========================================================================
//                              定时器中断设置
//========================================================================

#define     Timer0_Interrupt(n)      (n==0?(ET0 = 0):(ET0 = 1))        /* Timer0中断使能 */
#define     Timer1_Interrupt(n)      (n==0?(ET1 = 0):(ET1 = 1))        /* Timer1中断使能 */
#define     Timer2_Interrupt(n)      (n==0?(IE2 = (unsigned char)((IE2 & ~0x04) | ((0) ? 0x04 : 0))):(IE2 = (unsigned char)((IE2 & ~0x04) | ((1) ? 0x04 : 0))))        /* Timer2中断使能 */
#define     Timer3_Interrupt(n)      (n==0?(IE2 = (unsigned char)((IE2 & ~0x20) | ((0) ? 0x20 : 0))):(IE2 = (unsigned char)((IE2 & ~0x20) | ((1) ? 0x20 : 0))))        /* Timer3中断使能 */
#define     Timer4_Interrupt(n)      (n==0?(IE2 = (unsigned char)((IE2 & ~0x40) | ((0) ? 0x40 : 0))):(IE2 = (unsigned char)((IE2 & ~0x40) | ((1) ? 0x40 : 0))))        /* Timer4中断使能 */
#define     Timer11_Interrupt(n)     (n==0?(T11CR &= ~0x02):(T11CR |= 0x02))/* Timer11中断使能 */

//========================================================================
//                             外部中断设置
//========================================================================

#define     INT0_Interrupt(n)        (n==0?(EX0 = 0):(EX0 = 1))        /* INT0中断使能 */
#define     INT1_Interrupt(n)        (n==0?(EX1 = 0):(EX1 = 1))        /* INT1中断使能 */
#define     INT2_Interrupt(n)        (n==0?(INTCLKO = (unsigned char)((INTCLKO & ~0x10) | ((0) ? 0x10 : 0))):(INTCLKO = (unsigned char)((INTCLKO & ~0x10) | ((1) ? 0x10 : 0))))        /* INT2中断使能 */
#define     INT3_Interrupt(n)        (n==0?(INTCLKO = (unsigned char)((INTCLKO & ~0x20) | ((0) ? 0x20 : 0))):(INTCLKO = (unsigned char)((INTCLKO & ~0x20) | ((1) ? 0x20 : 0))))        /* INT3中断使能 */
#define     INT4_Interrupt(n)        (n==0?(INTCLKO = (unsigned char)((INTCLKO & ~0x40) | ((0) ? 0x40 : 0))):(INTCLKO = (unsigned char)((INTCLKO & ~0x40) | ((1) ? 0x40 : 0))))        /* INT4中断使能 */

//========================================================================
//                              ADC中断设置
//========================================================================

#define     ADC_Interrupt(n)         (n==0?(EADC = 0):(EADC = 1))      /* ADC中断控制 */

//========================================================================
//                              SPI中断设置
//========================================================================

#define     SPI_Interrupt(n)         (n==0?(IE2 = (unsigned char)((IE2 & ~0x02) | ((0) ? 0x02 : 0))):(IE2 = (unsigned char)((IE2 & ~0x02) | ((1) ? 0x02 : 0))))      /* SPI中断使能 */

//========================================================================
//                              RTC中断设置
//========================================================================

#define     RTC_Interrupt(n)         RTCIEN = (n)        /* RTC中断使能 */

//========================================================================
//                              UART中断设置
//========================================================================

#define     UART1_Interrupt(n)      (n==0?(ES = 0):(ES = 1))       /* UART1中断使能 */
#define     UART2_Interrupt(n)      (n==0?(IE2 = (unsigned char)((IE2 & ~0x01) | ((0) ? 0x01 : 0))):(IE2 = (unsigned char)((IE2 & ~0x01) | ((1) ? 0x01 : 0))))     /* UART2中断使能 */
#define     UART3_Interrupt(n)      (n==0?(IE2 = (unsigned char)((IE2 & ~0x08) | ((0) ? 0x08 : 0))):(IE2 = (unsigned char)((IE2 & ~0x08) | ((1) ? 0x08 : 0))))     /* UART3中断使能 */
#define     UART4_Interrupt(n)      (n==0?(IE2 = (unsigned char)((IE2 & ~0x10) | ((0) ? 0x10 : 0))):(IE2 = (unsigned char)((IE2 & ~0x10) | ((1) ? 0x10 : 0))))     /* UART4中断使能 */

//========================================================================
//                              I2C中断设置
//========================================================================

#define     I2C_Master_Inturrupt(n) (n==0?(I2CMSCR &= ~0x80):(I2CMSCR |= 0x80))    //0：禁止 I2C 功能；1：使能 I2C 功能

//========================================================================
//                              QSPI中断设置
//========================================================================

#define     QSPI_Interrupt(n)       QSPI_CR3 = (n & 0x0f)          /* QSPI中断使能 */

//========================================================================
//                            中断优先级定义
//========================================================================

#ifndef Priority_0
#define Priority_0          0	//中断优先级为 0 级（最低级）
#endif

#ifndef Priority_1
#define Priority_1          1	//中断优先级为 1 级（较低级）
#endif

#ifndef Priority_2
#define Priority_2          2	//中断优先级为 2 级（较高级）
#endif

#ifndef Priority_3
#define Priority_3          3	//中断优先级为 3 级（最高级）
#endif

//串口2中断优先级控制
#define     UART2_Priority(n)           do{if(n == 0) IP2H = (unsigned char)((IP2H & ~0x01) | ((0, IP2 &= ~0x01) ? 0x01 : 0)); \
                                            if(n == 1) IP2H = (unsigned char)((IP2H & ~0x01) | ((0, IP2 |= 0x01) ? 0x01 : 0)); \
                                            if(n == 2) IP2H = (unsigned char)((IP2H & ~0x01) | ((1, IP2 &= ~0x01) ? 0x01 : 0)); \
                                            if(n == 3) IP2H = (unsigned char)((IP2H & ~0x01) | ((1, IP2 |= 0x01) ? 0x01 : 0)); \
                                        }while(0)
//SPI中断优先级控制
#define     SPI_Priority(n)             do{if(n == 0) IP2H = (unsigned char)((IP2H & ~0x02) | ((0, IP2 &= ~0x02) ? 0x02 : 0)); \
                                            if(n == 1) IP2H = (unsigned char)((IP2H & ~0x02) | ((0, IP2 |= 0x02) ? 0x02 : 0)); \
                                            if(n == 2) IP2H = (unsigned char)((IP2H & ~0x02) | ((1, IP2 &= ~0x02) ? 0x02 : 0)); \
                                            if(n == 3) IP2H = (unsigned char)((IP2H & ~0x02) | ((1, IP2 |= 0x02) ? 0x02 : 0)); \
                                        }while(0)
//外部中断4中断优先级控制
#define     INT4_Priority(n)            do{if(n == 0) IP2H = (unsigned char)((IP2H & ~0x10) | ((0, IP2 &= ~0x10) ? 0x10 : 0)); \
                                            if(n == 1) IP2H = (unsigned char)((IP2H & ~0x10) | ((0, IP2 |= 0x10) ? 0x10 : 0)); \
                                            if(n == 2) IP2H = (unsigned char)((IP2H & ~0x10) | ((1, IP2 &= ~0x10) ? 0x10 : 0)); \
                                            if(n == 3) IP2H = (unsigned char)((IP2H & ~0x10) | ((1, IP2 |= 0x10) ? 0x10 : 0)); \
                                        }while(0)
//比较器中断优先级控制
#define     CMP_Priority(n)             do{if(n == 0) IP2H = (unsigned char)((IP2H & ~0x20) | ((0, IP2 &= ~0x20) ? 0x20 : 0)); \
                                            if(n == 1) IP2H = (unsigned char)((IP2H & ~0x20) | ((0, IP2 |= 0x20) ? 0x20 : 0)); \
                                            if(n == 2) IP2H = (unsigned char)((IP2H & ~0x20) | ((1, IP2 &= ~0x20) ? 0x20 : 0)); \
                                            if(n == 3) IP2H = (unsigned char)((IP2H & ~0x20) | ((1, IP2 |= 0x20) ? 0x20 : 0)); \
                                        }while(0)
//I2C中断优先级控制
#define     I2C_Priority(n)             do{if(n == 0) IP2H = (unsigned char)((IP2H & ~0x40) | ((0, IP2 &= ~0x40) ? 0x40 : 0)); \
                                            if(n == 1) IP2H = (unsigned char)((IP2H & ~0x40) | ((0, IP2 |= 0x40) ? 0x40 : 0)); \
                                            if(n == 2) IP2H = (unsigned char)((IP2H & ~0x40) | ((1, IP2 &= ~0x40) ? 0x40 : 0)); \
                                            if(n == 3) IP2H = (unsigned char)((IP2H & ~0x40) | ((1, IP2 |= 0x40) ? 0x40 : 0)); \
                                        }while(0)
//串口3中断优先级控制
#define     UART3_Priority(n)           do{if(n == 0) IP3H = (unsigned char)((IP3H & ~0x01) | ((0, IP3 &= ~0x01) ? 0x01 : 0)); \
                                            if(n == 1) IP3H = (unsigned char)((IP3H & ~0x01) | ((0, IP3 |= 0x01) ? 0x01 : 0)); \
                                            if(n == 2) IP3H = (unsigned char)((IP3H & ~0x01) | ((1, IP3 &= ~0x01) ? 0x01 : 0)); \
                                            if(n == 3) IP3H = (unsigned char)((IP3H & ~0x01) | ((1, IP3 |= 0x01) ? 0x01 : 0)); \
                                        }while(0)
//串口4中断优先级控制
#define     UART4_Priority(n)           do{if(n == 0) IP3H = (unsigned char)((IP3H & ~0x02) | ((0, IP3 &= ~0x02) ? 0x02 : 0)); \
                                            if(n == 1) IP3H = (unsigned char)((IP3H & ~0x02) | ((0, IP3 |= 0x02) ? 0x02 : 0)); \
                                            if(n == 2) IP3H = (unsigned char)((IP3H & ~0x02) | ((1, IP3 &= ~0x02) ? 0x02 : 0)); \
                                            if(n == 3) IP3H = (unsigned char)((IP3H & ~0x02) | ((1, IP3 |= 0x02) ? 0x02 : 0)); \
                                        }while(0)

//外部中断0中断优先级控制
#define     INT0_Priority(n)            do{if(n == 0) IPH = (unsigned char)((IPH & ~0x01) | ((0, PX0 = 0) ? 0x01 : 0)); \
                                            if(n == 1) IPH = (unsigned char)((IPH & ~0x01) | ((0, PX0 = 1) ? 0x01 : 0)); \
                                            if(n == 2) IPH = (unsigned char)((IPH & ~0x01) | ((1, PX0 = 0) ? 0x01 : 0)); \
                                            if(n == 3) IPH = (unsigned char)((IPH & ~0x01) | ((1, PX0 = 1) ? 0x01 : 0)); \
                                        }while(0)
//外部中断1中断优先级控制
#define     INT1_Priority(n)            do{if(n == 0) IPH = (unsigned char)((IPH & ~0x04) | ((0, PX1 = 0) ? 0x04 : 0)); \
                                            if(n == 1) IPH = (unsigned char)((IPH & ~0x04) | ((0, PX1 = 1) ? 0x04 : 0)); \
                                            if(n == 2) IPH = (unsigned char)((IPH & ~0x04) | ((1, PX1 = 0) ? 0x04 : 0)); \
                                            if(n == 3) IPH = (unsigned char)((IPH & ~0x04) | ((1, PX1 = 1) ? 0x04 : 0)); \
                                        }while(0)
//定时器0中断优先级控制
#define     Timer0_Priority(n)          do{if(n == 0) IPH = (unsigned char)((IPH & ~0x02) | ((0, PT0 = 0) ? 0x02 : 0)); \
                                            if(n == 1) IPH = (unsigned char)((IPH & ~0x02) | ((0, PT0 = 1) ? 0x02 : 0)); \
                                            if(n == 2) IPH = (unsigned char)((IPH & ~0x02) | ((1, PT0 = 0) ? 0x02 : 0)); \
                                            if(n == 3) IPH = (unsigned char)((IPH & ~0x02) | ((1, PT0 = 1) ? 0x02 : 0)); \
                                        }while(0)
//定时器1中断优先级控制
#define     Timer1_Priority(n)          do{if(n == 0) IPH = (unsigned char)((IPH & ~0x08) | ((0, PT1 = 0) ? 0x08 : 0)); \
                                            if(n == 1) IPH = (unsigned char)((IPH & ~0x08) | ((0, PT1 = 1) ? 0x08 : 0)); \
                                            if(n == 2) IPH = (unsigned char)((IPH & ~0x08) | ((1, PT1 = 0) ? 0x08 : 0)); \
                                            if(n == 3) IPH = (unsigned char)((IPH & ~0x08) | ((1, PT1 = 1) ? 0x08 : 0)); \
                                        }while(0)
//串口1中断优先级控制
#define     UART1_Priority(n)           do{if(n == 0) IPH = (unsigned char)((IPH & ~0x10) | ((0, PS = 0) ? 0x10 : 0)); \
                                            if(n == 1) IPH = (unsigned char)((IPH & ~0x10) | ((0, PS = 1) ? 0x10 : 0)); \
                                            if(n == 2) IPH = (unsigned char)((IPH & ~0x10) | ((1, PS = 0) ? 0x10 : 0)); \
                                            if(n == 3) IPH = (unsigned char)((IPH & ~0x10) | ((1, PS = 1) ? 0x10 : 0)); \
                                        }while(0)
//ADC中断优先级控制
#define     ADC_Priority(n)             do{if(n == 0) IPH = (unsigned char)((IPH & ~0x20) | ((0, PADC = 0) ? 0x20 : 0)); \
                                            if(n == 1) IPH = (unsigned char)((IPH & ~0x20) | ((0, PADC = 1) ? 0x20 : 0)); \
                                            if(n == 2) IPH = (unsigned char)((IPH & ~0x20) | ((1, PADC = 0) ? 0x20 : 0)); \
                                            if(n == 3) IPH = (unsigned char)((IPH & ~0x20) | ((1, PADC = 1) ? 0x20 : 0)); \
                                        }while(0)
//低压检测中断优先级控制
#define     LVD_Priority(n)             do{if(n == 0) IPH = (unsigned char)((IPH & ~0x40) | ((0, PADC = 0) ? 0x40 : 0)); \
                                            if(n == 1) IPH = (unsigned char)((IPH & ~0x40) | ((0, PADC = 1) ? 0x40 : 0)); \
                                            if(n == 2) IPH = (unsigned char)((IPH & ~0x40) | ((1, PADC = 0) ? 0x40 : 0)); \
                                            if(n == 3) IPH = (unsigned char)((IPH & ~0x40) | ((1, PADC = 1) ? 0x40 : 0)); \
                                        }while(0)
//高级PWMA中断优先级控制
#define     PWMA_Priority(n)            do{if(n == 0) IP2H = (unsigned char)((IP2H & ~0x04) | ((0, IP2 &= ~0x04) ? 0x04 : 0)); \
                                            if(n == 1) IP2H = (unsigned char)((IP2H & ~0x04) | ((0, IP2 |= 0x04) ? 0x04 : 0)); \
                                            if(n == 2) IP2H = (unsigned char)((IP2H & ~0x04) | ((1, IP2 &= ~0x04) ? 0x04 : 0)); \
                                            if(n == 3) IP2H = (unsigned char)((IP2H & ~0x04) | ((1, IP2 |= 0x04) ? 0x04 : 0)); \
                                        }while(0)

//高级PWMB中断优先级控制
#define     PWMB_Priority(n)            do{if(n == 0) IP2H = (unsigned char)((IP2H & ~0x08) | ((0, IP2 &= ~0x08) ? 0x08 : 0)); \
                                            if(n == 1) IP2H = (unsigned char)((IP2H & ~0x08) | ((0, IP2 |= 0x08) ? 0x08 : 0)); \
                                            if(n == 2) IP2H = (unsigned char)((IP2H & ~0x08) | ((1, IP2 &= ~0x08) ? 0x08 : 0)); \
                                            if(n == 3) IP2H = (unsigned char)((IP2H & ~0x08) | ((1, IP2 |= 0x08) ? 0x08 : 0)); \
                                        }while(0)

//RTC中断优先级控制
#define     RTC_Priority(n)             do{if(n == 0) IP3H = (unsigned char)((IP3H & ~0x04) | ((0, IP3 &= ~0x04) ? 0x04 : 0)); \
                                            if(n == 1) IP3H = (unsigned char)((IP3H & ~0x04) | ((0, IP3 |= 0x04) ? 0x04 : 0)); \
                                            if(n == 2) IP3H = (unsigned char)((IP3H & ~0x04) | ((1, IP3 &= ~0x04) ? 0x04 : 0)); \
                                            if(n == 3) IP3H = (unsigned char)((IP3H & ~0x04) | ((1, IP3 |= 0x04) ? 0x04 : 0)); \
                                        }while(0)

//QSPI中断优先级控制
#define     QSPI_Priority(n)            do{if(n == 0) QSPI_DCR1 &= ~0x0c; \
                                            if(n == 1) QSPI_DCR1 = (QSPI_DCR1 & ~0x0c) | 0x04; \
                                            if(n == 2) QSPI_DCR1 = (QSPI_DCR1 & ~0x0c) | 0x08; \
                                            if(n == 3) QSPI_DCR1 |= 0x0c; \
                                        }while(0)

//========================================================================
//                           外部函数和变量声明
//========================================================================

u8 NVIC_Timer0_Init(u8 State, u8 Priority);
u8 NVIC_Timer1_Init(u8 State, u8 Priority);
u8 NVIC_Timer2_Init(u8 State, u8 Priority);
u8 NVIC_Timer3_Init(u8 State, u8 Priority);
u8 NVIC_Timer4_Init(u8 State, u8 Priority);
u8 NVIC_Timer11_Init(u8 State, u8 Priority);
u8 NVIC_INT0_Init(u8 State, u8 Priority);
u8 NVIC_INT1_Init(u8 State, u8 Priority);
u8 NVIC_INT2_Init(u8 State, u8 Priority);
u8 NVIC_INT3_Init(u8 State, u8 Priority);
u8 NVIC_INT4_Init(u8 State, u8 Priority);
u8 NVIC_ADC_Init(u8 State, u8 Priority);
u8 NVIC_SPI_Init(u8 State, u8 Priority);
u8 NVIC_RTC_Init(u8 State, u8 Priority);
u8 NVIC_CMP_Init(u8 State, u8 Priority);
u8 NVIC_I2C_Init(u8 Mode, u8 State, u8 Priority);
u8 NVIC_UART1_Init(u8 State, u8 Priority);
u8 NVIC_UART2_Init(u8 State, u8 Priority);
u8 NVIC_UART3_Init(u8 State, u8 Priority);
u8 NVIC_UART4_Init(u8 State, u8 Priority);
u8 NVIC_PWM_Init(u8 Channel, u8 State, u8 Priority);
u8 NVIC_DMA_ADC_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_M2M_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_SPI_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_LCM_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_I2CT_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_I2CR_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_UART1_Tx_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_UART1_Rx_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_UART2_Tx_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_UART2_Rx_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_UART3_Tx_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_UART3_Rx_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_UART4_Tx_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_DMA_UART4_Rx_Init(u8 State, u8 Priority, u8 Bus_Priority);
u8 NVIC_LCM_Init(u8 State, u8 Priority);
u8 NVIC_QSPI_Init(u8 State, u8 Priority);

#endif

