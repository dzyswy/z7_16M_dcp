/*
 * stamp_timer_dev.h
 *
 *  Created on: 2020Äê11ÔÂ30ÈÕ
 *      Author: 85710
 */

#ifndef SRC_STAMP_TIMER_DEV_H_
#define SRC_STAMP_TIMER_DEV_H_


#include "xtmrctr.h"


#ifdef __cplusplus
extern "C" {
#endif

//------------------------------------------- StampTimerDev ---------------------------------------------

struct StampTimerDev
{
	XTmrCtr tmr;
};

int stamp_timer_init(struct StampTimerDev* dev, int dev_id);
int stamp_timer_start(struct StampTimerDev* dev);
u64 get_timestamp(struct StampTimerDev* dev);
u32 get_timestamp_ms(struct StampTimerDev* dev);
u64 get_timestamp_us(struct StampTimerDev* dev);

#ifdef __cplusplus
}
#endif


#endif /* SRC_STAMP_TIMER_DEV_H_ */
