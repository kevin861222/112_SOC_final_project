module firmat(
    input clk,
    input rst, 

    input [1:0] acc_ap_start_q,
    //fir
    //AXI_stream_slave
    input                       fir_ss_tvalid, 
    input   [31:0]              fir_ss_tdata, 
    input                       fir_ss_tlast, 
    output  reg                 fir_ss_tready, 
    input                       ap_start_fir,
    //out
    output reg   [31:0]         firmat_data_out, //firmat
    output reg                  fir_w_fifo_en,
    output reg                  done_fir,

    //matmul
    //AXI_stream_slave
    input                       mat_ss_tvalid, 
    input   [31:0]              mat_ss_tdata, 
    input                       mat_ss_tlast, 
    output  reg                 mat_ss_tready, 
    input                       ap_start_matmul,
    //out
    output reg                  mat_w_fifo_en,
    output reg                  done_matmul
);
    localparam IDLE_fir = 2'd0,
               READ_fir = 2'd1,
               STORE_fir = 2'd2,
               OPER_fir = 2'd3;

    localparam IDLE_mat = 2'd0,
               READ_mat = 2'd1,
               OPER_mat = 2'd2,
               SEND_mat = 2'd3;

    //fir
    reg fir_ss_tready_d;
    reg [1:0] fir_state_cs, fir_state_ns;
    reg [6:0] fir_counter_r_q, fir_counter_r_d;
    reg fir_counter_r_rst, fir_counter_r_en;
    reg [3:0] fir_counter_s_q, fir_counter_s_d;
    reg fir_counter_s_rst, fir_counter_s_en;
    reg [31:0] tap_q [0:10];
    reg [31:0] tap_d [0:10];
    reg [31:0] shiftbuf_q [0:10];
    reg [31:0] shiftbuf_d [0:10];
    reg [31:0] multbuf [0:10];
    reg [3:0] index0, index1, index2, index3, index4, index5, index6, index7, index8, index9, index10;
    integer i;
    //fifo
    wire full, empty;
    reg r_en, w_en, rstfifo;
    reg [31:0] din;
    wire [31:0] dout;


    

    //mat
    reg mat_ss_tready_d;
    reg [1:0] mat_state_cs, mat_state_ns;
    reg [5:0] mat_counter_r_q, mat_counter_r_d;
    reg mat_counter_r_rst, mat_counter_r_en;
    reg [31:0] matrix_q [0:31];
    reg [31:0] matrix_d [0:31];
    reg [31:0] Aarray[0:3];
    reg [31:0] Barray[0:3];

    reg [31:0] A [0:10];
    reg [31:0] B [0:10];

    //together
    always @(*) begin
        if(acc_ap_start_q[0]) begin //fir
            {A[0], A[1], A[2], A[3], A[4], A[5], A[6], A[7], A[8], A[9], A[10]} = {tap_q[0], tap_q[1], tap_q[2], tap_q[3], tap_q[4], tap_q[5], tap_q[6], tap_q[7], tap_q[8], tap_q[9], tap_q[10]};
            {B[0], B[1], B[2], B[3], B[4], B[5], B[6], B[7], B[8], B[9], B[10]} = {multbuf[0], multbuf[1], multbuf[2], multbuf[3], multbuf[4], multbuf[5], multbuf[6], multbuf[7], multbuf[8], multbuf[9], multbuf[10]};
        end
        else if(acc_ap_start_q[1]) begin
            {A[0], A[1], A[2], A[3], A[4], A[5], A[6], A[7], A[8], A[9], A[10]} = {Aarray[0], Aarray[1], Aarray[2], Aarray[3], 32'd0, 32'd0 ,32'd0 ,32'd0 ,32'd0 ,32'd0, 32'd0};
            {B[0], B[1], B[2], B[3], B[4], B[5], B[6], B[7], B[8], B[9], B[10]} = {Barray[0], Barray[1], Barray[2], Barray[3], 32'd0, 32'd0 ,32'd0 ,32'd0 ,32'd0 ,32'd0, 32'd0};
        end
        else begin
            {A[0], A[1], A[2], A[3], A[4], A[5], A[6], A[7], A[8], A[9], A[10]} = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0};
            {B[0], B[1], B[2], B[3], B[4], B[5], B[6], B[7], B[8], B[9], B[10]} = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0};
        end
    end
    always @(*) begin
        firmat_data_out = (A[0]*B[0]) + (A[1]*B[1]) + (A[2]*B[2]) + (A[3]*B[3]) + (A[4]*B[4]) + (A[5]*B[5]) + (A[6]*B[6]) + (A[7]*B[7]) + (A[8]*B[8])+ (A[9]*B[9]) + (A[10]*B[10]);
    end
    //fir
    always @(*) begin
        fir_counter_r_rst = 1'd0;
        fir_counter_r_en = 1'd0;
        fir_counter_s_rst = 1'd0;
        fir_counter_s_en = 1'd0;
        fir_w_fifo_en = 1'd0;
        done_fir = 1'd0;
        fir_ss_tready_d = 1'd0;
        for(i=0; i<11; i=i+1) shiftbuf_d[i] = shiftbuf_q[i];
        for(i=0; i<11; i=i+1) tap_d[i] = tap_q[i];
        r_en = 1'd0;
        w_en = 1'd0;
        din = 32'd0;
        rstfifo = 1'd0;

        case(fir_state_cs)
            IDLE_fir: begin
                if(ap_start_fir) begin
                    fir_ss_tready_d = 1'd1;
                    fir_state_ns = READ_fir;
                end
                else begin
                    fir_state_ns = IDLE_fir;
                end
            end
            READ_fir: begin
                fir_ss_tready_d = 1'd1;
                if(fir_ss_tready && fir_ss_tvalid) begin
                    fir_counter_r_en = 1'd1;
                    tap_d[fir_counter_r_q] = fir_ss_tdata;

                    if(fir_counter_r_q == 10) begin
                        fir_counter_r_rst = 1'd1;
                        fir_state_ns = STORE_fir;                        
                    end
                    else 
                        fir_state_ns = READ_fir;
                end
                else begin
                    fir_state_ns = READ_fir;
                end            
            end
            STORE_fir: begin
                fir_ss_tready_d = ~full;
                w_en = fir_ss_tvalid;
                din = fir_ss_tdata;

                if(fir_counter_r_q == 0 || fir_counter_r_q == 1) begin
                    if(fir_ss_tready && fir_ss_tvalid) begin
                        r_en = 1'd1;
                        fir_counter_r_en = 1'd1;
                        fir_state_ns = STORE_fir;
                    end
                    else begin
                        fir_state_ns = STORE_fir;
                    end
                end
                else begin
                    r_en = 1'd1;
                    fir_counter_r_en = 1'd1;
                    fir_counter_s_en = 1'd1;
                    shiftbuf_d[fir_counter_s_q] = dout;
                    fir_state_ns = OPER_fir;
                end
            end
            OPER_fir: begin
                fir_ss_tready_d = ~full;
                w_en = fir_ss_tvalid;
                din = fir_ss_tdata;
                fir_w_fifo_en = 1'd1;

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

                if(fir_counter_r_q == 66) begin
                    rstfifo = 1'd1;
                    fir_counter_s_rst = 1'd1;
                    fir_counter_r_rst = 1'd1;
                    done_fir = 1'd1;
                    fir_state_ns = IDLE_fir;
                end
                else begin
                    fir_ss_tready_d = 1'd1;
                    fir_state_ns = STORE_fir;
                end
            end
            default: fir_state_ns = IDLE_fir;
        endcase
    end
    always @(*) begin
        index0 = ((fir_counter_s_q + 4'd1) > 10) ?   4'd0                 : (fir_counter_s_q + 4'd1);
        index1 = ((fir_counter_s_q + 4'd2) > 10) ?   (fir_counter_s_q - 4'd9) : (fir_counter_s_q + 4'd2);
        index2 = ((fir_counter_s_q + 4'd3) > 10) ?   (fir_counter_s_q - 4'd8) : (fir_counter_s_q + 4'd3);
        index3 = ((fir_counter_s_q + 4'd4) > 10) ?   (fir_counter_s_q - 4'd7) : (fir_counter_s_q + 4'd4);
        index4 = ((fir_counter_s_q + 4'd5) > 10) ?   (fir_counter_s_q - 4'd6) : (fir_counter_s_q + 4'd5);
        index5 = ((fir_counter_s_q + 4'd6) > 10) ?   (fir_counter_s_q - 4'd5) : (fir_counter_s_q + 4'd6);
        index6 = ((fir_counter_s_q + 4'd7) > 10) ?   (fir_counter_s_q - 4'd4) : (fir_counter_s_q + 4'd7);
        index7 = ((fir_counter_s_q + 4'd8) > 10) ?   (fir_counter_s_q - 4'd3) : (fir_counter_s_q + 4'd8);
        index8 = ((fir_counter_s_q + 4'd9) > 10) ?   (fir_counter_s_q - 4'd2) : (fir_counter_s_q + 4'd9);
        index9 = ((fir_counter_s_q + 4'd10) > 10) ?   (fir_counter_s_q - 4'd1) : (fir_counter_s_q + 4'd10);
        index10 = ((fir_counter_s_q + 4'd11) > 10) ?   (fir_counter_s_q)       : (fir_counter_s_q + 4'd11);
    end

    always @(*) begin   //counter_r_q
        if(fir_counter_r_rst)
            fir_counter_r_d = 6'd0;
        else if(fir_counter_r_en)
            fir_counter_r_d = fir_counter_r_q + 1;
        else 
            fir_counter_r_d = fir_counter_r_q;
    end
    always @(*) begin //store position counter
        if(fir_counter_s_rst)
            fir_counter_s_d = 6'd10;
        else if(fir_counter_s_en) begin
            if(fir_counter_s_q == 6'd0)
                fir_counter_s_d = 6'd10;
            else
                fir_counter_s_d = fir_counter_s_q - 1;
        end
        else 
            fir_counter_s_d = fir_counter_s_q; 
    end

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            fir_ss_tready <= 1'd0;
            fir_state_cs <= 2'd0;
            fir_counter_r_q <= 7'd0;
            fir_counter_s_q <= 6'd10;
            for(i=0; i<11; i=i+1) shiftbuf_q[i] <= 32'd0;
            for(i=0; i<11; i=i+1) tap_q[i] <= 32'd0;
        end
        else begin
            fir_ss_tready <= fir_ss_tready_d;
            fir_state_cs <= fir_state_ns;
            fir_counter_r_q <= fir_counter_r_d;
            fir_counter_s_q <= fir_counter_s_d;
            for(i=0; i<11; i=i+1) shiftbuf_q[i] <= shiftbuf_d[i];
            for(i=0; i<11; i=i+1) tap_q[i] <= tap_d[i];
        end
    end

    //matmul
    always @(*) begin
        mat_ss_tready_d = (mat_state_cs == READ_mat) ? 1'd1 : 1'd0;
    end
    
    always @(*) begin
        mat_counter_r_en = 1'd0;
        mat_counter_r_rst = 1'd0;
        mat_w_fifo_en = 1'd0;
        done_matmul = 1'd0;

        case(mat_state_cs)
            IDLE_mat: begin
                if(ap_start_matmul) begin
                    mat_state_ns = READ_mat;
                end
                else begin
                    mat_state_ns = IDLE_mat;
                end
            end
            READ_mat: begin
                if(mat_ss_tready && mat_ss_tvalid) begin
                    mat_counter_r_en = 1'd1;
                    matrix_d[mat_counter_r_q] = mat_ss_tdata;

                    if(mat_counter_r_q == 31) begin
                        mat_counter_r_rst = 1'd1;
                        mat_state_ns = OPER_mat;                        
                    end
                    else 
                        mat_state_ns = READ_mat;
                end
                else begin
                    mat_state_ns = READ_mat;
                end
            end
            OPER_mat: begin
                mat_counter_r_en = 1'd1;
                mat_w_fifo_en = 1'd1;
                mat_state_ns = OPER_mat;

                case(mat_counter_r_q) 
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

                        mat_counter_r_rst = 1'd1;
                        done_matmul = 1'd1;
                        mat_state_ns = IDLE_mat;
                    end
                    default: mat_counter_r_rst = 1'd1;
                endcase
            end
            default: mat_state_ns = IDLE_mat;
        endcase
    end

    always @(*) begin   //counter_r_q
        if(mat_counter_r_rst)
            mat_counter_r_d = 6'd0;
        else if(mat_counter_r_en)
            mat_counter_r_d = mat_counter_r_q + 1;
        else 
            mat_counter_r_d = mat_counter_r_q;
    end

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            mat_ss_tready <= 1'd0;
            mat_state_cs <= 2'd0;
            mat_counter_r_q <= 6'd0;
            for(i=0; i<32; i=i+1) matrix_q[i] <= 32'd0;
        end
        else begin
            mat_ss_tready <= mat_ss_tready_d;
            mat_state_cs <= mat_state_ns;
            mat_counter_r_q <= mat_counter_r_d;
            for(i=0; i<32; i=i+1) matrix_q[i] <= matrix_d[i];
        end
    end

    //fir data fifo
    synchronous_fifo 
    #(.DEPTH(65), .DATA_WIDTH(32))
    U_fir_sync_fifo(
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
endmodule