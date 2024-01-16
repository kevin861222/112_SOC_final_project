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
wire dma_r_ready;
wire [12:0] dma_r_addr, dma_w_addr;
wire [31:0] dma_w_data;
wire dma_r_ack;
wire dma_w_valid;
wire dma_in_valid;
wire wbs_ack_o_dma;
wire [31:0] wbs_dat_o_dma;

// Arbiter
wire wbs_cache_miss;
wire wbs_ack_o_abt;

// BRAM_u0
wire bram_u0_wr;
wire bram_u0_in_valid;
wire [12:0] bram_u0_addr;
wire [31:0] bram_u0_data_in;
wire bram_u0_reader_sel;
wire [31:0] brc_u0_data_o;

// BRAM_u1
wire bram_u1_wr;
wire bram_u1_in_valid;
wire [12:0] bram_u1_addr;
wire [31:0] bram_u1_data_in;
wire [31:0] brc_u1_data_o;

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

// Data FIFO
wire fifo_full_n;
wire wbs_ack_o_FIFO;
wire [31:0] wbs_dat_o_FIFO;

// Instruction Cache 
wire wbs_ack_o_brc_u0;
wire fifo_in_valid;
wire wbs_ack_o_cache;
wire [31:0] wbs_dat_o_cache;

// UART
wire wbs_ack_o_uart;
wire [31:0] wbs_dat_o_uart;
wire user_irq_uart;

// CPU           /*     R/W      |       R        |       R        |        RW      |      W
assign wbs_ack_o = wbs_ack_o_dma | wbs_ack_o_FIFO | wbs_ack_o_brc_u0 | wbs_ack_o_uart | wbs_ack_o_abt ;
assign wbs_dat_o = wbs_dat_o_dma | wbs_dat_o_FIFO | brc_u0_data_o | wbs_dat_o_uart;
assign user_irq = {2'b0, user_irq_uart};

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
    .wbs_ack_o(wbs_ack_o_dma),
    .wbs_dat_o(wbs_dat_o_dma),
    // AXI-Stream (DMA->ASIC)
    .sm_tvalid(sm_tvalid), 
    .sm_tdata(sm_tdata), 
    .sm_tlast(sm_tlast), 
    .sm_tready(sm_tready), 
    // AXI-Stream (DMA<-ASIC)
    .ss_tready(ss_tready),
    .ss_tvalid(ss_tvalid), 
    .ss_tdata(ss_tdata), 
    .ss_tlast(ss_tlast),

    // Memory
    // DMA Read (DMA<-Arbiter)
    .mem_r_ready(dma_r_ready),
    .mem_r_addr(dma_r_addr),
    .mem_r_ack(dma_r_ack),
    // DMA Write (DMA->Arbiter)
    .mem_w_valid(dma_w_valid),
    .mem_w_addr(dma_w_addr),
    .mem_w_data(dma_w_data),
    // BRAM Controller u0 (DMA<-BRAM Controller)
    .mem_r_valid(dma_in_valid),
    .mem_r_data(brc_u0_data_o),

    // ASIC status
    .ap_start_ASIC(ap_start_ASIC),
    .ap_idle_ASIC(ap_idle_ASIC),
    .ap_done_ASIC(ap_done_ASIC)
);

Arbiter Arbiter (
    /* CPU WB <--> Arbiter */
    // System 
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    // Wishbone Slave ports
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    // input [3:0] wbs_sel_i,
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ack_o_abt),

    /* CPU Cache <--> Arbiter */
    // .wbs_cache_miss(wbs_cache_miss),     // CPU intruction cache miss

    /* Data FIFO <--> Arbiter */
    .fifo_full_n(fifo_full_n),

    /* DMA <--> Arbiter */
    // DMA Read 
    .dma_r_ready(dma_r_ready), // it seen as read request
    .dma_r_addr(dma_r_addr),
    .dma_r_ack(dma_r_ack),
    
    // DMA Write
    .dma_w_valid(dma_w_valid), // it seen as write request
    .dma_w_addr(dma_w_addr),
    .dma_w_data(dma_w_data),

    /* Arbiter <--> BRAM Controller u0 */
    .CPU_get_data(wbs_ack_o_brc_u0),
    .bram_u0_wr(bram_u0_wr),  // 0:R 1:W
    .bram_u0_in_valid(bram_u0_in_valid), 
    .bram_u0_addr(bram_u0_addr), 
    .bram_u0_data_in(bram_u0_data_in),
    .bram_u0_reader_sel(bram_u0_reader_sel), // 0:DMA  1:CPU

    /* Arbiter <--> BRAM Controller u1 */
    .FIFO_get_data(fifo_in_valid),
    .bram_u1_wr(bram_u1_wr),  // 0:R 1:W
    .bram_u1_in_valid(bram_u1_in_valid), 
    .bram_u1_addr(bram_u1_addr), 
    .bram_u1_data_in(bram_u1_data_in) 
);

// instru_cache instru_cache (
//     // MGMT SoC Wishbone Slave
//     .clk(wb_clk_i),
//     .rst(wb_rst_i),
//     .wbs_stb_i(wbs_stb_i),
//     .wbs_cyc_i(wbs_cyc_i),
//     .wbs_we_i(wbs_we_i),
//     .wbs_adr_i(wbs_adr_i),
//     .wbs_ack_o(wbs_ack_o_cache),
//     .wbs_dat_o(wbs_dat_o_cache),
//     // Arbiter
//     .wbs_cache_miss(wbs_cache_miss),
//     // BRAM Controller u0
//     .bram_data_in(brc_u0_data_o),
//     .bram_in_valid(wbs_ack_o_brc_u0)
// );

bram_controller_u0 brc_u0 (
    /* From Sysytem */
    .clk(wb_clk_i),
    .rst(wb_rst_i),

    /* From Arbiter */
    .WR(bram_u0_wr),
    .In_valid(bram_u0_in_valid), 
    .Addr(bram_u0_addr),
    .Di(bram_u0_data_in),
    .reader_sel(bram_u0_reader_sel), // 2'b00:DMA 2'b01:CPU 2'b10:Pred_cache
    /*if add predict FIFO
    input [1:0] reader_sel,*/

    /* To DMA */
    .dma_in_valid(dma_in_valid),

    /* To CPU */
    .wbs_ack_o_brc_u0(wbs_ack_o_brc_u0),

    /* To DMA or CPU cache */
    .Do(brc_u0_data_o) //
);

bram_controller_u1 brc_u1 (
    /* From Sysytem */
    .clk(wb_clk_i),
    .rst(wb_rst_i),

    /* From Arbiter */
    .WR(bram_u1_wr),
    .In_valid(bram_u1_in_valid), 
    .Addr(bram_u1_addr),
    .Di(bram_u1_data_in),

    /* To CPU FIFO */
    .fifo_in_valid(fifo_in_valid),
    .Do(brc_u1_data_o) //
);

data_FIFO data_FIFO(
    /* System */
    .clk(wb_clk_i), 
    .rst(wb_rst_i),

    /* To arbiter */
    .abt_full_n(fifo_full_n),

    /* From controller */
    .brc_in_valid(fifo_in_valid),
    .Di(brc_u1_data_o),

    /* From WB bus */
    // Wishbone Slave ports
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    // input [3:0] wbs_sel_i,
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    
    /* To WB bus */
    .wbs_ack_o(wbs_ack_o_FIFO),
    .wbs_dat_o(wbs_dat_o_FIFO) 
);

accelerator acc_ASIC(
    // MGMT SoC Wishbone Slave
    .clk(wb_clk_i),
    .rst(wb_rst_i),       
    // AXI-Stream (ASIC<-DMA)
    .ss_tvalid(sm_tvalid), 
    .ss_tdata(sm_tdata), 
    .ss_tlast(sm_tlast), 
    .ss_tready(sm_tready), 
    // AXI-Stream (ASIC->DMA)
    .sm_tready(ss_tready), 
    .sm_tvalid(ss_tvalid), 
    .sm_tdata(ss_tdata), 
    .sm_tlast(ss_tlast), 
    // Status
    .ap_start(ap_start_ASIC),
    .ap_idle(ap_idle_ASIC),
    .ap_done(ap_done_ASIC)
);

uart uart (
    // MGMT SoC Wishbone Slave
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ack_o_uart),
    .wbs_dat_o(wbs_dat_o_uart),
    // IO ports
    .io_in  (io_in),
    .io_out (io_out),
    .io_oeb (io_oeb),
    // IRQ
    .user_irq (user_irq_uart)
);

endmodule	// user_project_wrapper

`default_nettype wire
