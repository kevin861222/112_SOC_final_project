// FIFO size only 32bits
// 如果確定只有32 bit 可以把 output reg 跟 FIFO reg 共用
module data_FIFO (
    /* System */
    input clk , 
    input rst ,

    /* To arbiter */
    output abt_full_n ,

    /* From controller */
    input brc_in_valid ,
    input [31:0] Di ,

    /* From WB bus */
    // Wishbone Slave ports
    input wbs_stb_i ,
    input wbs_cyc_i ,
    input wbs_we_i ,
    // input [3:0] wbs_sel_i ,
    input [31:0] wbs_dat_i ,
    input [31:0] wbs_adr_i ,
    
    /* To WB bus */
    output wbs_ack_o ,
    output [31:0] wbs_dat_o 
);
wire IsAcessFIFO ;
wire Isu1addr ;
assign Isu1addr = &(wbs_adr_i[14:12]);
assign IsAcessFIFO = (wbs_stb_i & wbs_cyc_i & ~wbs_we_i & Isu1addr ) ;

reg [31:0] FIFO_reg ;
reg full ;
assign abt_full_n = ~full ;

reg wbs_ack_q ;
reg [31:0] wbs_dat_o_q ;
assign wbs_ack_o = wbs_ack_q ;
assign wbs_dat_o = wbs_dat_o_q ;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        full <= 0 ;
        wbs_ack_q <= 0 ;
        wbs_dat_o_q <= 32'd0 ;
    end else if (brc_in_valid) begin
        FIFO_reg <= Di ;
        full <= 1 ;
    end else if (IsAcessFIFO) begin
        wbs_ack_q <= 1 ;
        wbs_dat_o_q <= FIFO_reg ;
        full <= 0 ;
    end else begin
        wbs_ack_q <= 0 ;
        wbs_dat_o_q <= 32'd0 ;
    end
end
    
endmodule