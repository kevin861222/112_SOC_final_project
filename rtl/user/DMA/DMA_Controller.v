// Memory Map - wishbone
//          +------+------+-------+------+---------+--------+
// DMA_cfg  | done | idle | start | type | channel | length |
//          | [12] | [11] | [10]  | [9]  |  [8:7]  |  [6:0] |
//          +------+------+-------+------+---------+--------+
// DMA_addr |                addr_DMA2RAM                   |
//          |                   [12:0]                      |
//          +-----------------------------------------------+
// DMA Config
// |Parameter     |Permission |Meaning                              |
// |--------------|-----------|-------------------------------------|
// |DMA_cfg[12]   |[Read only]|ap_done (1 stands for done)          |
// |DMA_cfg[11]   |[Read only]|ap_idle (1 stands for idle)          |
// |DMA_cfg[10]   |[R/W]      |ap_start(1 stands for start)         |
// |DMA_cfg[9]    |[R/W]      |type (mem->io=0, io->mem=1)          |
// |DMA_cfg[8:7]  |[R/W]      |channel[1:0] (fir=0,matmul=1,qsort=2)|
// |DMA_cfg[6:0]  |[R/W]      |length[6:0]                          |
// |--------------|-----------|-------------------------------------|
// |DMA_addr[12:0]|[R/W]      |address_DMA2RAM                      |

`include "../rtl/user/defines.v"
module DMA_Controller 
#(
    parameter pDATA_WIDTH = 32
)
(
    // Wishbone Slave ports (WB MI A)
    input             wb_clk_i,
    input             wb_rst_i,
    input             wbs_stb_i,
    input             wbs_cyc_i,
    input             wbs_we_i,
    input      [3:0]  wbs_sel_i,
    input      [31:0] wbs_dat_i,
    input      [31:0] wbs_adr_i,
    input      [31:0] wbs_adr_o,
    output reg        wbs_ack_o,
    output reg [31:0] wbs_dat_o,

    // AXI-Stream (Write, DMA->ASIC)
    input                      sm_tready, 
    output                     sm_tvalid, 
    output [(pDATA_WIDTH-1):0] sm_tdata, 
    output                     sm_tlast, 
    
    // AXI-Stream (Read, DMA<-ASIC)
    input                      ss_tvalid, 
    input  [(pDATA_WIDTH-1):0] ss_tdata, 
    input                      ss_tlast, 
    output                     ss_tready, 

    // Memory
    output        mem_r_ready, // mem_r_addr valid
    output [12:0] mem_r_addr,
    input         mem_r_ack,
    output        mem_w_valid,
    output [12:0] mem_w_addr,
    output [31:0] mem_w_data,
    input         mem_r_valid, // mem_r_data valid
    input  [31:0] mem_r_data,

    // ASIC signal line
    output    reg [2:0] ap_start_ASIC,
    input               ap_idle_ASIC,
    input         [2:0] ap_done_ASIC
);
//==============================================================================//
//                                  Declaration                                 //
//==============================================================================//
// Wishbone
wire wbs_valid;

// DMA
wire ap_start_DMA;
reg  ap_idle_DMA;
wire ap_done_DMA;
reg [1:0] ch;           // DMA IO channel (fir=0,matmul=1,sort=2)
reg [6:0]length;        // DMA transmit data length
reg type;               // Cache R(0)/W(1), mem->io=0, io->mem=1
reg [12:0]addr_DMA2RAM; // DMA address  io->memory

reg [6:0] length_request_BRAM;
reg [6:0] length_receive_BRAM;
reg [6:0] length_write_BRAM;
wire isAddr_DMA;
wire isAddr_DMA_w;
wire isAddr_DMA_r;

//==============================================================================//
//                                     Design                                   //
//==============================================================================//
// Wishbone
assign wbs_valid = wbs_cyc_i && wbs_stb_i; // address is in user project
assign isAddr_DMA = wbs_valid & wbs_adr_i[15:8]==8'h80; // 32'h3800_80XX
assign isAddr_DMA_w = (isAddr_DMA & wbs_we_i);
assign isAddr_DMA_r = (isAddr_DMA & ~wbs_we_i);

always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        wbs_ack_o <= 0;
    end
    else begin
        wbs_ack_o <= isAddr_DMA;
    end
end

always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        type <= 1'b0;
        ch <= 2'b0;
        length <= 7'b0;
        addr_DMA2RAM <= 13'b0;
    end
    else begin
        if(isAddr_DMA_w) begin
            case(wbs_adr_i[3:0])
            `DMA_offset_cfg: begin
                if(ap_idle_DMA) begin
                    type <= wbs_dat_i[9];
                    ch <= wbs_dat_i[8:7];
                    length <= wbs_dat_i[6:0];
                end
            end
            `DMA_offset_addr: begin
                addr_DMA2RAM <= wbs_dat_i[12:0];
            end
            endcase
        end

    end
end

always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        wbs_dat_o <= 32'h0;
    end
    else begin
        if(isAddr_DMA_r) begin
            case(wbs_adr_i[3:0])
            `DMA_offset_cfg: begin
                wbs_dat_o <= {19'b0, ap_done_DMA, ap_idle_DMA, ap_start_DMA, type, ch, length};
            end
            `DMA_offset_addr: begin
                wbs_dat_o <= {18'b0, addr_DMA2RAM};
            end
            endcase
        end
        else begin
            wbs_dat_o <= 0;
        end
    end
end

// DMA
assign ap_start_DMA = (isAddr_DMA_w && wbs_adr_i[3:0]==`DMA_offset_cfg && ap_idle_DMA)?wbs_dat_i[10]:0;
assign ap_done_DMA = (!ap_idle_DMA && 
                        (type==0 && mem_r_ack && length_request_BRAM==length-1) ||
                        (type==1 && ss_tvalid && length_write_BRAM==length-1));
always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        ap_idle_DMA <= 1;
    end
    else begin
        if(ap_start_DMA) 
            ap_idle_DMA <= 0;
        if(ap_done_DMA) 
            ap_idle_DMA <= 1;
    end
end

always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        length_request_BRAM <= 0;
    end
    else begin
        if(!ap_idle_DMA && mem_r_ack)
            length_request_BRAM <= length_request_BRAM + 1;

        if(ap_done_DMA) 
            length_request_BRAM <= 0;
    end
end

always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        length_receive_BRAM <= 0;
    end
    else begin
        if(mem_r_valid)
            length_receive_BRAM <= length_receive_BRAM + 1;

        if(length_receive_BRAM==length) 
            length_receive_BRAM <= 0;
    end
end

always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        length_write_BRAM <= 0;
    end
    else begin
        if(!ap_idle_DMA && mem_w_valid)
            length_write_BRAM <= length_write_BRAM + 1;

        if(ap_done_DMA) 
            length_write_BRAM <= 0;
    end
end

// Memory
// Memory - Read
assign mem_r_addr = (addr_DMA2RAM + length_request_BRAM);
assign mem_r_ready = (!ap_idle_DMA) && sm_tready;

// Memory - Write
assign mem_w_addr = (addr_DMA2RAM + length_write_BRAM);
assign mem_w_valid = ss_tvalid;
assign mem_w_data = ss_tdata;

// AXI-Stream (Write, DMA->ASIC)
assign sm_tdata = mem_r_data;
assign sm_tvalid = mem_r_valid;
assign sm_tlast = mem_r_valid && (|length) && (length_receive_BRAM==length-1);

// AXI-Stream (Read, DMA<-ASIC)
assign ss_tready = (!ap_idle_DMA && type==1);

// ASIC signal line
always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        ap_start_ASIC <= 3'b0;
    end
    else begin
        if(!ap_idle_DMA && ap_idle_ASIC)
            ap_start_ASIC[ch] <= 1'b1;
        
        if(|ap_start_ASIC) 
            ap_start_ASIC <= 3'b0;
    end
end
endmodule