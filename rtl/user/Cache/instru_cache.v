module instru_cache #(
    parameter CPU_Burst_Read_Lenght = 7 /*8-1*/
)(
    /* From system */
    input clk ,
    input rst ,

    /* From CPU */
    input wbs_stb_i ,
    input wbs_cyc_i ,
    input wbs_we_i ,
    // input [3:0] wbs_sel_i ,
    input [31:0] wbs_dat_i ,
    input [31:0] wbs_adr_i ,
    
    /* To CPU */
    output wbs_ack_o ,
    output [31:0] wbs_dat_o ,

    /* To Arbiter */
    output wbs_cache_miss ,

    /* From BRAM Controller */
    input [31:0] bram_data_in ,
    input bram_in_valid //

);
// 有效讀取就miss，讀走8筆回到IDLE
wire HIT ;
assign HIT = 0 ;
reg [31:0] cache [0:7] ;
reg [2:0] output_counter , save_counter ;
reg wbs_ack_q ; 
assign wbs_ack_o = wbs_ack_q ;
assign wbs_cache_miss =~cache_state_q & ~wbs_we_i & wbs_stb_i & wbs_cyc_i ;

localparam  IDLE = 1'd0 ,
            READ = 1'd1 ; // CPU Read data from cache 
reg cache_state_q , cache_state_d ; 
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cache_state_q <= 0 ; 
    end else begin  
        cache_state_q <= cache_state_d ;
    end
end
always @(*) begin
    case (cache_state_q)
        IDLE : begin
            cache_state_d = (HIT | bram_in_valid) ? (READ):(IDLE);
        end 
        READ : begin
            cache_state_d = ( output_counter == CPU_Burst_Read_Lenght ) ? (IDLE):(READ);
        end
        default : begin
            cache_state_d = (HIT | bram_in_valid) ? (READ):(IDLE);
        end 
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        output_counter <= 0 ;
    end else begin
        output_counter <= output_counter + wbs_ack_o ;
    end
end
always @(posedge clk or posedge rst) begin
    if (rst) begin
        wbs_ack_q <= 0 ;
    end else begin
        case (cache_state_q)
            IDLE : begin
                wbs_ack_q <= 0 ;
            end 
            READ : begin
                wbs_ack_q <= ~wbs_we_i & wbs_stb_i & wbs_cyc_i ;
            end
            default: wbs_ack_q <= 0 ;
        endcase
    end
end
always @(posedge clk or posedge rst) begin
    if (rst) begin
        save_counter <= 0 ;
    end else begin
        save_counter <= save_counter + bram_in_valid ;
    end
end

always @(posedge clk) begin
    if (bram_in_valid) begin
        cache[save_counter] <= bram_data_in ;
    end
end

    
endmodule