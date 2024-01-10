// Memory Map - wishbone
//          +------+------+-------+------+---------+--------+
//  DMA_cfg |      |      |       |      |         |        |
//          | done | idle | start | type | channel | length |
// 38008000 |      |      |       |      |         |        |
//          +------+------+-------+------+---------+--------+
//            [12]   [11]   [10]     [9]    [8:7]     [6:0]
// 
// 
//          +--------------------------------+--------------+
// DMA_addr |                                |              |
//          |                                | addr_DMA2RAM |
// 38008004 |                                |              |
//          +--------------------------------+--------------+
//                                                 [12:0]
// parameter
// ------------------------------------------------------------------ //
// DMA_cfg[12]     = ap_done (1 stands for done)           [Read only]
// DMA_cfg[11]     = ap_idle (1 stands for idle)           [Read only]
// DMA_cfg[10]     = ap_start(1 stands for start)          [R/W]
// DMA_cfg[9]      = type (mem->io=0, io->mem=1)           [R/W]
// DMA_cfg[8:7]    = channel[1:0] (fir=0,matmul=1,qsort=2) [R/W]
// DMA_cfg[6:0]    = length[6:0]                           [R/W]
// ------------------------------------------------------------------ //
// DMA_addr[12:0]  = address_DMA2RAM                       [R/W]

// TODO
// 1. connect LA to CPU to tell DMA is done
// 2. ASIC, sm_tready = 1 -> in_valid = 1 -> ack = 1 -> sm_tvalid = 1
// in_valid condition is wrong need to fix
`include "../rtl/user/defines.v"
module DMA_Controller 
#(
    parameter pDATA_WIDTH = 32
)
(
    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    input [31:0] wbs_adr_o,
    output     wbs_ack_o,
    output reg [31:0] wbs_dat_o,
    output [127:0] la_data_out,

    // AXI-Stream (Write, DMA->ASIC)
    input                          sm_tready, 
    output                         sm_tvalid, 
    output     [(pDATA_WIDTH-1):0] sm_tdata, 
    output reg                     sm_tlast, 
    
    // AXI-Stream (Read, DMA<-ASIC)
    input                          ss_tvalid, 
    input      [(pDATA_WIDTH-1):0] ss_tdata, 
    input                          ss_tlast, 
    output reg                     ss_tready, 

    // Memory
    output reg    mem_r_ready, // mem_r_addr valid
    output [12:0] mem_r_addr,
    input         mem_r_ack,
    output        mem_w_valid,
    output [12:0] mem_w_addr,
    output [31:0] mem_w_data,
    input         mem_r_valid, // mem_r_data valid
    input  [31:0] mem_r_data,

    // ASIC signal line
    output reg [2:0] ap_start_ASIC,
    input            ap_idle_ASIC,
    input      [2:0] ap_done_ASIC
);
//==============================================================================//
//                                  Declaration                                 //
//==============================================================================//
// Wishbone
wire wbs_valid;

// DMA
reg ap_start_DMA;
reg ap_idle_DMA;
reg ap_done_DMA;
reg [1:0] ch;           // DMA IO channel (fir=0,matmul=1,sort=2)
reg [6:0]length;        // DMA transmit data length
reg type;               // Cache R(0)/W(1), mem->io=0, io->mem=1
reg [12:0]addr_DMA2RAM; // DMA address  io->memory

reg [6:0] counter_length;
wire isAddr_DMA;
wire isAddr_DMA_w;
wire isAddr_DMA_r;

//==============================================================================//
//                                     Design                                   //
//==============================================================================//
// Wishbone
assign wbs_ack_o = isAddr_DMA;
assign wbs_valid = wbs_cyc_i && wbs_stb_i; // address is in user project
assign isAddr_DMA = wbs_valid & wbs_adr_i[15:8]==8'h80; // 32'h3800_80XX
assign isAddr_DMA_w = (isAddr_DMA & wbs_we_i);
assign isAddr_DMA_r = (isAddr_DMA & ~wbs_we_i);

always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        ap_start_DMA <= 1'b0;
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
                    ap_start_DMA <= wbs_dat_i[10];
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

        if(ap_done_DMA) begin
            type <= 1'b0;
            ch <= 2'b0;
            length <= 7'b0;
            addr_DMA2RAM <= 13'b0;
        end

        if(ap_start_DMA) ap_start_DMA <= 1'b0;
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
    end
end

// DMA
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
        ap_done_DMA <= 0;
    end
    else begin
        if(!ap_idle_DMA & counter_length==length)
            ap_done_DMA <= 1;

        if(ap_done_DMA) 
            ap_done_DMA <= 0;
    end
end

always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        counter_length <= 0;
    end
    else begin
        if(!ap_idle_DMA && mem_r_ack && counter_length<length)
            counter_length <= counter_length + 1;

        if(ap_done_DMA) 
            counter_length <= 0;
    end
end

// Memory
// Read
// mem_r_addr
// mem_r_ready, 應該會一直有效直到ack
// mem_r_ack
// mem_r_valid
// mem_r_data

// Write
// mem_w_valid
// mem_w_addr
// mem_w_data

assign mem_r_addr = (addr_DMA2RAM | counter_length);

always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        mem_r_ready <= 0;
    end
    else begin
        if(!ap_idle_DMA && ((counter_length==0) || (counter_length>0 && sm_tready)))
            mem_r_ready <= 1;
        
        if(mem_r_ack)
            mem_r_ready <= 0;
    end
end

// AXI-Stream (Write, DMA->ASIC)
// 會有一種情況
// sm_tready = 0, sm_tvalid = 1
assign sm_tdata = mem_r_data;
assign sm_tvalid = mem_r_ack;
always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        sm_tlast <= 0;
    end
    else begin
    end
end

// AXI-Stream (Read, DMA<-ASIC)
always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        ss_tready <= 1;
    end
    else begin
    end
end

// ASIC signal line
// ap_idle_ASIC  觸發條件是啥 會先檢查ASIC是否為idle
// ap_done_ASIC
// ap_start_ASIC
always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if(wb_rst_i) begin
        ap_start_ASIC <= 3'b0;
    end
    else begin
        if(ap_idle_ASIC)
            ap_start_ASIC[ch] <= ap_start_DMA;

        if(|ap_start_ASIC[ch]) 
            ap_start_ASIC <= 3'b0;
    end

end
endmodule