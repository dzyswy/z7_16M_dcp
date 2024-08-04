/*
 * gmax4002.h
 *
 *  Created on: 2023Äê6ÔÂ17ÈÕ
 *      Author: Administrator
 */

#ifndef SRC_CMOS_SENSOR_H_
#define SRC_CMOS_SENSOR_H_


#include "fpga_common.h"
#include "item_param.h"
#include "io_mem.h"

#ifdef __cplusplus
extern "C" {
#endif






struct FpgaTop;
typedef struct FpgaTop FpgaTop;


struct XlnxSpi;
typedef struct XlnxSpi XlnxSpi;

//--------------------------------------------------------------------------------------

typedef struct CmosSensor CmosSensor;


struct CmosSensor {
	RegMem regs_;

	//class member------------------------------------------------------------------
	FpgaTop* sys_;
	XlnxSpi* spi_;
	u32 sensor_vs_frame_count_;
	u8 spi_tx_buff_[16];
	u8 spi_rx_buff_[16];






	//class method-------------------------------------------------------------------
	void (*init)(CmosSensor* ths, FpgaTop* sys);
	void (*read_back_param)(CmosSensor* ths);

	func_set_exp_time set_exp_time;
};


void CmosSensor_(CmosSensor* ths, u32 phy_base, u32 total_size);

#ifdef __cplusplus
}
#endif


#endif /* SRC_CMOS_SENSOR_H_ */
