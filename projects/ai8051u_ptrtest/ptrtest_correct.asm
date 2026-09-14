; ptrtest_correct.asm — 手工编写正确的DR28间接寻址代码
; 验证.ptr_rt修复的概念：fill/sum通过DR28间接访问C的buffer
;
; 帧布局（fill）：
;   @spx+0: 指针低字节(DPL)   @spx-1: 指针中字节(DPH)   @spx-2: 指针高字节(B)
;   DR28 = 0:high:mid:low (3字节指针)
;   @dr28 = 间接访问buffer

	.area CSEG    (CODE)

	.globl _fill
_fill:
	; 分配栈帧（最小：3字节存参数指针 + 返回值用dpl）
	inc spx,#0x04
	inc spx,#0x04
	inc spx,#0x04

	; 保存参数指针到帧槽 @spx / @spx-1 / @spx-2
	mov a,dpl
	mov @spx,a
	mov a,dph
	mov @spx-0x1,a
	mov a,b
	mov @spx-0x2,a

	; loadPtrToDr28: 从帧槽加载3字节指针到DR28
	mov a,@spx-0x2		; 高字节 -> R0
	mov r0,a
	mov a,@spx-0x1		; 中字节 -> R1
	mov r1,a
	mov a,@spx			; 低字节 -> R2
	mov r2,a
	push #0
	push r0
	push r1
	push r2
	pop dr28			; DR28 = 0:R0:R1:R2 = 指针值

	; derefWrite: buf[0] = 'h' (0x68)
	mov a,#0x68
	mov r3,a
	mov @dr28,r3

	; derefWrite: buf[1] = 'e' (0x65)
	inc dr28
	mov a,#0x65
	mov r3,a
	mov @dr28,r3

	; derefWrite: buf[2] = 'l' (0x6c)
	inc dr28
	mov a,#0x6c
	mov r3,a
	mov @dr28,r3

	; derefWrite: buf[3] = 'l' (0x6c)
	inc dr28
	mov a,#0x6c
	mov r3,a
	mov @dr28,r3

	; derefWrite: buf[4] = 'o' (0x6f)
	inc dr28
	mov a,#0x6f
	mov r3,a
	mov @dr28,r3

	; 返回 5
	mov dpl,#0x05

	; 释放栈帧
	dec spx,#0x04
	dec spx,#0x04
	dec spx,#0x04
	eret

	.globl _sum
_sum:
	; 分配栈帧
	inc spx,#0x04
	inc spx,#0x04
	inc spx,#0x04

	; 保存参数指针
	mov a,dpl
	mov @spx,a
	mov a,dph
	mov @spx-0x1,a
	mov a,b
	mov @spx-0x2,a

	; loadPtrToDr28
	mov a,@spx-0x2
	mov r0,a
	mov a,@spx-0x1
	mov r1,a
	mov a,@spx
	mov r2,a
	push #0
	push r0
	push r1
	push r2
	pop dr28

	; derefRead: buf[0] -> A, 累加
	mov r3,@dr28
	mov a,r3
	mov r4,a			; r4 = s = buf[0]

	; derefRead: buf[1]
	inc dr28
	mov r3,@dr28
	mov a,r4
	add a,r3
	mov r4,a			; s += buf[1]

	; derefRead: buf[2]
	inc dr28
	mov r3,@dr28
	mov a,r4
	add a,r3
	mov r4,a			; s += buf[2]

	; derefRead: buf[3]
	inc dr28
	mov r3,@dr28
	mov a,r4
	add a,r3
	mov r4,a			; s += buf[3]

	; derefRead: buf[4]
	inc dr28
	mov r3,@dr28
	mov a,r4
	add a,r3			; A = s + buf[4]

	; 返回 s (低8位)
	mov dpl,a

	; 释放栈帧
	dec spx,#0x04
	dec spx,#0x04
	dec spx,#0x04
	eret
