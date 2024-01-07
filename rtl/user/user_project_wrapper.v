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
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

// DMA
wire [1:0]dma_burst;
wire dma_rw;
wire dma_in_valid;
wire [12:0] dma_addr;
wire ack_from_abt , ack_from_ctr ;
wire [31:0] dma_data_out;
wire [31:0] dma_data_in;

// Arbiter
wire wbs_cache_miss;

// BRAM
wire bram_in_valid;
wire bram_data_in;
wire bram_wr;
wire bram_addr;
wire reader_sel;
wire bram_data_out ;
wire cache_in_valid ;

// ASIC
wire [2:0] ap_start_ASIC;
wire       ap_idle_ASIC;
wire [2:0] ap_done_ASIC;

// AXI-Stream (Write, DMA->ASIC)
wire        sm_tready;
wire        sm_tvalid;
wire [31:0] sm_tdata;
wire        sm_tlast;

// AXI-Stream (Read, DMA<-ASIC)
wire        ss_tvalid;
wire [31:0] ss_tdata;
wire        ss_tlast;
wire        ss_tready;

DMA_Controller DMA_Controller (
    // MGMT SoC Wishbone Slave
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_dat_o(wbs_dat_o),
    .la_data_out(la_data_out), 
    // Arbiter
    .rw(dma_rw),
    .burst(dma_burst),
    .ack(ack_from_abt|ack_from_ctr), // Wangyu : There are two ack source , from arbiter and BRAM controller .
    .addr(dma_addr),
    .in_valid(dma_in_valid), 

    .data_in(bram_data_out), // wangyu : change dma_data_in into bram_data_out
    .data_out(dma_data_in),
    // AXI-Stream (DMA->ASIC)
    .sm_tvalid(sm_tvalid), 
    .sm_tdata(sm_tdata), 
    .sm_tlast(sm_tlast), 
    .sm_tready(sm_tready), 
    // AXI-Stream (DMA<-ASIC)
    .ss_tready(ss_tready),
    .ss_tvalid(ss_tvalid), 
    .ss_tdata(ss_tdata), 
    .ss_tlast(ss_tlast)
);

Arbiter Arbiter (
    // MGMT SoC Wishbone Slave
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_we_i(wbs_we_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_ack_o(wbs_ack_o),
    // Cache -> Arbiter
    .wbs_cache_miss(wbs_cache_miss),
    // DMA
    .dma_rw(dma_rw),
    .dma_burst(dma_burst),
    .dma_ack(ack_from_abt),
    .dma_addr(dma_addr),
    .dma_data_in(dma_data_in),
    .dma_in_valid(dma_in_valid),
    // BRAM Controller
    .bram_in_valid(bram_in_valid),
    .bram_data_in(bram_data_in),
    .bram_wr(bram_wr),
    .bram_addr(bram_addr),
    .reader_sel(reader_sel)
);

instru_cache instru_cache (
    // MGMT SoC Wishbone Slave
    .clk(wb_clk_i),
    .rst(wb_rst_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_dat_o(wbs_dat_o),
    // Arbiter
    .wbs_cache_miss(wbs_cache_miss),
    // BRAM Controller
    .bram_data_in(bram_data_out),
    .bram_in_valid(cache_in_valid)
);

bram_controller bram_controller(
    // MGMT SoC Wishbone Slave
    .clk(wb_clk_i),
    .rst(wb_rst_i),
    // Arbiter
    .WR(bram_wr),
    .Addr(bram_addr),
    .reader_sel(reader_sel),
    // DMA
    .dma_ack(ack_from_ctr),
    // Arbiter
    .Di(bram_data_in),
    .In_valid(bram_in_valid),
    // Cache & DMA
    .Do(bram_data_out),
    // Cache
    .Out_valid(cache_in_valid)
);

accelerator accelerator(
    // MGMT SoC Wishbone Slave
    .clk(wb_clk_i),
    .rst(wb_rst_i),       
    // AXI-Stream (DMA->ASIC)
    .ss_tvalid(sm_tvalid), 
    .ss_tdata(sm_tdata), 
    .ss_tlast(sm_tlast), 
    .ss_tready(sm_tready), 
    // AXI-Stream (DMA<-ASIC)
    .sm_tready(ss_tready), 
    .sm_tvalid(ss_tvalid), 
    .sm_tdata(ss_tdata), 
    .sm_tlast(ss_tlast), 
    // Status
    .ap_start(ap_start),
    .ap_idle(ap_idle),
    .ap_done(ap_done)
);

endmodule	// user_project_wrapper

`default_nettype wire
