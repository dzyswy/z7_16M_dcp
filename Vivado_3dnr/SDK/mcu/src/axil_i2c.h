/*
 * axil_i2c.h
 *
 *  Created on: 2023Äê4ÔÂ27ÈÕ
 *      Author: Administrator
 */

#ifndef SRC_AXIL_I2C_H_
#define SRC_AXIL_I2C_H_


#include "io_mem.h"
#include "xiic.h"
#include "xil_io.h"
#include "xil_printf.h"


#ifdef __cplusplus
extern "C" {
#endif

struct FpgaTop;
typedef struct FpgaTop FpgaTop;

//--------------------------------------------------------------------------------------

typedef struct XlnxI2c XlnxI2c;


struct XlnxI2c {
	RegMem regs_;

	//class member------------------------------------------------------------------
	FpgaTop* sys_;
	u8 slave_address_;
	u8 slave_address_wr_;
	u8 slave_address_rd_;

	//class method-------------------------------------------------------------------
	void (*init)(XlnxI2c* ths, FpgaTop* sys, u8 slave_address);
	int (*i2c_read_a16_8u)(XlnxI2c* ths, u16 address, u8* data);
	int (*i2c_write_a16_8u)(XlnxI2c* ths, u16 address, u32 data);

	int (*i2c_read_a8_16u)(XlnxI2c* ths, u8 address, u16* data);

};


void XlnxI2c_(XlnxI2c* ths, u32 phy_base, u32 total_size);

#ifdef __cplusplus
}
#endif

#endif /* SRC_AXIL_I2C_H_ */
