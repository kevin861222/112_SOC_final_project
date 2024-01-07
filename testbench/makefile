Target:
	@ rm -f *.hex *.hexe *.vvp *.vcd

	@ riscv-none-elf-gcc -Wl,--no-warn-rwx-segments -g \
		--save-temps \
		-Xlinker -Map=output.map \
		-I../firmware \
		-march=rv32i_zicsr -mabi=ilp32 -D__vexriscv__ \
		-Wl,-Bstatic,-T,../firmware/sections.lds,--strip-discarded \
		-ffreestanding -nostartfiles -o main.elf ../firmware/crt0_vex.S ../firmware/isr.c main.c 
	@ riscv-none-elf-objcopy -O verilog main.elf main.hex
	@ rm -f *.s *.o *.i *.out *.map *.elf *.hexe
	@ sed -ie 's/@10/@00/g' main.hex
	@ iverilog -Ttyp -DFUNCTIONAL -DSIM -DUNIT_DELAY=#1 \
		-f ./include.rtl.list -o main.vvp main_tb.v
	@ vvp main.vvp

.PHONY: clean wv

clean:
	@ rm -rf ./gdb.debug ./gdbwave.debug
	@ rm -f *.s *.o *.i *.out *.map *.elf *.hexe *.vvp *.vcd *.hex

wv:
	@ gtkwave main.vcd  waveform.gtkw  --autosavename