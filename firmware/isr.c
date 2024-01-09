// This file is Copyright (c) 2020 Florent Kermarrec <florent@enjoy-digital.fr>
// License: BSD

#include <csr.h>
#include <soc.h>
#include <irq_vex.h>
#include <uart.h>
#include <defs.h>

void isr(void);

#ifdef CONFIG_CPU_HAS_INTERRUPT

void isr(void)
{
#ifndef USER_PROJ_IRQ0_EN
	irq_setmask(0);
#else
    int buf;
    if ( irqs & (1 << USER_IRQ_0_INTERRUPT)) {
        user_irq_0_ev_pending_write(1); //Clear Interrupt Pending Event
        buf = uart_read();
        uart_write(buf);
    }
    // uint16_t mprj_31_16;
    // uint8_t mprj_31_24, mprj_23_16;
    // if( irqs & (1 << USER_IRQ_1_INTERRUPT)) {
    //     user_irq_1_ev_pending_write(1); //Clear Interrupt Pending Event
    //     mprj_31_16 = ((reg_la1_data & 0xFFFF0000) >> 16);
    //     mprj_31_24 = ((mprj_31_16 & (0xFF<<8))>>8);
    //     mprj_23_16 = ((mprj_31_16 & (0xFF<<0))>>0);

    //     uart_write(mprj_31_24);
    //     uart_write(mprj_23_16);
    //     uart_write(0x0a); // "\n"
    // }
#endif
    return;
}

#else

void isr(void){};

#endif