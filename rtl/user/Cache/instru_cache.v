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
    // input [31:0] wbs_dat_i ,
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
wire valid ;
assign valid = wbs_stb_i & wbs_cyc_i ;

/*---------------------------------------------------------------------------*/
/* output_counter */
reg [2:0] output_counter ;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        output_counter <= 0 ;
    end else begin
        output_counter <= output_counter + wbs_ack_o ;
    end
end

/*---------------------------------------------------------------------------*/
/* n_empty */
reg n_empty ;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        n_empty <= 0 ;
    end else begin
        n_empty <= (bram_in_valid) ? (1) : (n_empty) ;
    end
end


/*---------------------------------------------------------------------------*/
/* Addr Origin */
reg [9:0] addr_origin ;
always @(posedge bram_in_valid) begin
    addr_origin <=  wbs_adr_i[14:5] ;
end

/*---------------------------------------------------------------------------*/
/* HIT and MISS */
wire HIT , MISS ;
assign wbs_cache_miss = MISS ;
assign MISS = valid & ~wbs_we_i & ~cache_state_d & (wbs_adr_i [31:16]==16'h3800) & ~(&wbs_adr_i[14:12]) ;
assign HIT = n_empty & (addr_origin == wbs_adr_i[14:5]) & valid & ~wbs_we_i ;

/*---------------------------------------------------------------------------*/
/* FSM */
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
            cache_state_d = (MISS) ? (READ):(IDLE);
        end 
        READ : begin
            cache_state_d = ( output_counter == CPU_Burst_Read_Lenght ) ? (IDLE):(READ);
        end
        default : begin
            cache_state_d = IDLE;
        end 
    endcase
end

reg wbs_ack_o_d ;
reg [31:0] wbs_dat_o_d ;
assign wbs_ack_o = wbs_ack_o_d ;
assign wbs_dat_o = wbs_dat_o_d ;
always @(*) begin
    if (cache_state_d) begin
        wbs_ack_o_d = bram_in_valid ;
        wbs_dat_o_d = (bram_in_valid)?bram_data_in:(0) ; 
    end else begin
        wbs_ack_o_d = 0 ;
        wbs_dat_o_d = 0 ;
    end
end

    
endmodule