#ifndef __DEFINE_H__
#define __DEFINE_H__
#define NUM_FIR_TAP    11
#define NUM_FIR_INPUT  64
#define NUM_FIR_OUTPUT 64
#define MAT_SIZE 4
#define NUM_MAT_A      (MAT_SIZE*MAT_SIZE)
#define NUM_MAT_B      (MAT_SIZE*MAT_SIZE)
#define NUM_MAT_OUTPUT (MAT_SIZE*MAT_SIZE)
#define QSORT_SIZE 10
#define NUM_QSORT_INPUT  QSORT_SIZE
#define NUM_QSORT_OUTPUT QSORT_SIZE
// #define TIMES_RERUN 3
#define TIMES_RERUN 1

// Memory Map of BRAM u0 (data - unprocessed)
// Reference: ~/testbench/main.map
typedef enum
{
    fir_taps_base,
    fir_taps_end     = (fir_taps_base + NUM_FIR_TAP - 1),
    fir_input_base,
    fir_input_end    = (fir_input_base + NUM_FIR_INPUT - 1),
    mat_A_base,
    mat_A_end        = (mat_A_base + NUM_MAT_A - 1),
    mat_B_base,
    mat_B_end        = (mat_B_base + NUM_MAT_B - 1),
    qsort_input_base,
    qsort_input_end  = (qsort_input_base + NUM_QSORT_INPUT - 1)
} MM_BRAM_u0;

// Memory Map of BRAM u1 (data - processed)
typedef enum
{
    fir_output_base,
    fir_output_end    = (fir_output_base + NUM_FIR_OUTPUT - 1),
    mat_output_base,
    mat_output_end    = (mat_output_base + NUM_MAT_OUTPUT - 1),
    qsort_output_base,
    qsort_output_end  = (qsort_output_base + NUM_QSORT_OUTPUT - 1)
} MM_BRAM_u1;

// Memory-Map Address
#define MMIO_DMA         0x30008000
#define MMIO_UART        0x31000000
// Reference: ~/firmware/sections.lds
#define BRAM_u0_base     0x38000000
#define BRAM_u1_base     0x38007000

#define offset_DMA_cfg  0x00
#define offset_DMA_addr 0x04
#define DMA_cfg      (MMIO_DMA | offset_DMA_cfg)
#define DMA_addr     (MMIO_DMA | offset_DMA_addr)
#define reg_DMA_cfg  (*(volatile uint32_t *)DMA_cfg)  // 0x3000_8000
#define reg_DMA_addr (*(volatile uint32_t *)DMA_addr) // 0x3000_8004

#define offset_uart_rx_data 0x00
#define offset_uart_tx_data 0x04
#define offset_uart_stat    0x08
#define UART_RX_DATA  (MMIO_UART | offset_uart_rx_data)
#define UART_TX_DATA  (MMIO_UART | offset_uart_tx_data)
#define UART_STAT     (MMIO_UART | offset_uart_stat)
#define reg_rx_data   (*(volatile uint32_t *)UART_RX_DATA) // 0x3100_0000
#define reg_tx_data   (*(volatile uint32_t *)UART_TX_DATA) // 0x3100_0004
#define reg_uart_stat (*(volatile uint32_t *)UART_STAT)    // 0x3100_0008

// Reference: ~/firmware/sections.lds
#define BRAM_u0_length 0x00000500
#define BRAM_u1_length 0x00001000
#define BRAM_u0_end (BRAM_u0_base + BRAM_u0_length - 1)
#define BRAM_u1_end (BRAM_u1_base + BRAM_u1_length - 1)
#define reg_bram_u0_base (*(volatile uint32_t *)BRAM_u0_base) // 0x3800_0000
#define reg_bram_u0_end  (*(volatile uint32_t *)BRAM_u0_end)  // 0x3800_04ff
#define reg_bram_u1_base (*(volatile uint32_t *)BRAM_u1_base) // 0x3800_7000
#define reg_bram_u1_end  (*(volatile uint32_t *)BRAM_u1_end)  // 0x3800_7fff

#define DMA_cfg_length  0
#define DMA_cfg_channel 7
#define DMA_cfg_type    9
#define DMA_cfg_start   10
#define DMA_cfg_idle    11
#define DMA_cfg_done    12
#define DMA_addr_base   0

#define DMA_ch_FIR    0
#define DMA_ch_matmul 1
#define DMA_ch_qsort  2

#define DMA_type_MEM2IO 0
#define DMA_type_IO2MEM 1
#endif