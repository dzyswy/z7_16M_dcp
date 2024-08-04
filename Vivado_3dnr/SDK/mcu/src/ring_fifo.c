/*
 * ring_fifo.cpp
 *
 *  Created on: 2023Äê6ÔÂ28ÈÕ
 *      Author: Administrator
 */


#include "ring_fifo.h"



//--------------------------------------------------------------------------------------


static void reset_fifo(RingFifo* ths);
static int is_empty(RingFifo* ths);
static int is_full(RingFifo* ths);
static int push_data(RingFifo* ths, u8 data);
static int pop_data(RingFifo* ths, u8* data);
static int get_valid_len(RingFifo* ths);
static int get_data(RingFifo* ths, int index, u8* data);


void RingFifo_(RingFifo* ths, u16 deep)
{
	FpgaObj_(&ths->obj_);

	ths->wptr_ = 0;
	ths->rptr_ = 0;
	ths->deep_ = 128;

	ths->reset_fifo = reset_fifo;
	ths->is_empty = is_empty;
	ths->is_full = is_full;
	ths->push_data = push_data;
	ths->pop_data = pop_data;
	ths->get_valid_len = get_valid_len;
	ths->get_data = get_data;
}

static void reset_fifo(RingFifo* ths)
{
	ths->wptr_ = 0;
	ths->rptr_ = 0;
}

static int is_empty(RingFifo* ths)
{
	if ((ths->wptr_ % ths->deep_) == (ths->rptr_ % ths->deep_)) {
		return 1;
	}
	return 0;
}

static int is_full(RingFifo* ths)
{
	if (((ths->wptr_ + 1) % ths->deep_) == (ths->rptr_ % ths->deep_)) {
		return 1;
	}
	return 0;
}

static int push_data(RingFifo* ths, u8 data)
{
	if (is_full(ths)) {
		return -1;
	}
	ths->data_[ths->wptr_ % ths->deep_] = data;
	ths->wptr_++;
	return 0;
}

static int pop_data(RingFifo* ths, u8* data)
{
	if (is_empty(ths)) {
		return -1;
	}

	*data = ths->data_[ths->rptr_ % ths->deep_];
	ths->rptr_++;
	return 0;
}

static int get_valid_len(RingFifo* ths)
{
	u16 rptr = ths->rptr_ % ths->deep_;
	u16 wptr = ths->wptr_ % ths->deep_;

	if (wptr >= rptr)
		return (wptr - rptr);
	else
		return (wptr + ths->deep_ - rptr);
}

static int get_data(RingFifo* ths, int index, u8* data)
{
	if ((index < 0) || (index >= get_valid_len(ths)))
		return -1;

	*data = ths->data_[(ths->rptr_ + index) % ths->deep_];
	return 0;
}
