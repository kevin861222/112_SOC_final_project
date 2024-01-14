	.file	"define.c"
	.option nopic
	.attribute arch, "rv32i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.globl	fir_taps
	.data
	.align	2
	.type	fir_taps, @object
	.size	fir_taps, 44
fir_taps:
	.word	0
	.word	-10
	.word	-9
	.word	23
	.word	56
	.word	63
	.word	56
	.word	23
	.word	-9
	.word	-10
	.word	0
	.globl	fir_input
	.align	2
	.type	fir_input, @object
	.size	fir_input, 256
fir_input:
	.word	1
	.word	2
	.word	3
	.word	4
	.word	5
	.word	6
	.word	7
	.word	8
	.word	9
	.word	10
	.word	11
	.word	12
	.word	13
	.word	14
	.word	15
	.word	16
	.word	17
	.word	18
	.word	19
	.word	20
	.word	21
	.word	22
	.word	23
	.word	24
	.word	25
	.word	26
	.word	27
	.word	28
	.word	29
	.word	30
	.word	31
	.word	32
	.word	33
	.word	34
	.word	35
	.word	36
	.word	37
	.word	38
	.word	39
	.word	40
	.word	41
	.word	42
	.word	43
	.word	44
	.word	45
	.word	46
	.word	47
	.word	48
	.word	49
	.word	50
	.word	51
	.word	52
	.word	53
	.word	54
	.word	55
	.word	56
	.word	57
	.word	58
	.word	59
	.word	60
	.word	61
	.word	62
	.word	63
	.word	64
	.globl	fir_output
	.bss
	.align	2
	.type	fir_output, @object
	.size	fir_output, 256
fir_output:
	.zero	256
	.globl	mat_A
	.data
	.align	2
	.type	mat_A, @object
	.size	mat_A, 64
mat_A:
	.word	0
	.word	1
	.word	2
	.word	3
	.word	0
	.word	1
	.word	2
	.word	3
	.word	0
	.word	1
	.word	2
	.word	3
	.word	0
	.word	1
	.word	2
	.word	3
	.globl	mat_B_T
	.align	2
	.type	mat_B_T, @object
	.size	mat_B_T, 64
mat_B_T:
	.word	1
	.word	5
	.word	9
	.word	13
	.word	2
	.word	6
	.word	10
	.word	14
	.word	3
	.word	7
	.word	11
	.word	15
	.word	4
	.word	8
	.word	12
	.word	16
	.globl	mat_output
	.bss
	.align	2
	.type	mat_output, @object
	.size	mat_output, 64
mat_output:
	.zero	64
	.globl	qsort_input
	.data
	.align	2
	.type	qsort_input, @object
	.size	qsort_input, 40
qsort_input:
	.word	893
	.word	40
	.word	3233
	.word	4267
	.word	2669
	.word	2541
	.word	9073
	.word	6023
	.word	5681
	.word	4622
	.globl	qsort_output
	.bss
	.align	2
	.type	qsort_output, @object
	.size	qsort_output, 40
qsort_output:
	.zero	40
	.ident	"GCC: (g1ea978e3066) 12.1.0"
