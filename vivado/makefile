
path_upload    = ./jupyter_notebook
path_handoff   = ./vvd_caravel_fpga/vvd_caravel_fpga.gen/sources_1/bd/design_1/hw_handoff
path_bitstream = ./vvd_caravel_fpga/vvd_caravel_fpga.runs/impl_1
FILE = ./vivado.log
STRING = "CRITICAL WARNING: \[Timing 38-282\]"

Target:
	@ echo "start vivado project"
	@ make clean
	@ vivado -source vvd_caravel_fpga_40mhz.tcl -mode tcl
	@ make find_timing_violation
	@ cp -f $(path_handoff)/design_1.hwh $(path_upload)/caravel_fpga.hwh
	@ cp -f $(path_bitstream)/design_1_wrapper.bit $(path_upload)/caravel_fpga.bit
	@ echo "vivado complete"

.PHONY: clean
clean:
	@rm -rf ./NA ./.Xil ./vvd_caravel_fpga
	@rm -f *.log *.jou

find_timing_violation:
ifneq ("$(wildcard $(FILE))", "")
	@ cat $(FILE) | grep $(STRING)
endif