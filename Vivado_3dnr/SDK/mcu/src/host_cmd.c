/*
 * host_cmd.cpp
 *
 *  Created on: 2022閿熸枻鎷�2閿熸枻鎷�18閿熸枻鎷�
 *      Author: Administrator
 */
#include "host_cmd.h"
#include "fpga_top.h"





//--------------------------------------------------------------------------------------
static void process(HostCommand* ths, u32 timeout);
static u8 calc_sum_crc(u8* src, int len);
static int check_sum_crc(u8* src, int len, u8 crc);
static int standard_command_do_action(HostCommand* ths, u8* data);
static int camera_command_do_action(HostCommand* ths, u8* data);
static int DYT1229_do_action(HostCommand* ths, u8* data);
static void feedback(HostCommand* ths);
static void feedback_DYT1229(HostCommand* ths);


void HostCommand_(HostCommand* ths, FpgaTop* sys, PsUart* uart)
{
	FpgaObj_(&ths->obj_);

	ths->sys_ = sys;
	ths->uart_ = uart;

#if (DEBUG == 0)
	ths->feedback_mode_ = 1;
#else
	ths->feedback_mode_ = 0;
#endif

	memset(ths->feedback_buff_, 0, sizeof(ths->feedback_buff_));
	ths->feedback_buff_[0] = 0x55;
	ths->feedback_buff_[1] = 0xAA;


	//item param-------------------------------------------------------------------------------
	ItemParamUchar_(&ths->param_feedback_mode_, &ths->feedback_mode_, ITEM_PARAM_READ_WRITE, 0, 1, 1, 1, "feedback:%d");


	ths->process = process;
	ths->feedback = feedback;
}


static void set_dehaze_grade(HostCommand* ths, u8 value)
{
	ths->dehaze_grade_ = value;

	u8 tmp8u;
	float tmp32f;
	switch (ths->dehaze_grade_ )
	{
		case 1://low
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.dehaze_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.dehaze_mode_.param_, &tmp8u);
			ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_, &tmp8u);

			tmp32f = 0.5;
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_, &tmp32f);


			tmp32f = 0.3;
			ths->sys_->xisp_top_.xisp_post_param_.dehaze_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.dehaze_radio_.param_, &tmp32f);


			tmp32f = 0.1;
			ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_, &tmp32f);

		}break;
		case 2://middle
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.dehaze_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.dehaze_mode_.param_, &tmp8u);
			ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_, &tmp8u);

			tmp32f = 0.8;
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_, &tmp32f);


			tmp32f = 0.5;
			ths->sys_->xisp_top_.xisp_post_param_.dehaze_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.dehaze_radio_.param_, &tmp32f);

			tmp32f = 1.2;
			ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_, &tmp32f);

		}break;
		case 3://high
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.dehaze_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.dehaze_mode_.param_, &tmp8u);
			ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_, &tmp8u);

			tmp32f = 1.0;
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_, &tmp32f);


			tmp32f = 0.6;
			ths->sys_->xisp_top_.xisp_post_param_.dehaze_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.dehaze_radio_.param_, &tmp32f);

			tmp32f = 1.8;
			ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_, &tmp32f);

		}break;
		default://close
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_post_param_.dehaze_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.dehaze_mode_.param_, &tmp8u);
			ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_, &tmp8u);


			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_, NULL);


			tmp32f = 0.5;
			ths->sys_->xisp_top_.xisp_post_param_.dehaze_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.dehaze_radio_.param_, &tmp32f);

		}break;

	}
}

static void set_wdr_grade(HostCommand* ths, u8 value)
{
	ths->wdr_grade_ = value;

	u8 tmp8u;
	float tmp32f;
	switch (ths->wdr_grade_ )
	{
		case 1://low
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_, &tmp8u);

			tmp32f = 0.5;
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_, &tmp32f);


			tmp32f = 0.1;
			ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_, &tmp32f);

		}break;
		case 2://middle
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_, &tmp8u);

			tmp32f = 0.8;
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_, &tmp32f);


			tmp32f = 1.2;
			ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_, &tmp32f);

		}break;
		case 3://high
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_, &tmp8u);

			tmp32f = 1.0;
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_, &tmp32f);


			tmp32f = 1.8;
			ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_, &tmp32f);

		}break;
		default://close
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_mode_.param_, &tmp8u);


			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_, NULL);


			tmp32f = 0.5;
			ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.clahe_radio_.param_, &tmp32f);

		}break;

	}
}


static void set_denoise_2dnr_grade(HostCommand* ths, u8 value)
{
	ths->denoise_2dnr_grade_ = value;

	u8 tmp8u;
	float tmp32f;
	switch (ths->denoise_2dnr_grade_ )
	{
		case 1://low
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_mode_.param_, &tmp8u);

			tmp32f = 5.0;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_sigma_new_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_sigma_new_.param_, &tmp32f);

		}break;
		case 2://middle
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_mode_.param_, &tmp8u);

			tmp32f = 15.0;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_sigma_new_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_sigma_new_.param_, &tmp32f);

		}break;
		case 3://high
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_mode_.param_, &tmp8u);

			tmp32f = 30.0;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_sigma_new_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_sigma_new_.param_, &tmp32f);

		}break;
		default://close
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_mode_.param_, &tmp8u);

			tmp32f = 10.0;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_sigma_new_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_2dnr_sigma_new_.param_, &tmp32f);

		}break;

	}
}


static void set_denoise_3dnr_grade(HostCommand* ths, u8 value)
{
	ths->denoise_3dnr_grade_ = value;

	u8 tmp8u;
	float tmp32f;
	switch (ths->denoise_3dnr_grade_ )
	{
		case 1://low
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_mode_.param_, &tmp8u);

			tmp32f = 0.1;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c1_th_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c1_th_.param_, &tmp32f);

			tmp32f = 0.1;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c2_th_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c2_th_.param_, &tmp32f);

		}break;
		case 2://middle
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_mode_.param_, &tmp8u);

			tmp32f = 0.1;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c1_th_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c1_th_.param_, &tmp32f);

			tmp32f = 0.3;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c2_th_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c2_th_.param_, &tmp32f);

		}break;
		case 3://high
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_mode_.param_, &tmp8u);

			tmp32f = 0.1;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c1_th_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c1_th_.param_, &tmp32f);

			tmp32f = 0.9;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c2_th_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c2_th_.param_, &tmp32f);

		}break;
		default://close
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_mode_.param_, &tmp8u);

			tmp32f = 0.1;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c1_th_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c1_th_.param_, &tmp32f);

			tmp32f = 0.1;
			ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c2_th_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.denoise_3dnr_c2_th_.param_, &tmp32f);

		}break;

	}
}



static void set_sharpen_grade(HostCommand* ths, u8 value)
{
	ths->sharpen_grade_ = value;

	u8 tmp8u;
	float tmp32f;
	switch (ths->sharpen_grade_ )
	{
		case 1://low
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.sharpen_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.sharpen_mode_.param_, &tmp8u);

			tmp8u = 0;
			ths->sys_->xisp_top_.xvideo_post_param_.sharpen_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.sharpen_mode_.param_, &tmp8u);

			tmp32f = 1.2;
			ths->sys_->xisp_top_.xisp_post_param_.sharpen_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.sharpen_radio_.param_, &tmp32f);

			tmp32f = 0.5;
			ths->sys_->xisp_top_.xvideo_post_param_.sharpen_radio_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.sharpen_radio_.param_, &tmp32f);

		}break;
		case 2://middle
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.sharpen_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.sharpen_mode_.param_, &tmp8u);
			ths->sys_->xisp_top_.xvideo_post_param_.sharpen_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.sharpen_mode_.param_, &tmp8u);

			tmp32f = 1.5;
			ths->sys_->xisp_top_.xisp_post_param_.sharpen_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.sharpen_radio_.param_, &tmp32f);

			tmp32f = 0.8;
			ths->sys_->xisp_top_.xvideo_post_param_.sharpen_radio_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.sharpen_radio_.param_, &tmp32f);

		}break;
		case 3://high
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.sharpen_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.sharpen_mode_.param_, &tmp8u);
			ths->sys_->xisp_top_.xvideo_post_param_.sharpen_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.sharpen_mode_.param_, &tmp8u);

			tmp32f = 2.0;
			ths->sys_->xisp_top_.xisp_post_param_.sharpen_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.sharpen_radio_.param_, &tmp32f);
			tmp32f = 1.2;
			ths->sys_->xisp_top_.xvideo_post_param_.sharpen_radio_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.sharpen_radio_.param_, &tmp32f);

		}break;
		default://close
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.sharpen_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.sharpen_mode_.param_, &tmp8u);
			tmp8u = 0;
			ths->sys_->xisp_top_.xvideo_post_param_.sharpen_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.sharpen_mode_.param_, &tmp8u);

			tmp32f = 1.1;
			ths->sys_->xisp_top_.xisp_post_param_.sharpen_radio_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.sharpen_radio_.param_, &tmp32f);
			ths->sys_->xisp_top_.xvideo_post_param_.sharpen_radio_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.sharpen_radio_.param_, &tmp32f);

		}break;

	}
}


static void set_tonemap_grade(HostCommand* ths, u8 value)
{
	ths->tonemap_grade_ = value;

	u8 tmp8u;
	float tmp32f;
	switch (ths->tonemap_grade_ )
	{
		case 1://high light
		{
			tmp32f = -8.0;
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_intensity_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_intensity_.param_, &tmp32f);

			tmp32f = 0.0;
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_, &tmp32f);


		}break;
		case 2://low light
		{
			tmp32f = 4.0;
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_intensity_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_intensity_.param_, &tmp32f);

			tmp32f = 0.5;
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_, &tmp32f);

		}break;

		default://norm
		{

			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_intensity_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_intensity_.param_, NULL);
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_light_adapt_.param_, NULL);

		}break;

	}
}


static void set_flip_mode(HostCommand* ths, u8 value)
{
	ths->flip_mode_ = value;

	u8 tmp8u;
	switch (ths->flip_mode_ )
	{
		case 1://hflip
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xyuyv_s2mm_param_.vflip_mode_.param_.set_value(&ths->sys_->xisp_top_.xyuyv_s2mm_param_.vflip_mode_.param_, &tmp8u);

			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.hflip_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.hflip_mode_.param_, &tmp8u);

		}break;
		case 2://vflip
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xyuyv_s2mm_param_.vflip_mode_.param_.set_value(&ths->sys_->xisp_top_.xyuyv_s2mm_param_.vflip_mode_.param_, &tmp8u);

			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_post_param_.hflip_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.hflip_mode_.param_, &tmp8u);

		}break;
		case 3://vhflip
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xyuyv_s2mm_param_.vflip_mode_.param_.set_value(&ths->sys_->xisp_top_.xyuyv_s2mm_param_.vflip_mode_.param_, &tmp8u);

			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.hflip_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.hflip_mode_.param_, &tmp8u);

		}break;
		default://no flip
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xyuyv_s2mm_param_.vflip_mode_.param_.set_value(&ths->sys_->xisp_top_.xyuyv_s2mm_param_.vflip_mode_.param_, &tmp8u);

			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_post_param_.hflip_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.hflip_mode_.param_, &tmp8u);

		}break;

	}
}


static void process(HostCommand* ths, u32 timeout)
{

	u8 temp;
	u8 buff[64] = {0};
	u8 data[64] = {0};
	u8* pdata = (u8*)&buff[0];

	u32 tv0 = ths->sys_->get_ms(ths->sys_);
	while(ths->uart_->buff_.get_valid_len(&ths->uart_->buff_) >= 7)
	{
		u32 tv1 = ths->sys_->get_ms(ths->sys_);
		u32 dlt_time = ABS_DEC(tv0, tv1);
		if (dlt_time > timeout) {
			syslog("HostCommand::uart_recv_demux timeout\r\n");

			ths->uart_->buff_.pop_data(&ths->uart_->buff_, &temp);
			continue;
		}

		ths->uart_->buff_.get_data(&ths->uart_->buff_, 0, &buff[0]);
		ths->uart_->buff_.get_data(&ths->uart_->buff_, 1, &buff[1]);
		ths->uart_->buff_.get_data(&ths->uart_->buff_, 2, &buff[2]);
		ths->uart_->buff_.get_data(&ths->uart_->buff_, 3, &buff[3]);

		if ((pdata[0] == 0x55) && (pdata[1] == 0xaa))
		{
			if (ths->uart_->buff_.get_valid_len(&ths->uart_->buff_) >= 9)
			{
				for (int i = 0; i < 9; i++)
				{
					ths->uart_->buff_.pop_data(&ths->uart_->buff_, &data[i]);
				}
				standard_command_do_action(ths, data);
				break;
			}
		}
		else if ((pdata[0] == 0x81) && (pdata[1] == 0x01))
		{
			if (ths->uart_->buff_.get_valid_len(&ths->uart_->buff_) >= 7)
			{
				for (int i = 0; i < 7; i++)
				{
					ths->uart_->buff_.pop_data(&ths->uart_->buff_, &data[i]);
				}
				camera_command_do_action(ths, data);
				break;
			}
		}
		else
		{
			ths->uart_->buff_.pop_data(&ths->uart_->buff_, &temp);
		}

	}
}

static u8 calc_sum_crc(u8* src, int len)
{
	u8 sum = 0;
	for (int i = 0; i < len; i++)
	{
		sum += src[i];
	}
	return sum;
}

static int check_sum_crc(u8* src, int len, u8 crc)
{
	if (calc_sum_crc(src, len) == crc)
		return 0;
	return -1;
}

static int standard_command_do_action(HostCommand* ths, u8* data)
{
	u8 crc = calc_sum_crc(data, 8);
	if ((data[8] != 0xff) && (crc != data[8]))
	{
		return -1;
	}

	u8* pdata = data;

	u16 cmd_addr_ = ((u16)pdata[2] << 8) | ((u16)pdata[3]);
	u32 cmd_data_ = ((u32)pdata[4] << 24) | ((u32)pdata[5] << 16) | ((u32)pdata[6] << 8) | ((u32)pdata[7]);


#if 1
	switch(cmd_addr_)
	{
		case 0x1001:
		{
			//plog("btn_menu\r\n");
			ths->sys_->xmenu_.btn_menu(&ths->sys_->xmenu_);
		}break;

		case 0x1002:
		{
			//plog("btn_left\r\n");
			ths->sys_->xmenu_.btn_left(&ths->sys_->xmenu_);
		}break;

		case 0x1003:
		{
			//plog("btn_right\r\n");
			ths->sys_->xmenu_.btn_right(&ths->sys_->xmenu_);
		}break;

		case 0x1004:
		{
			//plog("btn_up\r\n");
			ths->sys_->xmenu_.btn_up(&ths->sys_->xmenu_);
		}break;

		case 0x1005:
		{
			//plog("btn_down\r\n");
			ths->sys_->xmenu_.btn_down(&ths->sys_->xmenu_);
		}break;

		case 0x1100:
		{
			ths->sys_->xisp_top_.xdna_param_.xlnx_passwd0_.param_.set_value(&ths->sys_->xisp_top_.xdna_param_.xlnx_passwd0_.param_, &cmd_data_);
			printf("xlnx_passwd0:0x%08x\n", cmd_data_);
		}break;
		case 0x1101:
		{
			ths->sys_->xisp_top_.xdna_param_.xlnx_passwd1_.param_.set_value(&ths->sys_->xisp_top_.xdna_param_.xlnx_passwd1_.param_, &cmd_data_);
			printf("xlnx_passwd1:0x%08x\n", cmd_data_);
		}break;
		case 0x1102:
		{
			ths->sys_->xisp_top_.xdna_param_.xlnx_passwd2_.param_.set_value(&ths->sys_->xisp_top_.xdna_param_.xlnx_passwd2_.param_, &cmd_data_);
			printf("xlnx_passwd2:0x%08x\n", cmd_data_);
		}break;
		case 0x1103:
		{
			ths->sys_->xisp_top_.xdna_param_.xlnx_passwd3_.param_.set_value(&ths->sys_->xisp_top_.xdna_param_.xlnx_passwd3_.param_, &cmd_data_);
			printf("xlnx_passwd3:0x%08x\n", cmd_data_);
		}break;

		case 0x1200:
		{
			ths->sys_->xconfig_.save_config(&ths->sys_->xconfig_);
		}break;

		case 0x1201:
		{
			ths->sys_->xconfig_.load_config(&ths->sys_->xconfig_);
		}break;

		case 0x1202:
		{
			ths->sys_->xconfig_.load_default_factory_config(&ths->sys_->xconfig_);
		}break;

		default:
			break;
	}

#endif
	return 0;
}


static int camera_command_do_action(HostCommand* ths, u8* data)
{
	u8* pdata = data;

	u16 cmd_addr = ((u16)pdata[2] << 8) | ((u16)pdata[3]);
	u16 cmd_data = ((u16)pdata[4] << 8) | ((u16)pdata[5]);



	u8 tmp8u;
	u16 tmp16u;
	u32 tmp32u;
	float tmp32f;

#if 1
	switch(cmd_addr)
	{

		//dehaze low
		case 0x3701:
		{
			set_dehaze_grade(ths, 1);

		}break;

		//dehaze middle
		case 0x3702:
		{
			set_dehaze_grade(ths, 2);
		}break;

		//dehaze high
		case 0x3703:
		{
			set_dehaze_grade(ths, 3);
		}break;

		//dehaze close
		case 0x3700:
		{
			set_dehaze_grade(ths, 0);

		}break;

		//WDR low
		case 0x0601:
		{
			set_wdr_grade(ths, 1);
		}break;

		//WDR middle
		case 0x0602:
		{
			set_wdr_grade(ths, 2);
		}break;

		//WDR high
		case 0x0603:
		{
			set_wdr_grade(ths, 3);
		}break;

		//WDR close
		case 0x0600:
		{
			set_wdr_grade(ths, 0);
		}break;


		//2DNR low
		case 0x5301:
		{
			set_denoise_2dnr_grade(ths, 1);
		}break;


		//2DNR middle
		case 0x5302:
		{
			set_denoise_2dnr_grade(ths, 2);
		}break;

		//2DNR high
		case 0x5303:
		{
			set_denoise_2dnr_grade(ths, 3);
		}break;

		//2DNR close
		case 0x5300:
		{
			set_denoise_2dnr_grade(ths, 0);
		}break;


		//3DNR low
		case 0x5401:
		{
			set_denoise_3dnr_grade(ths, 1);
		}break;

		//3DNR middle
		case 0x5402:
		{
			set_denoise_3dnr_grade(ths, 2);
		}break;

		//3DNR high
		case 0x5403:
		{
			set_denoise_3dnr_grade(ths, 3);
		}break;

		//3DNR close
		case 0x5400:
		{
			set_denoise_3dnr_grade(ths, 0);
		}break;


		//sharpen low
		case 0x5C01:
		{
			set_sharpen_grade(ths, 1);
		}break;

		//sharpen middle
		case 0x5C02:
		{
			set_sharpen_grade(ths, 2);
		}break;

		//sharpen high
		case 0x5C03:
		{
			set_sharpen_grade(ths, 3);
		}break;

		//sharpen close
		case 0x5C00:
		{
			set_sharpen_grade(ths, 0);
		}break;


		//ss +
		case 0x1904:
		{
			ths->sys_->xisp_top_.xisp_post_param_.rich_ss_.param_.inc_value(&ths->sys_->xisp_top_.xisp_post_param_.rich_ss_.param_, NULL);

		}break;

		//ss -
		case 0x1905:
		{
			ths->sys_->xisp_top_.xisp_post_param_.rich_ss_.param_.dec_value(&ths->sys_->xisp_top_.xisp_post_param_.rich_ss_.param_, NULL);

		}break;

		//ss -
		case 0x1906:
		{
			ths->sys_->xisp_top_.xisp_post_param_.rich_ss_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.rich_ss_.param_, NULL);

		}break;


		//cc +
		case 0x1704:
		{
			ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_contrast_.param_.inc_value(&ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_contrast_.param_, NULL);

		}break;

		//cc -
		case 0x1705:
		{
			ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_contrast_.param_.dec_value(&ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_contrast_.param_, NULL);

		}break;

		//cc reset
		case 0x1706:
		{
			ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_contrast_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_contrast_.param_, NULL);

		}break;

		//bb +
		case 0x0d04:
		{
			ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_brightness_.param_.inc_value(&ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_brightness_.param_, NULL);

		}break;

		//bb -
		case 0x0d05:
		{
			ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_brightness_.param_.dec_value(&ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_brightness_.param_, NULL);

		}break;

		//bb reset
		case 0x0d06:
		{
			ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_brightness_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_brightness_.param_, NULL);

		}break;


		//gamma +
		case 0x0e04:
		{
			ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_gamma_new_.param_.inc_value(&ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_gamma_new_.param_, NULL);

		}break;

		//gamma -
		case 0x0e05:
		{
			ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_gamma_new_.param_.dec_value(&ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_gamma_new_.param_, NULL);

		}break;

		//gamma reset
		case 0x0e06:
		{
			ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_gamma_new_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.rgb_proc_gamma_new_.param_, NULL);

		}break;


		//color
		case 0x6300:
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_post_param_.yuyv_gray_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.yuyv_gray_mode_.param_, &tmp8u);

		}break;

		//gray
		case 0x6301:
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.yuyv_gray_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.yuyv_gray_mode_.param_, &tmp8u);

		}break;

		case 0x4C00://gray level reset
		{
			ths->sys_->xisp_top_.xisp_3a_param_.ae_gray_level_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.ae_gray_level_.param_, NULL);

		}break;

		case 0x4C01://gray level inc
		{
			ths->sys_->xisp_top_.xisp_3a_param_.ae_gray_level_.param_.inc_value(&ths->sys_->xisp_top_.xisp_3a_param_.ae_gray_level_.param_, NULL);
		}break;

		case 0x4C02://gray level dec
		{
			ths->sys_->xisp_top_.xisp_3a_param_.ae_gray_level_.param_.dec_value(&ths->sys_->xisp_top_.xisp_3a_param_.ae_gray_level_.param_, NULL);
		}break;

		case 0x4C03://gray level set
		{
			tmp16u = cmd_data;
			ths->sys_->xisp_top_.xisp_3a_param_.ae_gray_level_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.ae_gray_level_.param_, &tmp16u);
		}break;

		case 0x4D00://tonemap close
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_mode_.param_, &tmp8u);
		}break;

		case 0x4D01://tonemap open
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_3a_param_.tonemap_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.tonemap_mode_.param_, &tmp8u);
		}break;

		//scale
		case 0x4600:
		{
			tmp32f = cmd_data / 100.0;
			ths->sys_->xisp_top_.xvideo_mm2s_param_.resize_scale_.param_.set_value(&ths->sys_->xisp_top_.xvideo_mm2s_param_.resize_scale_.param_, &tmp32f);
		}break;

		//freeze
		case 0x0c00:
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xyuyv_s2mm_param_.freeze_mode_new_.param_.set_value(&ths->sys_->xisp_top_.xyuyv_s2mm_param_.freeze_mode_new_.param_, &tmp8u);
		}break;

 		//defreeze
		case 0x0c01:
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xyuyv_s2mm_param_.freeze_mode_new_.param_.set_value(&ths->sys_->xisp_top_.xyuyv_s2mm_param_.freeze_mode_new_.param_, &tmp8u);
		}break;

		//cursor open
		case 0x6701:
		{
			ths->sys_->xisp_top_.xvideo_post_param_.cursor_mode_.param_.inc_value(&ths->sys_->xisp_top_.xvideo_post_param_.cursor_mode_.param_, NULL);
			ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_mode_.param_.inc_value(&ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_mode_.param_, NULL);
		}break;

		//cursor close
		case 0x6700:
		{
			ths->sys_->xisp_top_.xvideo_post_param_.cursor_mode_.param_.dec_value(&ths->sys_->xisp_top_.xvideo_post_param_.cursor_mode_.param_, NULL);
			ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_mode_.param_.dec_value(&ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_mode_.param_, NULL);
		}break;

		//cursor reset
		case 0x6800:
		{
			ths->sys_->xisp_top_.xvideo_post_param_.cursor_center_.param_.inc_value(&ths->sys_->xisp_top_.xvideo_post_param_.cursor_center_.param_, NULL);
			ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_center_.param_.inc_value(&ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_center_.param_, NULL);
		}break;

		//cursor up
		case 0x6801:
		{
			ths->sys_->xisp_top_.xvideo_post_param_.cursor_cy_.param_.dec_value(&ths->sys_->xisp_top_.xvideo_post_param_.cursor_cy_.param_, NULL);
			ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_cy_.param_.dec_value(&ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_cy_.param_, NULL);
		}break;

		//cursor down
		case 0x6802:
		{
			ths->sys_->xisp_top_.xvideo_post_param_.cursor_cy_.param_.inc_value(&ths->sys_->xisp_top_.xvideo_post_param_.cursor_cy_.param_, NULL);
			ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_cy_.param_.inc_value(&ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_cy_.param_, NULL);
		}break;

		//cursor left
		case 0x6803:
		{
			ths->sys_->xisp_top_.xvideo_post_param_.cursor_cx_.param_.dec_value(&ths->sys_->xisp_top_.xvideo_post_param_.cursor_cx_.param_, NULL);
			ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_cx_.param_.dec_value(&ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_cx_.param_, NULL);
		}break;

		//cursor right
		case 0x6804:
		{
			ths->sys_->xisp_top_.xvideo_post_param_.cursor_cx_.param_.inc_value(&ths->sys_->xisp_top_.xvideo_post_param_.cursor_cx_.param_, NULL);
			ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_cx_.param_.inc_value(&ths->sys_->xisp_top_.xphoto_mm2s_param_.cursor_cx_.param_, NULL);
		}break;


		//exp time manual
		case 0x4a00:
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_3a_param_.ae_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.ae_mode_.param_, &tmp8u);

			tmp32u = cmd_data;
			ths->sys_->xisp_top_.xisp_3a_param_.ae_exp_time_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.ae_exp_time_.param_, &tmp32u);

		}break;

		//exp time inc
		case 0x4a01:
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_3a_param_.ae_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.ae_mode_.param_, &tmp8u);

			tmp32u = cmd_data;
			ths->sys_->xisp_top_.xisp_3a_param_.ae_exp_time_.param_.inc_value(&ths->sys_->xisp_top_.xisp_3a_param_.ae_exp_time_.param_, &tmp32u);

		}break;

		//exp time dec
		case 0x4a02:
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_3a_param_.ae_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.ae_mode_.param_, &tmp8u);

			tmp32u = cmd_data;
			ths->sys_->xisp_top_.xisp_3a_param_.ae_exp_time_.param_.dec_value(&ths->sys_->xisp_top_.xisp_3a_param_.ae_exp_time_.param_, &tmp32u);

		}break;

		//exp time auto
		case 0x4a03:
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_3a_param_.ae_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.ae_mode_.param_, &tmp8u);


		}break;

		//ae gain manual
		case 0x4b00:
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_3a_param_.ag_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.ag_mode_.param_, &tmp8u);

			tmp32f = cmd_data / 100.0;
			ths->sys_->xisp_top_.xisp_3a_param_.ag_alpha_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.ag_alpha_.param_, &tmp32f);

		}break;

		//ae gain inc
		case 0x4b01:
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_3a_param_.ag_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.ag_mode_.param_, &tmp8u);

			tmp32f = cmd_data / 100.0;
			ths->sys_->xisp_top_.xisp_3a_param_.ag_alpha_.param_.inc_value(&ths->sys_->xisp_top_.xisp_3a_param_.ag_alpha_.param_, &tmp32f);

		}break;

		//ae gain dec
		case 0x4b02:
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_3a_param_.ag_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.ag_mode_.param_, &tmp8u);

			tmp32f = cmd_data / 100.0;
			ths->sys_->xisp_top_.xisp_3a_param_.ag_alpha_.param_.dec_value(&ths->sys_->xisp_top_.xisp_3a_param_.ag_alpha_.param_, &tmp32f);

		}break;

		//ae gain auto
		case 0x4b03:
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_3a_param_.ag_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.ag_mode_.param_, &tmp8u);
		}break;

		case 0x4E00://tonemap norm
		{
			set_tonemap_grade(ths, 0);
		}break;

		case 0x4E01://tonemap high light
		{
			set_tonemap_grade(ths, 1);
		}break;

		case 0x4E02://tonemap low light
		{
			set_tonemap_grade(ths, 2);
		}break;

		case 0x4F00://dpc close
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_3a_param_.dpc_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.dpc_mode_.param_, &tmp8u);
		}break;

		case 0x4F01://dpc open
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_3a_param_.dpc_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_3a_param_.dpc_mode_.param_, &tmp8u);
		}break;

		//no flip
		case 0x6600:
		{
			set_flip_mode(ths, 0);
		}break;

		//hflip
		case 0x6601:
		{
			set_flip_mode(ths, 1);
		}break;

		//vflip
		case 0x6602:
		{
			set_flip_mode(ths, 2);
		}break;

		//vhflip
		case 0x6603:
		{
			set_flip_mode(ths, 3);
		}break;

		//tpg close
		case 0x6400:
		{
			tmp8u = 0;
			ths->sys_->xisp_top_.xisp_post_param_.tpg_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.tpg_mode_.param_, &tmp8u);

		}break;

		//tpg open
		case 0x6401:
		{
			tmp8u = 1;
			ths->sys_->xisp_top_.xisp_post_param_.tpg_mode_.param_.set_value(&ths->sys_->xisp_top_.xisp_post_param_.tpg_mode_.param_, &tmp8u);

		}break;

		//feedback close
		case 0x7000:
		{
			tmp8u = 0;
			ths->sys_->xhost_cmd_.param_feedback_mode_.param_.set_value(&ths->sys_->xhost_cmd_.param_feedback_mode_.param_, &tmp8u);

		}break;

		//feedback open
		case 0x7001:
		{
			tmp8u = 0;
			ths->sys_->xhost_cmd_.param_feedback_mode_.param_.set_value(&ths->sys_->xhost_cmd_.param_feedback_mode_.param_, &tmp8u);

		}break;


		//save config
		case 0x0300:
		{
			ths->sys_->xconfig_.save_config(&ths->sys_->xconfig_);
		}break;

		//load default config
		case 0x0400:
		{
			ths->sys_->xconfig_.load_default_factory_config(&ths->sys_->xconfig_);
		}break;

	}
#endif

	return 0;
}


static void feedback(HostCommand* ths)
{
	if (!ths->feedback_mode_) {
		return;
	}

#if 1
	//version
	ths->feedback_buff_[2] = (SOFTWARE_VERSION >> 24) & 0xff;
	ths->feedback_buff_[3] = (SOFTWARE_VERSION >> 16) & 0xff;
	ths->feedback_buff_[4] = (SOFTWARE_VERSION >> 8) & 0xff;
	ths->feedback_buff_[5] = SOFTWARE_VERSION & 0xff;

	//ae_exp_time_
	u32 ae_exp_time_ = ths->sys_->xisp_top_.xisp_3a_param_.ae_exp_time_.get_value_uint(&ths->sys_->xisp_top_.xisp_3a_param_.ae_exp_time_);
	ths->feedback_buff_[6] = (ae_exp_time_ >> 8) & 0xff;
	ths->feedback_buff_[7] = ae_exp_time_ & 0xff;

	//ae_gain_;
	float ag_alpha_ = ths->sys_->xisp_top_.xisp_3a_param_.ag_alpha_.get_value_float(&ths->sys_->xisp_top_.xisp_3a_param_.ag_alpha_);
	u16 ag_alpha_16u = ag_alpha_ * 100;
	ths->feedback_buff_[8] = (ag_alpha_16u >> 8) & 0xff;
	ths->feedback_buff_[9] = ag_alpha_16u & 0xff;

	//black_gray_aver_
	u16 black_gray_aver_ = ths->sys_->xisp_top_.xisp_3a_param_.black_gray_aver_.get_value_ushort(&ths->sys_->xisp_top_.xisp_3a_param_.black_gray_aver_);
	ths->feedback_buff_[10] = (black_gray_aver_ >> 8) & 0xff;
	ths->feedback_buff_[11] = black_gray_aver_ & 0xff;

	//af_dx_
	u16 af_dx_ = ths->sys_->xisp_top_.xisp_3a_param_.af_dx_.get_value_ushort(&ths->sys_->xisp_top_.xisp_3a_param_.af_dx_);
	ths->feedback_buff_[12] = (af_dx_ >> 8) & 0xff;
	ths->feedback_buff_[13] = af_dx_ & 0xff;

	//resize_scale_
	float resize_scale_ = ths->sys_->xisp_top_.xvideo_mm2s_param_.resize_scale_.get_value_float(&ths->sys_->xisp_top_.xvideo_mm2s_param_.resize_scale_);
	u16 resize_scale_16u = resize_scale_ * 100;
	ths->feedback_buff_[14] = (resize_scale_16u >> 8) & 0xff;
	ths->feedback_buff_[15] = resize_scale_16u & 0xff;

	//temperature
	char temperature = 25;
	ths->feedback_buff_[16] = temperature;

	//iris
	ths->feedback_buff_[17] = 0;

	ths->feedback_buff_[19] = calc_sum_crc(&ths->feedback_buff_[0], 19);
	ths->uart_->send_buff(ths->uart_, (const u8*)&ths->feedback_buff_[0], 20);

#endif
}













