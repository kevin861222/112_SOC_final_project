// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps
// `define times_rerun 3
`define times_rerun 1
module main_tb;
	reg clock;
	reg RSTB;
	reg CSB;

	reg power1, power2;

	wire gpio;
	wire [37:0] mprj_io;
	wire [15:0] checkbits;
	wire uart_tx;
	wire uart_rx;
	reg tx_start;
	reg [7:0] tx_data;
	wire tx_busy;
	wire tx_clear_req;
	assign checkbits  = mprj_io[31:16];
	assign uart_tx = mprj_io[6];
	assign mprj_io[5] = uart_rx;

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	initial begin
		$dumpfile("main.vcd");
		$dumpvars(0, main_tb);

		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (250) begin
			repeat (1000) @(posedge clock);
			// $display("+1000 cycles");
		end
		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, Test LA (GL) Failed");
		`else
			$display ("Monitor: Timeout, Test LA (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	reg [7:0] times_workload, times_uart;
	initial begin
		fork
			for(times_workload=0;times_workload<`times_rerun;times_workload=times_workload+1) begin
				$display("Times = %1d/%1d - Hardware", times_workload+1, `times_rerun);
				fir;
				matmul;
				qsort;
			end
			
			for(times_workload=0;times_workload<`times_rerun;times_workload=times_workload+1) begin
				$display("Times = %1d/%1d - Hardware(check)", times_workload+1, `times_rerun);
				fir_check;
				matmul_check;
				qsort_check;
			end
			
			for(times_uart=0;times_uart<`times_rerun;times_uart=times_uart+1) begin
				$display("Times = %1d/%1d - UART", times_uart+1, `times_rerun);
				send_data(times_uart);
			end
		join
		$finish;
	end

	// FIR
	integer fir_taps   [10:0];
	integer fir_input  [63:0];
	integer fir_output [63:0];
	reg [6:0] fir_i, fir_j;
	initial begin
		// Input - FIR taps
		fir_taps[0] =   0;
		fir_taps[1] = -10;
		fir_taps[2] =  -9;
		fir_taps[3] =  23;
		fir_taps[4] =  56;
		fir_taps[5] =  63;
		fir_taps[6] =  56;
		fir_taps[7] =  23;
		fir_taps[8] =  -9;
		fir_taps[9] = -10;
		fir_taps[10] =  0;
		// Input - FIR Xn
		for(fir_i=0;fir_i<64;fir_i=fir_i+1) begin
			fir_input[fir_i] = fir_i + 1;
		end
		// Output - FIR Yn
		for(fir_i=0;fir_i<64;fir_i=fir_i+1) begin
			fir_output[fir_i] = 0;
			for(fir_j=0;fir_j<$min(fir_i+1, 11);fir_j=fir_j+1) begin
				fir_output[fir_i] = fir_output[fir_i] + fir_taps[fir_j] * fir_input[fir_i-fir_j];
			end
		end
		// for(fir_i=0;fir_i<64;fir_i=fir_i+1) begin
		// 	$display("Y[%d] = %d", fir_i, fir_output[fir_i]);
		// end
	end

	// matmul
	integer mat_A[15:0];
	integer mat_B_T[15:0];
	integer mat_output[15:0];
	reg [4:0]mat_i, mat_j, mat_k;
	initial begin
		// Input - mat_A
		for(mat_i=0;mat_i<16;mat_i=mat_i+1) begin
			mat_A[mat_i] = mat_i%4;
		end
		// Input - mat_B
		for(mat_i=0;mat_i<4;mat_i=mat_i+1) begin
			for(mat_j=0;mat_j<4;mat_j=mat_j+1) begin
				mat_B_T[mat_i*4+mat_j] = mat_j*4+mat_i+1;
			end
		end
		// Output
		for(mat_i=0;mat_i<4;mat_i=mat_i+1) begin
			for(mat_j=0;mat_j<4;mat_j=mat_j+1) begin
				mat_output[mat_i*4+mat_j] = 0;
				for(mat_k=0;mat_k<4;mat_k=mat_k+1) begin
					mat_output[mat_i*4+mat_j] = mat_output[mat_i*4+mat_j] + mat_A[mat_k] * mat_B_T[mat_j*4+mat_k];
				end
			end
		end
		// for(mat_i=0;mat_i<16;mat_i=mat_i+1) begin
		// 	$display("mat_output[%d] = %d", mat_i, mat_output[mat_i]);
		// end
	end

	// qsort
	integer qsort_input[9:0];
	integer qsort_output[9:0];
	initial begin
		// Input
		qsort_input[0] =  893;
		qsort_input[1] =   40;
		qsort_input[2] = 3233;
		qsort_input[3] = 4267;
		qsort_input[4] = 2669;
		qsort_input[5] = 2541;
		qsort_input[6] = 9073;
		qsort_input[7] = 6023;
		qsort_input[8] = 5681;
		qsort_input[9] = 4622;
		// Output
		qsort_output[0] =   40;
		qsort_output[1] =  893;
		qsort_output[2] = 2541;
		qsort_output[3] = 2669;
		qsort_output[4] = 3233;
		qsort_output[5] = 4267;
		qsort_output[6] = 4622;
		qsort_output[7] = 5681;
		qsort_output[8] = 6023;
		qsort_output[9] = 9073;
	end

	task fir;
	begin
		// FIR
		wait(checkbits == 16'hAB00);
		$display("Test start - FIR");
		wait(checkbits == 16'hAB01);
		$display("Test end   - FIR");
	end
	endtask

	reg [6:0] fir_chk_i;
	task fir_check;
	begin
		// FIR
		wait(checkbits == 16'hAB30);
		$display("Test check start - FIR");
		wait(checkbits != 16'hAB30);
		for(fir_chk_i=0;fir_chk_i<64;fir_chk_i=fir_chk_i+1) 
		begin
			wait(checkbits==fir_output[fir_chk_i][31:16]);
			$display("ans[31:16] = %6d, golden ans[31:16] = %6d", checkbits, fir_output[fir_chk_i][31:16]);
			wait(checkbits==fir_output[fir_chk_i][15:0]);
			$display("ans[15:0]  = %6d, golden ans[15:0]  = %6d", checkbits, fir_output[fir_chk_i][15:0]);
			$display("FIR passed - pattern #%2d", fir_chk_i);
		end
		wait(checkbits == 16'hAB31);
		$display("Test check end   - FIR");
	end
	endtask


	task matmul;
	begin
		// Matrix Multiplication
		wait(checkbits == 16'hAB10);
		$display("Test start - matmul");
		wait(checkbits == 16'hAB11);
		$display("Test end   - matmul");
	end
	endtask

	reg [6:0] mat_chk_i;
	task matmul_check;
	begin
		// Matrix Multiplication
		wait(checkbits == 16'hAB40);
		$display("Test check start - matmul");
		for(mat_chk_i=0;mat_chk_i<16;mat_chk_i=mat_chk_i+1) 
		begin
			wait(checkbits==mat_output[mat_chk_i]);
			$display("ans = %2d, golden ans = %2d", checkbits, mat_output[mat_chk_i]);
			$display("matmul passed - pattern #%02d", mat_chk_i);
		end
		wait(checkbits == 16'hAB41);
		$display("Test check end   - matmul");
	end
	endtask
	
	task qsort;
	begin
		// Quick Sort
		wait(checkbits == 16'hAB20);
		$display("Test start - qsort");
		wait(checkbits == 16'hAB21);
		$display("Test end   - qsort");
	end
	endtask

	reg [6:0] qsort_chk_i;
	task qsort_check;
	begin
		// Quick Sort
		wait(checkbits == 16'hAB50);
		$display("Test check start - qsort");
		for(qsort_chk_i=0;qsort_chk_i<10;qsort_chk_i=qsort_chk_i+1) 
		begin
			wait(checkbits==qsort_output[qsort_chk_i]);
			$display("ans = %4d, golden ans = %4d", checkbits, qsort_output[qsort_chk_i]);
			$display("qsort passed - pattern #%1d", qsort_chk_i);
		end
		wait(checkbits == 16'hAB51);
		$display("Test check end   - qsort");
	end
	endtask

	task send_data(input [7:0] data);
	begin
		tx_start = 1;
		tx_data = data;
		wait(tx_busy); // wait for transmission start
		wait(!tx_busy); // wait for transmission complete
		tx_start = 0;
		$display("tx complete - data: 8'd%03d, 8'h%02x", data, data);
	end 
	endtask

	initial begin
		RSTB <= 1'b0;
		CSB  <= 1'b1;		// Force CSB high
		#2000;
		RSTB <= 1'b1;	    	// Release reset
		#170000;
		CSB = 1'b0;		// CSB can be released
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		#200;
		power1 <= 1'b1;
		#200;
		power2 <= 1'b1;
	end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD1V8;
	wire VDD3V3;
	wire VSS;
    
	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	assign mprj_io[3] = 1;  // Force CSB high.
	assign mprj_io[0] = 0;  // Disable debug mode

	caravel uut (
		.clock    (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("main.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

	// Testbench UART
	tbuart tbuart (
		.ser_rx(uart_tx),
		.tx_start(tx_start),
		.ser_tx(uart_rx),
		.tx_data(tx_data),
		.tx_busy(tx_busy),
		.tx_clear_req(tx_clear_req)
	);

endmodule
`default_nettype wire
