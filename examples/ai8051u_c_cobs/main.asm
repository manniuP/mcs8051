;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.6.0 #0 (MINGW64)
;--------------------------------------------------------
	.module main
	
	.optsdcc -mmcs251 --model-large
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _cobs_log_end
	.globl _cobs_log_str
	.globl _cobs_log_var
	.globl _cobs_log_u16
	.globl _cobs_log_u8
	.globl _cobs_log_begin
	.globl _cobs_init
	.globl _delay_ms
	.globl _uart_putc
	.globl _uart_init
	.globl _P77
	.globl _P76
	.globl _P75
	.globl _P74
	.globl _P73
	.globl _P72
	.globl _P71
	.globl _P70
	.globl _B7
	.globl _B6
	.globl _B5
	.globl _B4
	.globl _B3
	.globl _B2
	.globl _B1
	.globl _B0
	.globl _P67
	.globl _P66
	.globl _P65
	.globl _P64
	.globl _P63
	.globl _P62
	.globl _P61
	.globl _P60
	.globl _P
	.globl _F1
	.globl _OV
	.globl _RS0
	.globl _RS1
	.globl _F0
	.globl _AC
	.globl _CY
	.globl _P57
	.globl _P56
	.globl _P55
	.globl _P54
	.globl _P53
	.globl _P52
	.globl _P51
	.globl _P50
	.globl _P47
	.globl _P46
	.globl _P45
	.globl _P44
	.globl _P43
	.globl _P42
	.globl _P41
	.globl _P40
	.globl _PX0
	.globl _PT0
	.globl _PX1
	.globl _PT1
	.globl _PS
	.globl _PADC
	.globl _PLVD
	.globl _PPCA
	.globl _RXD
	.globl _TXD
	.globl _INT0
	.globl _INT1
	.globl _T0
	.globl _T1
	.globl _WR
	.globl _RD
	.globl _P37
	.globl _P36
	.globl _P35
	.globl _P34
	.globl _P33
	.globl _P32
	.globl _P31
	.globl _P30
	.globl _EX0
	.globl _ET0
	.globl _EX1
	.globl _ET1
	.globl _ES
	.globl _EADC
	.globl _ELVD
	.globl _EA
	.globl _P27
	.globl _P26
	.globl _P25
	.globl _P24
	.globl _P23
	.globl _P22
	.globl _P21
	.globl _P20
	.globl _RI
	.globl _TI
	.globl _RB8
	.globl _TB8
	.globl _REN
	.globl _SM2
	.globl _SM1
	.globl _SM0
	.globl _P17
	.globl _P16
	.globl _P15
	.globl _P14
	.globl _P13
	.globl _P12
	.globl _P11
	.globl _P10
	.globl _IT0
	.globl _IE0
	.globl _IT1
	.globl _IE1
	.globl _TR0
	.globl _TF0
	.globl _TR1
	.globl _TF1
	.globl _P07
	.globl _P06
	.globl _P05
	.globl _P04
	.globl _P03
	.globl _P02
	.globl _P01
	.globl _P00
	.globl _RSTCFG
	.globl _S4BUF
	.globl _S4CON
	.globl _USBADR
	.globl _P7
	.globl _IAP_ADDRE
	.globl _IAP_TPS
	.globl _USBCON
	.globl _B
	.globl _AUXINTIF
	.globl _IP3H
	.globl _DMAIR
	.globl _USBDAT
	.globl _MXAX
	.globl _CKCON
	.globl _WTST
	.globl _P6
	.globl _CMPCR2
	.globl _CMPCR1
	.globl _DPS
	.globl _P7M0
	.globl _P7M1
	.globl _ACC
	.globl _IP3
	.globl _ADCCFG
	.globl _T4T3M
	.globl _T3T4M
	.globl _USBCLK
	.globl _TL2
	.globl _TH2
	.globl _TL3
	.globl _TH3
	.globl _TL4
	.globl _TH4
	.globl _T2L
	.globl _T2H
	.globl _T3L
	.globl _T3H
	.globl _T4L
	.globl _T4H
	.globl _PSW1
	.globl _PSW
	.globl _SPDAT
	.globl _SPCTL
	.globl _SPSTAT
	.globl _P6M0
	.globl _P6M1
	.globl _P5M0
	.globl _P5M1
	.globl _P5
	.globl _IAP_CONTR
	.globl _IAP_TRIG
	.globl _IAP_CMD
	.globl _IAP_ADDRL
	.globl _IAP_ADDRH
	.globl _IAP_DATA
	.globl _WDT_CONTR
	.globl _P4
	.globl _P_SW4
	.globl _ADC_RESL
	.globl _ADC_RES
	.globl _ADC_CONTR
	.globl _P_SW3
	.globl _P_SW2
	.globl _SADEN
	.globl _IP
	.globl _IPH
	.globl _IP2H
	.globl _IP2
	.globl _P4M0
	.globl _P4M1
	.globl _P3M0
	.globl _P3M1
	.globl _P3
	.globl _IE2
	.globl _TA
	.globl _S3BUF
	.globl _S3CON
	.globl _WKTCH
	.globl _WKTCL
	.globl _SADDR
	.globl _IE
	.globl _VRTRIM
	.globl _P_SW1
	.globl _BUS_SPEED
	.globl _P2
	.globl _IRTRIM
	.globl _LIRTRIM
	.globl _IRCBAND
	.globl _S2BUF
	.globl _S2CON
	.globl _SBUF
	.globl _SCON
	.globl _AUXR2
	.globl _P2M0
	.globl _P2M1
	.globl _P0M0
	.globl _P0M1
	.globl _P1M0
	.globl _P1M1
	.globl _P1
	.globl _INTCLKO
	.globl _AUXR
	.globl _TH1
	.globl _TH0
	.globl _TL1
	.globl _TL0
	.globl _TMOD
	.globl _TCON
	.globl _PCON
	.globl _SPH
	.globl _DPXL
	.globl _DPH
	.globl _DPL
	.globl _SP
	.globl _P0
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
	.area RSEG    (ABS,DATA)
	.org 0x0000
_P0	=	0x0080
_SP	=	0x0081
_DPL	=	0x0082
_DPH	=	0x0083
_DPXL	=	0x0084
_SPH	=	0x0085
_PCON	=	0x0087
_TCON	=	0x0088
_TMOD	=	0x0089
_TL0	=	0x008a
_TL1	=	0x008b
_TH0	=	0x008c
_TH1	=	0x008d
_AUXR	=	0x008e
_INTCLKO	=	0x008f
_P1	=	0x0090
_P1M1	=	0x0091
_P1M0	=	0x0092
_P0M1	=	0x0093
_P0M0	=	0x0094
_P2M1	=	0x0095
_P2M0	=	0x0096
_AUXR2	=	0x0097
_SCON	=	0x0098
_SBUF	=	0x0099
_S2CON	=	0x009a
_S2BUF	=	0x009b
_IRCBAND	=	0x009d
_LIRTRIM	=	0x009e
_IRTRIM	=	0x009f
_P2	=	0x00a0
_BUS_SPEED	=	0x00a1
_P_SW1	=	0x00a2
_VRTRIM	=	0x00a6
_IE	=	0x00a8
_SADDR	=	0x00a9
_WKTCL	=	0x00aa
_WKTCH	=	0x00ab
_S3CON	=	0x00ac
_S3BUF	=	0x00ad
_TA	=	0x00ae
_IE2	=	0x00af
_P3	=	0x00b0
_P3M1	=	0x00b1
_P3M0	=	0x00b2
_P4M1	=	0x00b3
_P4M0	=	0x00b4
_IP2	=	0x00b5
_IP2H	=	0x00b6
_IPH	=	0x00b7
_IP	=	0x00b8
_SADEN	=	0x00b9
_P_SW2	=	0x00ba
_P_SW3	=	0x00bb
_ADC_CONTR	=	0x00bc
_ADC_RES	=	0x00bd
_ADC_RESL	=	0x00be
_P_SW4	=	0x00bf
_P4	=	0x00c0
_WDT_CONTR	=	0x00c1
_IAP_DATA	=	0x00c2
_IAP_ADDRH	=	0x00c3
_IAP_ADDRL	=	0x00c4
_IAP_CMD	=	0x00c5
_IAP_TRIG	=	0x00c6
_IAP_CONTR	=	0x00c7
_P5	=	0x00c8
_P5M1	=	0x00c9
_P5M0	=	0x00ca
_P6M1	=	0x00cb
_P6M0	=	0x00cc
_SPSTAT	=	0x00cd
_SPCTL	=	0x00ce
_SPDAT	=	0x00cf
_PSW	=	0x00d0
_PSW1	=	0x00d1
_T4H	=	0x00d2
_T4L	=	0x00d3
_T3H	=	0x00d4
_T3L	=	0x00d5
_T2H	=	0x00d6
_T2L	=	0x00d7
_TH4	=	0x00d2
_TL4	=	0x00d3
_TH3	=	0x00d4
_TL3	=	0x00d5
_TH2	=	0x00d6
_TL2	=	0x00d7
_USBCLK	=	0x00dc
_T3T4M	=	0x00dd
_T4T3M	=	0x00dd
_ADCCFG	=	0x00de
_IP3	=	0x00df
_ACC	=	0x00e0
_P7M1	=	0x00e1
_P7M0	=	0x00e2
_DPS	=	0x00e3
_CMPCR1	=	0x00e6
_CMPCR2	=	0x00e7
_P6	=	0x00e8
_WTST	=	0x00e9
_CKCON	=	0x00ea
_MXAX	=	0x00eb
_USBDAT	=	0x00ec
_DMAIR	=	0x00ed
_IP3H	=	0x00ee
_AUXINTIF	=	0x00ef
_B	=	0x00f0
_USBCON	=	0x00f4
_IAP_TPS	=	0x00f5
_IAP_ADDRE	=	0x00f6
_P7	=	0x00f8
_USBADR	=	0x00fc
_S4CON	=	0x00fd
_S4BUF	=	0x00fe
_RSTCFG	=	0x00ff
;--------------------------------------------------------
; special function bits
;--------------------------------------------------------
	.area RSEG    (ABS,DATA)
	.org 0x0000
_P00	=	0x0080
_P01	=	0x0081
_P02	=	0x0082
_P03	=	0x0083
_P04	=	0x0084
_P05	=	0x0085
_P06	=	0x0086
_P07	=	0x0087
_TF1	=	0x008f
_TR1	=	0x008e
_TF0	=	0x008d
_TR0	=	0x008c
_IE1	=	0x008b
_IT1	=	0x008a
_IE0	=	0x0089
_IT0	=	0x0088
_P10	=	0x0090
_P11	=	0x0091
_P12	=	0x0092
_P13	=	0x0093
_P14	=	0x0094
_P15	=	0x0095
_P16	=	0x0096
_P17	=	0x0097
_SM0	=	0x009f
_SM1	=	0x009e
_SM2	=	0x009d
_REN	=	0x009c
_TB8	=	0x009b
_RB8	=	0x009a
_TI	=	0x0099
_RI	=	0x0098
_P20	=	0x00a0
_P21	=	0x00a1
_P22	=	0x00a2
_P23	=	0x00a3
_P24	=	0x00a4
_P25	=	0x00a5
_P26	=	0x00a6
_P27	=	0x00a7
_EA	=	0x00af
_ELVD	=	0x00ae
_EADC	=	0x00ad
_ES	=	0x00ac
_ET1	=	0x00ab
_EX1	=	0x00aa
_ET0	=	0x00a9
_EX0	=	0x00a8
_P30	=	0x00b0
_P31	=	0x00b1
_P32	=	0x00b2
_P33	=	0x00b3
_P34	=	0x00b4
_P35	=	0x00b5
_P36	=	0x00b6
_P37	=	0x00b7
_RD	=	0x00b7
_WR	=	0x00b6
_T1	=	0x00b5
_T0	=	0x00b4
_INT1	=	0x00b3
_INT0	=	0x00b2
_TXD	=	0x00b1
_RXD	=	0x00b0
_PPCA	=	0x00bf
_PLVD	=	0x00be
_PADC	=	0x00bd
_PS	=	0x00bc
_PT1	=	0x00bb
_PX1	=	0x00ba
_PT0	=	0x00b9
_PX0	=	0x00b8
_P40	=	0x00c0
_P41	=	0x00c1
_P42	=	0x00c2
_P43	=	0x00c3
_P44	=	0x00c4
_P45	=	0x00c5
_P46	=	0x00c6
_P47	=	0x00c7
_P50	=	0x00c8
_P51	=	0x00c9
_P52	=	0x00ca
_P53	=	0x00cb
_P54	=	0x00cc
_P55	=	0x00cd
_P56	=	0x00ce
_P57	=	0x00cf
_CY	=	0x00d7
_AC	=	0x00d6
_F0	=	0x00d5
_RS1	=	0x00d4
_RS0	=	0x00d3
_OV	=	0x00d2
_F1	=	0x00d1
_P	=	0x00d0
_P60	=	0x00e8
_P61	=	0x00e9
_P62	=	0x00ea
_P63	=	0x00eb
_P64	=	0x00ec
_P65	=	0x00ed
_P66	=	0x00ee
_P67	=	0x00ef
_B0	=	0x00f0
_B1	=	0x00f1
_B2	=	0x00f2
_B3	=	0x00f3
_B4	=	0x00f4
_B5	=	0x00f5
_B6	=	0x00f6
_B7	=	0x00f7
_P70	=	0x00f8
_P71	=	0x00f9
_P72	=	0x00fa
_P73	=	0x00fb
_P74	=	0x00fc
_P75	=	0x00fd
_P76	=	0x00fe
_P77	=	0x00ff
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
; Stack segment in internal ram
;--------------------------------------------------------
	.area SSEG
__start__stack:
	.ds	1

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
_out_buf:
	.ds 128
_g16:
	.ds 2
_send_PARM_2:
	.ds 2
_send_p_10000_66:
	.ds 3
_main_e_10000_70:
	.ds 12
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
; interrupt vector
;--------------------------------------------------------
	.area HOME    (CODE)
__interrupt_vect:
	ljmp	__sdcc_mcs251_reset_trampoline
__sdcc_mcs251_reset_trampoline::
	ejmp	__sdcc_gsinit_startup
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area HOME    (CODE)
	.area GSINIT  (CODE)
	.area GSFINAL (CODE)
	.area GSINIT  (CODE)
	.globl __sdcc_gsinit_startup
	.globl __sdcc_program_startup
	.globl __start__stack
	.globl __mcs51_genXINIT
	.globl __mcs51_genXRAMCLEAR
	.globl __mcs51_genRAMCLEAR
	.area GSFINAL (CODE)
	ejmp	__sdcc_program_startup
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area HOME    (CODE)
	.area HOME    (CODE)
__sdcc_program_startup:
	ecall	_main
__sdcc_program_exit:
	sjmp	.
;	return from main will return to caller
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area CSEG    (CODE)
;------------------------------------------------------------
;Allocation info for local variables in function 'mcs_nop_impl'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\lib\include/mcs_intrins.h:12: static void mcs_nop_impl(void) { __asm NOP __endasm; }
;	-----------------------------------------
;	 function mcs_nop_impl
;	-----------------------------------------
_mcs_nop_impl:
	ar7 = 0x07
	ar6 = 0x06
	ar5 = 0x05
	ar4 = 0x04
	ar3 = 0x03
	ar2 = 0x02
	ar1 = 0x01
	ar0 = 0x00
	NOP	
	eret
;------------------------------------------------------------
;Allocation info for local variables in function 'send'
;------------------------------------------------------------
;n             Allocated with name '_send_PARM_2'
;p             Allocated with name '_send_p_10000_66'
;i             Allocated with name '_send_i_10000_67'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:20: static void send(const unsigned char *p, unsigned int n)
;	-----------------------------------------
;	 function send
;	-----------------------------------------
_send:
	mov	r7,b
	mov	r6,dph
	mov	a,dpl
	mov	dptr,#(_send_p_10000_66 + 2)
	mov	dpxl,#((_send_p_10000_66 + 2) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#(_send_p_10000_66 + 1)
	mov	dpxl,#((_send_p_10000_66 + 1) >> 16)
	mov	@dpx,a
	mov	a,r7
	mov	dptr,#_send_p_10000_66
	mov	dpxl,#(_send_p_10000_66 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:23: for (i = 0; i < n; i++) uart_putc(p[i]);
	mov	dptr,#(_send_p_10000_66 + 2)
	mov	dpxl,#((_send_p_10000_66 + 2) >> 16)
	mov	a,@dpx
	mov	r7,a
	mov	dptr,#(_send_p_10000_66 + 1)
	mov	dpxl,#((_send_p_10000_66 + 1) >> 16)
	mov	a,@dpx
	mov	r6,a
	mov	dptr,#_send_p_10000_66
	mov	dpxl,#(_send_p_10000_66 >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#(_send_PARM_2 + 1)
	mov	dpxl,#((_send_PARM_2 + 1) >> 16)
	mov	a,@dpx
	mov	r3,a
	mov	dptr,#_send_PARM_2
	mov	dpxl,#(_send_PARM_2 >> 16)
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
	ejmp	00105$
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
	mov	dpl,a
	push	ar7
	push	ar6
	push	ar5
	push	ar3
	push	ar2
	push	r15
	push	r14
	ecall	_uart_putc
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
00105$:
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:24: }
	eret
;------------------------------------------------------------
;Allocation info for local variables in function 'main'
;------------------------------------------------------------
;e             Allocated with name '_main_e_10000_70'
;n             Allocated with name '_main_n_10000_70'
;------------------------------------------------------------
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:26: void main(void)
;	-----------------------------------------
;	 function main
;	-----------------------------------------
_main:
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:31: WDT_CONTR = 0x00;                  /* 关看门狗 */
	mov	_WDT_CONTR,#0x00
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:32: uart_init();
	ecall	_uart_init
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:33: cobs_init(&e, out_buf, sizeof out_buf);
	mov	a,#_out_buf
	mov	dptr,#(_cobs_init_PARM_2 + 2)
	mov	dpxl,#((_cobs_init_PARM_2 + 2) >> 16)
	mov	@dpx,a
	mov	a,#(_out_buf >> 8)
	mov	dptr,#(_cobs_init_PARM_2 + 1)
	mov	dpxl,#((_cobs_init_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,#(_out_buf >> 16)
	mov	dptr,#_cobs_init_PARM_2
	mov	dpxl,#(_cobs_init_PARM_2 >> 16)
	mov	@dpx,a
	mov	a,#0x80
	mov	dptr,#(_cobs_init_PARM_3 + 1)
	mov	dpxl,#((_cobs_init_PARM_3 + 1) >> 16)
	mov	@dpx,a
	clr	a
	mov	dptr,#_cobs_init_PARM_3
	mov	dpxl,#(_cobs_init_PARM_3 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_init
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:35: while (1)
	mov	r7,#0x00
	mov	r6,#0x00
00102$:
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:37: cobs_log_begin(&e, 0x0001);
	mov	a,#0x01
	mov	dptr,#(_cobs_log_begin_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_begin_PARM_2 + 1) >> 16)
	mov	@dpx,a
	clr	a
	mov	dptr,#_cobs_log_begin_PARM_2
	mov	dpxl,#(_cobs_log_begin_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	push	ar7
	push	ar6
	ecall	_cobs_log_begin
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:38: send(out_buf, cobs_log_end(&e));               /* boot */
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_end
	mov	a, dpl
	mov	b, dph
	mov	dptr,#(_send_PARM_2 + 1)
	mov	dpxl,#((_send_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,b
	mov	dptr,#_send_PARM_2
	mov	dpxl,#(_send_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_out_buf
	mov	b, #(_out_buf >> 16)
	ecall	_send
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:40: cobs_log_begin(&e, 0x0002);
	mov	a,#0x02
	mov	dptr,#(_cobs_log_begin_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_begin_PARM_2 + 1) >> 16)
	mov	@dpx,a
	clr	a
	mov	dptr,#_cobs_log_begin_PARM_2
	mov	dpxl,#(_cobs_log_begin_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_begin
	pop	ar6
	pop	ar7
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:41: cobs_log_u16(&e, n);
	mov	a,r7
	mov	dptr,#(_cobs_log_u16_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_u16_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#_cobs_log_u16_PARM_2
	mov	dpxl,#(_cobs_log_u16_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	push	ar7
	push	ar6
	ecall	_cobs_log_u16
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:42: send(out_buf, cobs_log_end(&e));               /* count = n */
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_end
	mov	a, dpl
	mov	b, dph
	mov	dptr,#(_send_PARM_2 + 1)
	mov	dpxl,#((_send_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,b
	mov	dptr,#_send_PARM_2
	mov	dpxl,#(_send_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_out_buf
	mov	b, #(_out_buf >> 16)
	ecall	_send
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:44: cobs_log_begin(&e, 0x0003);
	mov	a,#0x03
	mov	dptr,#(_cobs_log_begin_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_begin_PARM_2 + 1) >> 16)
	mov	@dpx,a
	clr	a
	mov	dptr,#_cobs_log_begin_PARM_2
	mov	dpxl,#(_cobs_log_begin_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_begin
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:45: cobs_log_u8(&e, 0xab);
	mov	a,#0xab
	mov	dptr,#_cobs_log_u8_PARM_2
	mov	dpxl,#(_cobs_log_u8_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_u8
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:46: cobs_log_u8(&e, 0xcd);
	mov	a,#0xcd
	mov	dptr,#_cobs_log_u8_PARM_2
	mov	dpxl,#(_cobs_log_u8_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_u8
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:47: send(out_buf, cobs_log_end(&e));               /* xy */
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_end
	mov	a, dpl
	mov	b, dph
	mov	dptr,#(_send_PARM_2 + 1)
	mov	dpxl,#((_send_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,b
	mov	dptr,#_send_PARM_2
	mov	dpxl,#(_send_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_out_buf
	mov	b, #(_out_buf >> 16)
	ecall	_send
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:49: cobs_log_begin(&e, 0x0004);
	mov	a,#0x04
	mov	dptr,#(_cobs_log_begin_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_begin_PARM_2 + 1) >> 16)
	mov	@dpx,a
	clr	a
	mov	dptr,#_cobs_log_begin_PARM_2
	mov	dpxl,#(_cobs_log_begin_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_begin
	pop	ar6
	pop	ar7
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:50: cobs_log_var(&e, n);
	mov	a,r7
	mov	dptr,#(_cobs_log_var_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_var_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#_cobs_log_var_PARM_2
	mov	dpxl,#(_cobs_log_var_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	push	ar7
	push	ar6
	ecall	_cobs_log_var
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:51: send(out_buf, cobs_log_end(&e));               /* cvar（LEB128） */
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_end
	mov	a, dpl
	mov	b, dph
	mov	dptr,#(_send_PARM_2 + 1)
	mov	dpxl,#((_send_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,b
	mov	dptr,#_send_PARM_2
	mov	dpxl,#(_send_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_out_buf
	mov	b, #(_out_buf >> 16)
	ecall	_send
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:53: cobs_log_begin(&e, 0x0005);
	mov	a,#0x05
	mov	dptr,#(_cobs_log_begin_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_begin_PARM_2 + 1) >> 16)
	mov	@dpx,a
	clr	a
	mov	dptr,#_cobs_log_begin_PARM_2
	mov	dpxl,#(_cobs_log_begin_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_begin
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:54: cobs_log_str(&e, "hello");
	mov	a,#___str_0
	mov	dptr,#(_cobs_log_str_PARM_2 + 2)
	mov	dpxl,#((_cobs_log_str_PARM_2 + 2) >> 16)
	mov	@dpx,a
	mov	a,#(___str_0 >> 8)
	mov	dptr,#(_cobs_log_str_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_str_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,#(___str_0 >> 16)
	mov	dptr,#_cobs_log_str_PARM_2
	mov	dpxl,#(_cobs_log_str_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_str
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:55: send(out_buf, cobs_log_end(&e));               /* msg */
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_end
	mov	a, dpl
	mov	b, dph
	mov	dptr,#(_send_PARM_2 + 1)
	mov	dpxl,#((_send_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,b
	mov	dptr,#_send_PARM_2
	mov	dpxl,#(_send_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_out_buf
	mov	b, #(_out_buf >> 16)
	ecall	_send
	pop	ar6
	pop	ar7
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:57: g16 = n;                                       /* u16 全局写（大端） */
	mov	a,r7
	mov	dptr,#(_g16 + 1)
	mov	dpxl,#((_g16 + 1) >> 16)
	mov	@dpx,a
	mov	a,r6
	mov	dptr,#_g16
	mov	dpxl,#(_g16 >> 16)
	mov	@dpx,a
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:58: cobs_log_begin(&e, 0x0006);
	mov	a,#0x06
	mov	dptr,#(_cobs_log_begin_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_begin_PARM_2 + 1) >> 16)
	mov	@dpx,a
	clr	a
	mov	dptr,#_cobs_log_begin_PARM_2
	mov	dpxl,#(_cobs_log_begin_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	push	ar7
	push	ar6
	ecall	_cobs_log_begin
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:59: cobs_log_u16(&e, g16);                         /* 读回，应等于 count */
	mov	dptr,#(_g16 + 1)
	mov	dpxl,#((_g16 + 1) >> 16)
	mov	a,@dpx
	mov	r5,a
	mov	dptr,#_g16
	mov	dpxl,#(_g16 >> 16)
	mov	a,@dpx
	mov	r4,a
	mov	a,r5
	mov	dptr,#(_cobs_log_u16_PARM_2 + 1)
	mov	dpxl,#((_cobs_log_u16_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,r4
	mov	dptr,#_cobs_log_u16_PARM_2
	mov	dpxl,#(_cobs_log_u16_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_u16
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:60: send(out_buf, cobs_log_end(&e));
	mov	dptr,#_main_e_10000_70
	mov	b, #(_main_e_10000_70 >> 16)
	ecall	_cobs_log_end
	mov	a, dpl
	mov	b, dph
	mov	dptr,#(_send_PARM_2 + 1)
	mov	dpxl,#((_send_PARM_2 + 1) >> 16)
	mov	@dpx,a
	mov	a,b
	mov	dptr,#_send_PARM_2
	mov	dpxl,#(_send_PARM_2 >> 16)
	mov	@dpx,a
	mov	dptr,#_out_buf
	mov	b, #(_out_buf >> 16)
	ecall	_send
	pop	ar6
	pop	ar7
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:62: n++;
	inc	r7
	cjne	r7,#0x00,00113$
	inc	r6
00113$:
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:64: delay_ms(100);                                 /* 约 10 帧组/秒 */
	mov	dptr,#0x0064
	push	ar7
	push	ar6
	ecall	_delay_ms
	pop	ar6
	pop	ar7
	ejmp	00102$
;	E:\code\yuyan\mcs251\examples\ai8051u_c_cobs\main.c:66: }
	eret
	.area CSEG    (CODE)
	.area CONST   (CODE)
	.area CONST   (CODE)
___str_0:
	.ascii "hello"
	.db 0x00
	.area CSEG    (CODE)
	.area XINIT   (CODE)
	.area CABS    (ABS,CODE)
