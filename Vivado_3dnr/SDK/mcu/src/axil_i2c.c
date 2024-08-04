/*
 * axil_i2c.cpp
 *
 *  Created on: 2023Äê4ÔÂ27ÈÕ
 *      Author: Administrator
 */

#include "axil_i2c.h"
#include "fpga_top.h"




//--------------------------------------------------------------------------------------
static void init(XlnxI2c* ths, FpgaTop* sys, u8 slave_address);
static int i2c_recv_a16_buff(XlnxI2c* ths, u16 address, u8* buff, u32 len);
static int i2c_read_a16_8u(XlnxI2c* ths, u16 address, u8* data);
static int i2c_write_a16_8u(XlnxI2c* ths, u16 address, u32 data);
static int i2c_read_a8_buff(XlnxI2c* ths, u8 address, u8* buff, u32 len);
static int i2c_read_a8_16u(XlnxI2c* ths, u8 address, u16* data);


void XlnxI2c_(XlnxI2c* ths, u32 phy_base, u32 total_size)
{
	RegMem_(&ths->regs_, phy_base, total_size);

	ths->init = init;
	ths->i2c_read_a16_8u = i2c_read_a16_8u;
	ths->i2c_write_a16_8u = i2c_write_a16_8u;
	ths->i2c_read_a8_16u = i2c_read_a8_16u;
}



static void init(XlnxI2c* ths, FpgaTop* sys, u8 slave_address)
{
	ths->sys_ = sys;
	ths->slave_address_ = slave_address;
	ths->slave_address_wr_ = slave_address << 1;
	ths->slave_address_rd_ = (slave_address << 1) + 1;

	XIic_IntrGlobalDisable(ths->regs_.phy_base_);


	//ths->regs_.set_value(&ths->regs_, 0x144, 0x20);
}


static int i2c_recv_a16_buff(XlnxI2c* ths, u16 address, u8* buff, u32 len)
{
	u8 mem[2];

	mem[0] = address & 0xff;
	mem[1] = (address >> 8) & 0xff;
	while(XIic_ReadReg(ths->regs_.phy_base_, XIIC_SR_REG_OFFSET) & XIIC_SR_BUS_BUSY_MASK);
	int ret = XIic_Send(ths->regs_.phy_base_, ths->slave_address_, mem, 2, XIIC_REPEATED_START);
	if (ret != 2) {

		/* Send is aborted so reset Tx FIFO */
		u32 cr = XIic_ReadReg(ths->regs_.phy_base_, XIIC_CR_REG_OFFSET);
		XIic_WriteReg(ths->regs_.phy_base_, XIIC_CR_REG_OFFSET, cr | XIIC_CR_TX_FIFO_RESET_MASK);
		XIic_WriteReg(ths->regs_.phy_base_, XIIC_CR_REG_OFFSET, XIIC_CR_ENABLE_DEVICE_MASK);
		printf("Recv is aborted so reset Tx FIFO\n");
		return -1;
	}

	ret = XIic_Recv(ths->regs_.phy_base_, ths->slave_address_, buff, len, XIIC_STOP);
	if (ret != len) {
		return -1;
	}

	return 0;
}

static int i2c_read_a16_8u(XlnxI2c* ths, u16 address, u8* data)
{
	u8 buff[1];
	int ret = i2c_recv_a16_buff(ths, address, buff, 1);
	if (ret < 0) {
		return -1;
	}

	*data = buff[0];
	return 0;
}


static int i2c_write_a16_8u(XlnxI2c* ths, u16 address, u32 data)
{
	u8 buff[3];
	buff[0] = address & 0xff;
	buff[1] = (address >> 8) & 0xff;
	buff[2] = data & 0xff;
	XIic_Send(ths->regs_.phy_base_, ths->slave_address_,  buff, 3, XIIC_STOP);
	usleep(10000);
	return 0;
}


static int i2c_read_a8_buff(XlnxI2c* ths, u8 address, u8* buff, u32 len)
{
	u8 mem[1];
	mem[0] = address & 0xff;
	while(XIic_ReadReg(ths->regs_.phy_base_, XIIC_SR_REG_OFFSET) & XIIC_SR_BUS_BUSY_MASK);
	int ret = XIic_Send(ths->regs_.phy_base_, ths->slave_address_, mem, 1, XIIC_REPEATED_START);
	if (ret != 1) {

		/* Send is aborted so reset Tx FIFO */
		u32 cr = XIic_ReadReg(ths->regs_.phy_base_, XIIC_CR_REG_OFFSET);
		XIic_WriteReg(ths->regs_.phy_base_, XIIC_CR_REG_OFFSET, cr | XIIC_CR_TX_FIFO_RESET_MASK);
		XIic_WriteReg(ths->regs_.phy_base_, XIIC_CR_REG_OFFSET, XIIC_CR_ENABLE_DEVICE_MASK);
		printf("Recv is aborted so reset Tx FIFO\n");
		return -1;
	}

	ret = XIic_Recv(ths->regs_.phy_base_, ths->slave_address_, buff, len, XIIC_STOP);
	if (ret != len) {
		return -1;
	}

	return 0;
}

static int i2c_read_a8_16u(XlnxI2c* ths, u8 address, u16* data)
{
	u8 buff[2];
	int ret = i2c_read_a8_buff(ths, address, buff, 2);
	if (ret < 0) {
		return -1;
	}

	*data = ((u16)buff[0] << 8) | ((u16)buff[1]);
	return 0;
}



