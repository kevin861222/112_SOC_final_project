`ifndef DEFINE_V
`define DEFINE_V
    // BRAM
    `define BRAM_ADDR_LENGTH 13
    
    //DMA
    `define addr_DMA  32'h3000_8000
    `define DMA_offset_cfg  4'h0
    `define DMA_offset_addr 4'h4

    // UART
    `define addr_UART 32'h3000_9000

`endif