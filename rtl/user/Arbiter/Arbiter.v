/*
命名規則：
input 開頭為 「是誰發送的」
output 開頭為 「要傳給誰的」
wbs 例外
*/

/*待優化
1. BRAM u0 / u1 的地址不用那麼多，看到時候算完的資料有多大在優化
2. cache FIFO 看多久讀一次決定大小。
3. 把 bram 地址改用 define 參數
4. DMA 讀資料會不會被 CPU 讀取要求中斷
5. 調整 BRAM 大小
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
    // input wbs_cache_miss ,     // CPU intruction cache miss

    /* Data FIFO <--> Arbiter */
    input fifo_full_n ,

    /* DMA <--> Arbiter */
    // use Stream protoco to read / write data .
    // Read / Write can be simultaneous . 
    // DMA Read 
    input dma_r_ready , // it seen as read request
    input [12:0] dma_r_addr ,
    output dma_r_ack ,
    
    // DMA Write
    input dma_w_valid , // it seen as write request
    input [12:0] dma_w_addr ,
    input [31:0] dma_w_data ,

    /* Arbiter <--> BRAM Controller u0 */
    input CPU_get_data ,
    output bram_u0_wr ,  // 0:R 1:W
    output bram_u0_in_valid , 
    output [12:0] bram_u0_addr , 
    output [31:0] bram_u0_data_in ,
    output bram_u0_reader_sel , // 0:DMA  1:CPU

    /* Arbiter <--> BRAM Controller u1 */
    input FIFO_get_data ,
    output bram_u1_wr ,  // 0:R 1:W
    output bram_u1_in_valid , 
    output [12:0] bram_u1_addr , 
    output [31:0] bram_u1_data_in 
    // output bram_u1_reader_sel // 0:DMA  1:CPU
);

// WB bus
reg wbs_ack_d ;
assign wbs_ack_o = wbs_ack_d ;
wire cpu_read_request ;
wire cpu_read_valid ;
assign cpu_read_valid = wbs_stb_i & wbs_cyc_i & (~wbs_we_i) ;

assign cpu_read_request = cpu_read_valid & ((wbs_adr_i[15:12]==4'h1) | (wbs_adr_i[15:12]==4'h2)) & (wbs_adr_i[31:24]==8'h38) & (wbs_adr_i[4:0]==5'd0);

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
assign dma_write_request = dma_w_valid ; 
reg dma_r_ack_d ;
assign dma_r_ack = dma_r_ack_d ;

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

// CPU_read_counter
reg CPU_read_flag_d ;
reg FIFO_read_flag_d , FIFO_read_flag_q;
always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if (wb_rst_i) begin
        FIFO_read_flag_q <= 0 ;
    end else begin
        FIFO_read_flag_q <= FIFO_read_flag_d ;
    end
end
reg [12:0] FIFO_counter ;
reg [2:0] CPU_read_counter ;
always @(posedge wb_rst_i or posedge wb_clk_i) begin
    if (wb_rst_i) begin
        FIFO_counter <= 0 ;
        CPU_read_counter <= 0 ;
    end else begin
        CPU_read_counter <= CPU_read_counter + CPU_read_flag_d ;
        FIFO_counter <= FIFO_counter + FIFO_get_data ;
    end
end

reg same_addr_flag_d , same_addr_flag_q ;
always @(posedge wb_clk_i or posedge wb_rst_i ) begin
    if (wb_rst_i) begin
        same_addr_flag_q <= 0 ;
    end else begin
        same_addr_flag_q <= same_addr_flag_d ;
    end
end

/* function */
/* access BRAM u0
Contents : CPU Instruction / BSS / Raw Data
Addr : 0x3800_0000 ~ 0x3800_6FFF
Condition : CPU - W / R
            DMA - R
*/
always @(*) begin
    if (same_addr_flag_q) begin : CPU_Read_Request_is_been_processed
        same_addr_flag_d = CPU_get_data ? (0):(1) ;
    end else begin
        same_addr_flag_d = 0 ;
    end
    CPU_read_flag_d = 0 ;
    wbs_ack_d = 0 ; 
    bram_u0_wr_d = 0 ;
    bram_u0_in_valid_d = 0 ;
    bram_u0_addr_d = 13'd0 ; 
    bram_u0_data_in_d = 32'd0 ; 
    bram_u0_reader_sel_d = 0 ;
    dma_r_ack_d = 0 ;
    
    if (wbs_stb_i & wbs_cyc_i & wbs_we_i & ~wbs_adr_i[15]) begin :          CPU_Write_u0
        wbs_ack_d = 1 ;
        bram_u0_wr_d = 1 ;
        bram_u0_in_valid_d = 1 ;
        bram_u0_addr_d = wbs_adr_i[15:2] ;
        bram_u0_data_in_d = wbs_dat_i ;
    end else if (dma_read_request) begin :                                  DMA_Read_u0
        bram_u0_wr_d = 0 ;
        bram_u0_in_valid_d = 1 ;
        bram_u0_addr_d = dma_r_addr ;
        bram_u0_reader_sel_d = 0 ;
        dma_r_ack_d = 1 ;
        // switch into DMA burst read mode .
    end else if (|CPU_read_counter) begin:                                      CPU_Burst_Read_Instruction
        CPU_read_flag_d = 1 ;
        bram_u0_wr_d = 0 ;
        bram_u0_in_valid_d = 1 ;
        bram_u0_addr_d = wbs_adr_i[15:2] + CPU_read_counter ;
        bram_u0_reader_sel_d = 1 ;
    end else if ( cpu_read_request & ~same_addr_flag_q ) begin :                                  CPU_Read_u0
        /*wbs_stb_i & wbs_cyc_i & ~wbs_we_i & ~wbs_adr_i[15] & is_u0 &*/
        same_addr_flag_d = 1 ;
        CPU_read_flag_d = 1 ;
        bram_u0_wr_d = 0 ;
        bram_u0_in_valid_d = 1 ;
        bram_u0_addr_d = wbs_adr_i[15:2] ;
        bram_u0_reader_sel_d = 1 ;
    end /*else if () begin : Predict_FIFO_Read

    end*/ else begin : IDLE_task
        bram_u0_in_valid_d = 0 ;
    end
end
/* access BRAM u1
Contents : Processed Data
Addr : 0x3800_7000 ~ 0x3800_7FFF
Condition : CPU - R 
            DMA - W 
*/
always @(*) begin
    if (FIFO_get_data) begin
        FIFO_read_flag_d = 0;
    end
    else begin
        FIFO_read_flag_d = FIFO_read_flag_q;
    end
    bram_u1_wr_d = 0 ;
    bram_u1_in_valid_d = 0 ;
    bram_u1_addr_d = 13'd0 ;
    bram_u1_data_in_d = 32'd0 ; 
    if (dma_write_request) begin : DMA_Write_u1
    // first 10th data will directly write into FIFO
        bram_u1_wr_d = 1 ;
        bram_u1_in_valid_d = 1 ;
        bram_u1_addr_d = dma_w_addr ;
        bram_u1_data_in_d = dma_w_data ;
    end else if (fifo_full_n & (~FIFO_read_flag_q)) begin : CPU_Read_u1
    /*wbs_stb_i & wbs_cyc_i & ~wbs_we_i & ~wbs_adr_i[15] & is_u1 & wbs_same_addr_n*/
        FIFO_read_flag_d = 1;
        bram_u1_wr_d = 0 ;
        bram_u1_in_valid_d = 1 ;
        bram_u1_addr_d = /*offset =*/13'd0 + FIFO_counter ;//wbs_adr_i[15:2] ;
    end
end

endmodule