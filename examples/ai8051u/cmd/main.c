/*
 * main.c — P0「UART 下发指令」：主机经 UART1 下发 **COBS 帧命令**，MCU 解析后执行并回包。
 *
 * 复用 lib/cobs 的帧格式（与 ziglog/ccobs/usbcdcobs 同一张表），主机端用 host/cmd.py：
 *   原始帧：0x7E, id_lo, id_hi, 参数…, XOR       （XOR 从 id_lo 起到参数末，不含 0x7E）
 *   发/收：整帧 COBS 编码后以 0x00 定界。
 *
 * 命令（id）与应答（id | 0x8000）：
 *   0x0001 ping  —                      → 0x8001 u16 0x1234
 *   0x0002 mul   — u32 a, u32 b         → 0x8002 u32 (a*b)      （MDU 硬件，指令码 0x02）
 *   0x0003 div   — u32 a, u32 b         → 0x8003 u32 q, u32 r   （MDU 硬件，指令码 0x04；b=0 → 均 0xFFFFFFFF）
 *   0x0004 led   — u8 on(0/1)           → 0x8004 u8 状态（P1.1）
 *   0x0005 echo  — 原始字节             → 0x8005 原样回显
 *   0x0010 cossin— i16 角(BAM)          → 0x8010 i16 cos, i16 sin（Q15）
 *   0x0011 atan2 — i16 y, i16 x         → 0x8011 i16 角(BAM)
 *   0x0012 sqrt  — u32                  → 0x8012 u16
 *   0x0013 mag   — i16 x, i16 y         → 0x8013 u16
 *   其它         —                      → 0x7FFF u16 原 id, u8 0xFF
 *
 * 单编译单元：ISR 与 main 同文件（SDCC mcs251 的 IVT 只在含 main 的模块生成，见 docs/14）。
 * 串口 P3.0(RxD)/P3.1(TxD)，115200 8N1。
 */

#include "config.h"
#include "c51.h"              /* ISR(n) / CRITICAL */
#include "uart251.h"
#include "cobs.h"
#include "cordic.h"
#include "ai8051u_mdu.h"      /* 32 位硬件乘除（DMAIR @0xED） */

#define FRAME_MAX   128

/* 接收：ISR 收 COBS 字节（不含定界符），遇 0x00 置 rx_ready 并暂停，主循环取走后再开 */
static volatile unsigned char rx_cobs[FRAME_MAX];
static volatile unsigned int  rx_len;
static volatile unsigned char rx_ready;

static unsigned char frame_cobs[FRAME_MAX];   /* 主循环快照 */
static unsigned char frame[FRAME_MAX];        /* COBS 解码后的原始帧 */
static unsigned char tx_buf[FRAME_MAX];
static cobs_enc_t    enc;

void uart1_isr(void) ISR(UART1_VECTOR)
{
    unsigned char c;
    if (RI) {
        RI = 0;
        c = SBUF;
        if (c == 0x00) {
            rx_ready = 1;                     /* 帧结束；主循环处理并复位前不再收 */
        } else if (!rx_ready && rx_len < FRAME_MAX) {
            rx_cobs[rx_len++] = c;
        }
    }
}

static void send(const unsigned char *p, unsigned int n)
{
    unsigned int i;
    for (i = 0; i < n; i++) uart_putc(p[i]);
}

static void reply(void)
{
    unsigned int n = cobs_log_end(&enc);
    if (n) send(tx_buf, n);
}

static unsigned long rd32(const unsigned char *p)
{
    return (unsigned long)p[0]
         | ((unsigned long)p[1] << 8)
         | ((unsigned long)p[2] << 16)
         | ((unsigned long)p[3] << 24);
}

static int rd16s(const unsigned char *p)   /* 有符号 16 位（小端） */
{
    return (int)((unsigned int)p[0] | ((unsigned int)p[1] << 8));
}

static void handle(unsigned int id, const unsigned char *p, unsigned int n)
{
    switch (id) {
    case 0x0001:                              /* ping */
        cobs_log_begin(&enc, 0x8001);
        cobs_log_u16(&enc, 0x1234);
        reply();
        break;

    case 0x0002:                              /* mul → 走 MDU 硬件（指令码 0x02） */
        if (n >= 8) {
            unsigned long a = rd32(p);
            unsigned long b = rd32(p + 4);
            unsigned long r;
            CRITICAL { r = mdu_mul32(a, b); } /* MDU 用 R0-R7：关中断防串口 ISR 踩操作数 */
            cobs_log_begin(&enc, 0x8002);
            cobs_log_u32(&enc, r);
            reply();
        }
        break;

    case 0x0003:                              /* div → 走 MDU 硬件（指令码 0x04），商+余 */
        if (n >= 8) {
            unsigned long a = rd32(p);
            unsigned long b = rd32(p + 4);
            unsigned long q;
            unsigned long r;
            if (b == 0) {                     /* 保持与软件版一致的除零约定 */
                q = 0xFFFFFFFFUL;
                r = 0xFFFFFFFFUL;
            } else {
                CRITICAL {
                    q = mdu_div32u(a, b);
                    r = mdu_mod32u(a, b);
                }
            }
            cobs_log_begin(&enc, 0x8003);
            cobs_log_u32(&enc, q);
            cobs_log_u32(&enc, r);
            reply();
        }
        break;

    case 0x0004:                              /* led (P1.1) */
        if (n >= 1) {
            P11 = (p[0] & 1) ? 1 : 0;
            cobs_log_begin(&enc, 0x8004);
            cobs_log_u8(&enc, P11 ? 1 : 0);
            reply();
        }
        break;

    case 0x0005:                              /* echo */
        {
            unsigned int i;
            cobs_log_begin(&enc, 0x8005);
            for (i = 0; i < n; i++) cobs_log_raw(&enc, p[i]);
            reply();
        }
        break;

    case 0x0010:                              /* cossin: i16 角(BAM) → i16 cos, i16 sin（Q15） */
        if (n >= 2) {
            int s, c;
            cordic_sincos((int)((unsigned int)p[0] | ((unsigned int)p[1] << 8)), &s, &c);
            cobs_log_begin(&enc, 0x8010);
            cobs_log_u16(&enc, (unsigned int)c);
            cobs_log_u16(&enc, (unsigned int)s);
            reply();
        }
        break;

    case 0x0011:                              /* atan2: i16 y, i16 x → i16 角(BAM) */
        if (n >= 4) {
            int ang = cordic_atan2(rd16s(p), rd16s(p + 2));
            cobs_log_begin(&enc, 0x8011);
            cobs_log_u16(&enc, (unsigned int)ang);
            reply();
        }
        break;

    case 0x0012:                              /* sqrt: u32 → u16 */
        if (n >= 4) {
            cobs_log_begin(&enc, 0x8012);
            cobs_log_u16(&enc, cordic_isqrt(rd32(p)));
            reply();
        }
        break;

    case 0x0013:                              /* mag: i16 x, i16 y → u16 */
        if (n >= 4) {
            cobs_log_begin(&enc, 0x8013);
            cobs_log_u16(&enc, cordic_mag(rd16s(p), rd16s(p + 2)));
            reply();
        }
        break;

    default:                                  /* 未知命令 */
        cobs_log_begin(&enc, 0x7fff);
        cobs_log_u16(&enc, id);
        cobs_log_u8(&enc, 0xff);
        reply();
        break;
    }
}

void main(void)
{
    WDT_CONTR = 0x00;                         /* 关看门狗 */
    P1M0 |= 0x02;  P1M1 &= ~0x02;             /* P1.1 推挽输出（LED） */

    uart_init();
    uart_rx_enable();
    cobs_init(&enc, tx_buf, sizeof tx_buf);

    /* 上电自报：id 0x0001，u16 0x1234（主机据此确认板子在跑） */
    cobs_log_begin(&enc, 0x0001);
    cobs_log_u16(&enc, 0x1234);
    reply();

    for (;;) {
        if (rx_ready) {
            unsigned int len, i, rawlen, ck, id;

            CRITICAL { len = rx_len; }        /* rx_ready=1 期间缓冲稳定 */
            for (i = 0; i < len; i++) frame_cobs[i] = rx_cobs[i];
            CRITICAL { rx_len = 0; rx_ready = 0; }

            rawlen = cobs_decode(frame_cobs, len, frame, sizeof frame);
            if (rawlen >= 4 && frame[0] == 0x7e) {
                ck = 0;
                for (i = 1; i + 1 < rawlen; i++) ck ^= frame[i];
                if (ck == frame[rawlen - 1]) {
                    id = (unsigned int)frame[1] | ((unsigned int)frame[2] << 8);
                    handle(id, &frame[3], rawlen - 4);
                }
            }
        }
    }
}
