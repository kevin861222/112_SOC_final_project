	.file	"isr.c"
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
	.type	user_irq_0_ev_pending_write, @function
user_irq_0_ev_pending_write:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	li	a5,-268406784
	addi	a1,a5,-2032
	lw	a0,-20(s0)
	call	csr_write_simple
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	user_irq_0_ev_pending_write, .-user_irq_0_ev_pending_write
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
	.type	irq_pending, @function
irq_pending:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
 #APP
# 37 "../firmware/irq_vex.h" 1
	csrr a5, 4032
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	irq_pending, .-irq_pending
	.align	2
	.globl	isr
	.type	isr, @function
isr:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	sw	s1,20(sp)
	addi	s0,sp,32
	call	irq_pending
	mv	s1,a0
	call	irq_getmask
	mv	a5,a0
	and	a5,s1,a5
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	andi	a5,a5,4
	beq	a5,zero,.L12
	li	a0,1
	call	user_irq_0_ev_pending_write
	call	uart_read
	mv	a5,a0
	sw	a5,-24(s0)
	lw	a5,-24(s0)
	andi	a5,a5,0xff
	mv	a0,a5
	call	uart_write
	nop
.L12:
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	addi	sp,sp,32
	jr	ra
	.size	isr, .-isr
	.ident	"GCC: (g1ea978e3066) 12.1.0"
