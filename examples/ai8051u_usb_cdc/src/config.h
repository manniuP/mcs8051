#ifndef __CONFIG_H__
#define __CONFIG_H__

/* 本板 AI8051U 实际 IRC = 40MHz（USB 用内部 IRC48M，与 FOSC 无关）。
 * 改成 40MHz 使 UART2 的 BR() 与实际时钟一致（原例程按 24MHz）。 */
#define FOSC                    40000000UL

#define EN_EP1IN
#define EN_EP2IN
//#define EN_EP3IN
//#define EN_EP4IN
//#define EN_EP5IN
#define EN_EP1OUT
//#define EN_EP2OUT
//#define EN_EP3OUT
//#define EN_EP4OUT
//#define EN_EP5OUT

#define EP0_SIZE                64

#ifdef EN_EP1IN
#define EP1IN_SIZE              64
#endif
#ifdef EN_EP2IN
#define EP2IN_SIZE              64
#endif
#ifdef EN_EP3IN
#define EP3IN_SIZE              64
#endif
#ifdef EN_EP4IN
#define EP4IN_SIZE              64
#endif
#ifdef EN_EP5IN
#define EP5IN_SIZE              64
#endif
#ifdef EN_EP1OUT
#define EP1OUT_SIZE             64
#endif
#ifdef EN_EP2OUT
#define EP2OUT_SIZE             64
#endif
#ifdef EN_EP3OUT
#define EP3OUT_SIZE             64
#endif
#ifdef EN_EP4OUT
#define EP4OUT_SIZE             64
#endif
#ifdef EN_EP5OUT
#define EP5OUT_SIZE             64
#endif

#endif

