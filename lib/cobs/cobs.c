/* cobs.c — 平台无关 COBS + 轻量日志帧（实现，见 cobs.h）。
 *
 * 纯 C、无 libc 依赖（不调用 memset/strlen 等），可编到 mcs51 / mcs251 / 主机。
 * 与 cobs.zig 等价，改动请保持同步。
 */
#include "cobs.h"

static void cobs_patch(cobs_enc_t *e) {
    if (e->code_pos < e->len) e->buf[e->code_pos] = e->code;
}

static void cobs_begin_block(cobs_enc_t *e, unsigned char code) {
    if (e->len >= e->cap) {
        e->overflow = 1;
        return;
    }
    e->code_pos = e->len;
    e->buf[e->len] = 0; /* 长度码占位 */
    e->len++;
    e->code = code;
}

void cobs_init(cobs_enc_t *e, unsigned char *buf, unsigned int cap) {
    e->buf = buf;
    e->cap = cap;
    cobs_reset(e);
}

void cobs_reset(cobs_enc_t *e) {
    e->len = 0;
    e->code = 1;
    e->code_pos = 0;
    e->ck = 0;
    e->overflow = 0;
    if (e->cap == 0) {
        e->overflow = 1;
        return;
    }
    e->buf[0] = 0; /* 首个块长度码占位 */
    e->len = 1;
}

void cobs_putc(cobs_enc_t *e, unsigned char b) {
    if (b == 0) {
        cobs_patch(e);
        cobs_begin_block(e, 1);
        return;
    }
    if (e->code == 255) {
        cobs_patch(e);
        cobs_begin_block(e, 1);
    }
    if (e->len >= e->cap) {
        e->overflow = 1;
        return;
    }
    e->buf[e->len] = b;
    e->len++;
    e->code++;
}

unsigned int cobs_finish(cobs_enc_t *e) {
    cobs_patch(e);
    if (e->len >= e->cap) {
        e->overflow = 1;
        return 0;
    }
    e->buf[e->len] = 0x00; /* 帧定界 */
    e->len++;
    return e->overflow ? 0 : e->len;
}

unsigned int cobs_encode(const unsigned char *in, unsigned int in_len,
                         unsigned char *out, unsigned int out_cap) {
    cobs_enc_t e;
    unsigned int i;
    cobs_init(&e, out, out_cap);
    for (i = 0; i < in_len; i++) cobs_putc(&e, in[i]);
    return cobs_finish(&e);
}

/* ---- 日志帧 ---- */

void cobs_log_begin(cobs_enc_t *e, unsigned int id) {
    unsigned char il = (unsigned char)(id & 0xff);
    unsigned char ih = (unsigned char)((id >> 8) & 0xff);
    cobs_reset(e);
    cobs_putc(e, 0x7e);
    cobs_putc(e, il);
    cobs_putc(e, ih);
    e->ck = il ^ ih;
}

void cobs_log_raw(cobs_enc_t *e, unsigned char b) {
    cobs_putc(e, b);
    e->ck ^= b;
}

void cobs_log_u8(cobs_enc_t *e, unsigned char v) {
    cobs_log_raw(e, v);
}

void cobs_log_u16(cobs_enc_t *e, unsigned int v) {
    cobs_log_raw(e, (unsigned char)(v & 0xff));
    cobs_log_raw(e, (unsigned char)((v >> 8) & 0xff));
}

void cobs_log_u32(cobs_enc_t *e, unsigned long v) {
    cobs_log_raw(e, (unsigned char)(v & 0xff));
    cobs_log_raw(e, (unsigned char)((v >> 8) & 0xff));
    cobs_log_raw(e, (unsigned char)((v >> 16) & 0xff));
    cobs_log_raw(e, (unsigned char)((v >> 24) & 0xff));
}

void cobs_log_var(cobs_enc_t *e, unsigned int v) {
    for (;;) {
        unsigned char b = (unsigned char)(v & 0x7f);
        v >>= 7;
        if (v != 0) {
            cobs_log_raw(e, (unsigned char)(b | 0x80));
        } else {
            cobs_log_raw(e, b);
            return;
        }
    }
}

void cobs_log_bytes(cobs_enc_t *e, const unsigned char *p, unsigned int n) {
    unsigned int i;
    cobs_log_var(e, n);
    for (i = 0; i < n; i++) cobs_log_raw(e, p[i]);
}

void cobs_log_str(cobs_enc_t *e, const char *s) {
    unsigned int n = 0;
    while (s[n] != '\0') n++;
    cobs_log_var(e, n);
    while (*s != '\0') cobs_log_raw(e, (unsigned char)*s++);
}

unsigned int cobs_log_end(cobs_enc_t *e) {
    cobs_log_raw(e, e->ck);
    return cobs_finish(e);
}
