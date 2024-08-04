/*
 * ps_uart.h
 *
 *  Created on: 2023Äê10ÔÂ31ÈÕ
 *      Author: Administrator
 */

#ifndef SRC_PS_UART_H_
#define SRC_PS_UART_H_







#ifdef __cplusplus
extern "C" {
#endif

#include "fpga_common.h"
#include "io_mem.h"
#include "ring_fifo.h"
#include "xuartps_hw.h"
#include "xuartps.h"

struct FpgaTop;
typedef struct FpgaTop FpgaTop;

//--------------------------------------------------------------------------------------


typedef struct PsUart PsUart;

struct PsUart {
	RegMem regs_;

	//class member------------------------------------------------------------------
	FpgaTop* sys_;
	RingFifo buff_;
	u32 irq_count_;
	XUartPs xuart_;

	//class method-------------------------------------------------------------------
	int (*init)(PsUart* ths, FpgaTop* sys, u16 deep, int dev_id, u32 baud_rate, u32 data_bits, u32 parity, u8 stop_bits);
	void (*send_buff)(PsUart* ths, const u8* data, int len);

};


void PsUart_(PsUart* ths);
void uart_recv_poll(PsUart* uart);
void ps_uart_isr_handle(void* arg);









#ifdef __cplusplus
}
#endif

















#endif /* SRC_PS_UART_H_ */
