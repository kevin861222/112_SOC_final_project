	.file	"main.c"
	.option nopic
	.attribute arch, "rv32i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.type	flush_cpu_icache, @function
flush_cpu_icache:
	addi	sp,sp,-16
	sw	s0,12(sp)
	addi	s0,sp,16
	nop
	lw	s0,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	flush_cpu_icache, .-flush_cpu_icache
	.align	2
	.type	flush_cpu_dcache, @function
flush_cpu_dcache:
	addi	sp,sp,-16
	sw	s0,12(sp)
	addi	s0,sp,16
	nop
	lw	s0,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	flush_cpu_dcache, .-flush_cpu_dcache
	.align	2
	.type	csr_write_simple, @function
csr_write_simple:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	sw	a1,-24(s0)
	lw	a5,-24(s0)
	lw	a4,-20(s0)
	sw	a4,0(a5)
	nop
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	csr_write_simple, .-csr_write_simple
	.align	2
	.type	user_irq_0_ev_enable_write, @function
user_irq_0_ev_enable_write:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	li	a5,-268406784
	addi	a1,a5,-2028
	lw	a0,-20(s0)
	call	csr_write_simple
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	user_irq_0_ev_enable_write, .-user_irq_0_ev_enable_write
	.align	2
	.type	irq_getmask, @function
irq_getmask:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
 #APP
# 25 "../firmware/irq_vex.h" 1
	csrr a5, 3008
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	irq_getmask, .-irq_getmask
	.align	2
	.type	irq_setmask, @function
irq_setmask:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	lw	a5,-20(s0)
 #APP
# 31 "../firmware/irq_vex.h" 1
	csrw 3008, a5
# 0 "" 2
 #NO_APP
	nop
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	irq_setmask, .-irq_setmask
	.section	.mprjram,"ax",@progbits
	.align	2
	.globl	Hardware_test
	.type	Hardware_test, @function
Hardware_test:
	addi	sp,sp,-16
	sw	s0,12(sp)
	addi	s0,sp,16
	li	a5,637534208
	addi	a5,a5,12
	li	a4,-1426063360
	sw	a4,0(a5)
	li	a5,805339136
	addi	a5,a5,4
	sw	zero,0(a5)
	li	a5,805339136
	li	a4,1035
	sw	a4,0(a5)
	nop
.L9:
	li	a5,805339136
	lw	a4,0(a5)
	li	a5,4096
	addi	a5,a5,-2048
	and	a5,a4,a5
	beq	a5,zero,.L9
	li	a5,805339136
	addi	a5,a5,4
	li	a4,11
	sw	a4,0(a5)
	li	a5,805339136
	li	a4,1088
	sw	a4,0(a5)
	nop
.L10:
	li	a5,805339136
	lw	a4,0(a5)
	li	a5,4096
	addi	a5,a5,-2048
	and	a5,a4,a5
	beq	a5,zero,.L10
	li	a5,805339136
	addi	a5,a5,4
	sw	zero,0(a5)
	li	a5,805339136
	li	a4,1600
	sw	a4,0(a5)
	nop
.L11:
	li	a5,805339136
	lw	a4,0(a5)
	li	a5,4096
	addi	a5,a5,-2048
	and	a5,a4,a5
	beq	a5,zero,.L11
	li	a5,637534208
	addi	a5,a5,12
	li	a4,-1425997824
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,12
	li	a4,-1425014784
	sw	a4,0(a5)
	li	a5,805339136
	addi	a5,a5,4
	li	a4,75
	sw	a4,0(a5)
	li	a5,805339136
	li	a4,1168
	sw	a4,0(a5)
	nop
.L12:
	li	a5,805339136
	lw	a4,0(a5)
	li	a5,4096
	addi	a5,a5,-2048
	and	a5,a4,a5
	beq	a5,zero,.L12
	li	a5,805339136
	addi	a5,a5,4
	li	a4,91
	sw	a4,0(a5)
	li	a5,805339136
	li	a4,1168
	sw	a4,0(a5)
	nop
.L13:
	li	a5,805339136
	lw	a4,0(a5)
	li	a5,4096
	addi	a5,a5,-2048
	and	a5,a4,a5
	beq	a5,zero,.L13
	li	a5,805339136
	addi	a5,a5,4
	li	a4,64
	sw	a4,0(a5)
	li	a5,805339136
	li	a4,1680
	sw	a4,0(a5)
	nop
.L14:
	li	a5,805339136
	lw	a4,0(a5)
	li	a5,4096
	addi	a5,a5,-2048
	and	a5,a4,a5
	beq	a5,zero,.L14
	li	a5,637534208
	addi	a5,a5,12
	li	a4,-1424949248
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,12
	li	a4,-1423966208
	sw	a4,0(a5)
	li	a5,805339136
	addi	a5,a5,4
	li	a4,107
	sw	a4,0(a5)
	li	a5,805339136
	li	a4,1290
	sw	a4,0(a5)
	nop
.L15:
	li	a5,805339136
	lw	a4,0(a5)
	li	a5,4096
	addi	a5,a5,-2048
	and	a5,a4,a5
	beq	a5,zero,.L15
	li	a5,805339136
	addi	a5,a5,4
	li	a4,64
	sw	a4,0(a5)
	li	a5,805339136
	li	a4,1802
	sw	a4,0(a5)
	nop
.L16:
	li	a5,805339136
	lw	a4,0(a5)
	li	a5,4096
	addi	a5,a5,-2048
	and	a5,a4,a5
	beq	a5,zero,.L16
	li	a5,637534208
	addi	a5,a5,12
	li	a4,-1423900672
	sw	a4,0(a5)
	nop
	lw	s0,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	Hardware_test, .-Hardware_test
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	li	a5,637534208
	addi	a5,a5,160
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,156
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,152
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,148
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,144
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,140
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,136
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,132
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,128
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,124
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,120
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,116
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,112
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,108
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,104
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,100
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,96
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,92
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,88
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,84
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,80
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,76
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,72
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,68
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,64
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,52
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,48
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,44
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,40
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,36
	li	a4,8192
	addi	a4,a4,-2040
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,60
	li	a4,8192
	addi	a4,a4,-2039
	sw	a4,0(a5)
	li	a5,637534208
	addi	a5,a5,56
	li	a4,1026
	sw	a4,0(a5)
	li	a5,-268423168
	addi	a4,a5,12
	li	a5,0
	sw	a5,0(a4)
	li	a4,-268423168
	addi	a4,a4,28
	sw	a5,0(a4)
	li	a5,-268423168
	addi	a4,a5,8
	li	a5,0
	sw	a5,0(a4)
	li	a4,-268423168
	addi	a4,a4,24
	sw	a5,0(a4)
	li	a5,-268423168
	addi	a4,a5,4
	li	a5,0
	sw	a5,0(a4)
	li	a4,-268423168
	addi	a4,a4,20
	sw	a5,0(a4)
	li	a4,-268423168
	li	a5,0
	sw	a5,0(a4)
	li	a4,-268423168
	addi	a4,a4,16
	sw	a5,0(a4)
	call	irq_getmask
	mv	a5,a0
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	ori	a5,a5,4
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	call	irq_setmask
	li	a0,1
	call	user_irq_0_ev_enable_write
	li	a5,-268419072
	addi	a5,a5,-2048
	li	a4,1
	sw	a4,0(a5)
	li	a5,-268410880
	li	a4,1
	sw	a4,0(a5)
	li	a5,637534208
	li	a4,1
	sw	a4,0(a5)
	nop
.L18:
	li	a5,637534208
	lw	a4,0(a5)
	li	a5,1
	beq	a4,a5,.L18
	call	Hardware_test
	call	Hardware_test
	call	Hardware_test
.L19:
	j	.L19
	.size	main, .-main
	.ident	"GCC: (g1ea978e3066) 12.1.0"
