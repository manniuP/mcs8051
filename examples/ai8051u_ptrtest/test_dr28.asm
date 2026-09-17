; test_dr28.asm - 测试sdas251是否支持DR28间接寻址
	.area CSEG    (CODE)
	.globl _test_dr28
_test_dr28:
	; 保存参数指针
	mov a,dpl
	mov r0,a
	mov a,dph
	mov r1,a
	mov a,b
	mov r2,a

	; loadPtrToDr28: push 0,r0,r1,r2 -> pop dr28
	push #0
	push r0
	push r1
	push r2
	pop dr28

	; derefWrite: buf[0] = 0x68
	mov a,#0x68
	mov r3,a
	mov @dr28,r3

	; derefRead: buf[1] -> r4
	inc dr28
	mov r4,@dr28

	; 返回
	mov dpl,#0x05
	eret
