#include <defs.h>
#define DMA_wbs         0x30008000
#define DMA_offset_cfg  0x00
#define DMA_offset_addr 0x04
#define DMA_cfg  (DMA_wbs | DMA_offset_cfg)
#define DMA_addr (DMA_wbs | DMA_offset_addr)
#define reg_DMA_cfg  (*(volatile uint32_t *)DMA_cfg)  // 0x3000_8000
#define reg_DMA_addr (*(volatile uint32_t *)DMA_addr) // 0x3000_8004
#define BRAM_addr_FIR    0x00
#define BRAM_addr_matmul 0x80
#define BRAM_addr_qsort  0xf0

int __attribute__ ( ( section ( ".mprjram" ) ) ) mprj(){
	// reg_mprj_datal = (0xAB40<<16);

	// reg_DMA_addr  = (BRAM_addr_qsort<<0);
	// // DMA_cfg[12]  = ap_busy (1 stands for DMA busy)             [Read only]
    // // DMA_cfg[11]  = ap_idle (1 stands for DMA idle)             [Read only]
    // // DMA_cfg[10]  = ap_start (1 stands for DMA start working)   [R/W]
    // // DMA_cfg[9]   = type (mem->io=0, io->mem=1)                 [R/W]
    // // DMA_cfg[8:7] = channel[1:0] (fir=0,matmul=1,sort=2)        [R/W]
    // // DMA_cfg[6:0] = length[6:0]                                 [R/W]
    // reg_DMA_cfg  = (1<< 10) | (0 << 9) | (0 << 7) | (64<<0);


	// reg_mprj_datal = (0xAB51<<16);
	return 10 ;
}