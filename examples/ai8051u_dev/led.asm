	.area DSEG    (DATA)
	.globl _output_mode
_output_mode:
	.ds 1
	.area DSEG    (DATA)
	.globl _P1M1
_P1M1:
	.ds 2
	.area DSEG    (DATA)
	.globl _P1M1_ADDR
_P1M1_ADDR:
	.ds 1
	.area XSEG    (XDATA)
	.globl _empty
_empty:
	.ds 42
	.area XSEG    (XDATA)
	.globl _cpu
_cpu:
	.ds 46
	.area DSEG    (DATA)
	.globl _P1M0
_P1M0:
	.ds 2
	.area DSEG    (DATA)
	.globl _P1M0_ADDR
_P1M0_ADDR:
	.ds 1
	.area DSEG    (DATA)
	.globl _ticks
_ticks:
	.ds 2
	.area DSEG    (DATA)
	.globl _P1
_P1:
	.ds 2
	.area DSEG    (DATA)
	.globl _P1_ADDR
_P1_ADDR:
	.ds 1
	.area XSEG    (XDATA)
	.globl _P1p
_P1p:
	.ds 3
	.area CSEG    (CODE)
	.globl _led_main
_led_main:
        add spx,#0x0007
	anl 0x91,#0xfd
L_led_main_1:
	orl 0x92,#0x02
L_led_main_3:
        mov a,#0x5a
        mov dptr,#_buf
        mov dpxl,#(_buf >> 16)
        mov @dpx,a
L_led_main_4:
        mov a,_ticks
        mov @spx-0x1,a
        mov a,_ticks+1
        add a,#0x01
        mov @spx-0x2,a
        mov a,@spx-0x1
        addc a,#0x00
        mov _ticks,a
        mov a,@spx-0x2
        mov _ticks+1,a
        mov a,_ticks
        mov a,_ticks+1
        mov 0x90,a
        ecall _led_delay500ms
        mov a,#0xff
        mov 0x90,a
        ecall _led_delay500ms
        ejmp L_led_main_4
L_led_main_5:
	.area CSEG    (CODE)
	.globl _led_delay500ms
_led_delay500ms:
        add spx,#0x0012
        mov a,#0x00
        mov @spx,a
        mov @spx-0x1,a
L_led_delay500ms_2:
        mov a,@spx
        mov @spx-0x2,a
        mov a,@spx-0x1
        mov @spx-0x3,a
        clr cy
        mov a,@spx-0x2
        subb a,#0x64
        mov a,@spx-0x3
        subb a,#0x00
        clr a
        addc a,#0x00
        jnz L_led_delay500ms_14
        ejmp L_led_delay500ms_15
L_led_delay500ms_14:
        mov a,#0x00
        mov @spx-0x5,a
        mov @spx-0x6,a
L_led_delay500ms_10:
        mov a,@spx-0x5
        mov @spx-0x7,a
        mov a,@spx-0x6
        mov @spx-0x8,a
        clr cy
        mov a,@spx-0x7
        subb a,#0x10
        mov a,@spx-0x8
        subb a,#0x27
        clr a
        addc a,#0x00
        jnz L_led_delay500ms_17
        ejmp L_led_delay500ms_18
L_led_delay500ms_17:
        mov a,@spx-0x5
        mov @spx-0xa,a
        mov a,@spx-0x6
        mov @spx-0xb,a
        mov a,@spx-0xa
        add a,#0x01
        mov @spx-0xc,a
        mov a,@spx-0xb
        addc a,#0x00
        mov @spx-0xd,a
        mov a,@spx-0xc
        mov @spx-0x5,a
        mov a,@spx-0xd
        mov @spx-0x6,a
        ejmp L_led_delay500ms_13
L_led_delay500ms_18:
        ejmp L_led_delay500ms_9
L_led_delay500ms_19:
L_led_delay500ms_13:
        ejmp L_led_delay500ms_10
L_led_delay500ms_11:
L_led_delay500ms_9:
L_led_delay500ms_7:
        mov a,@spx
        mov @spx-0xe,a
        mov a,@spx-0x1
        mov @spx-0xf,a
        mov a,@spx-0xe
        add a,#0x01
        mov @spx-0x10,a
        mov a,@spx-0xf
        addc a,#0x00
        mov @spx-0x11,a
        mov a,@spx-0x10
        mov @spx,a
        mov a,@spx-0x11
        mov @spx-0x1,a
        ejmp L_led_delay500ms_5
L_led_delay500ms_15:
        ejmp L_led_delay500ms_1
L_led_delay500ms_16:
L_led_delay500ms_5:
        ejmp L_led_delay500ms_2
L_led_delay500ms_3:
L_led_delay500ms_1:
        sub spx,#0x0012
        eret
	.area XSEG    (XDATA)
	.globl _buf
_buf:
	.ds 16
	.area XSEG    (XDATA)
	.globl _generic
_generic:
	.ds 54
	.area CSEG    (CODE)
	.globl _main
_main:
	ejmp _led_main
