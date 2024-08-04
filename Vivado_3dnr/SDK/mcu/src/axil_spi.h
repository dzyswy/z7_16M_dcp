/*
 * axil_spi.h
 *
 *  Created on: 2024Äê3ÔÂ11ÈÕ
 *      Author: Administrator
 */

#ifndef SRC_AXIL_SPI_H_
#define SRC_AXIL_SPI_H_

#include "io_mem.h"
#include "xil_io.h"
#include "xil_printf.h"
//#include "xspi_l.h"


#define AXIL_SPI_DGIER_OFFSET	0x1C	/**< Global Intr Enable Reg */
#define AXIL_SPI_IISR_OFFSET	0x20	/**< Interrupt status Reg */
#define AXIL_SPI_IIER_OFFSET	0x28	/**< Interrupt Enable Reg */
#define AXIL_SPI_SRR_OFFSET	 	0x40	/**< Software Reset register */
#define AXIL_SPI_CR_OFFSET		0x60	/**< Control register */
#define AXIL_SPI_SR_OFFSET		0x64	/**< Status Register */
#define AXIL_SPI_DTR_OFFSET		0x68	/**< Data transmit */
#define AXIL_SPI_DRR_OFFSET		0x6C	/**< Data receive */
#define AXIL_SPI_SSR_OFFSET		0x70	/**< 32-bit slave select */
#define AXIL_SPI_TFO_OFFSET		0x74	/**< Tx FIFO occupancy */
#define AXIL_SPI_RFO_OFFSET		0x78	/**< Rx FIFO occupancy */


#ifdef __cplusplus
extern "C" {
#endif

struct FpgaTop;
typedef struct FpgaTop FpgaTop;

//--------------------------------------------------------------------------------------

typedef struct XlnxSpi XlnxSpi;


struct XlnxSpi {
	RegMem regs_;

	//class member------------------------------------------------------------------
	FpgaTop* sys_;

	//class method-------------------------------------------------------------------
	void (*init)(XlnxSpi* ths, FpgaTop* sys);
	int (*spi_transfer)(XlnxSpi* ths, u8* tx_buff, u8* rx_buff, u32 len);


};


void XlnxSpi_(XlnxSpi* ths, u32 phy_base, u32 total_size);

#ifdef __cplusplus
}
#endif

#endif /* SRC_AXIL_SPI_H_ */
