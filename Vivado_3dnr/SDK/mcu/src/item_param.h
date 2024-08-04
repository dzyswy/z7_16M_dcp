/*
 * item_param.h
 *
 *  Created on: 2023Äê7ÔÂ1ÈÕ
 *      Author: Administrator
 */

#ifndef SRC_ITEM_PARAM_H_
#define SRC_ITEM_PARAM_H_


#include "fpga_common.h"

#ifdef __cplusplus
extern "C" {
#endif



enum ENUM_ITEM_PARAM_IO_TYPE {
	ITEM_PARAM_READ_ONLY = 1,
	ITEM_PARAM_READ_WRITE = 2
};

enum ENUM_ITEM_PARAM_DATA_TYPE {
	ITEM_PARAM_ACTION_DATA = 1,
	ITEM_PARAM_INT_DATA = 2,
	ITEM_PARAM_UINT_DATA = 3,
	ITEM_PARAM_SHORT_DATA = 4,
	ITEM_PARAM_USHORT_DATA = 5,
	ITEM_PARAM_CHAR_DATA = 6,
	ITEM_PARAM_UCHAR_DATA = 7,
	ITEM_PARAM_FLOAT_DATA = 8,
};


typedef void (*item_param_action_func)(void* arg);

//--------------------------------------------------------------------------------------


typedef struct ItemParam ItemParam;
struct ItemParam {

	//class member------------------------------------------------------------------
	void* data_;
	const char* str_fmt_;
	enum ENUM_ITEM_PARAM_DATA_TYPE data_type_;


	//class method-------------------------------------------------------------------
	void (*set_value)(ItemParam* ths, void* data);
	void (*inc_value)(ItemParam* ths, void* data);
	void (*dec_value)(ItemParam* ths, void* data);
};

void ItemParam_(ItemParam* ths, int data_type);


//--------------------------------------------------------------------------------------


typedef struct ItemAction ItemAction;
struct ItemAction {
	ItemParam param_;
	//class member------------------------------------------------------------------
	void* arg_;

	//class method-------------------------------------------------------------------
	item_param_action_func action_func_;
};

void ItemAction_(ItemAction* ths, void* arg, item_param_action_func action_func);


//--------------------------------------------------------------------------------------
typedef struct ItemParamInt ItemParamInt;
struct ItemParamInt {
	ItemParam param_;

	//class member------------------------------------------------------------------
	int min_value_;
	int max_value_;
	int defalut_value_;
	int defalut_step_;

	//class method-------------------------------------------------------------------
	int (*get_value_int)(ItemParamInt* ths);
};

void ItemParamInt_(ItemParamInt* ths, int* data, int io_type, int min_value, int max_value, int defalut_value, int defalut_step, const char* str_fmt);


//--------------------------------------------------------------------------------------
typedef struct ItemParamShort ItemParamShort;
struct ItemParamShort {
	ItemParam param_;

	//class member------------------------------------------------------------------
	short min_value_;
	short max_value_;
	short defalut_value_;
	short defalut_step_;

	//class method-------------------------------------------------------------------
	short (*get_value_short)(ItemParamShort* ths);
};

void ItemParamShort_(ItemParamShort* ths, short* data, int io_type, short min_value, short max_value, short defalut_value, short defalut_step, const char* str_fmt);


//--------------------------------------------------------------------------------------
typedef struct ItemParamUint ItemParamUint;
struct ItemParamUint {
	ItemParam param_;

	//class member------------------------------------------------------------------
	u32 min_value_;
	u32 max_value_;
	u32 defalut_value_;
	u32 defalut_step_;

	//class method-------------------------------------------------------------------
	u32 (*get_value_uint)(ItemParamUint* ths);

};

void ItemParamUint_(ItemParamUint* ths, u32* data, int io_type, u32 min_value, u32 max_value, u32 defalut_value, u32 defalut_step, const char* str_fmt);



//--------------------------------------------------------------------------------------
typedef struct ItemParamUchar ItemParamUchar;
struct ItemParamUchar {
	ItemParam param_;

	//class member------------------------------------------------------------------
	u8 min_value_;
	u8 max_value_;
	u8 defalut_value_;
	u8 defalut_step_;

	//class method-------------------------------------------------------------------
	u8 (*get_value_uchar)(ItemParamUchar* ths);
};

void ItemParamUchar_(ItemParamUchar* ths, u8* data, int io_type, u8 min_value, u8 max_value, u8 defalut_value, u8 defalut_step, const char* str_fmt);


//--------------------------------------------------------------------------------------
typedef struct ItemParamUshort ItemParamUshort;
struct ItemParamUshort {
	ItemParam param_;

	//class member------------------------------------------------------------------
	u16 min_value_;
	u16 max_value_;
	u16 defalut_value_;
	u16 defalut_step_;

	//class method-------------------------------------------------------------------
	u16 (*get_value_ushort)(ItemParamUshort* ths);
};

void ItemParamUshort_(ItemParamUshort* ths, u16* data, int io_type, u16 min_value, u16 max_value, u16 defalut_value, u16 defalut_step, const char* str_fmt);


//--------------------------------------------------------------------------------------
typedef struct ItemParamFloat ItemParamFloat;
struct ItemParamFloat {
	ItemParam param_;

	//class member------------------------------------------------------------------
	float min_value_;
	float max_value_;
	float defalut_value_;
	float defalut_step_;

	//class method-------------------------------------------------------------------
	float (*get_value_float)(ItemParamFloat* ths);
};

void ItemParamFloat_(ItemParamFloat* ths, float* data, int io_type, float min_value, float max_value, float defalut_value, float defalut_step, const char* str_fmt);












#ifdef __cplusplus
}
#endif


#endif /* SRC_ITEM_PARAM_H_ */
