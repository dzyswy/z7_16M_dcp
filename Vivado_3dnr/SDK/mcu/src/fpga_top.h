/*
 * fpga_top.h
 *
 *  Created on: 2022��1��26��
 *      Author: Administrator
 */

#ifndef SRC_FPGA_TOP_H_
#define SRC_FPGA_TOP_H_



#include "xil_printf.h"
#include "xscugic.h"
#include "stamp_timer_dev.h"


#include "board_param.h"

#include "host_cmd.h"




#include "axil_spi.h"
#include "cmos_sensor.h"


#include "xisp_top.h"


#include "menu_osd.h"
#include "config_param.h"


#ifdef __cplusplus
extern "C" {
#endif




//--------------------------------------------------------------------------------------
typedef struct FpgaTop FpgaTop;


struct FpgaTop {
	FpgaObj obj_;
	//class member------------------------------------------------------------------


	u32 version_;


	struct StampTimerDev sys_timer_;
	XScuGic xintc_;

	PsUart host_uart_;
	HostCommand xhost_cmd_;

	XlnxI2c xeeprom_i2c_;
	ConfigParam xconfig_;



	XlnxSpi xsensor_spi_;
	CmosSensor xsensor_;

	XIspTop xisp_top_;




	MenuOsd xmenu_;



	//item_param ----------------------------------------------------------
	ItemParamUint param_sensor_vs_frame_count_;
	ItemParamUint param_host_uart_irq_count_;


	//class method-------------------------------------------------------------------
	void (*init)(FpgaTop* ths);
	void (*process)(FpgaTop* ths);
	u32 (*get_ms)(FpgaTop* ths);
	u64 (*get_us)(FpgaTop* ths);

};


void FpgaTop_(FpgaTop* ths);







#ifdef __cplusplus
}
#endif


#endif /* SRC_FPGA_TOP_H_ */
