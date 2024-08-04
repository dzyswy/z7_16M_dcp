/*
 * gmax4002.cpp
 *
 *  Created on: 2023Äê6ÔÂ17ÈÕ
 *      Author: Administrator
 */


#include "cmos_sensor.h"
#include "fpga_top.h"






//--------------------------------------------------------------------------------------





static void set_senvtc_reset(CmosSensor* ths, u32 value)
{
	ths->regs_.set_value_bit(&ths->regs_, 0, BIT(0), value);
}

static void set_serdes_reset(CmosSensor* ths, u32 value)
{
	ths->regs_.set_value_bit(&ths->regs_, 0, BIT(1), value);
}

static void set_sen_poweren(CmosSensor* ths, u32 value)
{
	ths->regs_.set_value_bit(&ths->regs_, 0, BIT(2), value);
}

static void set_sen_inclk_en(CmosSensor* ths, u32 value)
{
	ths->regs_.set_value_bit(&ths->regs_, 0, BIT(3), value);
}

static void set_sen_sysrstn(CmosSensor* ths, u32 value)
{
	ths->regs_.set_value_bit(&ths->regs_, 0, BIT(4), value);
}

static void set_sen_sysstbn(CmosSensor* ths, u32 value)
{
	ths->regs_.set_value_bit(&ths->regs_, 0, BIT(5), value);
}

static void set_SERDES_BIT_REVERSE(CmosSensor* ths, u32 value)
{
	ths->regs_.set_value_bit(&ths->regs_, 0, BIT(6), value);
}

static void set_SERDES_MANUL_MODE(CmosSensor* ths, u32 value)
{
	ths->regs_.set_value_bit(&ths->regs_, 0, BIT(7), value);
}

static void set_serdes_start(CmosSensor* ths, u32 value)
{
	ths->regs_.set_value_bit(&ths->regs_, 0, BIT(8), value);
}

static void set_stream_on(CmosSensor* ths, u32 value)
{
	ths->regs_.set_value_bit(&ths->regs_, 0, BIT(9), value);
}

static void sensor_cfg_init(CmosSensor* ths)
{
	u32 ACTIVE_WIDTH = 257;
	u32 ACTIVE_HEIGHT = 3280;
	u32 FRAME_WIDTH = 600;
	u32 FRAME_HEIGHT = 3500;

	u32 SOF_H_PATTERN = 0xFFF0;
	u32 SOF_L_PATTERN = 0x00000AB0;
	u32 SOL_H_PATTERN = 0xFFF0;
	u32 SOL_L_PATTERN = 0x00000800;
	u32 EOL_H_PATTERN = 0xFFF0;
	u32 EOL_L_PATTERN = 0x000009D0;
	u32 EOF_H_PATTERN = 0xFFF0;
	u32 EOF_L_PATTERN = 0x00000B60;


	u32 CHECK_SEARCH_LINE = 128;
	u32 CHECK_PATTERN_NUM = 128;
	u32 EYE_RANGE    	  = 4;
	u32 SERDES_SLIP_NUM   = 1;
	u32 SERDES_DELAY_NUM  = 2;


	ths->regs_.set_value(&ths->regs_, 4 * 2, (ACTIVE_HEIGHT << 16) | ACTIVE_WIDTH);
	ths->regs_.set_value(&ths->regs_, 4 * 3, (FRAME_HEIGHT << 16) | FRAME_WIDTH);
	ths->regs_.set_value(&ths->regs_, 4 * 4, SOF_L_PATTERN    );
	ths->regs_.set_value(&ths->regs_, 4 * 5, SOF_H_PATTERN   );
	ths->regs_.set_value(&ths->regs_, 4 * 6, SOL_L_PATTERN   );
	ths->regs_.set_value(&ths->regs_, 4 * 7, SOL_H_PATTERN     );
	ths->regs_.set_value(&ths->regs_, 4 * 8, EOL_L_PATTERN   );
	ths->regs_.set_value(&ths->regs_, 4 * 9, EOL_H_PATTERN     );
	ths->regs_.set_value(&ths->regs_, 4 * 10, EOF_L_PATTERN   );
	ths->regs_.set_value(&ths->regs_, 4 * 11, EOF_H_PATTERN     );
	ths->regs_.set_value(&ths->regs_, 4 * 12, (CHECK_PATTERN_NUM << 16) | CHECK_SEARCH_LINE     );
	ths->regs_.set_value(&ths->regs_, 4 * 13, (SERDES_DELAY_NUM << 16) | (SERDES_SLIP_NUM << 8) | EYE_RANGE       );

}

static u32 get_status(CmosSensor* ths)
{
	return ths->regs_.get_value(&ths->regs_, 4 * 1);
}




static int sensor_spi_set_8u(CmosSensor* ths, u16 address, u8 data)
{
	ths->spi_tx_buff_[0] = (address >> 8) & 0xff;
	ths->spi_tx_buff_[1] = address & 0xff;
	ths->spi_tx_buff_[2] = data;
	ths->spi_->spi_transfer(ths->spi_, ths->spi_tx_buff_, ths->spi_rx_buff_, 3);
	return 0;
}

static int sensor_spi_get_8u(CmosSensor* ths, u16 address, u8* data)
{
	ths->spi_tx_buff_[0] = (address >> 8) & 0xff;
	ths->spi_tx_buff_[1] = address & 0xff;
	ths->spi_->spi_transfer(ths->spi_, ths->spi_tx_buff_, ths->spi_rx_buff_, 3);
	*data = ths->spi_rx_buff_[2];
	return 0;
}

static int sensor_spi_set_exp_time(CmosSensor* ths, u32 value)
{
	ths->spi_tx_buff_[0] = 0x00;
	ths->spi_tx_buff_[1] = 0x16;
	ths->spi_tx_buff_[2] = (value >> 16) & 0xff;
	ths->spi_tx_buff_[3] = (value >> 8) & 0xff;
	ths->spi_tx_buff_[4] = value & 0xff;
	ths->spi_->spi_transfer(ths->spi_, ths->spi_tx_buff_, ths->spi_rx_buff_, 5);
	return 0;
}

static int sensor_spi_get_exp_time(CmosSensor* ths, u32* data)
{
	ths->spi_tx_buff_[0] = 0x80;
	ths->spi_tx_buff_[1] = 0x16;
	ths->spi_->spi_transfer(ths->spi_, ths->spi_tx_buff_, ths->spi_rx_buff_, 5);
	*data = (ths->spi_rx_buff_[2] << 16) | (ths->spi_rx_buff_[3] << 8) | ths->spi_rx_buff_[4];
	return 0;
}








static int ht160a_4112_3280_p45_master_config(CmosSensor* ths)
{

	set_senvtc_reset(ths, 1);
	set_serdes_reset(ths, 1);
	set_sen_poweren(ths, 0);
	set_sen_inclk_en(ths, 0);
	set_sen_sysrstn(ths, 0);
	set_sen_sysstbn(ths, 0);
	set_SERDES_BIT_REVERSE(ths, 1);
	set_SERDES_MANUL_MODE(ths, 0);
	set_serdes_start(ths, 0);
	set_stream_on(ths, 0);
	sensor_cfg_init(ths);

	usleep(1000);



	set_sen_poweren(ths, 1);
	usleep(500000);



	set_sen_sysrstn(ths, 1);
	usleep(100000);

	set_sen_inclk_en(ths, 1);
	usleep(1000);


	set_sen_sysrstn(ths, 0);
	usleep(100000);

	set_sen_sysrstn(ths, 1);
	usleep(100000);


	u8 rdata = 0;

#if 0
	sensor_spi_get_8u(ths, 0x80FC, &rdata);
	usleep(1000);
	plog("sensor ID: 0x%x\r\n", rdata);

	sensor_spi_get_8u(ths, 0x80FD, &rdata);
	usleep(1000);
	plog("sensor ID: 0x%x\r\n", rdata);

	sensor_spi_get_8u(ths, 0x80FE, &rdata);
	usleep(1000);
	plog("sensor ID: 0x%x\r\n", rdata);
#endif


	u16 sensor_config[][2] = {

		{0x00FF, 0x00},
		{0x00D5, 0xEA},
		{0x00A0, 0x24},
		{0x004E, 0x9F},
		{0x004C, 0x01},
		{0x002A, 0x20},
		{0x0023, 0x50},
		{0x000F, 0x0D},
		{0x0010, 0xAB},
		{0x0012, 0x57},
		{0x0061, 0x10},
		{0x0062, 0x3F},
		{0x0065, 0x80},
		{0x004D, 0x86},
		{0x00C2, 0x72},
		{0x008D, 0xF2},
		{0x008E, 0xF0},
		{0x006A, 0xD4},
		{0x006C, 0x3C},
		{0x006D, 0x07},
		{0x0095, 0x10},
		{0x00F2, 0x48},
		{0x002A, 0x20},

//		{0x00A0, 0x25},
//		{0x00A4, 0x83},

		{0x004C, 0x81},
		{0x00FF, 0x3F},

		{0xFFFF, 0xFF},
	};



	u16 count = 0;
	count = 0;
	while(1)
	{
		u16 address = sensor_config[count][0];
		u16 data = sensor_config[count][1];

		if (address == 0xffff) {
			break;
		}

		sensor_spi_set_8u(ths, address, data);
		usleep(2000);

		count++;
	};

#if 1
	count = 0;
	while(1)
	{
		u16 address = sensor_config[count][0];
		u16 data = sensor_config[count][1];

		if (address == 0xffff) {
			break;
		}

		u16 raddr = address | 0x8000;

		sensor_spi_get_8u(ths, raddr, &rdata);
		usleep(1000);

		plog("%d: 0x%x: wr:0x%x, rd:0x%x\r\n", count, address, data, rdata);
		count++;
	};
#endif




//	usleep(50000);
//	set_sen_sysstbn(ths, 1);
//	usleep(50000);


	usleep(500000);

	set_serdes_reset(ths, 0);
	usleep(1000);
	set_serdes_reset(ths, 1);
	usleep(1000);
	set_serdes_reset(ths, 0);
	usleep(10000);

	set_serdes_start(ths, 1);
	usleep(1000);
	set_serdes_start(ths, 0);
	usleep(1000);

	u32 tv0 = ths->sys_->get_ms(ths->sys_);
	while(get_status(ths) != 0x3) {
		u32 tv1 = ths->sys_->get_ms(ths->sys_);
		u32 dlt_time = ABS_DEC(tv0, tv1);
		if (dlt_time > 1000) {
			printf("sensor retrain! status=%x\n", get_status(ths));
			return - 1;
		}
	}
	set_stream_on(ths, 1);


	return 0;
}


static void config_sensor(CmosSensor* ths)
{
	printf("config sensor...\n");
	while(1) {
		int ret = ht160a_4112_3280_p45_master_config(ths);
		if (ret >= 0) {
			break;
		}
	}
	printf("config sensor ok!\n");
}



static void set_exp_time(void* arg, u32 value)
{
	CmosSensor* ths = (CmosSensor*)arg;
	u32 exp_time_num = value / 6.35;
	u32 GRSTW = 3500 - 2 - exp_time_num;
	sensor_spi_set_exp_time(ths, GRSTW);
}


static void init(CmosSensor* ths, FpgaTop* sys)
{
	//class member---------------------------------------------------------------
	ths->sys_ = sys;
	ths->spi_ = &sys->xsensor_spi_;


	config_sensor(ths);
	set_exp_time(ths, 15000);

}

static void read_back_param(CmosSensor* ths)
{
	ths->sensor_vs_frame_count_++;
}

void CmosSensor_(CmosSensor* ths, u32 phy_base, u32 total_size)
{
	RegMem_(&ths->regs_, phy_base, total_size);
	ths->sensor_vs_frame_count_ = 0;

	//class method-----------------------------------------------------------------
	ths->init = init;
	ths->read_back_param = read_back_param;
	ths->set_exp_time = set_exp_time;
}



