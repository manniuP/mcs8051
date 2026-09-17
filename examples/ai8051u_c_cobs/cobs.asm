;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.6.0 #0 (MINGW64)
;--------------------------------------------------------
	.module cobs
	
	.optsdcc -mmcs251 --model-large
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _cobs_log_str_PARM_2
	.globl _cobs_log_bytes_PARM_3
	.globl _cobs_log_bytes_PARM_2
	.globl _cobs_log_var_PARM_2
	.globl _cobs_log_u32_PARM_2
	.globl _cobs_log_u16_PARM_2
	.globl _cobs_log_u8_PARM_2
	.globl _cobs_log_raw_PARM_2
	.globl _cobs_log_begin_PARM_2
	.globl _cobs_encode_PARM_4
	.globl _cobs_encode_PARM_3
	.globl _cobs_encode_PARM_2
	.globl _cobs_putc_PARM_2
	.globl _cobs_init_PARM_3
	.globl _cobs_init_PARM_2
	.globl _cobs_init
	.globl _cobs_reset
	.globl _cobs_putc
	.globl _cobs_finish
	.globl _cobs_encode
	.globl _cobs_log_begin
	.globl _cobs_log_raw
	.globl _cobs_log_u8
	.globl _cobs_log_u16
	.globl _cobs_log_u32
	.globl _cobs_log_var
	.globl _cobs_log_bytes
	.globl _cobs_log_str
	.globl _cobs_log_end
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
	.area RSEG    (ABS,DATA)
	.org 0x0000
;--------------------------------------------------------
; special function bits
;--------------------------------------------------------
	.area RSEG    (ABS,DATA)
	.org 0x0000
;--------------------------------------------------------
; overlayable register banks
;--------------------------------------------------------
	.area REG_BANK_0	(REL,OVR,DATA)
	.ds 8
;--------------------------------------------------------
; internal ram data
;--------------------------------------------------------
	.area DSEG    (DATA)
;--------------------------------------------------------
; overlayable items in internal ram
;--------------------------------------------------------
;--------------------------------------------------------
; indirectly addressable internal ram data
;--------------------------------------------------------
	.area ISEG    (DATA)
;--------------------------------------------------------
; absolute internal ram data
;--------------------------------------------------------
	.area IABS    (ABS,DATA)
	.area IABS    (ABS,DATA)
;--------------------------------------------------------
; bit data
;--------------------------------------------------------
	.area BSEG    (BIT)
;--------------------------------------------------------
; paged external ram data
;--------------------------------------------------------
	.area PSEG    (PAG,XDATA)
;--------------------------------------------------------
; uninitialized external ram data
;--------------------------------------------------------
	.area XSEG    (XDATA)
_cobs_patch_e_10000_15:
	.ds 3
_cobs_begin_block_PARM_2:
	.ds 1
_cobs_begin_block_e_10000_18:
	.ds 3
_cobs_begin_block_sloc1_1_0:
	.ds 3
_cobs_init_PARM_2:
	.ds 3
_cobs_init_PARM_3:
	.ds 2
_cobs_init_e_10000_22:
	.ds 3
_cobs_init_sloc0_1_0:
	.ds 3
_cobs_reset_e_10000_24:
	.ds 3
_cobs_reset_sloc0_1_0:
	.ds 3
_cobs_reset_sloc1_1_0:
	.ds 3
_cobs_putc_PARM_2:
	.ds 1
_cobs_putc_e_10000_28:
	.ds 3
_cobs_putc_sloc1_1_0:
	.ds 3
_cobs_putc_sloc2_1_0:
	.ds 3
_cobs_finish_e_10000_36:
	.ds 3
_cobs_finish_sloc1_1_0:
	.ds 3
_cobs_encode_PARM_2:
	.ds 2
_cobs_encode_PARM_3:
	.ds 3
_cobs_encode_PARM_4:
	.ds 2
_cobs_encode_in_10000_40:
	.ds 3
_cobs_encode_e_10000_41:
	.ds 12
_cobs_log_begin_PARM_2:
	.ds 2
_cobs_log_begin_e_10000_43:
	.ds 3
_cobs_log_raw_PARM_2:
	.ds 1
_cobs_log_raw_e_10000_45:
	.ds 3
_cobs_log_u8_PARM_2:
	.ds 1
_cobs_log_u8_e_10000_47:
	.ds 3
_cobs_log_u16_PARM_2:
	.ds 2
_cobs_log_u16_e_10000_49:
	.ds 3
_cobs_log_u32_PARM_2:
	.ds 4
_cobs_log_u32_e_10000_51:
	.ds 3
_cobs_log_var_PARM_2:
	.ds 2
_cobs_log_var_e_10000_53:
	.ds 3
_cobs_log_var_b_30000_56:
	.ds 1
_cobs_log_bytes_PARM_2:
	.ds 3
_cobs_log_bytes_PARM_3:
	.ds 2
_cobs_log_bytes_e_10000_60:
	.ds 3
_cobs_log_bytes_sloc0_1_0:
	.ds 3
_cobs_log_str_PARM_2:
	.ds 3
_cobs_log_str_e_10000_63:
	.ds 3
_cobs_log_end_e_10000_65:
	.ds 3
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
	.area XABS    (ABS,XDATA)
;--------------------------------------------------------
; initialized external ram data
;--------------------------------------------------------
	.area XISEG   (XDATA)
	.area HOME    (CODE)
	.area GSINIT0 (CODE)
	.area GSINIT1 (CODE)
	.area GSINIT2 (CODE)
	.area GSINIT3 (CODE)
	.area GSINIT4 (CODE)
	.area GSINIT5 (CODE)
	.area GSINIT  (CODE)
	.area GSFINAL (CODE)
	.area CSEG    (CODE)
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area HOME    (CODE)
	.area GSINIT  (CODE)
	.area GSFINAL (CODE)
	.area GSINIT  (CODE)
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area HOME    (CODE)
	.area HOME    (CODE)
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area CSEG    (CODE)
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_patch'
;------------------------------------------------------------
;e             Allocated with name '_cobs_patch_e_10000_15'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:8: static void cobs_patch(cobs_enc_t *e) {
;	-----------------------------------------
;	 function cobs_patch
;	-----------------------------------------
_cobs_patch:
	ar7 = 0x07
	ar6 = 0x06
	ar5 = 0x05
	ar4 = 0x04
	ar3 = 0x03
	ar2 = 0x02
	ar1 = 0x01
	ar0 = 0x00
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_patch_e_10000_15 + 2)
	mov	dpxl,#((_cobs_patch_e_10000_15 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_patch_e_10000_15 + 1)
	mov	dpxl,#((_cobs_patch_e_10000_15 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_patch_e_10000_15
	mov	dpxl,#(_cobs_patch_e_10000_15 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:9: if (e->code_pos < e->len) e->buf[e->code_pos] = e->code;
	mov	dptr,#(_cobs_patch_e_10000_15 + 2)
	mov	dpxl,#((_cobs_patch_e_10000_15 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_patch_e_10000_15 + 1)
	mov	dpxl,#((_cobs_patch_e_10000_15 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_patch_e_10000_15
	mov	dpxl,#(_cobs_patch_e_10000_15 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	a,#0x07
	add	a,r7
	mov	r3,a
	clr	a
	addc	a,r6
	mov	r4,a
	clr	a
	addc	a,r5
	mov	r2,a
	mov	dpl,r3
	mov	dph,r4
	mov	dpxl,r2
	mov	dr28,dpx
	ecall	__gptrget
	mov	r2,a
	inc	dpx
	ecall	__gptrget
	mov	r3,a
	mov	a,#0x05
	add	a,r7
	mov	r4,a
	clr	a
	addc	a,r6
	mov	r1,a
	clr	a
	addc	a,r5
	mov	r0,a
	mov	dpl,r4
	mov	dph,r1
	mov	dpxl,r0
	mov	dr28,dpx
	ecall	__gptrget
	mov	r1,a
	inc	dpx
	ecall	__gptrget
	mov	r4,a
	clr	c
	mov	a,r3
	subb	a,r4
	mov	a,r2
	subb	a,r1
	jc	00112$
	ejmp	00103$
00112$:
	mov	ar4,r7
	mov	ar1,r6
	mov	ar0,r5
	mov	dpl,r4
	mov	dph,r1
	mov	dpxl,r0
	mov	dr28,dpx
	ecall	__gptrget
	mov	r0,a
	inc	dpx
	ecall	__gptrget
	mov	r1,a
	inc	dpx
	ecall	__gptrget
	add	a,r3
	mov	r4,a
	mov	a,r2
	addc	a,r1
	mov	r1,a
	clr	a
	addc	a,r0
	mov	r0,a
	mov	a,#0x09
	add	a,r7
	mov	r7,a
	clr	a
	addc	a,r6
	mov	r6,a
	clr	a
	addc	a,r5
	mov	r5,a
	mov	dpl,r7
	mov	dph,r6
	mov	dpxl,r5
	mov	dr28,dpx
	ecall	__gptrget
	mov	r7,a
	mov	dpl,r4
	mov	dph,r1
	mov	dpxl,r0
	mov	dr28,dpx
	mov	a,r7
	ecall	__gptrput
00103$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:10: }
	eret
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_begin_block'
;------------------------------------------------------------
;code          Allocated with name '_cobs_begin_block_PARM_2'
;e             Allocated with name '_cobs_begin_block_e_10000_18'
;sloc0         Allocated with name '_cobs_begin_block_sloc0_1_0'
;sloc1         Allocated with name '_cobs_begin_block_sloc1_1_0'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:12: static void cobs_begin_block(cobs_enc_t *e, unsigned char code) {
;	-----------------------------------------
;	 function cobs_begin_block
;	-----------------------------------------
_cobs_begin_block:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_begin_block_e_10000_18 + 2)
	mov	dpxl,#((_cobs_begin_block_e_10000_18 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_begin_block_e_10000_18 + 1)
	mov	dpxl,#((_cobs_begin_block_e_10000_18 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_begin_block_e_10000_18
	mov	dpxl,#(_cobs_begin_block_e_10000_18 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:13: if (e->len >= e->cap) {
	mov	dptr,#(_cobs_begin_block_e_10000_18 + 2)
	mov	dpxl,#((_cobs_begin_block_e_10000_18 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_begin_block_e_10000_18 + 1)
	mov	dpxl,#((_cobs_begin_block_e_10000_18 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_begin_block_e_10000_18
	mov	dpxl,#(_cobs_begin_block_e_10000_18 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	a,#0x05
	add	a,r7
	mov	dptr,#(_cobs_begin_block_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_begin_block_sloc1_1_0 + 2) >> 16)
	mov	@dpx,a
	clr	a
	addc	a,r6
	mov	dptr,#(_cobs_begin_block_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_begin_block_sloc1_1_0 + 1) >> 16)
	mov	@dpx,a
	clr	a
	addc	a,r5
	mov	dptr,#_cobs_begin_block_sloc1_1_0
	mov	dpxl,#(_cobs_begin_block_sloc1_1_0 >> 16)
	mov	@dpx,a
	mov	dptr,#(_cobs_begin_block_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_begin_block_sloc1_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_begin_block_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_begin_block_sloc1_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_begin_block_sloc1_1_0
	mov	dpxl,#(_cobs_begin_block_sloc1_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	ecall	__gptrget
	mov	r14,a
	inc	dpx
	ecall	__gptrget
	mov	r15,a
	mov	a,#0x03
	add	a,r7
	mov	r4,a
	clr	a
	addc	a,r6
	mov	r1,a
	clr	a
	addc	a,r5
	mov	r0,a
	mov	dpl,r4
	mov	dph,r1
	mov	dpxl,r0
	mov	dr28,dpx
	ecall	__gptrget
	mov	r1,a
	inc	dpx
	ecall	__gptrget
	mov	r4,a
	clr	c
	mov	a,r15
	subb	a,r4
	mov	a,r14
	subb	a,r1
	jnc	00112$
	ejmp	00102$
00112$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:14: e->overflow = 1;
	mov	a,#0x0b
	add	a,r7
	mov	r4,a
	clr	a
	addc	a,r6
	mov	r3,a
	clr	a
	addc	a,r5
	mov	r2,a
	mov	dpl,r4
	mov	dph,r3
	mov	dpxl,r2
	mov	dr28,dpx
	mov	a,#0x01
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:15: return;
	ejmp	00103$
00102$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:17: e->code_pos = e->len;
	mov	a,#0x07
	add	a,r7
	mov	r4,a
	clr	a
	addc	a,r6
	mov	r3,a
	clr	a
	addc	a,r5
	mov	r2,a
	mov	dpl,r4
	mov	dph,r3
	mov	dpxl,r2
	mov	dr28,dpx
	mov	a,r14
	ecall	__gptrput
	inc	dpx
	mov	a,r15
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:18: e->buf[e->len] = 0; /* 长度码占位 */
	mov	ar4,r7
	mov	ar3,r6
	mov	ar2,r5
	mov	dpl,r4
	mov	dph,r3
	mov	dpxl,r2
	mov	dr28,dpx
	ecall	__gptrget
	mov	r2,a
	inc	dpx
	ecall	__gptrget
	mov	r3,a
	inc	dpx
	ecall	__gptrget
	mov	r4,a
	mov	dptr,#(_cobs_begin_block_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_begin_block_sloc1_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_begin_block_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_begin_block_sloc1_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_begin_block_sloc1_1_0
	mov	dpxl,#(_cobs_begin_block_sloc1_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	ecall	__gptrget
	mov	r14,a
	inc	dpx
	ecall	__gptrget
	add	a,r4
	mov	r4,a
	mov	a,r14
	addc	a,r3
	mov	r3,a
	clr	a
	addc	a,r2
	mov	r2,a
	mov	dpl,r4
	mov	dph,r3
	mov	dpxl,r2
	mov	dr28,dpx
	clr	a
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:19: e->len++;
	mov	dptr,#(_cobs_begin_block_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_begin_block_sloc1_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_begin_block_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_begin_block_sloc1_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_begin_block_sloc1_1_0
	mov	dpxl,#(_cobs_begin_block_sloc1_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	ecall	__gptrget
	mov	r3,a
	inc	dpx
	ecall	__gptrget
	mov	r2,a
	inc	r2
	cjne	r2,#0x00,00113$
	inc	r3
00113$:
	mov	dptr,#(_cobs_begin_block_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_begin_block_sloc1_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_begin_block_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_begin_block_sloc1_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_begin_block_sloc1_1_0
	mov	dpxl,#(_cobs_begin_block_sloc1_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	mov	a,r3
	ecall	__gptrput
	inc	dpx
	mov	a,r2
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:20: e->code = code;
	mov	a,#0x09
	add	a,r7
	mov	r7,a
	clr	a
	addc	a,r6
	mov	r6,a
	clr	a
	addc	a,r5
	mov	r5,a
	mov	dptr,#_cobs_begin_block_PARM_2
	mov	dpxl,#(_cobs_begin_block_PARM_2 >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	dpl,r7
	mov	dph,r6
	mov	dpxl,r5
	mov	dr28,dpx
	mov	a,r4
	ecall	__gptrput
00103$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:21: }
	eret
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_init'
;------------------------------------------------------------
;buf           Allocated with name '_cobs_init_PARM_2'
;cap           Allocated with name '_cobs_init_PARM_3'
;e             Allocated with name '_cobs_init_e_10000_22'
;sloc0         Allocated with name '_cobs_init_sloc0_1_0'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:23: void cobs_init(cobs_enc_t *e, unsigned char *buf, unsigned int cap) {
;	-----------------------------------------
;	 function cobs_init
;	-----------------------------------------
_cobs_init:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_init_e_10000_22 + 2)
	mov	dpxl,#((_cobs_init_e_10000_22 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_init_e_10000_22 + 1)
	mov	dpxl,#((_cobs_init_e_10000_22 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_init_e_10000_22
	mov	dpxl,#(_cobs_init_e_10000_22 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:24: e->buf = buf;
	mov	dptr,#(_cobs_init_e_10000_22 + 2)
	mov	dpxl,#((_cobs_init_e_10000_22 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_init_e_10000_22 + 1)
	mov	dpxl,#((_cobs_init_e_10000_22 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_init_e_10000_22
	mov	dpxl,#(_cobs_init_e_10000_22 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	a,r7
	mov	dptr,#(_cobs_init_sloc0_1_0 + 2)
	mov	dpxl,#((_cobs_init_sloc0_1_0 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_init_sloc0_1_0 + 1)
	mov	dpxl,#((_cobs_init_sloc0_1_0 + 1) >> 16)
	mov	@dpx,a
	mov	a,r5
	mov	dptr,#_cobs_init_sloc0_1_0
	mov	dpxl,#(_cobs_init_sloc0_1_0 >> 16)
	mov	@dpx,a
	mov	dptr,#(_cobs_init_PARM_2 + 2)
	mov	dpxl,#((_cobs_init_PARM_2 + 2) >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	dptr,#(_cobs_init_PARM_2 + 1)
	mov	dpxl,#((_cobs_init_PARM_2 + 1) >> 16)
	mov	a,@dpx
	mov	r1,a
	mov	dptr,#_cobs_init_PARM_2
	mov	dpxl,#(_cobs_init_PARM_2 >> 16)
	mov	a,@dpx
	mov	r0,a
	mov	dptr,#(_cobs_init_sloc0_1_0 + 2)
	mov	dpxl,#((_cobs_init_sloc0_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_init_sloc0_1_0 + 1)
	mov	dpxl,#((_cobs_init_sloc0_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_init_sloc0_1_0
	mov	dpxl,#(_cobs_init_sloc0_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	mov	a,r0
	ecall	__gptrput
	inc	dpx
	mov	a,r1
	ecall	__gptrput
	inc	dpx
	mov	a,r4
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:25: e->cap = cap;
	mov	a,#0x03
	add	a,r7
	mov	r4,a
	clr	a
	addc	a,r6
	mov	r3,a
	clr	a
	addc	a,r5
	mov	r2,a
	mov	dptr,#(_cobs_init_PARM_3 + 1)
	mov	dpxl,#((_cobs_init_PARM_3 + 1) >> 16)
	mov	a,@dpx
	mov	r15,a
	mov	dptr,#_cobs_init_PARM_3
	mov	dpxl,#(_cobs_init_PARM_3 >> 16)
	mov	a,@dpx
	mov	r14,a
	mov	dpl,r4
	mov	dph,r3
	mov	dpxl,r2
	mov	dr28,dpx
	mov	a,r14
	ecall	__gptrput
	inc	dpx
	mov	a,r15
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:26: cobs_reset(e);
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:27: }
	ejmp	_cobs_reset
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_reset'
;------------------------------------------------------------
;e             Allocated with name '_cobs_reset_e_10000_24'
;sloc0         Allocated with name '_cobs_reset_sloc0_1_0'
;sloc1         Allocated with name '_cobs_reset_sloc1_1_0'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:29: void cobs_reset(cobs_enc_t *e) {
;	-----------------------------------------
;	 function cobs_reset
;	-----------------------------------------
_cobs_reset:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_reset_e_10000_24 + 2)
	mov	dpxl,#((_cobs_reset_e_10000_24 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_reset_e_10000_24 + 1)
	mov	dpxl,#((_cobs_reset_e_10000_24 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_reset_e_10000_24
	mov	dpxl,#(_cobs_reset_e_10000_24 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:30: e->len = 0;
	mov	dptr,#(_cobs_reset_e_10000_24 + 2)
	mov	dpxl,#((_cobs_reset_e_10000_24 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_reset_e_10000_24 + 1)
	mov	dpxl,#((_cobs_reset_e_10000_24 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_reset_e_10000_24
	mov	dpxl,#(_cobs_reset_e_10000_24 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	a,#0x05
	add	a,r7
	mov	dptr,#(_cobs_reset_sloc0_1_0 + 2)
	mov	dpxl,#((_cobs_reset_sloc0_1_0 + 2) >> 16)
	mov	@dpx,a
	clr	a
	addc	a,r6
	mov	dptr,#(_cobs_reset_sloc0_1_0 + 1)
	mov	dpxl,#((_cobs_reset_sloc0_1_0 + 1) >> 16)
	mov	@dpx,a
	clr	a
	addc	a,r5
	mov	dptr,#_cobs_reset_sloc0_1_0
	mov	dpxl,#(_cobs_reset_sloc0_1_0 >> 16)
	mov	@dpx,a
	mov	dptr,#(_cobs_reset_sloc0_1_0 + 2)
	mov	dpxl,#((_cobs_reset_sloc0_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_reset_sloc0_1_0 + 1)
	mov	dpxl,#((_cobs_reset_sloc0_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_reset_sloc0_1_0
	mov	dpxl,#(_cobs_reset_sloc0_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	clr	a
	ecall	__gptrput
	inc	dpx
	clr	a
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:31: e->code = 1;
	mov	a,#0x09
	add	a,r7
	mov	r4,a
	clr	a
	addc	a,r6
	mov	r1,a
	clr	a
	addc	a,r5
	mov	r0,a
	mov	dpl,r4
	mov	dph,r1
	mov	dpxl,r0
	mov	dr28,dpx
	mov	a,#0x01
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:32: e->code_pos = 0;
	mov	a,#0x07
	add	a,r7
	mov	r4,a
	clr	a
	addc	a,r6
	mov	r3,a
	clr	a
	addc	a,r5
	mov	r2,a
	mov	dpl,r4
	mov	dph,r3
	mov	dpxl,r2
	mov	dr28,dpx
	clr	a
	ecall	__gptrput
	inc	dpx
	clr	a
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:33: e->ck = 0;
	mov	a,#0x0a
	add	a,r7
	mov	r4,a
	clr	a
	addc	a,r6
	mov	r3,a
	clr	a
	addc	a,r5
	mov	r2,a
	mov	dpl,r4
	mov	dph,r3
	mov	dpxl,r2
	mov	dr28,dpx
	clr	a
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:34: e->overflow = 0;
	mov	a,#0x0b
	add	a,r7
	mov	dptr,#(_cobs_reset_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_reset_sloc1_1_0 + 2) >> 16)
	mov	@dpx,a
	clr	a
	addc	a,r6
	mov	dptr,#(_cobs_reset_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_reset_sloc1_1_0 + 1) >> 16)
	mov	@dpx,a
	clr	a
	addc	a,r5
	mov	dptr,#_cobs_reset_sloc1_1_0
	mov	dpxl,#(_cobs_reset_sloc1_1_0 >> 16)
	mov	@dpx,a
	mov	dptr,#(_cobs_reset_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_reset_sloc1_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_reset_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_reset_sloc1_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_reset_sloc1_1_0
	mov	dpxl,#(_cobs_reset_sloc1_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	clr	a
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:35: if (e->cap == 0) {
	mov	a,#0x03
	add	a,r7
	mov	r4,a
	clr	a
	addc	a,r6
	mov	r1,a
	clr	a
	addc	a,r5
	mov	r0,a
	mov	dpl,r4
	mov	dph,r1
	mov	dpxl,r0
	mov	dr28,dpx
	ecall	__gptrget
	mov	r1,a
	inc	dpx
	ecall	__gptrget
	orl	a,r1
	jz	00112$
	ejmp	00102$
00112$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:36: e->overflow = 1;
	mov	dptr,#(_cobs_reset_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_reset_sloc1_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_reset_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_reset_sloc1_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_reset_sloc1_1_0
	mov	dpxl,#(_cobs_reset_sloc1_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	mov	a,#0x01
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:37: return;
	ejmp	00103$
00102$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:39: e->buf[0] = 0; /* 首个块长度码占位 */
	mov	dpl,r7
	mov	dph,r6
	mov	dpxl,r5
	mov	dr28,dpx
	ecall	__gptrget
	mov	r5,a
	inc	dpx
	ecall	__gptrget
	mov	r6,a
	inc	dpx
	ecall	__gptrget
	mov	dpl,a
	mov	dph,r6
	mov	dpxl,r5
	mov	dr28,dpx
	clr	a
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:40: e->len = 1;
	mov	dptr,#(_cobs_reset_sloc0_1_0 + 2)
	mov	dpxl,#((_cobs_reset_sloc0_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_reset_sloc0_1_0 + 1)
	mov	dpxl,#((_cobs_reset_sloc0_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_reset_sloc0_1_0
	mov	dpxl,#(_cobs_reset_sloc0_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	clr	a
	ecall	__gptrput
	inc	dpx
	mov	a,#0x01
	ecall	__gptrput
00103$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:41: }
	eret
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_putc'
;------------------------------------------------------------
;b             Allocated with name '_cobs_putc_PARM_2'
;e             Allocated with name '_cobs_putc_e_10000_28'
;sloc0         Allocated with name '_cobs_putc_sloc0_1_0'
;sloc1         Allocated with name '_cobs_putc_sloc1_1_0'
;sloc2         Allocated with name '_cobs_putc_sloc2_1_0'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:43: void cobs_putc(cobs_enc_t *e, unsigned char b) {
;	-----------------------------------------
;	 function cobs_putc
;	-----------------------------------------
_cobs_putc:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_putc_e_10000_28 + 2)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_putc_e_10000_28 + 1)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_putc_e_10000_28
	mov	dpxl,#(_cobs_putc_e_10000_28 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:44: if (b == 0) {
	mov	dptr,#_cobs_putc_PARM_2
	mov	dpxl,#(_cobs_putc_PARM_2 >> 16)
	mov	a,@dpx
	mov	r13,a
	mov	dptr,#_cobs_putc_PARM_2
	mov	dpxl,#(_cobs_putc_PARM_2 >> 16)
	mov	a,@dpx
	jz	00130$
	ejmp	00102$
00130$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:45: cobs_patch(e);
	mov	dptr,#(_cobs_putc_e_10000_28 + 2)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 2) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#(_cobs_putc_e_10000_28 + 1)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 1) >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#_cobs_putc_e_10000_28
	mov	dpxl,#(_cobs_putc_e_10000_28 >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	dpl, r6
	mov	dph, r5
	mov	b, r4
	ecall	_cobs_patch
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:46: cobs_begin_block(e, 1);
	mov	dptr,#(_cobs_putc_e_10000_28 + 2)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 2) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#(_cobs_putc_e_10000_28 + 1)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 1) >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#_cobs_putc_e_10000_28
	mov	dpxl,#(_cobs_putc_e_10000_28 >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	a,#0x01
	mov	dptr,#_cobs_begin_block_PARM_2
	mov	dpxl,#(_cobs_begin_block_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r6
	mov	dph, r5
	mov	b, r4
	ecall	_cobs_begin_block
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:47: return;
	ejmp	00107$
00102$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:49: if (e->code == 255) {
	mov	dptr,#(_cobs_putc_e_10000_28 + 2)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 2) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#(_cobs_putc_e_10000_28 + 1)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 1) >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#_cobs_putc_e_10000_28
	mov	dpxl,#(_cobs_putc_e_10000_28 >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	a,#0x09
	add	a,r6
	mov	r3,a
	clr	a
	addc	a,r5
	mov	r2,a
	clr	a
	addc	a,r4
	mov	r1,a
	mov	dpl,r3
	mov	dph,r2
	mov	dpxl,r1
	mov	dr28,dpx
	ecall	__gptrget
	mov	r3,a
	cjne	r3,#0xff,00131$
	sjmp	00132$
00131$:
	ejmp	00104$
00132$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:50: cobs_patch(e);
	mov	dpl, r6
	mov	dph, r5
	mov	b, r4
	push	ar6
	push	ar5
	push	ar4
	push	r13
	ecall	_cobs_patch
	pop	r13
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:51: cobs_begin_block(e, 1);
	mov	dptr,#(_cobs_putc_e_10000_28 + 2)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 2) >> 16)
	mov	a,@dpx
	mov	r3,a
	mov	dptr,#(_cobs_putc_e_10000_28 + 1)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 1) >> 16)
	mov	a,@dpx
	mov	r2,a
	mov	dptr,#_cobs_putc_e_10000_28
	mov	dpxl,#(_cobs_putc_e_10000_28 >> 16)
	mov	a,@dpx
	mov	r1,a
	mov	a,#0x01
	mov	dptr,#_cobs_begin_block_PARM_2
	mov	dpxl,#(_cobs_begin_block_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r3
	mov	dph, r2
	mov	b, r1
	push	r13
	ecall	_cobs_begin_block
	pop	r13
	pop	ar4
	pop	ar5
	pop	ar6
00104$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:53: if (e->len >= e->cap) {
	mov	a,#0x05
	add	a,r6
	mov	r3,a
	clr	a
	addc	a,r5
	mov	r2,a
	clr	a
	addc	a,r4
	mov	r1,a
	mov	dpl,r3
	mov	dph,r2
	mov	dpxl,r1
	mov	dr28,dpx
	ecall	__gptrget
	mov	r2,a
	inc	dpx
	ecall	__gptrget
	mov	r3,a
	mov	a,#0x03
	add	a,r6
	mov	r6,a
	clr	a
	addc	a,r5
	mov	r5,a
	clr	a
	addc	a,r4
	mov	r4,a
	mov	dpl,r6
	mov	dph,r5
	mov	dpxl,r4
	mov	dr28,dpx
	ecall	__gptrget
	mov	r5,a
	inc	dpx
	ecall	__gptrget
	mov	r6,a
	clr	c
	mov	a,r3
	subb	a,r6
	mov	a,r2
	subb	a,r5
	jnc	00133$
	ejmp	00106$
00133$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:54: e->overflow = 1;
	mov	dptr,#(_cobs_putc_e_10000_28 + 2)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 2) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#(_cobs_putc_e_10000_28 + 1)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 1) >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#_cobs_putc_e_10000_28
	mov	dpxl,#(_cobs_putc_e_10000_28 >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	a,#0x0b
	add	a,r6
	mov	r6,a
	clr	a
	addc	a,r5
	mov	r5,a
	clr	a
	addc	a,r4
	mov	r4,a
	mov	dpl,r6
	mov	dph,r5
	mov	dpxl,r4
	mov	dr28,dpx
	mov	a,#0x01
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:55: return;
	ejmp	00107$
00106$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:57: e->buf[e->len] = b;
	mov	dptr,#(_cobs_putc_e_10000_28 + 2)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 2) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#(_cobs_putc_e_10000_28 + 1)
	mov	dpxl,#((_cobs_putc_e_10000_28 + 1) >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#_cobs_putc_e_10000_28
	mov	dpxl,#(_cobs_putc_e_10000_28 >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	ar3,r6
	mov	ar2,r5
	mov	ar1,r4
	mov	dpl,r3
	mov	dph,r2
	mov	dpxl,r1
	mov	dr28,dpx
	mov	dptr,#_cobs_putc_sloc1_1_0
	mov	dpxl,#(_cobs_putc_sloc1_1_0 >> 16)
	mov	dr24,dpx
	mov	dpx,dr28
	ecall	__gptrget
	mov	@dr24,a
	inc	dpx
	inc	dr24
	ecall	__gptrget
	mov	@dr24,a
	inc	dpx
	inc	dr24
	ecall	__gptrget
	mov	@dr24,a
	mov	a,#0x05
	add	a,r6
	mov	dptr,#(_cobs_putc_sloc2_1_0 + 2)
	mov	dpxl,#((_cobs_putc_sloc2_1_0 + 2) >> 16)
	mov	@dpx,a
	clr	a
	addc	a,r5
	mov	dptr,#(_cobs_putc_sloc2_1_0 + 1)
	mov	dpxl,#((_cobs_putc_sloc2_1_0 + 1) >> 16)
	mov	@dpx,a
	clr	a
	addc	a,r4
	mov	dptr,#_cobs_putc_sloc2_1_0
	mov	dpxl,#(_cobs_putc_sloc2_1_0 >> 16)
	mov	@dpx,a
	mov	dptr,#(_cobs_putc_sloc2_1_0 + 2)
	mov	dpxl,#((_cobs_putc_sloc2_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_putc_sloc2_1_0 + 1)
	mov	dpxl,#((_cobs_putc_sloc2_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_putc_sloc2_1_0
	mov	dpxl,#(_cobs_putc_sloc2_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	ecall	__gptrget
	mov	r14,a
	inc	dpx
	ecall	__gptrget
	mov	r15,a
	mov	dptr,#(_cobs_putc_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_putc_sloc1_1_0 + 2) >> 16)
	mov	a,@dpx
	mov	b,r15
	add	a,b
	mov	r7,a
	mov	dptr,#(_cobs_putc_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_putc_sloc1_1_0 + 1) >> 16)
	mov	a,@dpx
	mov	b,r14
	addc	a,b
	mov	r2,a
	mov	dptr,#_cobs_putc_sloc1_1_0
	mov	dpxl,#(_cobs_putc_sloc1_1_0 >> 16)
	mov	a,@dpx
	addc	a,#0x00
	mov	r1,a
	mov	dpl,r7
	mov	dph,r2
	mov	dpxl,r1
	mov	dr28,dpx
	mov	a,r13
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:58: e->len++;
	mov	dptr,#(_cobs_putc_sloc2_1_0 + 2)
	mov	dpxl,#((_cobs_putc_sloc2_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_putc_sloc2_1_0 + 1)
	mov	dpxl,#((_cobs_putc_sloc2_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_putc_sloc2_1_0
	mov	dpxl,#(_cobs_putc_sloc2_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	ecall	__gptrget
	mov	r3,a
	inc	dpx
	ecall	__gptrget
	mov	r2,a
	inc	r2
	cjne	r2,#0x00,00134$
	inc	r3
00134$:
	mov	dptr,#(_cobs_putc_sloc2_1_0 + 2)
	mov	dpxl,#((_cobs_putc_sloc2_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_putc_sloc2_1_0 + 1)
	mov	dpxl,#((_cobs_putc_sloc2_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_putc_sloc2_1_0
	mov	dpxl,#(_cobs_putc_sloc2_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	mov	a,r3
	ecall	__gptrput
	inc	dpx
	mov	a,r2
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:59: e->code++;
	mov	a,#0x09
	add	a,r6
	mov	r6,a
	clr	a
	addc	a,r5
	mov	r5,a
	clr	a
	addc	a,r4
	mov	r4,a
	mov	dpl,r6
	mov	dph,r5
	mov	dpxl,r4
	mov	dr28,dpx
	ecall	__gptrget
	mov	r7,a
	inc	r7
	mov	dpl,r6
	mov	dph,r5
	mov	dpxl,r4
	mov	dr28,dpx
	mov	a,r7
	ecall	__gptrput
00107$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:60: }
	eret
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_finish'
;------------------------------------------------------------
;e             Allocated with name '_cobs_finish_e_10000_36'
;sloc0         Allocated with name '_cobs_finish_sloc0_1_0'
;sloc1         Allocated with name '_cobs_finish_sloc1_1_0'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:62: unsigned int cobs_finish(cobs_enc_t *e) {
;	-----------------------------------------
;	 function cobs_finish
;	-----------------------------------------
_cobs_finish:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_finish_e_10000_36 + 2)
	mov	dpxl,#((_cobs_finish_e_10000_36 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_finish_e_10000_36 + 1)
	mov	dpxl,#((_cobs_finish_e_10000_36 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_finish_e_10000_36
	mov	dpxl,#(_cobs_finish_e_10000_36 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:63: cobs_patch(e);
	mov	dptr,#(_cobs_finish_e_10000_36 + 2)
	mov	dpxl,#((_cobs_finish_e_10000_36 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_finish_e_10000_36 + 1)
	mov	dpxl,#((_cobs_finish_e_10000_36 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_finish_e_10000_36
	mov	dpxl,#(_cobs_finish_e_10000_36 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
	ecall	_cobs_patch
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:64: if (e->len >= e->cap) {
	mov	dptr,#(_cobs_finish_e_10000_36 + 2)
	mov	dpxl,#((_cobs_finish_e_10000_36 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_finish_e_10000_36 + 1)
	mov	dpxl,#((_cobs_finish_e_10000_36 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_finish_e_10000_36
	mov	dpxl,#(_cobs_finish_e_10000_36 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	a,#0x05
	add	a,r7
	mov	dptr,#(_cobs_finish_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_finish_sloc1_1_0 + 2) >> 16)
	mov	@dpx,a
	clr	a
	addc	a,r6
	mov	dptr,#(_cobs_finish_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_finish_sloc1_1_0 + 1) >> 16)
	mov	@dpx,a
	clr	a
	addc	a,r5
	mov	dptr,#_cobs_finish_sloc1_1_0
	mov	dpxl,#(_cobs_finish_sloc1_1_0 >> 16)
	mov	@dpx,a
	mov	dptr,#(_cobs_finish_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_finish_sloc1_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_finish_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_finish_sloc1_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_finish_sloc1_1_0
	mov	dpxl,#(_cobs_finish_sloc1_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	ecall	__gptrget
	mov	r14,a
	inc	dpx
	ecall	__gptrget
	mov	r15,a
	mov	a,#0x03
	add	a,r7
	mov	r4,a
	clr	a
	addc	a,r6
	mov	r1,a
	clr	a
	addc	a,r5
	mov	r0,a
	mov	dpl,r4
	mov	dph,r1
	mov	dpxl,r0
	mov	dr28,dpx
	ecall	__gptrget
	mov	r1,a
	inc	dpx
	ecall	__gptrget
	mov	r4,a
	clr	c
	mov	a,r15
	subb	a,r4
	mov	a,r14
	subb	a,r1
	jnc	00121$
	ejmp	00102$
00121$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:65: e->overflow = 1;
	mov	a,#0x0b
	add	a,r7
	mov	r4,a
	clr	a
	addc	a,r6
	mov	r3,a
	clr	a
	addc	a,r5
	mov	r2,a
	mov	dpl,r4
	mov	dph,r3
	mov	dpxl,r2
	mov	dr28,dpx
	mov	a,#0x01
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:66: return 0;
	mov	dptr,#0x0000
	ejmp	00103$
00102$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:68: e->buf[e->len] = 0x00; /* 帧定界 */
	mov	ar4,r7
	mov	ar3,r6
	mov	ar2,r5
	mov	dpl,r4
	mov	dph,r3
	mov	dpxl,r2
	mov	dr28,dpx
	ecall	__gptrget
	mov	r2,a
	inc	dpx
	ecall	__gptrget
	mov	r3,a
	inc	dpx
	ecall	__gptrget
	add	a,r15
	mov	r4,a
	mov	a,r14
	addc	a,r3
	mov	r3,a
	clr	a
	addc	a,r2
	mov	r2,a
	mov	dpl,r4
	mov	dph,r3
	mov	dpxl,r2
	mov	dr28,dpx
	clr	a
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:69: e->len++;
	mov	dptr,#(_cobs_finish_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_finish_sloc1_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_finish_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_finish_sloc1_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_finish_sloc1_1_0
	mov	dpxl,#(_cobs_finish_sloc1_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	ecall	__gptrget
	mov	r3,a
	inc	dpx
	ecall	__gptrget
	mov	r2,a
	inc	r2
	cjne	r2,#0x00,00122$
	inc	r3
00122$:
	mov	dptr,#(_cobs_finish_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_finish_sloc1_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_finish_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_finish_sloc1_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_finish_sloc1_1_0
	mov	dpxl,#(_cobs_finish_sloc1_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	mov	a,r3
	ecall	__gptrput
	inc	dpx
	mov	a,r2
	ecall	__gptrput
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:70: return e->overflow ? 0 : e->len;
	mov	a,#0x0b
	add	a,r7
	mov	r7,a
	clr	a
	addc	a,r6
	mov	r6,a
	clr	a
	addc	a,r5
	mov	r5,a
	mov	dpl,r7
	mov	dph,r6
	mov	dpxl,r5
	mov	dr28,dpx
	ecall	__gptrget
	jnz	00123$
	ejmp	00105$
00123$:
	mov	r7,#0x00
	mov	r6,#0x00
	ejmp	00106$
00105$:
	mov	dptr,#(_cobs_finish_sloc1_1_0 + 2)
	mov	dpxl,#((_cobs_finish_sloc1_1_0 + 2) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#(_cobs_finish_sloc1_1_0 + 1)
	mov	dpxl,#((_cobs_finish_sloc1_1_0 + 1) >> 16)
	mov	a,@dpx
	push	acc
	mov	dptr,#_cobs_finish_sloc1_1_0
	mov	dpxl,#(_cobs_finish_sloc1_1_0 >> 16)
	mov	a,@dpx
	push	acc
	pop	dpxl
	pop	dph
	pop	dpl
	mov	dr28,dpx
	ecall	__gptrget
	mov	r6,a
	inc	dpx
	ecall	__gptrget
	mov	r7,a
00106$:
	mov	dpl, r7
	mov	dph, r6
00103$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:71: }
	eret
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_encode'
;------------------------------------------------------------
;in_len        Allocated with name '_cobs_encode_PARM_2'
;out           Allocated with name '_cobs_encode_PARM_3'
;out_cap       Allocated with name '_cobs_encode_PARM_4'
;in            Allocated with name '_cobs_encode_in_10000_40'
;e             Allocated with name '_cobs_encode_e_10000_41'
;i             Allocated with name '_cobs_encode_i_10000_41'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:73: unsigned int cobs_encode(const unsigned char *in, unsigned int in_len,
;	-----------------------------------------
;	 function cobs_encode
;	-----------------------------------------
_cobs_encode:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_encode_in_10000_40 + 2)
	mov	dpxl,#((_cobs_encode_in_10000_40 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_encode_in_10000_40 + 1)
	mov	dpxl,#((_cobs_encode_in_10000_40 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_encode_in_10000_40
	mov	dpxl,#(_cobs_encode_in_10000_40 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:77: cobs_init(&e, out, out_cap);
	mov	dptr,#(_cobs_encode_PARM_3 + 2)
	mov	dpxl,#((_cobs_encode_PARM_3 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_encode_PARM_3 + 1)
	mov	dpxl,#((_cobs_encode_PARM_3 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_encode_PARM_3
	mov	dpxl,#(_cobs_encode_PARM_3 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#(_cobs_encode_PARM_4 + 1)
	mov	dpxl,#((_cobs_encode_PARM_4 + 1) >> 16)
	mov	a,@dpx
	mov	r3,a
	mov	dptr,#_cobs_encode_PARM_4
	mov	dpxl,#(_cobs_encode_PARM_4 >> 16)
	mov	a,@dpx
	mov	r2,a
	mov	a,r7
	mov	dptr,#(_cobs_init_PARM_2 + 2)
	mov	dpxl,#((_cobs_init_PARM_2 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_init_PARM_2 + 1)
	mov	dpxl,#((_cobs_init_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,r5
	mov	dptr,#_cobs_init_PARM_2
	mov	dpxl,#(_cobs_init_PARM_2 >> 16)
	mov	@dpx,a
	mov	a,r3
	mov	dptr,#(_cobs_init_PARM_3 + 1)
	mov	dpxl,#((_cobs_init_PARM_3 + 1) >> 16)
	mov	@dpx,a
	mov	a,r2
	mov	dptr,#_cobs_init_PARM_3
	mov	dpxl,#(_cobs_init_PARM_3 >> 16)
	mov	@dpx,a
	mov	dptr,#_cobs_encode_e_10000_41
	mov	b, #(_cobs_encode_e_10000_41 >> 16)
	ecall	_cobs_init
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:78: for (i = 0; i < in_len; i++) cobs_putc(&e, in[i]);
	mov	dptr,#(_cobs_encode_in_10000_40 + 2)
	mov	dpxl,#((_cobs_encode_in_10000_40 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_encode_in_10000_40 + 1)
	mov	dpxl,#((_cobs_encode_in_10000_40 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_encode_in_10000_40
	mov	dpxl,#(_cobs_encode_in_10000_40 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#(_cobs_encode_PARM_2 + 1)
	mov	dpxl,#((_cobs_encode_PARM_2 + 1) >> 16)
	mov	a,@dpx
	mov	r3,a
	mov	dptr,#_cobs_encode_PARM_2
	mov	dpxl,#(_cobs_encode_PARM_2 >> 16)
	mov	a,@dpx
	mov	r2,a
	mov	r15,#0x00
	mov	r14,#0x00
00103$:
	clr	c
	mov	a,r15
	subb	a,r3
	mov	a,r14
	subb	a,r2
	jc	00122$
	ejmp	00101$
00122$:
	mov	a,r15
	add	a,r7
	mov	r4,a
	mov	a,r14
	addc	a,r6
	mov	r1,a
	clr	a
	addc	a,r5
	mov	r0,a
	mov	dpl,r4
	mov	dph,r1
	mov	dpxl,r0
	mov	dr28,dpx
	ecall	__gptrget
	mov	dptr,#_cobs_putc_PARM_2
	mov	dpxl,#(_cobs_putc_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_cobs_encode_e_10000_41
	mov	b, #(_cobs_encode_e_10000_41 >> 16)
	push	ar7
	push	ar6
	push	ar5
	push	ar3
	push	ar2
	push	r15
	push	r14
	ecall	_cobs_putc
	pop	r14
	pop	r15
	pop	ar2
	pop	ar3
	pop	ar5
	pop	ar6
	pop	ar7
	inc	r15
	mov	a,r15
	cjne	a,#0x00,00123$
	inc	r14
00123$:
	ejmp	00103$
00101$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:79: return cobs_finish(&e);
	mov	dptr,#_cobs_encode_e_10000_41
	mov	b, #(_cobs_encode_e_10000_41 >> 16)
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:80: }
	ejmp	_cobs_finish
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_log_begin'
;------------------------------------------------------------
;id            Allocated with name '_cobs_log_begin_PARM_2'
;e             Allocated with name '_cobs_log_begin_e_10000_43'
;il            Allocated with name '_cobs_log_begin_il_10000_44'
;ih            Allocated with name '_cobs_log_begin_ih_10000_44'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:84: void cobs_log_begin(cobs_enc_t *e, unsigned int id) {
;	-----------------------------------------
;	 function cobs_log_begin
;	-----------------------------------------
_cobs_log_begin:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_log_begin_e_10000_43 + 2)
	mov	dpxl,#((_cobs_log_begin_e_10000_43 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_log_begin_e_10000_43 + 1)
	mov	dpxl,#((_cobs_log_begin_e_10000_43 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_log_begin_e_10000_43
	mov	dpxl,#(_cobs_log_begin_e_10000_43 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:85: unsigned char il = (unsigned char)(id & 0xff);
	mov	dptr,#(_cobs_log_begin_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_begin_PARM_2 + 1) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#_cobs_log_begin_PARM_2
	mov	dpxl,#(_cobs_log_begin_PARM_2 >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	ar5,r7
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:86: unsigned char ih = (unsigned char)((id >> 8) & 0xff);
	mov	ar7,r6
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:87: cobs_reset(e);
	mov	dptr,#(_cobs_log_begin_e_10000_43 + 2)
	mov	dpxl,#((_cobs_log_begin_e_10000_43 + 2) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#(_cobs_log_begin_e_10000_43 + 1)
	mov	dpxl,#((_cobs_log_begin_e_10000_43 + 1) >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	dptr,#_cobs_log_begin_e_10000_43
	mov	dpxl,#(_cobs_log_begin_e_10000_43 >> 16)
	mov	a,@dpx
	mov	r3,a
	mov	dpl, r6
	mov	dph, r4
	mov	b, r3
	push	ar7
	push	ar5
	ecall	_cobs_reset
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:88: cobs_putc(e, 0x7e);
	mov	dptr,#(_cobs_log_begin_e_10000_43 + 2)
	mov	dpxl,#((_cobs_log_begin_e_10000_43 + 2) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#(_cobs_log_begin_e_10000_43 + 1)
	mov	dpxl,#((_cobs_log_begin_e_10000_43 + 1) >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	dptr,#_cobs_log_begin_e_10000_43
	mov	dpxl,#(_cobs_log_begin_e_10000_43 >> 16)
	mov	a,@dpx
	mov	r3,a
	mov	a,#0x7e
	mov	dptr,#_cobs_putc_PARM_2
	mov	dpxl,#(_cobs_putc_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r6
	mov	dph, r4
	mov	b, r3
	ecall	_cobs_putc
	pop	ar5
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:89: cobs_putc(e, il);
	mov	dptr,#(_cobs_log_begin_e_10000_43 + 2)
	mov	dpxl,#((_cobs_log_begin_e_10000_43 + 2) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#(_cobs_log_begin_e_10000_43 + 1)
	mov	dpxl,#((_cobs_log_begin_e_10000_43 + 1) >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	dptr,#_cobs_log_begin_e_10000_43
	mov	dpxl,#(_cobs_log_begin_e_10000_43 >> 16)
	mov	a,@dpx
	mov	r3,a
	mov	a,r5
	mov	dptr,#_cobs_putc_PARM_2
	mov	dpxl,#(_cobs_putc_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r6
	mov	dph, r4
	mov	b, r3
	push	ar5
	ecall	_cobs_putc
	pop	ar5
	pop	ar7
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:90: cobs_putc(e, ih);
	mov	dptr,#(_cobs_log_begin_e_10000_43 + 2)
	mov	dpxl,#((_cobs_log_begin_e_10000_43 + 2) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#(_cobs_log_begin_e_10000_43 + 1)
	mov	dpxl,#((_cobs_log_begin_e_10000_43 + 1) >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	dptr,#_cobs_log_begin_e_10000_43
	mov	dpxl,#(_cobs_log_begin_e_10000_43 >> 16)
	mov	a,@dpx
	mov	r3,a
	mov	a,r7
	mov	dptr,#_cobs_putc_PARM_2
	mov	dpxl,#(_cobs_putc_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r6
	mov	dph, r4
	mov	b, r3
	push	ar7
	push	ar5
	ecall	_cobs_putc
	pop	ar5
	pop	ar7
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:91: e->ck = il ^ ih;
	mov	dptr,#(_cobs_log_begin_e_10000_43 + 2)
	mov	dpxl,#((_cobs_log_begin_e_10000_43 + 2) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#(_cobs_log_begin_e_10000_43 + 1)
	mov	dpxl,#((_cobs_log_begin_e_10000_43 + 1) >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	dptr,#_cobs_log_begin_e_10000_43
	mov	dpxl,#(_cobs_log_begin_e_10000_43 >> 16)
	mov	a,@dpx
	mov	r3,a
	mov	a,#0x0a
	add	a,r6
	mov	r6,a
	clr	a
	addc	a,r4
	mov	r4,a
	clr	a
	addc	a,r3
	mov	r3,a
	mov	a,r5
	xrl	ar7,a
	mov	dpl,r6
	mov	dph,r4
	mov	dpxl,r3
	mov	dr28,dpx
	mov	a,r7
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:92: }
	ejmp	__gptrput
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_log_raw'
;------------------------------------------------------------
;b             Allocated with name '_cobs_log_raw_PARM_2'
;e             Allocated with name '_cobs_log_raw_e_10000_45'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:94: void cobs_log_raw(cobs_enc_t *e, unsigned char b) {
;	-----------------------------------------
;	 function cobs_log_raw
;	-----------------------------------------
_cobs_log_raw:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_log_raw_e_10000_45 + 2)
	mov	dpxl,#((_cobs_log_raw_e_10000_45 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_log_raw_e_10000_45 + 1)
	mov	dpxl,#((_cobs_log_raw_e_10000_45 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_log_raw_e_10000_45
	mov	dpxl,#(_cobs_log_raw_e_10000_45 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:95: cobs_putc(e, b);
	mov	dptr,#(_cobs_log_raw_e_10000_45 + 2)
	mov	dpxl,#((_cobs_log_raw_e_10000_45 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_raw_e_10000_45 + 1)
	mov	dpxl,#((_cobs_log_raw_e_10000_45 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_raw_e_10000_45
	mov	dpxl,#(_cobs_log_raw_e_10000_45 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	dptr,#_cobs_putc_PARM_2
	mov	dpxl,#(_cobs_putc_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
	push	ar4
	ecall	_cobs_putc
	pop	ar4
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:96: e->ck ^= b;
	mov	dptr,#(_cobs_log_raw_e_10000_45 + 2)
	mov	dpxl,#((_cobs_log_raw_e_10000_45 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_raw_e_10000_45 + 1)
	mov	dpxl,#((_cobs_log_raw_e_10000_45 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_raw_e_10000_45
	mov	dpxl,#(_cobs_log_raw_e_10000_45 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	a,#0x0a
	add	a,r7
	mov	r7,a
	clr	a
	addc	a,r6
	mov	r6,a
	clr	a
	addc	a,r5
	mov	r5,a
	mov	dpl,r7
	mov	dph,r6
	mov	dpxl,r5
	mov	dr28,dpx
	ecall	__gptrget
	xrl	ar4,a
	mov	dpl,r7
	mov	dph,r6
	mov	dpxl,r5
	mov	dr28,dpx
	mov	a,r4
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:97: }
	ejmp	__gptrput
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_log_u8'
;------------------------------------------------------------
;v             Allocated with name '_cobs_log_u8_PARM_2'
;e             Allocated with name '_cobs_log_u8_e_10000_47'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:99: void cobs_log_u8(cobs_enc_t *e, unsigned char v) {
;	-----------------------------------------
;	 function cobs_log_u8
;	-----------------------------------------
_cobs_log_u8:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_log_u8_e_10000_47 + 2)
	mov	dpxl,#((_cobs_log_u8_e_10000_47 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_log_u8_e_10000_47 + 1)
	mov	dpxl,#((_cobs_log_u8_e_10000_47 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_log_u8_e_10000_47
	mov	dpxl,#(_cobs_log_u8_e_10000_47 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:100: cobs_log_raw(e, v);
	mov	dptr,#(_cobs_log_u8_e_10000_47 + 2)
	mov	dpxl,#((_cobs_log_u8_e_10000_47 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_u8_e_10000_47 + 1)
	mov	dpxl,#((_cobs_log_u8_e_10000_47 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_u8_e_10000_47
	mov	dpxl,#(_cobs_log_u8_e_10000_47 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#_cobs_log_u8_PARM_2
	mov	dpxl,#(_cobs_log_u8_PARM_2 >> 16)
	mov	a,@dpx
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:101: }
	ejmp	_cobs_log_raw
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_log_u16'
;------------------------------------------------------------
;v             Allocated with name '_cobs_log_u16_PARM_2'
;e             Allocated with name '_cobs_log_u16_e_10000_49'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:103: void cobs_log_u16(cobs_enc_t *e, unsigned int v) {
;	-----------------------------------------
;	 function cobs_log_u16
;	-----------------------------------------
_cobs_log_u16:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_log_u16_e_10000_49 + 2)
	mov	dpxl,#((_cobs_log_u16_e_10000_49 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_log_u16_e_10000_49 + 1)
	mov	dpxl,#((_cobs_log_u16_e_10000_49 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_log_u16_e_10000_49
	mov	dpxl,#(_cobs_log_u16_e_10000_49 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:104: cobs_log_raw(e, (unsigned char)(v & 0xff));
	mov	dptr,#(_cobs_log_u16_e_10000_49 + 2)
	mov	dpxl,#((_cobs_log_u16_e_10000_49 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_u16_e_10000_49 + 1)
	mov	dpxl,#((_cobs_log_u16_e_10000_49 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_u16_e_10000_49
	mov	dpxl,#(_cobs_log_u16_e_10000_49 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#(_cobs_log_u16_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_u16_PARM_2 + 1) >> 16)
	mov	a,@dpx
	mov	r3,a
	mov	dptr,#_cobs_log_u16_PARM_2
	mov	dpxl,#(_cobs_log_u16_PARM_2 >> 16)
	mov	a,@dpx
	mov	r2,a
	mov	a,r3
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
	push	ar3
	push	ar2
	ecall	_cobs_log_raw
	pop	ar2
	pop	ar3
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:105: cobs_log_raw(e, (unsigned char)((v >> 8) & 0xff));
	mov	dptr,#(_cobs_log_u16_e_10000_49 + 2)
	mov	dpxl,#((_cobs_log_u16_e_10000_49 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_u16_e_10000_49 + 1)
	mov	dpxl,#((_cobs_log_u16_e_10000_49 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_u16_e_10000_49
	mov	dpxl,#(_cobs_log_u16_e_10000_49 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	a,r2
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:106: }
	ejmp	_cobs_log_raw
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_log_u32'
;------------------------------------------------------------
;v             Allocated with name '_cobs_log_u32_PARM_2'
;e             Allocated with name '_cobs_log_u32_e_10000_51'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:108: void cobs_log_u32(cobs_enc_t *e, unsigned long v) {
;	-----------------------------------------
;	 function cobs_log_u32
;	-----------------------------------------
_cobs_log_u32:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_log_u32_e_10000_51 + 2)
	mov	dpxl,#((_cobs_log_u32_e_10000_51 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_log_u32_e_10000_51 + 1)
	mov	dpxl,#((_cobs_log_u32_e_10000_51 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_log_u32_e_10000_51
	mov	dpxl,#(_cobs_log_u32_e_10000_51 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:109: cobs_log_raw(e, (unsigned char)(v & 0xff));
	mov	dptr,#(_cobs_log_u32_e_10000_51 + 2)
	mov	dpxl,#((_cobs_log_u32_e_10000_51 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_u32_e_10000_51 + 1)
	mov	dpxl,#((_cobs_log_u32_e_10000_51 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_u32_e_10000_51
	mov	dpxl,#(_cobs_log_u32_e_10000_51 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#(_cobs_log_u32_PARM_2 + 3)
	mov	dpxl,#((_cobs_log_u32_PARM_2 + 3) >> 16)
	mov	a,@dpx
	mov	r15,a
	mov	dptr,#(_cobs_log_u32_PARM_2 + 2)
	mov	dpxl,#((_cobs_log_u32_PARM_2 + 2) >> 16)
	mov	a,@dpx
	mov	r14,a
	mov	dptr,#(_cobs_log_u32_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_u32_PARM_2 + 1) >> 16)
	mov	a,@dpx
	mov	r13,a
	mov	dptr,#_cobs_log_u32_PARM_2
	mov	dpxl,#(_cobs_log_u32_PARM_2 >> 16)
	mov	a,@dpx
	mov	r12,a
	mov	a,r15
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
	push	r15
	push	r14
	push	r13
	push	r12
	ecall	_cobs_log_raw
	pop	r12
	pop	r13
	pop	r14
	pop	r15
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:110: cobs_log_raw(e, (unsigned char)((v >> 8) & 0xff));
	mov	dptr,#(_cobs_log_u32_e_10000_51 + 2)
	mov	dpxl,#((_cobs_log_u32_e_10000_51 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_u32_e_10000_51 + 1)
	mov	dpxl,#((_cobs_log_u32_e_10000_51 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_u32_e_10000_51
	mov	dpxl,#(_cobs_log_u32_e_10000_51 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	a,r14
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
	push	r15
	push	r14
	push	r13
	push	r12
	ecall	_cobs_log_raw
	pop	r12
	pop	r13
	pop	r14
	pop	r15
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:111: cobs_log_raw(e, (unsigned char)((v >> 16) & 0xff));
	mov	dptr,#(_cobs_log_u32_e_10000_51 + 2)
	mov	dpxl,#((_cobs_log_u32_e_10000_51 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_u32_e_10000_51 + 1)
	mov	dpxl,#((_cobs_log_u32_e_10000_51 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_u32_e_10000_51
	mov	dpxl,#(_cobs_log_u32_e_10000_51 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	a,r13
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
	push	r15
	push	r14
	push	r13
	push	r12
	ecall	_cobs_log_raw
	pop	r12
	pop	r13
	pop	r14
	pop	r15
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:112: cobs_log_raw(e, (unsigned char)((v >> 24) & 0xff));
	mov	dptr,#(_cobs_log_u32_e_10000_51 + 2)
	mov	dpxl,#((_cobs_log_u32_e_10000_51 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_u32_e_10000_51 + 1)
	mov	dpxl,#((_cobs_log_u32_e_10000_51 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_u32_e_10000_51
	mov	dpxl,#(_cobs_log_u32_e_10000_51 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	a,r12
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:113: }
	ejmp	_cobs_log_raw
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_log_var'
;------------------------------------------------------------
;v             Allocated with name '_cobs_log_var_PARM_2'
;e             Allocated with name '_cobs_log_var_e_10000_53'
;b             Allocated with name '_cobs_log_var_b_30000_56'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:115: void cobs_log_var(cobs_enc_t *e, unsigned int v) {
;	-----------------------------------------
;	 function cobs_log_var
;	-----------------------------------------
_cobs_log_var:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_log_var_e_10000_53 + 2)
	mov	dpxl,#((_cobs_log_var_e_10000_53 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_log_var_e_10000_53 + 1)
	mov	dpxl,#((_cobs_log_var_e_10000_53 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_log_var_e_10000_53
	mov	dpxl,#(_cobs_log_var_e_10000_53 >> 16)
	mov	@dpx,a
00105$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:117: unsigned char b = (unsigned char)(v & 0x7f);
	mov	dptr,#(_cobs_log_var_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_var_PARM_2 + 1) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#_cobs_log_var_PARM_2
	mov	dpxl,#(_cobs_log_var_PARM_2 >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	ar5,r7
	mov	a,#0x7f
	anl	a,r5
	mov	dptr,#_cobs_log_var_b_30000_56
	mov	dpxl,#(_cobs_log_var_b_30000_56 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:118: v >>= 7;
	mov	a,r6
	mov	c,acc.7
	xch	a,r7
	rlc	a
	xch	a,r7
	rlc	a
	xch	a,r7
	anl	a,#0x01
	mov	r6,a
	mov	a,r7
	mov	dptr,#(_cobs_log_var_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_var_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#_cobs_log_var_PARM_2
	mov	dpxl,#(_cobs_log_var_PARM_2 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:119: if (v != 0) {
	mov	dptr,#(_cobs_log_var_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_var_PARM_2 + 1) >> 16)
	mov	a,@dpx
	mov	b,a
	mov	dptr,#_cobs_log_var_PARM_2
	mov	dpxl,#(_cobs_log_var_PARM_2 >> 16)
	mov	a,@dpx
	orl	a,b
	jnz	00123$
	ejmp	00102$
00123$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:120: cobs_log_raw(e, (unsigned char)(b | 0x80));
	mov	dptr,#(_cobs_log_var_e_10000_53 + 2)
	mov	dpxl,#((_cobs_log_var_e_10000_53 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_var_e_10000_53 + 1)
	mov	dpxl,#((_cobs_log_var_e_10000_53 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_var_e_10000_53
	mov	dpxl,#(_cobs_log_var_e_10000_53 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#_cobs_log_var_b_30000_56
	mov	dpxl,#(_cobs_log_var_b_30000_56 >> 16)
	mov	a,@dpx
	orl	a,#0x80
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
	ecall	_cobs_log_raw
	ejmp	00105$
00102$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:122: cobs_log_raw(e, b);
	mov	dptr,#(_cobs_log_var_e_10000_53 + 2)
	mov	dpxl,#((_cobs_log_var_e_10000_53 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_var_e_10000_53 + 1)
	mov	dpxl,#((_cobs_log_var_e_10000_53 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_var_e_10000_53
	mov	dpxl,#(_cobs_log_var_e_10000_53 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#_cobs_log_var_b_30000_56
	mov	dpxl,#(_cobs_log_var_b_30000_56 >> 16)
	mov	a,@dpx
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:123: return;
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:126: }
	ejmp	_cobs_log_raw
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_log_bytes'
;------------------------------------------------------------
;p             Allocated with name '_cobs_log_bytes_PARM_2'
;n             Allocated with name '_cobs_log_bytes_PARM_3'
;e             Allocated with name '_cobs_log_bytes_e_10000_60'
;i             Allocated with name '_cobs_log_bytes_i_10000_61'
;sloc0         Allocated with name '_cobs_log_bytes_sloc0_1_0'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:128: void cobs_log_bytes(cobs_enc_t *e, const unsigned char *p, unsigned int n) {
;	-----------------------------------------
;	 function cobs_log_bytes
;	-----------------------------------------
_cobs_log_bytes:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_log_bytes_e_10000_60 + 2)
	mov	dpxl,#((_cobs_log_bytes_e_10000_60 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_log_bytes_e_10000_60 + 1)
	mov	dpxl,#((_cobs_log_bytes_e_10000_60 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_log_bytes_e_10000_60
	mov	dpxl,#(_cobs_log_bytes_e_10000_60 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:130: cobs_log_var(e, n);
	mov	dptr,#(_cobs_log_bytes_e_10000_60 + 2)
	mov	dpxl,#((_cobs_log_bytes_e_10000_60 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_bytes_e_10000_60 + 1)
	mov	dpxl,#((_cobs_log_bytes_e_10000_60 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_bytes_e_10000_60
	mov	dpxl,#(_cobs_log_bytes_e_10000_60 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#(_cobs_log_bytes_PARM_3 + 1)
	mov	dpxl,#((_cobs_log_bytes_PARM_3 + 1) >> 16)
	mov	a,@dpx
	mov	r3,a
	mov	dptr,#_cobs_log_bytes_PARM_3
	mov	dpxl,#(_cobs_log_bytes_PARM_3 >> 16)
	mov	a,@dpx
	mov	r2,a
	mov	a,r3
	mov	dptr,#(_cobs_log_var_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_var_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,r2
	mov	dptr,#_cobs_log_var_PARM_2
	mov	dpxl,#(_cobs_log_var_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
	push	ar3
	push	ar2
	ecall	_cobs_log_var
	pop	ar2
	pop	ar3
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:131: for (i = 0; i < n; i++) cobs_log_raw(e, p[i]);
	mov	dptr,#(_cobs_log_bytes_PARM_2 + 2)
	mov	dpxl,#((_cobs_log_bytes_PARM_2 + 2) >> 16)
	mov	a,@dpx
	mov	dptr,#(_cobs_log_bytes_sloc0_1_0 + 2)
	mov	dpxl,#((_cobs_log_bytes_sloc0_1_0 + 2) >> 16)
	mov	@dpx,a
	mov	dptr,#(_cobs_log_bytes_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_bytes_PARM_2 + 1) >> 16)
	mov	a,@dpx
	mov	dptr,#(_cobs_log_bytes_sloc0_1_0 + 1)
	mov	dpxl,#((_cobs_log_bytes_sloc0_1_0 + 1) >> 16)
	mov	@dpx,a
	mov	dptr,#_cobs_log_bytes_PARM_2
	mov	dpxl,#(_cobs_log_bytes_PARM_2 >> 16)
	mov	a,@dpx
	mov	dptr,#_cobs_log_bytes_sloc0_1_0
	mov	dpxl,#(_cobs_log_bytes_sloc0_1_0 >> 16)
	mov	@dpx,a
	mov	r15,#0x00
	mov	r14,#0x00
00103$:
	clr	c
	mov	a,r15
	subb	a,r3
	mov	a,r14
	subb	a,r2
	jc	00122$
	ejmp	00105$
00122$:
	push	ar3
	push	ar2
	mov	dptr,#(_cobs_log_bytes_e_10000_60 + 2)
	mov	dpxl,#((_cobs_log_bytes_e_10000_60 + 2) >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	dptr,#(_cobs_log_bytes_e_10000_60 + 1)
	mov	dpxl,#((_cobs_log_bytes_e_10000_60 + 1) >> 16)
	mov	a,@dpx
	mov	r1,a
	mov	dptr,#_cobs_log_bytes_e_10000_60
	mov	dpxl,#(_cobs_log_bytes_e_10000_60 >> 16)
	mov	a,@dpx
	mov	r0,a
	mov	dptr,#(_cobs_log_bytes_sloc0_1_0 + 2)
	mov	dpxl,#((_cobs_log_bytes_sloc0_1_0 + 2) >> 16)
	mov	a,@dpx
	mov	b,r15
	add	a,b
	mov	r7,a
	mov	dptr,#(_cobs_log_bytes_sloc0_1_0 + 1)
	mov	dpxl,#((_cobs_log_bytes_sloc0_1_0 + 1) >> 16)
	mov	a,@dpx
	mov	b,r14
	addc	a,b
	mov	r3,a
	mov	dptr,#_cobs_log_bytes_sloc0_1_0
	mov	dpxl,#(_cobs_log_bytes_sloc0_1_0 >> 16)
	mov	a,@dpx
	addc	a,#0x00
	mov	r2,a
	mov	dpl,r7
	mov	dph,r3
	mov	dpxl,r2
	mov	dr28,dpx
	ecall	__gptrget
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r4
	mov	dph, r1
	mov	b, r0
	push	ar3
	push	ar2
	push	r15
	push	r14
	ecall	_cobs_log_raw
	pop	r14
	pop	r15
	pop	ar2
	pop	ar3
	inc	r15
	mov	a,r15
	cjne	a,#0x00,00123$
	inc	r14
00123$:
	pop	ar2
	pop	ar3
	ejmp	00103$
00105$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:132: }
	eret
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_log_str'
;------------------------------------------------------------
;s             Allocated with name '_cobs_log_str_PARM_2'
;e             Allocated with name '_cobs_log_str_e_10000_63'
;n             Allocated with name '_cobs_log_str_n_10000_64'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:134: void cobs_log_str(cobs_enc_t *e, const char *s) {
;	-----------------------------------------
;	 function cobs_log_str
;	-----------------------------------------
_cobs_log_str:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_log_str_e_10000_63 + 2)
	mov	dpxl,#((_cobs_log_str_e_10000_63 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_log_str_e_10000_63 + 1)
	mov	dpxl,#((_cobs_log_str_e_10000_63 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_log_str_e_10000_63
	mov	dpxl,#(_cobs_log_str_e_10000_63 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:136: while (s[n] != '\0') n++;
	mov	dptr,#(_cobs_log_str_PARM_2 + 2)
	mov	dpxl,#((_cobs_log_str_PARM_2 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_str_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_str_PARM_2 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_str_PARM_2
	mov	dpxl,#(_cobs_log_str_PARM_2 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	r3,#0x00
	mov	r2,#0x00
00101$:
	mov	a,r3
	add	a,r7
	mov	r4,a
	mov	a,r2
	addc	a,r6
	mov	r1,a
	clr	a
	addc	a,r5
	mov	r0,a
	mov	dpl,r4
	mov	dph,r1
	mov	dpxl,r0
	mov	dr28,dpx
	ecall	__gptrget
	jnz	00139$
	ejmp	00103$
00139$:
	inc	r3
	cjne	r3,#0x00,00140$
	inc	r2
00140$:
	ejmp	00101$
00103$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:137: cobs_log_var(e, n);
	mov	dptr,#(_cobs_log_str_e_10000_63 + 2)
	mov	dpxl,#((_cobs_log_str_e_10000_63 + 2) >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	dptr,#(_cobs_log_str_e_10000_63 + 1)
	mov	dpxl,#((_cobs_log_str_e_10000_63 + 1) >> 16)
	mov	a,@dpx
	mov	r1,a
	mov	dptr,#_cobs_log_str_e_10000_63
	mov	dpxl,#(_cobs_log_str_e_10000_63 >> 16)
	mov	a,@dpx
	mov	r0,a
	mov	a,r3
	mov	dptr,#(_cobs_log_var_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_var_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,r2
	mov	dptr,#_cobs_log_var_PARM_2
	mov	dpxl,#(_cobs_log_var_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r4
	mov	dph, r1
	mov	b, r0
	push	ar7
	push	ar6
	push	ar5
	ecall	_cobs_log_var
	pop	ar5
	pop	ar6
	pop	ar7
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:138: while (*s != '\0') cobs_log_raw(e, (unsigned char)*s++);
00104$:
	mov	dpl,r7
	mov	dph,r6
	mov	dpxl,r5
	mov	dr28,dpx
	ecall	__gptrget
	mov	r4,a
	jnz	00141$
	ejmp	00107$
00141$:
	mov	dptr,#(_cobs_log_str_e_10000_63 + 2)
	mov	dpxl,#((_cobs_log_str_e_10000_63 + 2) >> 16)
	mov	a,@dpx
	mov	r3,a
	mov	dptr,#(_cobs_log_str_e_10000_63 + 1)
	mov	dpxl,#((_cobs_log_str_e_10000_63 + 1) >> 16)
	mov	a,@dpx
	mov	r2,a
	mov	dptr,#_cobs_log_str_e_10000_63
	mov	dpxl,#(_cobs_log_str_e_10000_63 >> 16)
	mov	a,@dpx
	mov	r1,a
	mov	a,r4
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	@dpx,a
	inc	r7
	cjne	r7,#0x00,00142$
	inc	r6
	cjne	r6,#0x00,00142$
	inc	r5
00142$:
	mov	dpl, r3
	mov	dph, r2
	mov	b, r1
	push	ar7
	push	ar6
	push	ar5
	ecall	_cobs_log_raw
	pop	ar5
	pop	ar6
	pop	ar7
	ejmp	00104$
00107$:
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:139: }
	eret
;------------------------------------------------------------
;Allocation info for local variables in function 'cobs_log_end'
;------------------------------------------------------------
;e             Allocated with name '_cobs_log_end_e_10000_65'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:141: unsigned int cobs_log_end(cobs_enc_t *e) {
;	-----------------------------------------
;	 function cobs_log_end
;	-----------------------------------------
_cobs_log_end:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_cobs_log_end_e_10000_65 + 2)
	mov	dpxl,#((_cobs_log_end_e_10000_65 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_cobs_log_end_e_10000_65 + 1)
	mov	dpxl,#((_cobs_log_end_e_10000_65 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_cobs_log_end_e_10000_65
	mov	dpxl,#(_cobs_log_end_e_10000_65 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:142: cobs_log_raw(e, e->ck);
	mov	dptr,#(_cobs_log_end_e_10000_65 + 2)
	mov	dpxl,#((_cobs_log_end_e_10000_65 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_end_e_10000_65 + 1)
	mov	dpxl,#((_cobs_log_end_e_10000_65 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_end_e_10000_65
	mov	dpxl,#(_cobs_log_end_e_10000_65 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	a,#0x0a
	add	a,r7
	mov	r4,a
	clr	a
	addc	a,r6
	mov	r3,a
	clr	a
	addc	a,r5
	mov	r2,a
	mov	dpl,r4
	mov	dph,r3
	mov	dpxl,r2
	mov	dr28,dpx
	ecall	__gptrget
	mov	dptr,#_cobs_log_raw_PARM_2
	mov	dpxl,#(_cobs_log_raw_PARM_2 >> 16)
	mov	@dpx,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
	ecall	_cobs_log_raw
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:143: return cobs_finish(e);
	mov	dptr,#(_cobs_log_end_e_10000_65 + 2)
	mov	dpxl,#((_cobs_log_end_e_10000_65 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_cobs_log_end_e_10000_65 + 1)
	mov	dpxl,#((_cobs_log_end_e_10000_65 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_cobs_log_end_e_10000_65
	mov	dpxl,#(_cobs_log_end_e_10000_65 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dpl, r7
	mov	dph, r6
	mov	b, r5
;	E:\code\yuyan\mcs251\lib\cobs\cobs.c:144: }
	ejmp	_cobs_finish
	.area CSEG    (CODE)
	.area CONST   (CODE)
	.area XINIT   (CODE)
	.area CABS    (ABS,CODE)
