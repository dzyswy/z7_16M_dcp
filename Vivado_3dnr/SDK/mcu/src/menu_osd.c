/*
 * menu_osd.cpp
 *
 *  Created on: 2023��3��30��
 *      Author: Administrator
 */



#include "menu_osd.h"
#include "fpga_top.h"



//--------------------------------------------------------------------------------------

extern FpgaTop g_fpga;

#if HAS_MCU_DDR

MenuItem g_menu_items[] = {

//	{"Status", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
//	{"sensor:1024", 0, MENU_ITEM_TWO_LEVEL, 0, (ItemParam*)&g_fpga.param_sensor_vs_frame_count_},
//	{"s2mm:1234", 0, MENU_ITEM_TWO_LEVEL, 0, (ItemParam*)&g_fpga.param_s2mm_isp_frame_count_},
//	{"mm2s:1234", 0, MENU_ITEM_TWO_LEVEL, 0, (ItemParam*)&g_fpga.param_mm2s_video_frame_count_},
//	{"vtc:1234", 0, MENU_ITEM_TWO_LEVEL, 0, (ItemParam*)&g_fpga.param_video_vtc_frame_count_},
//	{"host_uart:1234", 0, MENU_ITEM_TWO_LEVEL, 0, (ItemParam*)&g_fpga.param_host_uart_irq_count_},



	{"AE", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
	{"min:4096", 0, MENU_ITEM_TWO_LEVEL, 0,     (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.black_gray_min_},
	{"max:4096", 0, MENU_ITEM_TWO_LEVEL, 0,     (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.black_gray_max_},
	{"aver:4096", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.black_gray_aver_},
	{"exp:12345", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ae_exp_time_},
	{"alpha:15.0", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ag_alpha_},
	{"beta:4096", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.black_beta_},
	{"level:4096", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ae_gray_level_},
	{"ae_mode:0", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ae_mode_},
	{"ag_mode:0", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ag_mode_},
	{"roi_x:4096", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.black_roi_x_},
	{"roi_y:4096", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.black_roi_y_},
	{"roi_w:4096", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.black_roi_w_},
	{"roi_h:4096", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.black_roi_h_},

	{"DPC", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
	{"dpc_mode:1", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.dpc_mode_},
	{"dpc_auto:1", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.dpc_auto_},
	{"dpc_th:256", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.dpc_bad_th_},
	{"dpc_aver:256", 0, MENU_ITEM_TWO_LEVEL, 0, (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.dpc_gray_aver_},
	{"dpc_cnt:1024", 0, MENU_ITEM_TWO_LEVEL, 0, (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.dpc_bad_pixel_count_},

	{"AF", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
	{"dx:65536", 0, MENU_ITEM_TWO_LEVEL, 0,     (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.af_dx_},

	{"AWB", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
	{"rcoe:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_rcoe_},
	{"gcoe:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_gcoe_},
	{"bcoe:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_bcoe_},
	{"pcnt:0.05", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_white_pcnt_},
	{"mode:0", 0, MENU_ITEM_TWO_LEVEL, 0,       (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_mode_},
	{"auto:0", 0, MENU_ITEM_TWO_LEVEL, 0,       (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_auto_},
	{"cfa:1", 0, MENU_ITEM_TWO_LEVEL, 0,        (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.cfa_code_},
	{"raw_mode:1", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.raw_mode_},
	{"h_rg:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_h_rg_},
	{"h_bg:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_h_bg_},
	{"l_rg:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_l_rg_},
	{"l_bg:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_l_bg_},
	{"rg_r:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_rg_radius_},
	{"bg_r:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.awb_bg_radius_},

	{"CCM", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
	{"mode:0", 0, MENU_ITEM_TWO_LEVEL, 0,       (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ccm_mode_},
	{"c00:10.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ccm_c00_},
	{"c01:10.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ccm_c01_},
	{"c02:10.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ccm_c02_},
	{"c10:10.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ccm_c10_},
	{"c11:10.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ccm_c11_},
	{"c12:10.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ccm_c12_},
	{"c20:10.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ccm_c20_},
	{"c21:10.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ccm_c21_},
	{"c22:10.00", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.ccm_c22_},


	{"Tonemap", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
	{"min:4096", 0, MENU_ITEM_TWO_LEVEL, 0,     (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.tonemap_gray_min_},
	{"max:4096", 0, MENU_ITEM_TWO_LEVEL, 0,     (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.tonemap_gray_max_},
	{"aver:5120", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.tonemap_gray_aver_},
	{"log:123.01", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.tonemap_log_aver_},
	{"mode:1", 0, MENU_ITEM_TWO_LEVEL, 0,       (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.tonemap_mode_},
	{"EV:-0.0", 0, MENU_ITEM_TWO_LEVEL, 0,      (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.tonemap_intensity_},
	{"WDR:0.5", 0, MENU_ITEM_TWO_LEVEL, 0,      (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.tonemap_light_adapt_},
	{"roi_x:4096", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.tonemap_roi_x_},
	{"roi_y:4096", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.tonemap_roi_y_},
	{"roi_w:4096", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.tonemap_roi_w_},
	{"roi_h:4096", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_3a_param_.tonemap_roi_h_},

	{"Post", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
	
	{"dehaze_max:255", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.dehaze_gray_max_},
	{"dehaze_min:255", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.dehaze_gray_min_},
	{"dehaze_radio:0.9", 0, MENU_ITEM_TWO_LEVEL, 0, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.dehaze_radio_},
	{"dehaze_ss:0.9", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.dehaze_ss_},
	{"dehaze_mode:1", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.dehaze_mode_},
	{"clahe_radio:0.18", 0, MENU_ITEM_TWO_LEVEL, 0, (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.clahe_radio_},
	{"clahe_ss:0.9", 0, MENU_ITEM_TWO_LEVEL, 0,     (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.clahe_ss_},
	{"clahe_mode:1", 0, MENU_ITEM_TWO_LEVEL, 0,     (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.clahe_mode_},
	{"shp_radio:1.0", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.sharpen_radio_},
	{"shp_mode:1", 0, MENU_ITEM_TWO_LEVEL, 0,       (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.sharpen_mode_},

	{"RGB", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
	{"tpg:1", 0, MENU_ITEM_TWO_LEVEL, 0,            (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.tpg_mode_},
	{"ss:0.0", 0, MENU_ITEM_TWO_LEVEL, 0,           (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.rich_ss_},
	{"rich_mode:0.0", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.rich_mode_},
	{"aver:255", 0, MENU_ITEM_TWO_LEVEL, 0,         (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.rgb_proc_gray_aver_},
	{"cc:-15.0", 0, MENU_ITEM_TWO_LEVEL, 0,         (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.rgb_proc_contrast_},
	{"bb:-128", 0, MENU_ITEM_TWO_LEVEL, 0,          (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.rgb_proc_brightness_},
	{"gma:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,         (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.rgb_proc_gamma_new_},
	{"rgb_mode:1", 0, MENU_ITEM_TWO_LEVEL, 0,       (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.rgb_proc_mode_},
	{"gray_mode:1", 0, MENU_ITEM_TWO_LEVEL, 0,      (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.yuyv_gray_mode_},






	{"Func", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
	{"hflip:0", 0, MENU_ITEM_TWO_LEVEL, 0,          (ItemParam*)&g_fpga.xisp_top_.xisp_post_param_.hflip_mode_},
	{"vflip:0", 0, MENU_ITEM_TWO_LEVEL, 0,          (ItemParam*)&g_fpga.xisp_top_.xyuyv_s2mm_param_.vflip_mode_}, 
	{"freeze:0", 0, MENU_ITEM_TWO_LEVEL, 0,         (ItemParam*)&g_fpga.xisp_top_.xyuyv_s2mm_param_.freeze_mode_new_},
	{"resize_scale:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,(ItemParam*)&g_fpga.xisp_top_.xvideo_mm2s_param_.resize_scale_},
	{"resize_cx:1024", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xvideo_mm2s_param_.resize_cx_},
	{"resize_cy:1024", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xvideo_mm2s_param_.resize_cy_}, 


	{"Video", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
    {"2dnr_sigma:256", 0, MENU_ITEM_TWO_LEVEL, 0,   (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.denoise_2dnr_sigma_new_},
	{"2dnr_mode:1", 0, MENU_ITEM_TWO_LEVEL, 0,      (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.denoise_2dnr_mode_},
	{"c1_th:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,       (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.denoise_3dnr_c1_th_},
	{"c2_th:1.00", 0, MENU_ITEM_TWO_LEVEL, 0,       (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.denoise_3dnr_c2_th_},
	{"3dnr_mode:1", 0, MENU_ITEM_TWO_LEVEL, 0,      (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.denoise_3dnr_mode_},
	{"shp_radio:1.0", 0, MENU_ITEM_TWO_LEVEL, 0,    (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.sharpen_radio_},
	{"shp_mode:1", 0, MENU_ITEM_TWO_LEVEL, 0,       (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.sharpen_mode_},
	{"x:1920", 0, MENU_ITEM_TWO_LEVEL, 0,           (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.cursor_cx_},
	{"y:1080", 0, MENU_ITEM_TWO_LEVEL, 0,           (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.cursor_cy_},
	{"r:255", 0, MENU_ITEM_TWO_LEVEL, 0,            (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.cursor_rpixel_},
	{"g:255", 0, MENU_ITEM_TWO_LEVEL, 0,            (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.cursor_gpixel_},
	{"b:255", 0, MENU_ITEM_TWO_LEVEL, 0,            (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.cursor_bpixel_},
	{"center", 0, MENU_ITEM_TWO_LEVEL, 0,           (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.cursor_center_},
	{"mode:0", 0, MENU_ITEM_TWO_LEVEL, 0,           (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.cursor_type_},
	{"type:0", 0, MENU_ITEM_TWO_LEVEL, 0,           (ItemParam*)&g_fpga.xisp_top_.xvideo_post_param_.cursor_mode_},

	{"Photo", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
	{"x:1920", 0, MENU_ITEM_TWO_LEVEL, 0,           (ItemParam*)&g_fpga.xisp_top_.xphoto_mm2s_param_.cursor_cx_},
	{"y:1080", 0, MENU_ITEM_TWO_LEVEL, 0,           (ItemParam*)&g_fpga.xisp_top_.xphoto_mm2s_param_.cursor_cy_},
	{"r:255", 0, MENU_ITEM_TWO_LEVEL, 0,            (ItemParam*)&g_fpga.xisp_top_.xphoto_mm2s_param_.cursor_rpixel_},
	{"g:255", 0, MENU_ITEM_TWO_LEVEL, 0,            (ItemParam*)&g_fpga.xisp_top_.xphoto_mm2s_param_.cursor_gpixel_},
	{"b:255", 0, MENU_ITEM_TWO_LEVEL, 0,            (ItemParam*)&g_fpga.xisp_top_.xphoto_mm2s_param_.cursor_bpixel_},
	{"center", 0, MENU_ITEM_TWO_LEVEL, 0,           (ItemParam*)&g_fpga.xisp_top_.xphoto_mm2s_param_.cursor_center_},
	{"mode:0", 0, MENU_ITEM_TWO_LEVEL, 0,           (ItemParam*)&g_fpga.xisp_top_.xphoto_mm2s_param_.cursor_type_},
	{"type:0", 0, MENU_ITEM_TWO_LEVEL, 0,           (ItemParam*)&g_fpga.xisp_top_.xphoto_mm2s_param_.cursor_mode_},

	{"Config", 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
	{"Save", 0, MENU_ITEM_TWO_LEVEL, 0, (ItemParam*)&g_fpga.xconfig_.param_save_config_},
	{"Load", 0, MENU_ITEM_TWO_LEVEL, 0, (ItemParam*)&g_fpga.xconfig_.param_load_config_},
	{"Fact", 0, MENU_ITEM_TWO_LEVEL, 0, (ItemParam*)&g_fpga.xconfig_.param_load_default_factory_config_},

	{FACTORY_VERSION, 0, MENU_ITEM_ONE_LEVEL, 0, NULL},
};









//--------------------------------------------------------------------------------------
static void init(MenuOsd* ths);
static void create_menu(MenuOsd* ths);
static void refresh_menu(void* arg, u32* menu_ptr);
static u8 asii2index(u8 value);
static int ascii_type(u8* rptr);
static void set_menu_mode(MenuOsd* ths, int value);
static void btn_menu(MenuOsd* ths);
static void btn_left(MenuOsd* ths);
static void btn_right(MenuOsd* ths);
static void btn_up(MenuOsd* ths);
static void btn_down(MenuOsd* ths);
static void item_str_updata(MenuOsd* ths, MenuItem* item);

void MenuOsd_(MenuOsd* ths, FpgaTop* sys)
{
	FpgaObj_(&ths->obj_);

	ths->sys_ = sys;

	ths->max_menu_num_ = 10;
	ths->max_menu_str_len_ = 63;
	ths->item_space_num_ = 2;

	ths->menu_mode_ = 0;

	ths->hot_one_tree_id_ = 0;
	ths->hot_two_tree_id_ = -1;

	ths->init = init;
	ths->set_menu_mode = set_menu_mode;
	ths->refresh_menu = refresh_menu;
	ths->btn_menu = btn_menu;
	ths->btn_left = btn_left;
	ths->btn_right = btn_right;
	ths->btn_up = btn_up;
	ths->btn_down = btn_down;
}

static void init(MenuOsd* ths)
{
	create_menu(ths);
}


static void create_menu(MenuOsd* ths)
{
	int one_level_page_count = 0;
	int one_level_str_count = 0;
	int menu_count = -1;
	int items_count = (int)(sizeof(g_menu_items) / sizeof(MenuItem));
	for (int i = 0; i < items_count; i++) {

		MenuItem* menu_item = &g_menu_items[i];

		menu_item->str_len_ = (int)strlen((const char*)menu_item->str_) + 1;

		if (menu_item->type_ == MENU_ITEM_ONE_LEVEL) {
			menu_count++;
			ths->menu_levels_[menu_count].father_id = i;
			ths->menu_levels_[menu_count].son_min_id = -1;
			ths->menu_levels_[menu_count].son_max_id = -1;
			ths->menu_levels_[menu_count].son_count = 0;
			ths->menu_levels_[menu_count].page_count_ = 0;
			ths->menu_levels_[menu_count].str_count_ = 0;

			int item_str_count = menu_item->str_len_ + ths->item_space_num_;
			one_level_str_count += item_str_count;
			if (one_level_str_count > ths->max_menu_str_len_) {
				one_level_page_count++;
				one_level_str_count = item_str_count + ths->item_space_num_;
			}
			menu_item->page_ = one_level_page_count;
			continue;
		}

		if (menu_item->type_ == MENU_ITEM_TWO_LEVEL) {
			if (ths->menu_levels_[menu_count].son_min_id == -1) {
				ths->menu_levels_[menu_count].son_min_id = i;
			}

			if ((ths->menu_levels_[menu_count].son_max_id == -1) || (i > ths->menu_levels_[menu_count].son_max_id)) {
				ths->menu_levels_[menu_count].son_max_id = i;
			}

			ths->menu_levels_[menu_count].son_count++;

			int item_str_count = menu_item->str_len_ + ths->item_space_num_;
			ths->menu_levels_[menu_count].str_count_ += item_str_count;
		//	printf("menu_levels_[%d]: str_count=%d, page=%d\n", menu_count, menu_levels_[menu_count].str_count_, menu_levels_[menu_count].page_count_);

			if (ths->menu_levels_[menu_count].str_count_ > ths->max_menu_str_len_) {
				ths->menu_levels_[menu_count].page_count_++;
				ths->menu_levels_[menu_count].str_count_ = item_str_count + ths->item_space_num_;
			}
			menu_item->page_ = ths->menu_levels_[menu_count].page_count_;
		}
	}
	ths->menu_count_ = menu_count + 1;
}



static void refresh_menu(void* arg, u32* menu_ptr)
{
	MenuOsd* ths = (MenuOsd*)arg;
	if (ths->menu_mode_ == 0) {
		return;
	}

	memset(ths->menu_buff_, 0, sizeof(ths->menu_buff_));

	int menu_str_count = 0;

	if (ths->hot_two_tree_id_ == -1) {
		int hot_id = ths->menu_levels_[ths->hot_one_tree_id_].father_id;
		int hot_page = g_menu_items[hot_id].page_;
		for (int i = 0; i < ths->menu_count_; i++) {
			int item_id = ths->menu_levels_[i].father_id;
			MenuItem* menu_item = &g_menu_items[item_id];
			if (menu_item->page_ == hot_page) {

				int str_len = (int)strlen((const char*)menu_item->str_);
				str_len = (str_len < menu_item->str_len_) ? str_len : menu_item->str_len_;
				for (int c = 0; c < menu_item->str_len_; c++)
				{
					if (menu_str_count > ths->max_menu_str_len_) {
						break;
					}
					ths->menu_buff_[menu_str_count].ascii = asii2index(menu_item->str_[c]);
					ths->menu_buff_[menu_str_count].color = 7;
					ths->menu_buff_[menu_str_count].alpha = (item_id == hot_id) ? 1 : 0;
					menu_str_count++;
				}

				for (int c = 0; c < ths->item_space_num_; c++)
				{
					if (menu_str_count > ths->max_menu_str_len_) {
						break;
					}
					ths->menu_buff_[menu_str_count].ascii = 0;
					ths->menu_buff_[menu_str_count].alpha = 0;
					menu_str_count++;
				}
			}
		}
	}
	else {
		int hot_id = ths->menu_levels_[ths->hot_one_tree_id_].son_min_id + ths->hot_two_tree_id_;
		int hot_page = g_menu_items[hot_id].page_;
		for (int i = ths->menu_levels_[ths->hot_one_tree_id_].son_min_id; i <= ths->menu_levels_[ths->hot_one_tree_id_].son_max_id; i++)
		{
			MenuItem* menu_item = &g_menu_items[i];
			if (menu_item->page_ == hot_page) {

				//item_str_updata(ths, menu_item->id_, menu_item->str_, menu_item->str_len_);
				item_str_updata(ths, menu_item);

				int str_len = (int)strlen((const char*)menu_item->str_);
				str_len = (str_len < menu_item->str_len_) ? str_len : menu_item->str_len_;
				for (int c = 0; c < menu_item->str_len_; c++)
				{
					if (menu_str_count > ths->max_menu_str_len_) {
						break;
					}
					ths->menu_buff_[menu_str_count].ascii = asii2index(menu_item->str_[c]);
					ths->menu_buff_[menu_str_count].color = 7;
					ths->menu_buff_[menu_str_count].alpha = (i == hot_id) ? 1 : 0;
					menu_str_count++;
				}

				for (int c = 0; c < ths->item_space_num_; c++)
				{
					if (menu_str_count > ths->max_menu_str_len_) {
						break;
					}
					ths->menu_buff_[menu_str_count].ascii = 0;
					ths->menu_buff_[menu_str_count].alpha = 0;
					menu_str_count++;
				}
			}
		}
	}

	for (int k = 0; k < 64; k++) {
		FontWord word = ths->menu_buff_[k];
		u32 value = (((u32)word.reserved << 24) | ((u32)word.alpha << 16) | ((u32)word.color << 8) | ((u32)word.ascii));
		*menu_ptr++ = value;
	}
}


static u8 asii2index(u8 value)
{
	if ((value < 32) || (value > 126)) {
		return 0;
	} else {
		return value - 32;
	}
}

static int ascii_type(u8* rptr)
{
	if (*rptr >= 0xa1) {
		return 1;
	} else {
		return 0;
	}
}




static void set_menu_mode(MenuOsd* ths, int value)
{
	ths->menu_mode_ = (value < 0) ? 0 : ((value > 1) ? 1 : value);
	ths->sys_->xisp_top_.xvideo_post_param_.menu_osd_mode_.param_.set_value(&ths->sys_->xisp_top_.xvideo_post_param_.menu_osd_mode_.param_, &ths->menu_mode_);

}

static void btn_menu(MenuOsd* ths)
{

	if (ths->hot_two_tree_id_ == -1)
	{
		if (ths->menu_mode_ == 0) {
			set_menu_mode(ths, 1);
			ths->hot_one_tree_id_ = 0;
			ths->hot_two_tree_id_ = -1;
		} else {
			set_menu_mode(ths, 0);
			ths->hot_one_tree_id_ = 0;
			ths->hot_two_tree_id_ = -1;
		}
	}
	else {
		ths->hot_two_tree_id_ = -1;
	}
}



static void btn_left(MenuOsd* ths)
{
	if (ths->hot_two_tree_id_ == -1)
	{
		if (ths->hot_one_tree_id_ <= 0) {
			ths->hot_one_tree_id_ = 0;
		} else {
			ths->hot_one_tree_id_--;
		}
	}
	else
	{
		if (ths->hot_two_tree_id_ <= 0) {
			ths->hot_two_tree_id_ = 0;
		} else {
			ths->hot_two_tree_id_--;
		}
	}
}

static void btn_right(MenuOsd* ths)
{
	if (ths->hot_two_tree_id_ == -1) {
		if (ths->hot_one_tree_id_ >= (ths->menu_count_ - 1)) {
			ths->hot_one_tree_id_ = ths->menu_count_ - 1;
		} else {
			ths->hot_one_tree_id_++;
		}
	} else {
		int max_id = ths->menu_levels_[ths->hot_one_tree_id_].son_count;
		if (ths->hot_two_tree_id_ >= (max_id - 1)) {
			ths->hot_two_tree_id_ = max_id - 1;
		} else {
			ths->hot_two_tree_id_++;
		}
	}
}


static void btn_up(MenuOsd* ths)
{
	if (ths->hot_two_tree_id_ == -1) {
		ths->hot_two_tree_id_ = 0;
	} else {
		int hot_id = ths->menu_levels_[ths->hot_one_tree_id_].son_min_id + ths->hot_two_tree_id_;
		MenuItem* item = &g_menu_items[hot_id];

		if (item->param_ && item->param_->inc_value) {
			item->param_->inc_value(item->param_, NULL);
		}


	}
}

static void btn_down(MenuOsd* ths)
{
	if (ths->hot_two_tree_id_ == -1) {
		ths->hot_two_tree_id_ = 0;
	} else {
		int hot_id = ths->menu_levels_[ths->hot_one_tree_id_].son_min_id + ths->hot_two_tree_id_;
		MenuItem* item = &g_menu_items[hot_id];

		if (item->param_ && item->param_->dec_value) {
			item->param_->dec_value(item->param_, NULL);
		}
	}
}

static void item_str_updata(MenuOsd* ths, MenuItem* item)
{
	if (item->param_ && item->param_->str_fmt_) {
		memset(item->str_, 0, item->str_len_);
		switch((int)item->param_->data_type_)
		{
			case ITEM_PARAM_INT_DATA:
			{
				snprintf((char*)item->str_, item->str_len_, item->param_->str_fmt_, *(int*)item->param_->data_);
			}break;
			case ITEM_PARAM_UINT_DATA:
			{
				snprintf((char*)item->str_, item->str_len_, item->param_->str_fmt_, *(u32*)item->param_->data_);
			}break;

			case ITEM_PARAM_SHORT_DATA:
			{
				snprintf((char*)item->str_, item->str_len_, item->param_->str_fmt_, *(short*)item->param_->data_);
			}break;
			case ITEM_PARAM_USHORT_DATA:
			{
				snprintf((char*)item->str_, item->str_len_, item->param_->str_fmt_, *(u16*)item->param_->data_);
			}break;

			case ITEM_PARAM_CHAR_DATA:
			{
				snprintf((char*)item->str_, item->str_len_, item->param_->str_fmt_, *(char*)item->param_->data_);
			}break;
			case ITEM_PARAM_UCHAR_DATA:
			{
				snprintf((char*)item->str_, item->str_len_, item->param_->str_fmt_, *(u8*)item->param_->data_);
			}break;


			case ITEM_PARAM_FLOAT_DATA:
			{
				snprintf((char*)item->str_, item->str_len_, item->param_->str_fmt_, *(float*)item->param_->data_);
			}break;
		}
	}


}
#else

static void menu_osd_do_noting(MenuOsd* ths);
static void menu_osd_set_menu(MenuOsd* ths, int value);
static void menu_osd_refresh_menu(MenuOsd* ths, u32* menu_ptr);

void MenuOsd_(MenuOsd* ths, FpgaTop* sys)
{
	FpgaObj_(&ths->obj_);

	ths->sys_ = sys;

	ths->max_menu_num_ = 10;
	ths->max_menu_str_len_ = 63;
	ths->item_space_num_ = 2;

	ths->menu_mode_ = 0;

	ths->hot_one_tree_id_ = 0;
	ths->hot_two_tree_id_ = -1;

	ths->init = menu_osd_do_noting;
	ths->set_menu_mode = menu_osd_set_menu;
	ths->refresh_menu = menu_osd_refresh_menu;
	ths->btn_menu = menu_osd_do_noting;
	ths->btn_left = menu_osd_do_noting;
	ths->btn_right = menu_osd_do_noting;
	ths->btn_up = menu_osd_do_noting;
	ths->btn_down = menu_osd_do_noting;
}


static void menu_osd_do_noting(MenuOsd* ths)
{

}

static void menu_osd_set_menu(MenuOsd* ths, int value)
{

}

static void menu_osd_refresh_menu(MenuOsd* ths, u32* menu_ptr)
{


}


#endif //HAS_MCU_DDR
