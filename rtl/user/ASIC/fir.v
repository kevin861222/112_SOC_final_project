module fir(
    input clk,
    input rst, 
    //AXI_stream_slave
    input                       ss_tvalid, 
    input   [31:0]              ss_tdata, 
    input                       ss_tlast, 
    output  reg                 ss_tready, 
    input                       ap_start_fir,
    //out
    output reg   [31:0]         data_out,
    output reg                  w_fifo_en,
    output reg                  done_fir
);
    localparam IDLE = 2'd0,
              READ = 2'd1,
              STORE = 2'd2,
              OPER = 2'd3;

    reg ss_tready_d;
    reg [1:0] state_cs, state_ns;
    reg [5:0] counter_r_q, counter_r_d;
    reg counter_r_rst, counter_r_en;
    reg [3:0] counter_s_q, counter_s_d;
    reg counter_s_rst, counter_s_en;
    reg [31:0] tap_q [0:10];
    reg [31:0] tap_d [0:10];
    reg [31:0] shiftbuf_q [0:10];
    reg [31:0] shiftbuf_d [0:10];
    reg [31:0] multbuf [0:10];
    reg [3:0] index0, index1, index2, index3, index4, index5, index6, index7, index8, index9, index10;
    integer i;

    // always @(*) begin
    //     ss_tready_d = ((state_cs == READ) || (state_cs == STORE)) ? 1'd1 : 1'd0;
    // end

    always @(*) begin
        counter_r_rst = 1'd0;
        counter_r_en = 1'd0;
        counter_s_rst = 1'd0;
        counter_s_en = 1'd0;
        w_fifo_en = 1'd0;
        done_fir = 1'd0;
        ss_tready_d = 1'd0;
        for(i=0; i<11; i=i+1) shiftbuf_d[i] = shiftbuf_q[i];
        for(i=0; i<11; i=i+1) tap_d[i] = tap_q[i];

        case(state_cs)
            IDLE: begin
                if(ap_start_fir) begin
                    ss_tready_d = 1'd1;
                    state_ns = READ;
                end
                else begin
                    state_ns = IDLE;
                end
            end
            READ: begin
                ss_tready_d = 1'd1;
                if(ss_tready && ss_tvalid) begin
                    counter_r_en = 1'd1;
                    tap_d[counter_r_q] = ss_tdata;

                    if(counter_r_q == 10) begin
                        counter_r_rst = 1'd1;
                        state_ns = STORE;                        
                    end
                    else 
                        state_ns = READ;
                end
                else begin
                    state_ns = READ;
                end            
            end
            STORE: begin
                if(ss_tready && ss_tvalid) begin
                    counter_s_en = 1'd1;
                    shiftbuf_d[counter_s_q] = ss_tdata;
 
                    state_ns = OPER;
                end
                else begin
                    ss_tready_d = 1'd1;
                    state_ns = STORE;
                end  
            end
            OPER: begin
                w_fifo_en = 1'd1;
                counter_r_en = 1'd1;

                multbuf[0] = shiftbuf_d[index0];
                multbuf[1] = shiftbuf_d[index1];
                multbuf[2] = shiftbuf_d[index2];
                multbuf[3] = shiftbuf_d[index3];
                multbuf[4] = shiftbuf_d[index4];
                multbuf[5] = shiftbuf_d[index5];
                multbuf[6] = shiftbuf_d[index6];
                multbuf[7] = shiftbuf_d[index7];
                multbuf[8] = shiftbuf_d[index8];
                multbuf[9] = shiftbuf_d[index9];
                multbuf[10] = shiftbuf_d[index10];

                if(counter_r_q == 63) begin
                    counter_s_rst = 1'd1;
                    counter_r_rst = 1'd1;
                    done_fir = 1'd1;
                    state_ns = IDLE;
                end
                else begin
                    ss_tready_d = 1'd1;
                    state_ns = STORE;
                end
            end
            default: state_ns = IDLE;
        endcase
    end
    always @(*) begin
        index0 = ((counter_s_q + 4'd1) > 10) ?   4'd0                 : (counter_s_q + 4'd1);
        index1 = ((counter_s_q + 4'd2) > 10) ?   (counter_s_q - 4'd9) : (counter_s_q + 4'd2);
        index2 = ((counter_s_q + 4'd3) > 10) ?   (counter_s_q - 4'd8) : (counter_s_q + 4'd3);
        index3 = ((counter_s_q + 4'd4) > 10) ?   (counter_s_q - 4'd7) : (counter_s_q + 4'd4);
        index4 = ((counter_s_q + 4'd5) > 10) ?   (counter_s_q - 4'd6) : (counter_s_q + 4'd5);
        index5 = ((counter_s_q + 4'd6) > 10) ?   (counter_s_q - 4'd5) : (counter_s_q + 4'd6);
        index6 = ((counter_s_q + 4'd7) > 10) ?   (counter_s_q - 4'd4) : (counter_s_q + 4'd7);
        index7 = ((counter_s_q + 4'd8) > 10) ?   (counter_s_q - 4'd3) : (counter_s_q + 4'd8);
        index8 = ((counter_s_q + 4'd9) > 10) ?   (counter_s_q - 4'd2) : (counter_s_q + 4'd9);
        index9 = ((counter_s_q + 4'd10) > 10) ?   (counter_s_q - 4'd1) : (counter_s_q + 4'd10);
        index10 = ((counter_s_q + 4'd11) > 10) ?   (counter_s_q)       : (counter_s_q + 4'd11);
    end

    always @(*) begin
        data_out = (tap_q[0]*multbuf[0]) + (tap_q[1]*multbuf[1]) + (tap_q[2]*multbuf[2]) + (tap_q[3]*multbuf[3]) + (tap_q[4]*multbuf[4]) + (tap_q[5]*multbuf[5]) + (tap_q[6]*multbuf[6]) + (tap_q[7] * multbuf[7]) + (tap_q[8] * multbuf[8]) + (tap_q[9] * multbuf[9]) + (tap_q[10] * multbuf[10]);
    end

    always @(*) begin   //counter_r_q
        if(counter_r_rst)
            counter_r_d = 6'd0;
        else if(counter_r_en)
            counter_r_d = counter_r_q + 1;
        else 
            counter_r_d = counter_r_q;
    end
    always @(*) begin //store position counter
        if(counter_s_rst)
            counter_s_d = 6'd10;
        else if(counter_s_en) begin
            if(counter_s_q == 6'd0)
                counter_s_d = 6'd10;
            else
                counter_s_d = counter_s_q - 1;
        end
        else 
            counter_s_d = counter_s_q; 
    end

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            ss_tready <= 1'd0;
            state_cs <= 2'd0;
            counter_r_q <= 6'd0;
            counter_s_q <= 6'd10;
            for(i=0; i<11; i=i+1) shiftbuf_q[i] <= 32'd0;
            for(i=0; i<11; i=i+1) tap_q[i] <= 32'd0;
        end
        else begin
            ss_tready <= ss_tready_d;
            state_cs <= state_ns;
            counter_r_q <= counter_r_d;
            counter_s_q <= counter_s_d;
            for(i=0; i<11; i=i+1) shiftbuf_q[i] <= shiftbuf_d[i];
            for(i=0; i<11; i=i+1) tap_q[i] <= tap_d[i];
        end
    end

endmodule

