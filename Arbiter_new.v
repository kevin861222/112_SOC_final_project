/*
命名規則：
input 開頭為 「是誰發送的」
output 開頭為 「要傳給誰的」
wbs 例外
*/

/*待優化
1. BRAM u1 的地址不用那麼多
*/

module Arbiter #(
    parameter CPU_Burst_Read_Lenght = 7 /*8-1*/,
    parameter DELAYS = 10
)(
    /* CPU WB <--> Arbiter */
    // sent read / write request
    // System 
    input wb_clk_i ,
    input wb_rst_i ,
    // Wishbone Slave ports
    input wbs_stb_i ,
    input wbs_cyc_i ,
    input wbs_we_i ,
    // input [3:0] wbs_sel_i ,
    input [31:0] wbs_dat_i ,
    input [31:0] wbs_adr_i ,
    output wbs_ack_o ,

    /* CPU Cache <--> Arbiter */
    // sent read miss message
    input wbs_cache_miss ,     // CPU intruction cache miss

    /* Data FIFO <--> Arbiter */
    input fifo_full_n ,

    /* DMA <--> Arbiter */
    // use Stream protoco to read / write data .
    // Read / Write can be simultaneous . 
    // DMA Read 
    // input dma_addr_r , // it must access bram u0
    input dma_r_ready , // it seen as read request
    input [12:0] dma_r_addr ,
    output dma_ack ,
    
    // DMA Write
    // input dma_addr_w , // it must access bram u1
    input dma_in_valid , // it seen as write request
    input [12:0] dma_w_addr ,
    input [31:0] dma_w_data ,

    /* Arbiter <--> BRAM Controller u0 */
    output bram_u0_wr ,  // 0:R 1:W
    output bram_u0_in_valid , 
    output [12:0] bram_u0_addr , 
    output [31:0] bram_u0_data_in ,
    output bram_u0_reader_sel , // 0:DMA  1:CPU

    /* Arbiter <--> BRAM Controller u1 */
    output bram_u1_wr ,  // 0:R 1:W
    output bram_u1_in_valid , 
    output [12:0] bram_u1_addr , 
    output [31:0] bram_u1_data_in 
    // output bram_u1_reader_sel // 0:DMA  1:CPU
);

// WB bus
reg wbs_ack_d ;
assign wbs_ack_o = wbs_ack_d ;

// BRAM u0
reg bram_u0_wr_d ;
assign bram_u0_wr = bram_u0_wr_d ;
reg bram_u0_in_valid_d ;
assign bram_u0_in_valid = bram_u0_in_valid_d ; 
reg [12:0] bram_u0_addr_d ;
assign bram_u0_addr = bram_u0_addr_d ;
reg [31:0] bram_u0_data_in_d ;
assign bram_u0_data_in = bram_u0_data_in_d ;
reg bram_u0_reader_sel_d ;
assign bram_u0_reader_sel = bram_u0_reader_sel_d ;

// BRAM u1
reg bram_u1_wr_d ;
assign bram_u1_wr = bram_u1_wr_d ;
reg bram_u1_in_valid_d ;
assign bram_u1_in_valid = bram_u1_in_valid_d ; 
reg [12:0] bram_u1_addr_d ;
assign bram_u1_addr = bram_u1_addr_d ;
reg [31:0] bram_u1_data_in_d ;
assign bram_u1_data_in = bram_u1_data_in_d ;

// DMA
// Just rename
wire dma_read_request , dma_write_request ;
assign dma_read_request = dma_r_ready ;
assign dma_write_request = dma_in_valid ; 
reg dma_ack_d ;
assign dma_ack = dma_ack_d ;

// WB decoder 
wire is_u0 , is_u1;
assign is_u1 = wbs_adr_i[14]&wbs_adr_i[13]&wbs_adr_i[12];
assign is_u0 = !is_u1 ;

reg [12:0] last_wbs_read_addr ;
always @(posedge wb_clk_i) begin
    last_wbs_read_addr <= wbs_adr_i[15:2] ;
end
wire wbs_same_addr_n ;
assign wbs_same_addr_n = (last_wbs_read_addr==wbs_adr_i[15:2])?(0):(1);

/* function */
/* access BRAM u0
addr : 0x3800_0000 ~ 0x3800_6FFF
condition : CPU - W / R
            DMA - R
*/
always @(*) begin
    wbs_ack_d = 0 ; 
    bram_u0_wr_d = 0 ;
    bram_u0_in_valid_d = 0 ;
    bram_u0_addr_d = 13'd0 ; 
    bram_u0_data_in_d = 32'd0 ; 
    bram_u0_reader_sel_d = 0 ;
    dma_ack_d = 0 ;
    if (wbs_stb_i & wbs_cyc_i & wbs_we_i & ~wbs_adr_i[15]) begin :                                      CPU_Write
        wbs_ack_d = 1 ;
        bram_u0_wr_d = 1 ;
        bram_u0_in_valid_d = 1 ;
        bram_u0_addr_d = wbs_adr_i[15:2] ;
        bram_u0_data_in_d = wbs_dat_i ;
    end else if (wbs_stb_i & wbs_cyc_i & ~wbs_we_i & ~wbs_adr_i[15] & is_u0 & wbs_same_addr_n) begin :  CPU_Read
        // 地址沒切換會連續讀很多筆
        bram_u0_wr_d = 0 ;
        bram_u0_in_valid_d = 1 ;
        bram_u0_addr_d = wbs_adr_i[15:2] ;
        bram_u0_reader_sel_d = 1 ;
    end else if (dma_read_request) begin :                                                              DMA_Read
        bram_u0_wr_d = 0 ;
        bram_u0_in_valid_d = 1 ;
        bram_u0_addr_d = dma_r_addr ;
        bram_u0_reader_sel_d = 0 ;
        dma_ack_d = 1 ;
        // switch into DMA burst read mode .
    end
end
/* access BRAM u1
addr : 0x3800_7000 ~ 0x3800_7FFF
condition : CPU - R
            DMA - W
*/
always @(*) begin

    bram_u1_wr_d = 0 ;
    bram_u1_in_valid_d = 0 ;
    bram_u1_addr_d = 13'd0 ;
    bram_u1_data_in_d = 32'd0 ; 
    if (dma_write_request) begin : DMA_Write
        bram_u1_wr_d = 1 ;
        bram_u1_in_valid_d = 1 ;
        bram_u1_addr_d = dma_w_addr ;
        bram_u1_data_in_d = dma_w_data ;
    end else if (wbs_stb_i & wbs_cyc_i & ~wbs_we_i & ~wbs_adr_i[15] & is_u1 & wbs_same_addr_n ) begin : CPU_Read
        bram_u1_wr_d = 0 ;
        bram_u1_in_valid_d = 1 ;
        bram_u1_addr_d = wbs_adr_i[15:2] ;
    end
end

endmodule