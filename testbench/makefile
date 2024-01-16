ifeq ($(OS), Windows_NT)
CROSS_COMPILE = riscv-none-elf-
march = rv32i_zicsr
else
CROSS_COMPILE = riscv32-unknown-elf-
march = rv32i
endif

CC      = $(CROSS_COMPILE)gcc
OBJCPY  = $(CROSS_COMPILE)objcopy
OBJDMP  = $(CROSS_COMPILE)objdump
OBJSIZE = $(CROSS_COMPILE)size

Target:
	@ make clean
	@ $(CC) -Wl,--no-warn-rwx-segments \
		--save-temps \
		-I ../firmware \
		-march=$(march) -mabi=ilp32 -D__vexriscv__ \
		-DUSER_PROJ_IRQ0_EN \
		-Xlinker -Map=main.map \
		-Wl,-Bstatic,-T,../firmware/sections.lds,--strip-discarded \
		-ffreestanding -nostartfiles -o main.elf ../firmware/crt0_vex.S ../firmware/isr.c uart.c define.c main.c 
	@ $(OBJCPY) -O verilog main.elf main.hex
	@ sed -ie 's/@10/@00/g' main.hex
	@ iverilog -Ttyp -DFUNCTIONAL -DSIM -DUNIT_DELAY=#1 \
		-f ./include.rtl.list -o main.vvp main_tb.v
	@ vvp main.vvp

.PHONY: clean wv dump size

clean:
	@ rm -f *.s *.o *.i *.out *.map *.elf *.hexe *.vvp *.vcd *.hex

wv:
	@ gtkwave main.vcd  ../gtkw/data_fifo.gtkw

dump:
	@ $(OBJDMP) -d main.elf > dump.log

size:
	@ $(OBJSIZE) main.elf