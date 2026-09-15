/* cobs.h — 平台无关的 COBS 编码器 + 轻量二进制日志帧（C 接口）。
 *
 * 与同目录 cobs.zig 实现同一算法（两份实现便于各自语言原生调用；改动请保持同步，
 * 主机端 cobs_c_test.c / cobs_zig_test.zig 做往返一致性验证）。
 *
 * 设计：调用方提供输出缓冲区指针与容量；编码结果写在其中（单缓冲区、单趟，
 * “先占位长度码、后回填”）。如何输出（UART/USB/队列）由调用方决定。
 *
 * 日志帧（原始字节，随后整体 COBS，再以 0x00 结束）：
 *   0x7E, id_lo, id_hi, 参数…, XOR 校验
 * 参数：u8=1B、u16=2B 小端、u32=4B 小端、var=LEB128、str=LEB128(len)+字节。
 *
 * 用法：
 *   static unsigned char out[128];
 *   cobs_enc_t e;
 *   cobs_init(&e, out, sizeof out);
 *   cobs_log_begin(&e, 0x0002);
 *   cobs_log_u16(&e, 1234);
 *   unsigned int n = cobs_log_end(&e);   // out[0..n) 可发送；n==0 表示缓冲区不足
 *   uart_write(out, n);
 *
 * 注：cobs_enc_t 的字段布局与 cobs.zig 的 Encoder 一致（buf/cap/len/code_pos/code/ck/overflow）。
 */
#ifndef COBS_H
#define COBS_H

#ifdef __cplusplus
extern "C" {
#endif

/* 编码器状态。由调用方分配（通常栈上或全局），cobs_init 绑定输出缓冲区。 */
typedef struct {
    unsigned char *buf;      /* 输出缓冲区首地址（用户提供） */
    unsigned int   cap;      /* 缓冲区容量（字节） */
    unsigned int   len;      /* 已写入字节数 */
    unsigned int   code_pos; /* 当前块长度码位置 */
    unsigned char  code;     /* 当前块长度码（块内字节数 + 1） */
    unsigned char  ck;       /* 日志帧 XOR 校验累加 */
    unsigned char  overflow; /* 缓冲区不足置 1 */
} cobs_enc_t;

/* 绑定输出缓冲区并重置。 */
void cobs_init(cobs_enc_t *e, unsigned char *buf, unsigned int cap);

/* 重置编码器（预留首个长度码占位、清校验）。 */
void cobs_reset(cobs_enc_t *e);

/* 追加一个原始字节，做 COBS 编码（遇 0x00 / 满 254 字节封块）。 */
void cobs_putc(cobs_enc_t *e, unsigned char b);

/* 收尾：回填末尾长度码并追加 0x00 定界符；返回总长度（含定界符），不足返回 0。 */
unsigned int cobs_finish(cobs_enc_t *e);

/* 一次性编码：把 in[0..in_len) 编进 out（容量 out_cap）；返回长度或 0（不足）。 */
unsigned int cobs_encode(const unsigned char *in, unsigned int in_len,
                         unsigned char *out, unsigned int out_cap);

/* 一次性解码：把编码流 in[0..in_len)（**不含**尾部 0x00 定界符）解进 out（容量 out_cap）；
 * 返回解出长度，格式非法或 out 容量不足返回 0。 */
unsigned int cobs_decode(const unsigned char *in, unsigned int in_len,
                         unsigned char *out, unsigned int out_cap);

/* ---- 日志帧（在 COBS 之上） ---- */
void         cobs_log_begin(cobs_enc_t *e, unsigned int id);
void         cobs_log_raw(cobs_enc_t *e, unsigned char b);
void         cobs_log_u8(cobs_enc_t *e, unsigned char v);
void         cobs_log_u16(cobs_enc_t *e, unsigned int v);
void         cobs_log_u32(cobs_enc_t *e, unsigned long v);
void         cobs_log_var(cobs_enc_t *e, unsigned int v);   /* LEB128 */
void         cobs_log_bytes(cobs_enc_t *e, const unsigned char *p, unsigned int n);
void         cobs_log_str(cobs_enc_t *e, const char *s);    /* 以 NUL 结尾 */
unsigned int cobs_log_end(cobs_enc_t *e);

#ifdef __cplusplus
}
#endif

#endif /* COBS_H */
