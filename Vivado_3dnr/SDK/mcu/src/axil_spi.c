/*
 * axil_spi.c
 *
 *  Created on: 2024Äê3ÔÂ11ÈÕ
 *      Author: Administrator
 */

#include "axil_spi.h"
#include "fpga_top.h"


static void init(XlnxSpi* ths, FpgaTop* sys);
static int spi_transfer(XlnxSpi* ths, u8* tx_buff, u8* rx_buff, u32 len);

void XlnxSpi_(XlnxSpi* ths, u32 phy_base, u32 total_size)
{
	RegMem_(&ths->regs_, phy_base, total_size);
	ths->init = init;
	ths->spi_transfer = spi_transfer;
}



static void init(XlnxSpi* ths, FpgaTop* sys)
{
	ths->sys_ = sys;


}


static int spi_transfer(XlnxSpi* ths, u8* tx_buff, u8* rx_buff, u32 len)
{
	//reset tx rx fifo
	ths->regs_.set_value(&ths->regs_, AXIL_SPI_CR_OFFSET, 0x1E6);


	//send data
	for (u16 i = 0; i < len; i++)
	{
		ths->regs_.set_value(&ths->regs_, AXIL_SPI_DTR_OFFSET, tx_buff[i]);
	}

	// Issue chip select
	ths->regs_.set_value(&ths->regs_, AXIL_SPI_SSR_OFFSET, 0x00);

	//deasserting SPICR master inhibit bit
	ths->regs_.clr_bit(&ths->regs_, AXIL_SPI_CR_OFFSET, BIT(8));

	//check tx empty
	while(!(ths->regs_.get_value(&ths->regs_, AXIL_SPI_SR_OFFSET) & BIT(2)));



	//recv data
	u32 recv_count = 0;
	for (u16 i = 0; i < len; i++)
	{
		//check rx empty
		while(ths->regs_.get_value(&ths->regs_, AXIL_SPI_SR_OFFSET) & BIT(0));
		rx_buff[recv_count] = ths->regs_.get_value(&ths->regs_, AXIL_SPI_DRR_OFFSET);
		recv_count++;
	}

	// Deassert chip select
	ths->regs_.set_value(&ths->regs_, AXIL_SPI_SSR_OFFSET, 0x01);

	//asserting the SPICR master inhibit bit
	ths->regs_.set_bit(&ths->regs_, AXIL_SPI_CR_OFFSET, BIT(8));

	return recv_count;
}

//
//static int spi_flash_read_status(XlnxSpi* ths, u8 cmd, u8* status)
//{
//	ths->tx_buff_[0] = cmd;
//	int ret = spi_transfer(ths, 2);
//	if (ret < 0) {
//		return -1;
//	}
//
//	*status = ths->rx_buff_[1];
//	return 0;
//}
















