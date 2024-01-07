module matmul(
    input clk,
    input rst, 
    //AXI_stream_slave
    input                       ss_tvalid, 
    input   [31:0]              ss_tdata, 
    input                       ss_tlast, 
    output  reg                 ss_tready, 
    input                       ap_start_matmul,
    //out
    output reg   [31:0]         data_out,
    output reg                  w_fifo_en,
    output reg                  done_matmul
);

    localparam IDLE = 2'd0,
              READ = 2'd1,
              OPER = 2'd2,
              SEND = 2'd3;

    reg ss_tready_d;
    reg [1:0] state_cs, state_ns;
    reg [5:0] counter_r_q, counter_r_d;
    reg counter_r_rst, counter_r_en;
    reg [31:0] matrix_q [0:31];
    reg [31:0] matrix_d [0:31];
    reg [31:0] Aarray[0:3];
    reg [31:0] Barray[0:3];
    integer i;

    always @(*) begin
        ss_tready_d = (state_cs == READ) ? 1'd1 : 1'd0;
    end
    
    always @(*) begin
        counter_r_en = 1'd0;
        counter_r_rst = 1'd0;
        w_fifo_en = 1'd0;
        done_matmul = 1'd0;

        case(state_cs)
            IDLE: begin
                if(ap_start_matmul) begin
                    state_ns = READ;
                end
                else begin
                    state_ns = IDLE;
                end
            end
            READ: begin
                if(ss_tready && ss_tvalid) begin
                    counter_r_en = 1'd1;
                    matrix_d[counter_r_q] = ss_tdata;

                    if(counter_r_q == 31) begin
                        counter_r_rst = 1'd1;
                        state_ns = OPER;                        
                    end
                    else 
                        state_ns = READ;
                end
                else begin
                    state_ns = READ;
                end
            end
            OPER: begin
                counter_r_en = 1'd1;
                w_fifo_en = 1'd1;
                state_ns = OPER;

                case(counter_r_q) 
                    6'd0: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[0], matrix_q[1], matrix_q[2], matrix_q[3]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[16], matrix_q[17], matrix_q[18], matrix_q[19]};
                    end
                    6'd1: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[0], matrix_q[1], matrix_q[2], matrix_q[3]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[20], matrix_q[21], matrix_q[22], matrix_q[23]};
                    end
                    6'd2: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[0], matrix_q[1], matrix_q[2], matrix_q[3]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[24], matrix_q[25], matrix_q[26], matrix_q[27]};
                    end
                    6'd3: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[0], matrix_q[1], matrix_q[2], matrix_q[3]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[28], matrix_q[29], matrix_q[30], matrix_q[31]};
                    end
                    6'd4: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[4], matrix_q[5], matrix_q[6], matrix_q[7]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[16], matrix_q[17], matrix_q[18], matrix_q[19]};
                    end
                    6'd5: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[4], matrix_q[5], matrix_q[6], matrix_q[7]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[20], matrix_q[21], matrix_q[22], matrix_q[23]};
                    end
                    6'd6: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[4], matrix_q[5], matrix_q[6], matrix_q[7]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[24], matrix_q[25], matrix_q[26], matrix_q[27]};
                    end
                    6'd7: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[4], matrix_q[5], matrix_q[6], matrix_q[7]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[28], matrix_q[29], matrix_q[30], matrix_q[31]};
                    end
                    6'd8: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[8], matrix_q[9], matrix_q[10], matrix_q[11]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[16], matrix_q[17], matrix_q[18], matrix_q[19]};
                    end
                    6'd9: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[8], matrix_q[9], matrix_q[10], matrix_q[11]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[20], matrix_q[21], matrix_q[22], matrix_q[23]};
                    end
                    6'd10: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[8], matrix_q[9], matrix_q[10], matrix_q[11]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[24], matrix_q[25], matrix_q[26], matrix_q[27]};
                    end
                    6'd11: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[8], matrix_q[9], matrix_q[10], matrix_q[11]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[28], matrix_q[29], matrix_q[30], matrix_q[31]};
                    end
                    6'd12: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[12], matrix_q[13], matrix_q[14], matrix_q[15]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[16], matrix_q[17], matrix_q[18], matrix_q[19]};
                    end
                    6'd13: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[12], matrix_q[13], matrix_q[14], matrix_q[15]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[20], matrix_q[21], matrix_q[22], matrix_q[23]};
                    end
                    6'd14: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[12], matrix_q[13], matrix_q[14], matrix_q[15]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[24], matrix_q[25], matrix_q[26], matrix_q[27]};
                    end
                    6'd15: begin
                        {Aarray[0], Aarray[1], Aarray[2], Aarray[3]} = {matrix_q[12], matrix_q[13], matrix_q[14], matrix_q[15]};
                        {Barray[0], Barray[1], Barray[2], Barray[3]} = {matrix_q[28], matrix_q[29], matrix_q[30], matrix_q[31]};

                        counter_r_rst = 1'd1;
                        done_matmul = 1'd1;
                        state_ns = IDLE;
                    end
                    default: counter_r_rst = 1'd1;
                endcase
            end
            default: state_ns = IDLE;
        endcase
    end

    always @(*) begin
        data_out = (Aarray[0] * Barray[0]) + (Aarray[1] * Barray[1]) + (Aarray[2] * Barray[2]) + (Aarray[3] * Barray[3]);
    end

    always @(*) begin   //counter_r_q
        if(counter_r_rst)
            counter_r_d = 6'd0;
        else if(counter_r_en)
            counter_r_d = counter_r_q + 1;
        else 
            counter_r_d = counter_r_q;
    end

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            ss_tready <= 1'd0;
            state_cs <= 2'd0;
            counter_r_q <= 6'd0;
            for(i=0; i<32; i=i+1) matrix_q[i] <= 32'd0;
        end
        else begin
            ss_tready <= ss_tready_d;
            state_cs <= state_ns;
            counter_r_q <= counter_r_d;
            for(i=0; i<32; i=i+1) matrix_q[i] <= matrix_d[i];
        end
    end

endmodule