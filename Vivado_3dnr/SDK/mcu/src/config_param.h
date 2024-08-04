/*
 * config_save.h
 *
 *  Created on: 2023��12��2��
 *      Author: Administrator
 */

#ifndef SRC_CONFIG_PARAM_H_
#define SRC_CONFIG_PARAM_H_


#include "axil_i2c.h"
#include "item_param.h"

#ifdef __cplusplus
extern "C" {
#endif

struct FpgaTop;
typedef struct FpgaTop FpgaTop;


#define CONFIG_PARAM_NUMBER		64




//--------------------------------------------------------------------------------------
typedef struct ConfigItem ConfigItem;

struct ConfigItem {
	u16 offset_;
	u8 mask_h_;
	u8 mask_l_;
	u8 shift_;
	ItemParam* param_;
};


//--------------------------------------------------------------------------------------

typedef struct ConfigParam ConfigParam;


struct ConfigParam {
	FpgaObj obj_;
	//class member------------------------------------------------------------------
	FpgaTop* sys_;
	XlnxI2c* iic_;

	u32 param_mem_[CONFIG_PARAM_NUMBER];

	//item_param ----------------------------------------------------------
	ItemAction param_save_config_;
	ItemAction param_load_config_;
	ItemAction param_load_default_factory_config_; 

	//class method-------------------------------------------------------------------
	int (*save_config)(ConfigParam* ths);
	int (*load_config)(ConfigParam* ths);
	int (*load_default_factory_config)(ConfigParam* ths); 
};


void ConfigParam_(ConfigParam* ths, FpgaTop* sys, XlnxI2c* iic);

#ifdef __cplusplus
}
#endif




#endif /* SRC_CONFIG_PARAM_H_ */
