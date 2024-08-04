
#include "config_param.h"


#include "fpga_top.h"


extern FpgaTop g_fpga;


//--------------------------------------------------------------------------------------
static int save_config(ConfigParam* ths);
static int load_config(ConfigParam* ths);
static int load_default_factory_config(ConfigParam* ths);
static int load_default_user_config(ConfigParam* ths);
static void func_save_config(void* arg);
static void func_load_config(void* arg);
static void func_load_default_factory_config(void* arg); 

ConfigItem g_config_items[] = {

	//dna
	{ 0, 31,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xdna_param_.xlnx_passwd0_},
	{ 1, 31,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xdna_param_.xlnx_passwd1_},
	{ 2, 31,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xdna_param_.xlnx_passwd2_},
	{ 3, 31,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xdna_param_.xlnx_passwd3_},

//	//ISP_3A
//	{ 4, 15,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.black_beta_},
//
//
//	{ 8, 15,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ae_gray_level_},
//
//
//	{16,  7,  0,  0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_mode_},
//	{16, 15,  8,  8,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_auto_},
//	{16, 23, 16,  16,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.raw_mode_},
//	{17, 31,  0,  0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_rcoe_},
//	{18, 31,  0,  0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_gcoe_},
//	{19, 31,  0,  0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_bcoe_},
//
//	{20, 31,  0,  0,    (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.denoise_2dnr_sigma_new_},
//	{21, 31,  0,  0,    (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.denoise_3dnr_c2_th_},
//	{22,  7,  0,  0,    (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.denoise_2dnr_mode_},
//	{22, 15,  8,  8,    (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.denoise_3dnr_mode_},
//
//	//ISP_Post
//	{23, 31,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.dehaze_radio_},
//	{24,  7,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.dehaze_mode_},
//	{24, 15,  8,  8, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.clahe_mode_},
//	{24, 23, 16, 16, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.sharpen_mode_},
//	{24, 31, 24, 24, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.yuyv_gray_mode_},
//	{25, 31,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.clahe_radio_},
//	{26, 31,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.sharpen_radio_},
//	{27, 31,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.rich_ss_},
//	{28, 31,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.rgb_proc_contrast_},
//	{29, 15,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.rgb_proc_brightness_},
//	{30, 31,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.rgb_proc_gamma_new_},
//
//	//FUNC
//	{40,  7,  0,  0, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.hflip_mode_},
//	{40, 15,  8,  8, (ItemParam*)&g_fpga.xisp_top_.xyuyv_s2mm_param_.vflip_mode_},
//


};




void ConfigParam_(ConfigParam* ths, FpgaTop* sys, XlnxI2c* iic)
{
	FpgaObj_(&ths->obj_);

	ths->sys_ = sys;
	ths->iic_ = iic;

	for (u16 k = 0; k < CONFIG_PARAM_NUMBER; k++)
	{
		ths->param_mem_[k] = 0;
	}



	//item_param ----------------------------------------------------------
	ItemAction_(&ths->param_save_config_, ths, func_save_config);
	ItemAction_(&ths->param_load_config_, ths, func_load_config);
	ItemAction_(&ths->param_load_default_factory_config_, ths, func_load_default_factory_config); 


	ths->save_config = save_config;
	ths->load_config = load_config;
	ths->load_default_factory_config = load_default_factory_config; 


}



static int iic_set_value(ConfigParam* ths, u32 address, u32 value)
{
	u16 addr0 = address;
	u16 addr1 = address + 1;
	u16 addr2 = address + 2;
	u16 addr3 = address + 3;

	u32 data0 = value & 0xff;
	u32 data1 = (value >> 8) & 0xff;
	u32 data2 = (value >> 16) & 0xff;
	u32 data3 = (value >> 24) & 0xff;


	ths->iic_->i2c_write_a16_8u(ths->iic_, addr0, data0);
	usleep(200);
	ths->iic_->i2c_write_a16_8u(ths->iic_, addr1, data1);
	usleep(200);
	ths->iic_->i2c_write_a16_8u(ths->iic_, addr2, data2);
	usleep(200);
	ths->iic_->i2c_write_a16_8u(ths->iic_, addr3, data3);
	usleep(200);

	return 0;
}


static int iic_get_value(ConfigParam* ths, u32 address, u32* value)
{
	u16 addr0 = address;
	u16 addr1 = address + 1;
	u16 addr2 = address + 2;
	u16 addr3 = address + 3;

	u8 data0 = 0;
	u8 data1 = 0;
	u8 data2 = 0;
	u8 data3 = 0;

	ths->iic_->i2c_read_a16_8u(ths->iic_, addr0, &data0);
	usleep(200);
	ths->iic_->i2c_read_a16_8u(ths->iic_, addr1, &data1);
	usleep(200);
	ths->iic_->i2c_read_a16_8u(ths->iic_, addr2, &data2);
	usleep(200);
	ths->iic_->i2c_read_a16_8u(ths->iic_, addr3, &data3);
	usleep(200);

	u32 data = (data3 << 24) | (data2 << 16) | (data1 << 8) | data0;
	*value = data;

	return 0;
}


static u32 calc_sum_crc(u32* buff, u16 len)
{
	u32 sum = 0;
	for (u16 k = 0; k < len; k++)
	{
		sum += buff[k];
	}
	return sum;
}

static int save_config_id(ConfigParam* ths, u8 id, u32* buff)
{
	printf("Save config to id:%d, waiting, don't power off!\n", id);

	//crc
	u32 crc = calc_sum_crc(buff, CONFIG_PARAM_NUMBER - 1);
	buff[CONFIG_PARAM_NUMBER - 1] = crc;
	plog("calc crc: 0x%08x\r\n", crc);

	for (u16 k = 0; k < CONFIG_PARAM_NUMBER; k++)
	{
		plog("%d: 0x%08x\r\n", k, buff[k]);
	}

	//write eeprom
	for (u16 k = 0; k < CONFIG_PARAM_NUMBER; k++)
	{
		iic_set_value(ths, id * CONFIG_PARAM_NUMBER * 4 + k * 4, buff[k]);
	}
	printf("-----------------Save Config To ID:%d Ok---------------------\n", id);
	return 0;
}




static int load_config_id(ConfigParam* ths, u8 id, u32* buff)
{
	printf("Load config from id:%d...\n", id);

	//read eeprom
	for (u16 k = 0; k < CONFIG_PARAM_NUMBER; k++)
	{
		iic_get_value(ths, id * CONFIG_PARAM_NUMBER * 4 + k * 4, &buff[k]);
		plog("%d: 0x%08x\r\n", k, buff[k]);
	}

	//crc
	u32 crc = calc_sum_crc(buff, CONFIG_PARAM_NUMBER - 1);
	if (crc != buff[CONFIG_PARAM_NUMBER - 1]) {
		printf("--------Load Config Error---------------------\n");
		printf("read crc: 0x%08x, calc crc: 0x%08x\r\n", buff[CONFIG_PARAM_NUMBER - 1], crc);
		return -1;
	}


	printf("-----------------Load Config From ID:%d Ok---------------------\n", id);

	return 0;
}

static int save_config(ConfigParam* ths)
{

	int items_count = (int)(sizeof(g_config_items) / sizeof(ConfigItem));
	for (int i = 0; i < items_count; i++)
	{
		u32 data = 0;
		u8 tmp8u;
		char tmp8s;
		u16 tmp16u;
		short tmp16s;
		u32 tmp32u;
		int tmp32s;
		float tmp32f;
		ConfigItem* item = &g_config_items[i];
		switch((int)item->param_->data_type_)
		{

			case ITEM_PARAM_INT_DATA:
			{
				tmp32s = *((int*)item->param_->data_);
				*((int*)&data) = tmp32s;
			}break;
			case ITEM_PARAM_UINT_DATA:
			{
				tmp32u = *((u32*)item->param_->data_);
				*((u32*)&data) = tmp32u;
			}break;

			case ITEM_PARAM_SHORT_DATA:
			{
				tmp16s = *((short*)item->param_->data_);
				*((short*)&data) = tmp16s;
			}break;
			case ITEM_PARAM_USHORT_DATA:
			{
				tmp16u = *((u16*)item->param_->data_);
				*((u16*)&data) = tmp16u;
			}break;

			case ITEM_PARAM_CHAR_DATA:
			{
				tmp8s = *((char*)item->param_->data_);
				*((char*)&data) = tmp8s;
			}break;
			case ITEM_PARAM_UCHAR_DATA:
			{
				tmp8u = *((u8*)item->param_->data_);
				*((u8*)&data) = tmp8u;
			}break;


			case ITEM_PARAM_FLOAT_DATA:
			{
				tmp32f = *((float*)item->param_->data_);
				*((float*)&data) = tmp32f;
			}break;


		}

		u32 mask = GENMASK(item->mask_h_, item->mask_l_);
		IOMEM_REG_SET_VALUE(ths->param_mem_[item->offset_], data, mask, item->shift_);

	}


	u32 data = 0;
	iic_get_value(ths, 2 * CONFIG_PARAM_NUMBER * 4, &data);

	u32 id = (data == 0) ? 1:0;
	save_config_id(ths, id, ths->param_mem_);

	iic_set_value(ths, 2 * CONFIG_PARAM_NUMBER * 4, id);

	return 0;
}

static int load_config(ConfigParam* ths)
{
	int ret;
	u32 data = 0;
	iic_get_value(ths, 2 * CONFIG_PARAM_NUMBER * 4, &data);

	u32 id = (data == 0) ? 0:1;
	ret = load_config_id(ths, id, ths->param_mem_);
	if (ret < 0) {
		id = (data == 0) ? 1:0;
		ret = load_config_id(ths, id, ths->param_mem_);
		if (ret < 0) {
			return -1;
		}
	}

	int items_count = (int)(sizeof(g_config_items) / sizeof(ConfigItem));
	for (int i = 0; i < items_count; i++)
	{

		ConfigItem* item = &g_config_items[i];

		u32 mask = GENMASK(item->mask_h_, item->mask_l_);
		u32 data = IOMEM_REG_GET_VALUE(ths->param_mem_[item->offset_], mask, item->shift_);

		u8 tmp8u;
		char tmp8s;
		u16 tmp16u;
		short tmp16s;
		u32 tmp32u;
		int tmp32s;
		float tmp32f;


		switch((int)item->param_->data_type_)
		{

			case ITEM_PARAM_INT_DATA:
			{
				tmp32s = *((int *)&data);
				item->param_->set_value(item->param_, &tmp32s);
			}break;
			case ITEM_PARAM_UINT_DATA:
			{
				tmp32u = *((u32 *)&data);
				item->param_->set_value(item->param_, &tmp32u);
			}break;

			case ITEM_PARAM_SHORT_DATA:
			{
				tmp16s = *((int *)&data);
				item->param_->set_value(item->param_, &tmp16s);
			}break;
			case ITEM_PARAM_USHORT_DATA:
			{
				tmp16u = *((u32 *)&data);
				item->param_->set_value(item->param_, &tmp16u);
			}break;

			case ITEM_PARAM_CHAR_DATA:
			{
				tmp8s = *((int *)&data);
				item->param_->set_value(item->param_, &tmp8s);
			}break;
			case ITEM_PARAM_UCHAR_DATA:
			{
				tmp8u = *((u32 *)&data);
				item->param_->set_value(item->param_, &tmp8u);
			}break;


			case ITEM_PARAM_FLOAT_DATA:
			{
				tmp32f = *((float *)&data);
				item->param_->set_value(item->param_, &tmp32f);
			}break;

		}

	}


	return 0;
}

static int load_default_factory_config(ConfigParam* ths)
{
	int items_count = (int)(sizeof(g_config_items) / sizeof(ConfigItem));
	for (int i = 4; i < items_count; i++)
	{
		ConfigItem* item = &g_config_items[i];
		item->param_->set_value(item->param_, NULL);
	}

	printf("--------------Load Default Factory Config Ok-----------------");
	return 0;
}





static void func_save_config(void* arg)
{
	ConfigParam* ths = (ConfigParam*)arg;
	ths->save_config(ths);
}

static void func_load_config(void* arg)
{
	ConfigParam* ths = (ConfigParam*)arg;
	ths->load_config(ths);
}

static void func_load_default_factory_config(void* arg)
{
	ConfigParam* ths = (ConfigParam*)arg;
	ths->load_default_factory_config(ths);
}

 




