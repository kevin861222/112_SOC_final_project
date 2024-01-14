`timescale 1ns / 1ns
module accelerator(
    //system
    input clk,
    input rst,       

    //AXI_stream_slave//DMA to ACC
    input   wire                     ss_tvalid, 
    input   wire [31:0]              ss_tdata, 
    input   wire                     ss_tlast, 
    output  reg                      ss_tready, 

    input [2:0]                      ap_start,
    output reg                       ap_idle,
    //AXI_stream_master//ACC to DMA
    input   wire                     sm_tready, 
    output  reg                      sm_tvalid, 
    output  reg  [31:0]              sm_tdata, 
    output  reg                      sm_tlast, 

    output reg [2:0]                 ap_done
);
    localparam  IDLE = 2'd0,
                WAIT = 2'd1,
                SEND = 2'd2;

    reg [1:0] state_cs, state_ns;
    reg [2:0] ap_start_q, ap_start_d;
    reg ap_start_en;
    reg [5:0] counter_q, counter_d;

    wire done_fir, done_matmul, done_sorting;
    reg  ss_tvalid_fir, ss_tvalid_matmul, ss_tvalid_sorting;
    reg [31:0] ss_tdata_fir, ss_tdata_matmul, ss_tdata_sorting, din;
    reg  ss_tlast_fir, ss_tlast_matmul, ss_tlast_sorting;
    wire ss_tready_fir, ss_tready_matmul, ss_tready_sorting;
    wire [31:0] data_out_firmat, data_out_sorting;//data_out_fir, data_out_matmul
    wire w_fifo_en_fir, w_fifo_en_matmul, w_fifo_en_sorting;
    reg w_en, r_en, sm_tvalid_d, rstfifo;
    wire empty, full;
    wire [31:0] dout;

//==========FSM===========
    always @(*) begin
        ap_idle = 1'd0;
        ap_start_d = ap_start;
        ap_start_en = 1'd0;
        ap_done = 3'b000;
        counter_d = counter_q;
        rstfifo = 1'd0;
        sm_tlast = 1'd0;

        case(state_cs)
            IDLE: begin
                ap_idle = 1'd1;
                if(ap_start != 3'b000) begin 
                    ap_start_en = 1'd1;
                    state_ns = WAIT;

                    if(ap_start == 3'b001) begin
                        counter_d = 6'd63;
                    end
                    else if(ap_start == 3'b010) begin
                        counter_d = 6'd15;
                    end
                    else if(ap_start == 3'b100) begin
                        counter_d = 6'd9;
                    end
                    else begin
                        counter_d = 6'd0;
                    end
                end
                else begin
                    ap_start_d = 2'd0;
                    state_ns = IDLE;
                end
            end
            WAIT: begin
                if(ap_start_q == 3'b001) begin
                    ss_tvalid_fir = ss_tvalid;
                    ss_tdata_fir = ss_tdata;
                    ss_tlast_fir = ss_tlast;

                    if(done_fir) begin
                        ap_done = 3'b001;
                    end
                    else
                        ap_done = 3'b000;
                end
                else if(ap_start_q == 3'b010) begin
                    ss_tvalid_matmul = ss_tvalid;
                    ss_tdata_matmul = ss_tdata;
                    ss_tlast_matmul = ss_tlast;

                    if(done_matmul) begin
                        ap_done = 3'b010;
                    end
                    else
                        ap_done = 3'b000;                 
                end
                else if(ap_start_q == 3'b100) begin
                    ss_tvalid_sorting = ss_tvalid;
                    ss_tdata_sorting = ss_tdata;
                    ss_tlast_sorting = ss_tlast;

                    if(done_sorting) begin
                        ap_done = 3'b100;
                    end
                    else
                        ap_done = 3'b000;                   
                end
                else begin
                    state_ns = WAIT;
                end

                if(sm_tvalid) begin
                    counter_d = counter_q - 6'd1;
                    if((counter_q == 0) && empty) begin
                        ap_start_en = 1'd1;
                        ap_start_d = 3'd0;
                        rstfifo = 1'd1;
                        sm_tlast = 1'd1;
                        state_ns = IDLE;
                    end
                    else begin
                        state_ns = WAIT;
                    end
                end
                else begin
                    counter_d = counter_q;
                    state_ns = WAIT;
                end
            end
            default: state_ns = IDLE;
        endcase
    end
    
    always @(posedge clk, posedge rst) begin
        if(rst)
            ap_start_q <= 3'd0;
        else if(ap_start_en)
            ap_start_q <= ap_start_d;
        else 
            ap_start_q <= ap_start_q;
    end
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state_cs <= 2'd0;
            counter_q <= 6'd0;
            sm_tvalid <= 1'd0;
        end
        else begin
            state_cs <= state_ns; 
            counter_q <= counter_d;
            sm_tvalid <= sm_tvalid_d;
        end
    end
//==========MUX===========
    always @(*) begin
        case(ap_start_q)
            3'b001: begin
                ss_tready = ss_tready_fir;
                din = data_out_firmat;
                w_en = w_fifo_en_fir;
            end
            3'b010: begin
                ss_tready = ss_tready_matmul;
                din = data_out_firmat;
                w_en = w_fifo_en_matmul;
            end
            3'b100: begin
                ss_tready = ss_tready_sorting;
                din = data_out_sorting;
                w_en = w_fifo_en_sorting;
            end
            default: begin
                ss_tready = 1'd0;
                din = 32'd0;
                w_en = 1'd0;
            end
        endcase
    end
//==========SM===========
    always @(*) begin
        sm_tdata = dout;
        sm_tvalid_d = ~empty & sm_tready;
        r_en = sm_tready;
    end
//==========output FIFO===========
    synchronous_fifo 
    #(.DEPTH(65), .DATA_WIDTH(32))
    U_sync_fifo(
        .clk(clk),
        .rst(rst),
        .r_en(r_en),
        .w_en(w_en),
        .empty(empty),
        .full(full),
        .data_in(din),
        .data_out(dout),
        .rstfifo(rstfifo)
    );
//========fir/matmul/sorting=======
    firmat U_firmat(
        .clk(clk),
        .rst(rst), 
        .acc_ap_start_q(ap_start_q[1:0]),
        .fir_ss_tvalid(ss_tvalid_fir), 
        .fir_ss_tdata(ss_tdata_fir), 
        .fir_ss_tlast(ss_tlast_fir), 
        .fir_ss_tready(ss_tready_fir), 
        .ap_start_fir(ap_start[0]),
        .firmat_data_out(data_out_firmat), 
        .fir_w_fifo_en(w_fifo_en_fir),
        .done_fir(done_fir),
        .mat_ss_tvalid(ss_tvalid_matmul), 
        .mat_ss_tdata(ss_tdata_matmul), 
        .mat_ss_tlast(ss_tlast_fir), 
        .mat_ss_tready(ss_tready_matmul), 
        .ap_start_matmul(ap_start[1]),
        .mat_w_fifo_en(w_fifo_en_matmul),
        .done_matmul(done_matmul)
    );
    sorting U_sorting(
        .clk(clk),
        .rst(rst), 
        .ss_tvalid(ss_tvalid_sorting), 
        .ss_tdata(ss_tdata_sorting), 
        .ss_tlast(ss_tlast_sorting), 
        .ss_tready(ss_tready_sorting), 
        .ap_start_sorting(ap_start[2]),
        .data_out(data_out_sorting),
        .w_fifo_en(w_fifo_en_sorting),
        .done_sorting(done_sorting)
    );

endmodule