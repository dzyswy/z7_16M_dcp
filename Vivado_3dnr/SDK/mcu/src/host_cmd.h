/*
 * host_cmd.h
 *
 *  Created on: 2022Äê2ÔÂ18ÈÕ
 *      Author: Administrator
 */

#ifndef SRC_HOST_CMD_H_
#define SRC_HOST_CMD_H_


#include "ps_uart.h"
#include "item_param.h"

#ifdef __cplusplus
extern "C" {
#endif

struct FpgaTop;
typedef struct FpgaTop FpgaTop;

//--------------------------------------------------------------------------------------

typedef struct HostCommand HostCommand;


struct HostCommand {
	FpgaObj obj_;
	//class member------------------------------------------------------------------
	FpgaTop* sys_;
	PsUart* uart_;

	u8 feedback_buff_[25];
	u8 feedback_mode_;


	u8 dehaze_grade_;
	u8 wdr_grade_;
	u8 denoise_2dnr_grade_;
	u8 denoise_3dnr_grade_;
	u8 sharpen_grade_;
	u8 flip_mode_;
	u8 tonemap_grade_;
	u8 low_light_mode_;
	u8 over_light_mode_;

	//item_param ----------------------------------------------------------

	ItemParamUchar param_feedback_mode_;





	//class method-------------------------------------------------------------------
	void (*process)(HostCommand* ths, u32 timeout);

	void (*feedback)(HostCommand* ths);
};


void HostCommand_(HostCommand* ths, FpgaTop* sys, PsUart* uart);





#ifdef __cplusplus
}
#endif

#endif /* SRC_HOST_CMD_H_ */
