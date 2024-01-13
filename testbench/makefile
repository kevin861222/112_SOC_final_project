ifeq ($(OS), Windows_NT)
CC = riscv-none-elf-gcc
OBJCPY = riscv-none-elf-objcopy
march = rv32i_zicsr
else
CC = riscv32-unknown-elf-gcc
OBJCPY = riscv32-unknown-elf-objcopy
march = rv32i
endif

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

.PHONY: clean wv

clean:
	@ rm -f *.s *.o *.i *.out *.map *.elf *.hexe *.vvp *.vcd *.hex

wv:
	@ gtkwave main.vcd  uart.gtkw
