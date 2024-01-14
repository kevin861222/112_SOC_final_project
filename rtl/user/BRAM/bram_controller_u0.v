/* BRAM Controler 
Bram latency = 10 T 
burst = no
continuous read / write = yes
*/

module bram_controller_u0 (
/* From Sysytem */
input clk ,
input rst ,

/* From Arbiter */
input WR ,
input In_valid , 
input [12:0] Addr ,
input [31:0] Di ,
input reader_sel , // 2'b00:DMA 2'b01:CPU 2'b10:Pred_cache
/*if add predict FIFO
input [1:0] reader_sel ,*/

/* To DMA */
output dma_in_valid ,

/* To CPU cache */
output wbs_ack_o_brc_u0 ,

/* To DMA or CPU cache */
output [31:0] Do //
);
/*----------------------------------------------------------------------*/ 
// Task bay
reg [12:0]  Task_bay_addr   [0:8] ;
reg         Task_bay_rw     [0:8] ;
reg  [0:8]  Task_bay_valid        ;
reg [31:0]  Task_bay_data   [0:8] ;
reg [0:8]   Task_bay_sel          ; // 2'b00:DMA 2'b01:CPU 2'b10:Pred_cache
// pointer 
reg [3:0]   pointer ;
// Out valid 
reg Out_valid_q , Out_valid_d ; 

/*----------------------------------------------------------------------*/ 
/* Task bay 
To simulate 10 T delay ,
the requests will put on the bay first.
Then after 10 T , memory acts . 
The bay has a pointer , it moves every cycle .
The bay has 9 buffers . */
always @(posedge clk or posedge rst) begin
    if (rst) begin
        Task_bay_valid <= 10'd0 ;
    end else begin
        Task_bay_sel    [pointer] <= reader_sel ;
        Task_bay_addr   [pointer] <= Addr ;
        Task_bay_rw     [pointer] <= WR ;
        Task_bay_valid  [pointer] <= In_valid ;
        Task_bay_data   [pointer] <= Di ;
    end
end
/*---------------------------------------------------------------------*/
/*  Pointer 
    Every cycle + 1 */
always @( posedge clk or posedge rst ) begin
    if (rst) begin
        pointer <= 0 ; 
    end else begin
        if (pointer == 4'd8) begin
            pointer <= 0 ; 
        end else begin
            pointer <= pointer + 1 ;
        end
    end
end
/*---------------------------------------------------------------------*/
/* Signal to Bram */
wire WE ;
assign WE = Task_bay_rw[pointer];
wire EN ;
assign EN = Task_bay_valid[pointer];
wire [31:0] bram_Di  ; 
assign bram_Di = Task_bay_data[pointer] ;
wire [12:0] A ;
assign A = Task_bay_addr[pointer] ;
bram bram_u0 (
    .CLK(clk),
    /* To bram */
    .WE(WE),
    .EN(EN),
    .Di(bram_Di),
    .A(A),
    /* From bram */
    .Do(Do)
);
/*---------------------------------------------------------------------*/
/* Output Valid */
always @(posedge clk or posedge rst) begin
    if (rst) begin
        Out_valid_q <= 0 ;
    end else begin 
        Out_valid_q <= Out_valid_d ;
    end
end
always @(*) begin
    // when a valid read assert , out valid = 1 .
    Out_valid_d = ~Task_bay_rw[pointer] & Task_bay_valid[pointer] ; 
end
// 有分 Bank 理當可以用地址判斷，但我先用比較簡單的方法實現，我直接用Arbiter告訴controller這是誰給的 Read request
// wire IsDataForCache , IsDataForDMA ;
reg IsDataForCPU_d , IsDataForCPU_q , IsDataForDMA_d , IsDataForDMA_q ;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        IsDataForCPU_q <= 0 ;
        IsDataForDMA_q <= 0 ;
    end else begin
        IsDataForCPU_q <= IsDataForCPU_d ;
        IsDataForDMA_q <= IsDataForDMA_d ; 
    end
end
always @(*) begin
    IsDataForCPU_d = Task_bay_sel[pointer]==2'b01;
    IsDataForDMA_d = Task_bay_sel[pointer]==2'b00;
end
assign wbs_ack_o_brc_u0 = Out_valid_q & IsDataForCPU_q ;
assign dma_in_valid = Out_valid_q & IsDataForDMA_q ;

endmodule