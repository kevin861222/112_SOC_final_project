/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
#include <defs.h>
#include "define.h"
#ifdef USER_PROJ_IRQ0_EN
#include <irq_vex.h>
#endif
void __attribute__ ( ( section ( ".mprjram" ) ) ) Hardware_test(){
	// start flag - FIR
	reg_mprj_datal = (0xAB00<<16);
	// FIR tap
	reg_DMA_addr   = 	(fir_taps_base<<DMA_addr_base);
	reg_DMA_cfg    = 	(1 << DMA_cfg_start) | 
						(DMA_type_MEM2IO << DMA_cfg_type) | 
						(DMA_ch_FIR << DMA_cfg_channel) | 
						(NUM_FIR_TAP<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// FIR input
	reg_DMA_addr   = 	(fir_input_base<<DMA_addr_base);
	reg_DMA_cfg    = 	(1 << DMA_cfg_start) | 
						(DMA_type_MEM2IO << DMA_cfg_type) | 
						(DMA_ch_FIR << DMA_cfg_channel) | 
						(NUM_FIR_INPUT<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// FIR output
	reg_DMA_addr   = 	(fir_output_base<<DMA_addr_base);
	reg_DMA_cfg    = 	(1 << DMA_cfg_start) | 
						(DMA_type_IO2MEM << DMA_cfg_type) | 
						(DMA_ch_FIR << DMA_cfg_channel) | 
						(NUM_FIR_OUTPUT<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// end flag - FIR
	reg_mprj_datal = (0xAB01<<16);

	// start flag - matmul
	reg_mprj_datal = (0xAB10<<16);
	// matmul input A
	reg_DMA_addr   = 	(mat_A_base<<DMA_addr_base);
	reg_DMA_cfg    = 	(1 << DMA_cfg_start) | 
						(DMA_type_MEM2IO << DMA_cfg_type) | 
						(DMA_ch_matmul << DMA_cfg_channel) | 
						(NUM_MAT_A<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// matmul input B
	reg_DMA_addr   = 	(mat_B_base<<DMA_addr_base);
	reg_DMA_cfg    = 	(1 << DMA_cfg_start) | 
						(DMA_type_MEM2IO << DMA_cfg_type) | 
						(DMA_ch_matmul << DMA_cfg_channel) | 
						(NUM_MAT_B<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// matmul output
	reg_DMA_addr   = 	(mat_output_base<<DMA_addr_base);
	reg_DMA_cfg    = 	(1 << DMA_cfg_start) | 
						(DMA_type_IO2MEM << DMA_cfg_type) | 
						(DMA_ch_matmul << DMA_cfg_channel) | 
						(NUM_MAT_OUTPUT<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// end flag - matmul
	reg_mprj_datal = (0xAB11<<16);

	// start flag - qsort
	reg_mprj_datal = (0xAB20<<16);
	// qsort input
	reg_DMA_addr   = 	(qsort_input_base<<DMA_addr_base);
	reg_DMA_cfg    = 	(1 << DMA_cfg_start) | 
						(DMA_type_MEM2IO << DMA_cfg_type) | 
						(DMA_ch_qsort << DMA_cfg_channel) | 
						(NUM_QSORT_INPUT<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// qsort output
	reg_DMA_addr   = 	(mat_output_base<<DMA_addr_base);
	reg_DMA_cfg    = 	(1 << DMA_cfg_start) | 
						(DMA_type_IO2MEM << DMA_cfg_type) | 
						(DMA_ch_qsort << DMA_cfg_channel) | 
						(NUM_QSORT_OUTPUT<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// end flag - qsort
	reg_mprj_datal = (0xAB21<<16);

}
void main()
{
	reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

	reg_mprj_io_15 = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_13 = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_10 = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_9  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_8  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_7  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_4  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_3  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_2  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_1  = GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_0  = GPIO_MODE_USER_STD_OUTPUT;

	reg_mprj_io_6  = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_5  = GPIO_MODE_USER_STD_INPUT_NOPULL;

	// Configure LA probes [31:0], [127:64] as inputs to the cpu 
	// Configure LA probes [63:32] as outputs from the cpu
	reg_la0_oenb = reg_la0_iena = 0x00000000;    // [31:0]
	reg_la1_oenb = reg_la1_iena = 0x00000000;    // [63:32]
	reg_la2_oenb = reg_la2_iena = 0x00000000;    // [95:64]
	reg_la3_oenb = reg_la3_iena = 0x00000000;    // [127:96]
	// UART Receive Interrupt
#ifdef USER_PROJ_IRQ0_EN
    int mask;
	// unmask USER_IRQ_0_INTERRUPT
	mask = irq_getmask();
	mask |= 1 << USER_IRQ_0_INTERRUPT; // USER_IRQ_0_INTERRUPT = 2
	irq_setmask(mask);
	// enable user_irq_0_ev_enable
	user_irq_0_ev_enable_write(1);
#endif

	// Set User Project Slaves Enable
	reg_wb_enable = 1;

	reg_uart_enable = 1;

	// Now, apply the configuration
	reg_mprj_xfer = 1;
	while (reg_mprj_xfer == 1);

	Hardware_test();
	Hardware_test();
	Hardware_test();
	while (1) ;
}