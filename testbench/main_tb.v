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

	reg [7:0] times;
	initial begin
		fork
			for(times=0;times<`times_rerun;times=times+1) begin
				$display("Times = %1d/%1d - Hardware", times+1, `times_rerun);
				fir;
				// matmul;
				// qsort;
			end
			
			for(times=0;times<`times_rerun;times=times+1) begin
				$display("Times = %1d/%1d - UART", times+1, `times_rerun);
				send_data(times[7:0]);
			end
		join
		$finish;
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

	task matmul;
	begin
		// Matrix Multiplication
		wait(checkbits == 16'hAB10);
		$display("Test start - matmul");
		wait(checkbits == 16'hAB11);
		$display("Test end   - matmul");
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

	task send_data(input [7:0] data);
	begin
		tx_start = 0;
		wait(!tx_busy); // wait for uart ready
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
