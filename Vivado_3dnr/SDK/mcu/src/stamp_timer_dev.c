/*
 * stamp_timer_dev.cpp
 *
 *  Created on: 2020Äê11ÔÂ30ÈÕ
 *      Author: 85710
 */
#include "stamp_timer_dev.h"



//------------------------------------------- StampTimerDev ---------------------------------------------

int stamp_timer_init(struct StampTimerDev* dev, int dev_id)
{
	int ret;
	/*
	 * Initialize the timer counter so that it's ready to use,
	 * specify the device ID that is generated in xparameters.h
	 */
	ret = XTmrCtr_Initialize(&dev->tmr, dev_id);
	if (ret != XST_SUCCESS) {
		return -1;
	}

	/*
	 * Perform a self-test to ensure that the hardware was built
	 * correctly, use the 1st timer in the device (0)
	 */
	ret = XTmrCtr_SelfTest(&dev->tmr, 0);
	if (ret != XST_SUCCESS) {
		return -1;
	}

	/*
	 * Perform a self-test to ensure that the hardware was built
	 * correctly, use the 2nd timer in the device (0)
	 */
	ret = XTmrCtr_SelfTest(&dev->tmr, 1);
	if (ret != XST_SUCCESS) {
		return -1;
	}


	/*
	 * Set a reset value for the timer counter such that it will expire
	 * eariler than letting it roll over from 0, the reset value is loaded
	 * into the timer counter when it is started
	 */
	XTmrCtr_SetResetValue(&dev->tmr, 0, 0);
	XTmrCtr_SetResetValue(&dev->tmr, 0, 0);


	/*
	 * Enable the interrupt of the timer counter so interrupts will occur
	 * and use auto reload mode such that the timer counter will reload
	 * itself automatically and continue repeatedly, without this option
	 * it would expire once only and set the Cascade mode.
	 */
	XTmrCtr_SetOptions(&dev->tmr, 0,
				XTC_AUTO_RELOAD_OPTION |
				XTC_CASCADE_MODE_OPTION);

	/*
	 * Reset the timer counters such that it's incrementing by default
	 */
	 XTmrCtr_Reset(&dev->tmr, 0);
	 XTmrCtr_Reset(&dev->tmr, 1);

	 return 0;
}

int stamp_timer_start(struct StampTimerDev* dev)
{
	XTmrCtr_Start(&dev->tmr, 0);
	return 0;
}

u64 get_timestamp(struct StampTimerDev* dev)
{
	u32 val0 = XTmrCtr_GetValue(&dev->tmr, 0);
	u32 val1 = XTmrCtr_GetValue(&dev->tmr, 1);

	u64 ret = (((u64)val1) << 32) + val0;
	return ret;
}

u32 get_timestamp_ms(struct StampTimerDev* dev)
{
	u64 val = get_timestamp(dev);
	u64 ms = val / 100 / 1000;
	return (u32)ms;
}

u64 get_timestamp_us(struct StampTimerDev* dev)
{
	u64 val = get_timestamp(dev);
	u64 us = val / 100 ;
	return us;
}































