/*
 * ps_uart.c
 *
 *  Created on: 2023Äê10ÔÂ31ÈÕ
 *      Author: Administrator
 */

#include "ps_uart.h"
#include "fpga_top.h"



//--------------------------------------------------------------------------------------
static int init(PsUart* ths, FpgaTop* sys, u16 deep, int dev_id, u32 baud_rate, u32 data_bits, u32 parity, u8 stop_bits);
static void send_buff(PsUart* ths, const u8* data, int len);

void PsUart_(PsUart* ths)
{


	ths->init = init;
	ths->send_buff = send_buff;


}

static int init(PsUart* ths, FpgaTop* sys, u16 deep, int dev_id, u32 baud_rate, u32 data_bits, u32 parity, u8 stop_bits)
{
	ths->sys_ = sys;
	RingFifo_(&ths->buff_, deep);
	ths->irq_count_ = 0;

	int Status;

	XUartPs_Config *Config;

	Config = XUartPs_LookupConfig(dev_id);
	if (Config == NULL) {
		return -1;
	}
	Status = XUartPs_CfgInitialize(&ths->xuart_, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		return -1;
	}

	u32 phy_base = Config->BaseAddress;
	u32 total_size = 0x10000;

	RegMem_(&ths->regs_, phy_base, total_size);

	XUartPsFormat uart_fmt;
	uart_fmt.BaudRate = baud_rate;
	uart_fmt.DataBits = data_bits;
	uart_fmt.Parity = parity;
	uart_fmt.StopBits = stop_bits;
	Status = XUartPs_SetDataFormat(&ths->xuart_, &uart_fmt);
	if (Status != XST_SUCCESS) {
		return -1;
	}

	/* Check hardware build */
	Status = XUartPs_SelfTest(&ths->xuart_);
	if (Status != XST_SUCCESS) {
		return -1;
	}

	XUartPs_SetOperMode(&ths->xuart_, XUARTPS_OPER_MODE_NORMAL);



	u32 IntrMask = XUARTPS_IXR_RXOVR | XUARTPS_IXR_RXFULL;
	XUartPs_SetInterruptMask(&ths->xuart_, IntrMask);

	XUartPs_SetRecvTimeout(&ths->xuart_, 8);
	XUartPs_SetFifoThreshold(&ths->xuart_, 1);


	return 0;
}



static int uart_hw_is_recv_data(PsUart* ths)
{
	if (XUartPs_IsReceiveData(ths->regs_.phy_base_)) {
		return 1;
	} else {
		return 0;
	}
}

static int uart_hw_is_send_full(PsUart* ths)
{
	if (XUartPs_IsTransmitFull(ths->regs_.phy_base_)) {
		return 1;
	} else {
		return 0;
	}
}

static void send_data(PsUart* ths, u8 data)
{
	while(uart_hw_is_send_full(ths));
	XUartPs_WriteReg(ths->regs_.phy_base_, XUARTPS_FIFO_OFFSET, data);
}

static u8 recv_data(PsUart* ths)
{
	while(!uart_hw_is_recv_data(ths));
	u8 data = XUartPs_ReadReg(ths->regs_.phy_base_, XUARTPS_FIFO_OFFSET);
	return data;
}


static int recv_buff(PsUart* ths, int len, u32 timeout)
{
	int leave = len;
	u32 tv0 = ths->sys_->get_ms(ths->sys_);
	while(leave--)
	{
		while(!uart_hw_is_recv_data(ths))
		{
			u32 tv1 = ths->sys_->get_ms(ths->sys_);
			u32 dlt_time = ABS_DEC(tv0, tv1);
			if ((timeout > 0) && (dlt_time > timeout)) {
				return -1;
			}
		}
		u8 data = XUartPs_ReadReg(ths->regs_.phy_base_, XUARTPS_FIFO_OFFSET);
		ths->buff_.push_data(&ths->buff_, data);
	}

	return 0;
}

static void send_buff(PsUart* ths, const u8* data, int len)
{
	for (int i = 0; i < len; i++)
	{
		send_data(ths, data[i]);
	//	outbyte(data[i]);
	}
}

static void clear_recv_buff(PsUart* ths)
{
	ths->buff_.reset_fifo(&ths->buff_);
}


void ps_uart_isr_handle(void* arg)
{
	PsUart* uart = (PsUart*)arg;
	uart->irq_count_++;
	u32 IsrStatus;


	u32 uart_base_addr = uart->regs_.phy_base_;

	IsrStatus = XUartPs_ReadReg(uart_base_addr, XUARTPS_IMR_OFFSET);

	IsrStatus &= XUartPs_ReadReg(uart_base_addr, XUARTPS_ISR_OFFSET);



	while(1)
	{
		if (!uart_hw_is_recv_data(uart)) {
			break;
		}
		u8 data = XUartPs_ReadReg(uart_base_addr, XUARTPS_FIFO_OFFSET);
		uart->buff_.push_data(&uart->buff_, data);
	}


	XUartPs_WriteReg(uart_base_addr, XUARTPS_ISR_OFFSET, XUARTPS_IXR_MASK);

}

void uart_recv_poll(PsUart* uart)
{
	u32 uart_base_addr = uart->regs_.phy_base_;
	while(1)
	{
		if (!uart_hw_is_recv_data(uart)) {
			break;
		}
		u8 data = XUartPs_ReadReg(uart_base_addr, XUARTPS_FIFO_OFFSET);
		uart->buff_.push_data(&uart->buff_, data);
	}
}















