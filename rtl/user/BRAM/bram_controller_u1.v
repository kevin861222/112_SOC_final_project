/* BRAM Controler 
Bram latency = 10 T 
burst = no
continuous read / write = yes
*/

module bram_controller_u1 (
/* From Sysytem */
input clk ,
input rst ,

/* From Arbiter */
input WR ,
input In_valid , 
input [12:0] Addr ,
input [31:0] Di ,

/* To CPU FIFO */
output fifo_in_valid ,
output [31:0] Do //
);
assign Do = (fifo_in_valid)?(bram_Do):(0);
/*----------------------------------------------------------------------*/ 
// Pre-store
reg isFIFOrst ; 

/*----------------------------------------------------------------------*/ 
// Task bay
reg [12:0]  Task_bay_addr   [0:8] ;
reg         Task_bay_rw     [0:8] ;
reg [ 0:8]  Task_bay_valid        ;
reg [31:0]  Task_bay_data   [0:8] ;
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
        isFIFOrst <= 1 ;
    end else if (isFIFOrst) begin : pre_stroe
        isFIFOrst <= ~(In_valid & WR) ;
    end else begin
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
wire [31:0] bram_Do ;
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
    .Do(bram_Do)
);
/*---------------------------------------------------------------------*/
/* Output Valid */
always @(posedge clk or posedge rst) begin
    if (rst) begin
        Out_valid_q <= 0 ;
    end else begin 
        if (isFIFOrst) begin : Pre_store_case
            Out_valid_q <= In_valid & WR ;
        end else begin : normal_case
            Out_valid_q <= Out_valid_d ;
        end
    end
end
always @(*) begin
    // when a valid read assert , out valid = 1 .
    Out_valid_d = ~Task_bay_rw[pointer] & Task_bay_valid[pointer] ; 
end
assign fifo_in_valid = Out_valid_q ;
/* Pre-store */
endmodule