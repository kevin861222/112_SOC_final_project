module sorting(
    input clk,
    input rst, 
    //AXI_stream_slave
    input                       ss_tvalid, 
    input   [31:0]              ss_tdata, 
    input                       ss_tlast, 
    output  reg                 ss_tready, 
    input                       ap_start_sorting,
    //out
    output reg   [31:0]         data_out,
    output reg                  w_fifo_en,
    output reg                  done_sorting
);

localparam IDLE = 2'd0;
localparam READ = 2'd1;
localparam OPER = 2'd2;
localparam OUT = 2'd3;

// AXI-stream
reg ss_tready_d;

reg [1:0] state_d, state_q;
// reg [31:0] arr_d [0:9];
// reg [31:0] arr_q [0:9];
reg [31:0] arr [0:9];
reg [3:0] counter_r_q, counter_r_d;
reg counter_r_rst, counter_r_en;

integer i;

wire done;
reg sort_idx;
reg [3:0] sort_cnt;

always @(*) begin
    if (state_q == READ)
        ss_tready_d = 1'd1;
    else
        ss_tready_d = 1'd0;
end

always @(*) begin
    counter_r_rst = 1'd0;
    counter_r_en = 1'd0;
    w_fifo_en = 1'd0;
    done_sorting = 1'd0;

    case (state_q)
        IDLE: begin
            if (ap_start_sorting) begin
                state_d = READ;
            end
            else begin
                state_d = IDLE;
            end
        end
        READ: begin
            if(ss_tready && ss_tvalid) begin
                counter_r_en = 1'd1;
                arr[counter_r_q] = ss_tdata;

                if(counter_r_q == 9) begin
                    counter_r_rst = 1'd1;
                    state_d = OPER;                        
                end
                else 
                    state_d = READ;
            end
            else begin
                state_d = READ;
            end
        end
        OPER: begin
            if (done)
                state_d = OUT;
            else
                state_d = OPER;
        end
        OUT: begin 
            w_fifo_en = 1;
            counter_r_en = 1'd1;
            if (counter_r_q == 9) begin
                counter_r_rst = 1'd1;
                done_sorting = 1'd1;
                state_d = IDLE;
            end
            else
                state_d = OUT;
        end
    endcase
end

always @(*) begin   //counter_r_q
    if(counter_r_rst)
        counter_r_d = 4'd0;
    else if(counter_r_en)
        counter_r_d = counter_r_q + 1;
    else 
        counter_r_d = counter_r_q;
end

////// sort //////
assign done = (sort_cnt == 10);

always@(posedge clk or posedge rst) begin
    if(rst)
        sort_idx <= 0;
    else if(state_q == OPER)
        sort_idx <= ~sort_idx;
    else
        sort_idx <= 0;
end
       
always@(posedge clk or posedge rst) begin
    if(rst)
        sort_cnt <= 0;
    else if(state_q == OPER)
        sort_cnt <= (sort_cnt == 10) ? 0 : sort_cnt+1;
end

always@(posedge clk or posedge rst) begin
    if(rst) begin
        for(i=0; i<10; i=i+1) begin
            arr[i] <= 0;
        end
    end
    else if(state_q == OPER && ~sort_idx) begin
        for(i=0; i<10; i=i+2) begin
            arr[i] <= (arr[i] > arr[i+1]) ? arr[i+1] : arr[i];
            arr[i+1] <= (arr[i] > arr[i+1]) ? arr[i] : arr[i+1];
        end
    end
    else if(state_q == OPER && sort_idx) begin
        for(i=1; i<9; i=i+2) begin
            arr[i] <= (arr[i] > arr[i+1]) ? arr[i+1] : arr[i];
            arr[i+1] <= (arr[i] > arr[i+1]) ? arr[i] : arr[i+1];
        end
    end
end
////// sort //////

always @(*) begin
    if (state_q == OUT) begin
        data_out = arr[counter_r_q];
    end
end


always @(posedge clk or posedge rst) begin
    if (rst) begin
        ss_tready <= 1'd0;
        state_q <= 2'd0;
        counter_r_q <= 4'd0;
        // for(i=0; i<10; i=i+1) begin
        //     arr_q[i] <= 32'd0;
        // end
    end
    else begin
        ss_tready <= ss_tready_d;
        state_q <= state_d;
        counter_r_q <= counter_r_d;
        // for(i=0; i<10; i=i+1) begin
        //     arr_q[i] <= arr_d[i];
        // end
    end
end

endmodule
