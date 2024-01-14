	.file	"uart.c"
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
	.section	.mprj,"ax",@progbits
	.align	2
	.globl	uart_write
	.type	uart_write, @function
uart_write:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	nop
.L4:
	li	a5,822083584
	addi	a5,a5,8
	lw	a5,0(a5)
	andi	a5,a5,8
	bne	a5,zero,.L4
	li	a5,822083584
	addi	a5,a5,4
	lw	a4,-20(s0)
	sw	a4,0(a5)
	nop
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	uart_write, .-uart_write
	.align	2
	.globl	uart_write_char
	.type	uart_write_char, @function
uart_write_char:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	mv	a5,a0
	sb	a5,-17(s0)
	lbu	a4,-17(s0)
	li	a5,10
	bne	a4,a5,.L8
	li	a0,13
	call	uart_write_char
.L8:
	nop
.L7:
	li	a5,822083584
	addi	a5,a5,8
	lw	a5,0(a5)
	andi	a5,a5,8
	bne	a5,zero,.L7
	li	a5,822083584
	addi	a5,a5,4
	lbu	a4,-17(s0)
	sw	a4,0(a5)
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	uart_write_char, .-uart_write_char
	.align	2
	.globl	uart_write_string
	.type	uart_write_string, @function
uart_write_string:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	j	.L10
.L11:
	lw	a5,-20(s0)
	addi	a4,a5,1
	sw	a4,-20(s0)
	lbu	a5,0(a5)
	mv	a0,a5
	call	uart_write_char
.L10:
	lw	a5,-20(s0)
	lbu	a5,0(a5)
	bne	a5,zero,.L11
	nop
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	uart_write_string, .-uart_write_string
	.align	2
	.globl	uart_read_char
	.type	uart_read_char, @function
uart_read_char:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	li	a5,822083584
	addi	a5,a5,8
	lw	a5,0(a5)
	srli	a5,a5,5
	bne	a5,zero,.L13
	li	a5,822083584
	addi	a5,a5,8
	lw	a5,0(a5)
	srli	a5,a5,4
	bne	a5,zero,.L13
	sw	zero,-24(s0)
	j	.L14
.L15:
 #APP
# 34 "uart.c" 1
	nop
# 0 "" 2
 #NO_APP
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
.L14:
	lw	a5,-24(s0)
	ble	a5,zero,.L15
	li	a5,822083584
	lw	a5,0(a5)
	sb	a5,-17(s0)
.L13:
	lbu	a5,-17(s0)
	mv	a0,a5
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	uart_read_char, .-uart_read_char
	.align	2
	.globl	uart_read
	.type	uart_read, @function
uart_read:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	li	a5,822083584
	addi	a5,a5,8
	lw	a5,0(a5)
	srli	a5,a5,5
	bne	a5,zero,.L18
	li	a5,822083584
	addi	a5,a5,8
	lw	a5,0(a5)
	srli	a5,a5,4
	bne	a5,zero,.L18
	sw	zero,-24(s0)
	j	.L19
.L20:
 #APP
# 47 "uart.c" 1
	nop
# 0 "" 2
 #NO_APP
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
.L19:
	lw	a5,-24(s0)
	ble	a5,zero,.L20
	li	a5,822083584
	lw	a5,0(a5)
	sw	a5,-20(s0)
.L18:
	lw	a5,-20(s0)
	mv	a0,a5
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	uart_read, .-uart_read
	.ident	"GCC: (g1ea978e3066) 12.1.0"
