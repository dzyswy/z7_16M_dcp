/*
 * ring_fifo.h
 *
 *  Created on: 2023Äê6ÔÂ28ÈÕ
 *      Author: Administrator
 */

#ifndef SRC_RING_FIFO_H_
#define SRC_RING_FIFO_H_

#include "fpga_common.h"

#ifdef __cplusplus
extern "C" {
#endif

//--------------------------------------------------------------------------------------

typedef struct RingFifo RingFifo;


struct RingFifo {
	FpgaObj obj_;
	//class member------------------------------------------------------------------
	u16 wptr_;
	u16 rptr_;
	u8 data_[128];
	u16 deep_;

	//class method-------------------------------------------------------------------
	void (*reset_fifo)(RingFifo* ths);
	int (*is_empty)(RingFifo* ths);
	int (*is_full)(RingFifo* ths);
	int (*push_data)(RingFifo* ths, u8 data);
	int (*pop_data)(RingFifo* ths, u8* data);
	int (*get_valid_len)(RingFifo* ths);
	int (*get_data)(RingFifo* ths, int index, u8* data);
};


void RingFifo_(RingFifo* ths, u16 deep);

#ifdef __cplusplus
}
#endif

#endif /* SRC_RING_FIFO_H_ */
