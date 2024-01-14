`ifndef DEFINE_V
`define DEFINE_V

// BRAM
`define BRAM_ADDR_LENGTH 13

//DMA
`define addr_DMA  32'h3000_8000
`define DMA_offset_cfg  4'h0
`define DMA_offset_addr 4'h4

// UART
`define addr_RX_DATA   32'h3100_0000
`define addr_TX_DATA   32'h3100_0004
`define addr_STAT_REG  32'h3100_0008
`endif