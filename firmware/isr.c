// This file is Copyright (c) 2020 Florent Kermarrec <florent@enjoy-digital.fr>
// License: BSD

#include <irq_vex.h>
#include <uart.h>

extern char uart_read();
extern void uart_write(char);
void isr(void);

#ifdef CONFIG_CPU_HAS_INTERRUPT
void isr(void)
{
#ifndef USER_PROJ_IRQ0_EN
	irq_setmask(0);
#else
    uint32_t irqs = irq_pending() & irq_getmask();
    uint8_t buf;
    if ( irqs & (1 << USER_IRQ_0_INTERRUPT)) {
        user_irq_0_ev_pending_write(1); // Clear Interrupt Pending Event
        buf = uart_read();
        uart_write(buf);
    }
#endif
    return;
}

#else

void isr(void){};

#endif