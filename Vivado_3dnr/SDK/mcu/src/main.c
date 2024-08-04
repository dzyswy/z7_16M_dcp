/*
 * main.c
 *
 *  Created on: 2023Äê11ÔÂ1ÈÕ
 *      Author: Administrator
 */
#include "fpga_top.h"

//int main()
//{
//
//	struct StampTimerDev sys_timer_;
//
//	stamp_timer_init(&sys_timer_, SYS_TIMER_DEV_ID);
//	stamp_timer_start(&sys_timer_);
//
//	while(1) {
//
//		u64 val = get_timestamp(&sys_timer_);
//	}
//
//	return 0;
//}

FpgaTop g_fpga;

int main()
{
	FpgaTop_(&g_fpga);
	g_fpga.init(&g_fpga);
	g_fpga.process(&g_fpga);

	return 0;
}


