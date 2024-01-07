/*
待處理事項
1. 回把沒有用到的 FSM 砍掉
2. reg_q 有些沒有用到，可以移除
3. arbiter 和 controller 都會輸出 ack ，要到wrapper 的地方 or 起來，接到外部
*/
module Arbiter #(
    parameter CPU_Burst_Read_Lenght = 7 /*8-1*/,
    parameter DELAYS = 10
)(
    /* CPU WB --> Arbiter */
    // sent write request
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
    // output [31:0] wbs_dat_o ,

    /* CPU Cache --> Arbiter */
    // sent read miss message
    input wbs_cache_miss ,     // CPU intruction cache miss


    /* DMA --> Arbiter */
    // sent write / read request
    input dma_rw ,
    input [1:0] dma_burst ,
    input dma_in_valid ,
    input [12:0] dma_addr ,
    output dma_ack ,
    // output [31:0] dma_data_out ,
    input [31:0] dma_data_in ,

    /* Arbiter --> BRAM Controller */
    output bram_wr ,
    output bram_in_valid , 
    output [12:0] bram_addr , 
    output [31:0] bram_data_in ,
    output reader_sel // 0:DMA  1:CPU
);
/* Parameters */
reg [5:0] Read_count ; // range 0 ~ 63  
reg [2:0] Arbiter_state_q , Arbiter_state_d ;
reg [5:0] dma_burst_d /*, dma_burst_q*/ ;
reg dma_ack_d /*, dma_ack_q*/ , wbs_ack_d /*, wbs_ack_q*/ ;
assign dma_ack = dma_ack_d ;
assign wbs_ack_o = wbs_ack_d ;
reg reader_sel_d ;
assign reader_sel = reader_sel_d ;
/*--------------------------------------------------------------------------*/
/* WB valid */
wire wbs_valid ;
assign wbs_valid = wbs_cyc_i & wbs_stb_i ;
/*--------------------------------------------------------------------------*/
/* BRAM signals */
reg bram_wr_d ;
reg bram_in_valid_d ;
reg [12:0] bram_addr_d ;
reg [31:0] bram_data_in_d ;
assign bram_wr = bram_wr_d ;
assign bram_in_valid = bram_in_valid_d ;
assign bram_addr = bram_addr_d ;
assign bram_data_in = bram_data_in_d ;
/*--------------------------------------------------------------------------*/
/* Read Counter */
always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if (wb_rst_i) begin
        Read_count <= 0 ;
    end else begin
        case (Arbiter_state_q)
            /* 
            When FSM back to IDLE , counter returns to zero .
            When FSM ready to switch into read mode , counter + 1 .
            Because even FSM at IDLE state , it still process read task immediately . 

            ex : dma read , burst lenght = 10 
                0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
            clk |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
            FSM | 0| 0| 1| 1| 1| 1| 1| 1| 1| 1| 1| 0| 0| 0| 0|
            cnt | 0| 0| 1| 2| 3| 4| 5| 6| 7| 8| 9| 0| 0| 0| 0|
            ack _________________________________/‾‾‾‾‾‾‾‾‾‾‾‾
     read_valid ___/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
            */
            IDLE : Read_count <= ((wbs_valid & ~wbs_we_i & wbs_cache_miss)|(~dma_rw & dma_in_valid)) ;
            CPURead : Read_count <= Read_count + 1 ;
            DMARead : Read_count <= Read_count + 1 ;
            default : Read_count <= 0 ;
        endcase
    end
end
/*--------------------------------------------------------------------------*/
/* Arbiter FSM */
localparam  IDLE = 3'd0 ,
            DMARead = 3'd1 ,
            DMAWrite = 3'd2 ,
            CPURead = 3'd3 ,
            CPUWrite = 3'd4 ;
always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if (wb_rst_i) begin
        Arbiter_state_q <= 0 ;
    end else begin
        Arbiter_state_q <= Arbiter_state_d ;
    end
end
always @(*) begin
    case (Arbiter_state_q)
        IDLE: begin
            if (wbs_valid & ~wbs_we_i & wbs_cache_miss) begin      /*CPU Read*/
                Arbiter_state_d = CPURead ;
            end else if (~dma_rw & dma_in_valid) begin             /*DMA Read*/
                Arbiter_state_d = DMARead ;
            end else begin
                Arbiter_state_d = IDLE ;
            end
        end
        DMARead : begin 
            // occupy 'burst' cycles 
            Arbiter_state_d = (Read_count == dma_burst_d) ? (IDLE):(DMARead) ;
        end
        // DMAWrite : begin 

        // end
        CPURead : begin 
            // occupy '8' cycles
            Arbiter_state_d = (Read_count == CPU_Burst_Read_Lenght) ? (IDLE) : (DMARead) ; 
        end
        // CPUWrite : begin
        //     if (dma_rw & dma_in_valid) begin
        //         state_d = CPUWrite ;
        //     end else begin
        //         if (wbs_valid & wbs_we_i) begin                                 /*CPU Write*/
        //             state_d = CPUWrite ;
        //         end else if (dma_rw & dma_in_valid) begin                       /*DMA Write*/
        //             state_d = DMAWrite ;
        //         end else if (wbs_valid & ~wbs_we_i & wbs_cache_miss) begin      /*CPU Read*/
        //             state_d = CPURead ;
        //         end else if (~dma_rw & dma_in_valid) begin                      /*DMA Read*/
        //             state_d = DMARead ;
        //         end else begin
        //             state_d = IDLE ;
        //         end
        //     end
        // end
        default: Arbiter_state_d = IDLE ;
    endcase
end
/*--------------------------------------------------------------------------*/
/* ack‾ 
當狀態處於IDLE
如果收到 write 訊號會馬上回覆 ack
        0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
clk     |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
stb     ___/‾‾\___
cyc     ___/‾‾\___
wbs_we  ___/‾‾\___
ack     ___/‾‾\___
*/
/*--------------------------------------------------------------------------*/
/* DMA Burst Decoder*/
always @(*) begin
    case (dma_burst)
        2'b00: dma_burst_d = 10-1 ; 
        2'b01: dma_burst_d = 11-1 ; 
        2'b10: dma_burst_d = 16-1 ; 
        2'b11: dma_burst_d = 64-1 ; 
        default: dma_burst_d = 10-1 ; 
    endcase
end
/*--------------------------------------------------------------------------*/
/* Arbiter */
always @(*) begin
    reader_sel_d = 0 ;
    wbs_ack_d = 0 ;
    dma_ack_d = 0 ;
    bram_in_valid_d = 0 ;
    bram_wr_d = 0 ;
    bram_addr_d = 32'd0 ;
    bram_data_in_d = 32'd0 ;
    case (Arbiter_state_q)
        IDLE : begin
            if (wbs_valid & wbs_we_i) begin // CPU Write
                wbs_ack_d = 1 ;
                bram_wr_d = 1 ;
                bram_in_valid_d = 1 ;
                bram_data_in_d = wbs_dat_i ;
                bram_addr_d = wbs_adr_i[14:2];
            end else if (dma_rw & dma_in_valid) begin // DMA Write
                dma_ack_d = 1 ;
                bram_wr_d = 1 ;
                bram_in_valid_d = 1 ;
                bram_data_in_d = dma_data_in ;
                bram_addr_d = dma_addr ;
            end else if (wbs_valid & ~wbs_we_i & wbs_cache_miss) begin // CPU Read
                reader_sel_d = 1 ;
                bram_wr_d = 0 ;
                bram_in_valid_d = 1 ;
                bram_addr_d = wbs_adr_i[14:2] ;
            end else if (~dma_rw & dma_in_valid) begin // DMA Read 
                reader_sel_d = 1 ;
                bram_wr_d = 0 ;
                bram_in_valid_d = 1 ;
                bram_addr_d = dma_addr ;
            end else begin
                bram_in_valid_d = 0 ;
            end
        end
        DMARead : begin
            bram_wr_d = 0 ;
            bram_in_valid_d = 1 ;
            bram_addr_d = dma_addr+Read_count ;
        end
        CPURead : begin
            bram_wr_d = 0 ;
            bram_in_valid_d = 1 ;
            bram_addr_d = wbs_adr_i[14:2]+Read_count ;
        end
        default: begin
            bram_in_valid_d = 0 ;
        end
    endcase
end
endmodule