/*
 * menu_osd.h
 *
 *  Created on: 2023Äê3ÔÂ30ÈÕ
 *      Author: Administrator
 */

#ifndef SRC_MENU_OSD_H_
#define SRC_MENU_OSD_H_

#include "fpga_common.h"
#include "item_param.h"

#ifdef __cplusplus
extern "C" {
#endif

struct FpgaTop;
typedef struct FpgaTop FpgaTop;




enum ENUM_MENU_TYPE {
	MENU_ITEM_ONE_LEVEL = 1,
	MENU_ITEM_TWO_LEVEL = 2
};



typedef struct MenuItem {
	u8 str_[32];
	int str_len_;
	int type_;
	int page_;
//	int id_;
	ItemParam* param_;
}MenuItem;

typedef struct MenuLevel {
	int father_id;
	int son_min_id;
	int son_max_id;
	int son_count;

	int page_count_;
	int str_count_;
} MenuLevel;

typedef struct FontWord{
    u8 ascii;
    u8 color;
    u8 alpha;
    u8 reserved;
}FontWord;





//--------------------------------------------------------------------------------------

typedef struct MenuOsd MenuOsd;


struct MenuOsd {
	FpgaObj obj_;

	//class member------------------------------------------------------------------
	FpgaTop* sys_;
	int max_menu_num_;
	int max_menu_str_len_;
	int item_space_num_;


	MenuLevel menu_levels_[16];
	int menu_count_;

	FontWord menu_buff_[64];

	int menu_mode_;
	int hot_one_tree_id_;
	int hot_two_tree_id_;

	//class method-------------------------------------------------------------------
	void (*init)(MenuOsd* ths);
	void (*set_menu_mode)(void* arg, int value);
	func_menu_refresh refresh_menu;

	void (*btn_menu)(MenuOsd* ths);
	void (*btn_left)(MenuOsd* ths);
	void (*btn_right)(MenuOsd* ths);
	void (*btn_up)(MenuOsd* ths);
	void (*btn_down)(MenuOsd* ths);
};


void MenuOsd_(MenuOsd* ths, FpgaTop* sys);





#ifdef __cplusplus
}
#endif

#endif /* SRC_MENU_OSD_H_ */
