/*
 * isp_top.h
 *
 *  Created on: 2024��8��3��
 *      Author: Administrator
 */

#ifndef SRC_XISP_TOP_H_
#define SRC_XISP_TOP_H_

#include "fpga_common.h"
#include "item_param.h"

#ifdef __cplusplus
extern "C" {
#endif

//--------------------------------------------------------------------------------------
typedef struct XlnxDna XlnxDna;
struct XlnxDna;


typedef struct XlnxDnaParam XlnxDnaParam;
struct XlnxDnaParam {
	ItemParamUint xlnx_passwd0_;
	ItemParamUint xlnx_passwd1_;
	ItemParamUint xlnx_passwd2_;
	ItemParamUint xlnx_passwd3_;
};

//--------------------------------------------------------------------------------------

typedef struct XhlsIsp3A XhlsIsp3A;
struct XhlsIsp3A;

typedef struct XhlsIsp3AParam XhlsIsp3AParam;
struct XhlsIsp3AParam {
	//black
	ItemParamUshort black_gray_min_;
	ItemParamUshort black_gray_max_;
	ItemParamUshort black_gray_aver_;
	ItemParamFloat black_alpha_;
	ItemParamShort black_beta_;

	ItemParamUshort black_roi_x_;
	ItemParamUshort black_roi_y_;
	ItemParamUshort black_roi_w_;
	ItemParamUshort black_roi_h_;

	//ae
	ItemParamUshort ae_gray_level_;
	ItemParamUint ae_exp_time_;
	ItemParamUchar ae_mode_;


	//ag
	ItemParamFloat ag_alpha_;
	ItemParamUchar ag_mode_;


	//dpc
	ItemParamUchar dpc_mode_;
	ItemParamUchar dpc_auto_;
	ItemParamUshort dpc_bad_th_;
	ItemParamUshort dpc_gray_aver_;
	ItemParamUint dpc_bad_pixel_count_;

	//cfa
	ItemParamUchar cfa_code_;
	ItemParamUchar raw_mode_;



	//af
	ItemParamUshort af_dx_;

	//awb
	ItemParamUchar awb_mode_;
	ItemParamUchar awb_auto_;
	ItemParamFloat awb_rcoe_;
	ItemParamFloat awb_gcoe_;
	ItemParamFloat awb_bcoe_;
	ItemParamFloat awb_white_pcnt_;

	ItemParamFloat awb_h_rg_;
	ItemParamFloat awb_h_bg_;
	ItemParamFloat awb_l_rg_;
	ItemParamFloat awb_l_bg_;
	ItemParamFloat awb_rg_radius_;
	ItemParamFloat awb_bg_radius_;

	//ccm
	ItemParamFloat ccm_c00_;
	ItemParamFloat ccm_c01_;
	ItemParamFloat ccm_c02_;
	ItemParamFloat ccm_c10_;
	ItemParamFloat ccm_c11_;
	ItemParamFloat ccm_c12_;
	ItemParamFloat ccm_c20_;
	ItemParamFloat ccm_c21_;
	ItemParamFloat ccm_c22_;
	ItemParamUchar ccm_mode_;

	//tonemap
	ItemParamUchar tonemap_mode_;
	ItemParamUshort tonemap_gray_min_;
	ItemParamUshort tonemap_gray_max_;
	ItemParamUshort tonemap_gray_aver_;
	ItemParamFloat tonemap_log_aver_;
	ItemParamFloat tonemap_intensity_;
	ItemParamFloat tonemap_light_adapt_;

	ItemParamUshort tonemap_roi_x_;
	ItemParamUshort tonemap_roi_y_;
	ItemParamUshort tonemap_roi_w_;
	ItemParamUshort tonemap_roi_h_;
};

//--------------------------------------------------------------------------------------

typedef struct XhlsIspPost XhlsIspPost;
struct XhlsIspPost;

typedef struct XhlsIspPostParam XhlsIspPostParam;
struct XhlsIspPostParam {
	//dehaze
    ItemParamUchar dehaze_gray_max_;
	ItemParamUchar dehaze_gray_min_;
	ItemParamFloat dehaze_ss_;
    ItemParamUchar dehaze_mode_;
    ItemParamFloat dehaze_radio_;

    //clahe
	ItemParamFloat clahe_radio_;
	ItemParamFloat clahe_ss_;
	ItemParamUchar clahe_mode_;

    //tpg
    ItemParamUchar tpg_mode_;

    //rich
    ItemParamFloat rich_ss_;
    ItemParamUchar rich_mode_;

    //rgb_proc
    ItemParamUchar rgb_proc_gray_aver_;
	ItemParamFloat rgb_proc_contrast_;
	ItemParamShort rgb_proc_brightness_;
	ItemParamFloat rgb_proc_gamma_new_;
	ItemParamUchar rgb_proc_mode_;


	//sharpen
	ItemParamFloat sharpen_radio_;
	ItemParamUchar sharpen_mode_;

	//hflip
	ItemParamUchar hflip_mode_;

	//yuyv
	ItemParamUchar yuyv_gray_mode_;
};

//--------------------------------------------------------------------------------------

typedef struct XhlsYuyvS2mm XhlsYuyvS2mm;
struct XhlsYuyvS2mm;

typedef struct XhlsYuyvS2mmParam XhlsYuyvS2mmParam;
struct XhlsYuyvS2mmParam {
	ItemParamUchar vflip_mode_;
	ItemParamUchar freeze_mode_new_;

};

//--------------------------------------------------------------------------------------

typedef struct XhlsVideoMm2s XhlsVideoMm2s;
struct XhlsVideoMm2s;

typedef struct XhlsVideoMm2sParam XhlsVideoMm2sParam;
struct XhlsVideoMm2sParam {
	ItemParamFloat resize_scale_;
	ItemParamInt resize_cx_;
	ItemParamInt resize_cy_;
};

//--------------------------------------------------------------------------------------

typedef struct XhlsVideoPost XhlsVideoPost;
struct XhlsVideoPost;

typedef struct XhlsVideoPostParam XhlsVideoPostParam;
struct XhlsVideoPostParam {
	//denoise_2dnr
	ItemParamFloat denoise_2dnr_sigma_new_;
	ItemParamUchar denoise_2dnr_mode_;

 	//denoise_2dnr
	ItemParamUchar denoise_3dnr_mode_;
	ItemParamFloat denoise_3dnr_c1_th_;
	ItemParamFloat denoise_3dnr_c2_th_;

	//menu
	ItemParamUchar menu_osd_mode_;

	//cursor
	ItemParamUshort cursor_cx_;
	ItemParamUshort cursor_cy_;
	ItemParamUshort cursor_len_;
	ItemParamUshort cursor_thickness_;

	ItemParamUchar cursor_type_;
	ItemParamUchar cursor_mode_;

	ItemAction cursor_center_;

	ItemParamUchar cursor_rpixel_;
	ItemParamUchar cursor_gpixel_;
	ItemParamUchar cursor_bpixel_;

	//sharpen
	ItemParamFloat sharpen_radio_;
	ItemParamUchar sharpen_mode_;

};

//--------------------------------------------------------------------------------------

typedef struct XhlsYuyvS2mmVideo XhlsYuyvS2mmVideo;
struct XhlsYuyvS2mmVideo;

typedef struct XhlsYuyvS2mmVideoParam XhlsYuyvS2mmVideoParam;
struct XhlsYuyvS2mmVideoParam {

};

//--------------------------------------------------------------------------------------
typedef struct XhlsPreviewMm2s XhlsPreviewMm2s;
struct XhlsPreviewMm2s;

typedef struct XhlsPreviewMm2sParam XhlsPreviewMm2sParam;
struct XhlsPreviewMm2sParam {

};

//--------------------------------------------------------------------------------------
typedef struct XhlsPhotoMm2s XhlsPhotoMm2s;
struct XhlsPhotoMm2s;

typedef struct XhlsPhotoMm2sParam XhlsPhotoMm2sParam;
struct XhlsPhotoMm2sParam {
	//cursor
	ItemParamUshort cursor_cx_;
	ItemParamUshort cursor_cy_;
	ItemParamUshort cursor_len_;
	ItemParamUshort cursor_thickness_;
	ItemParamUchar cursor_type_;
	ItemParamUchar cursor_mode_;

	ItemAction cursor_center_;

	ItemParamUchar cursor_rpixel_;
	ItemParamUchar cursor_gpixel_;
	ItemParamUchar cursor_bpixel_;
};

//--------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------
typedef struct XIspTopParam XIspTopParam;
struct XIspTopParam {
    ItemParamUint yuyv_s2mm_frame_count_;
	ItemParamUint video_mm2s_frame_count_;
	ItemParamUint photo_mm2s_frame_count_;
};
//--------------------------------------------------------------------------------------

typedef struct XIspTop XIspTop;


struct XIspTop {

	//class member--------------------------------------------------------



	//resolution
	u32 dma_frame_width_;
	u32 dma_frame_height_;
	u32 isp_width_;
	u32 isp_height_;
	u32 video_width_;
	u32 video_height_;
	u32 photo_width_;
	u32 photo_height_;

	//ddr base
	u32 pl_ddr_mem0_base_;
	u32 pl_ddr_mem1_base_;
	u32 ps_ddr_mem0_base_;

	//reg base
	u32 xdna_phy_base_;
	u32 xisp_3a_phy_base_;
	u32 xisp_post_phy_base_;
	u32 xyuyv_s2mm_phy_base_;
	u32 xvideo_mm2s_phy_base_;
	u32 xvideo_post_phy_base_;
	u32 xvideo_s2mm_phy_base_;
	u32 xpreview_mm2s_phy_base_;
	u32 xphoto_mm2s_phy_base_;

	//frame count
	u32 yuyv_s2mm_frame_count_;
	u32 video_mm2s_frame_count_;
	u32 photo_mm2s_frame_count_;

	//sensor
	u32 min_exp_time_;
	u32 max_exp_time_;
	float step_exp_time_;
	void* xsensor_;
	func_set_exp_time set_exp_time;

	XlnxDna* xdna_;
	XlnxDnaParam xdna_param_;
	XhlsIsp3A* xisp_3a_;
	XhlsIsp3AParam xisp_3a_param_;
	XhlsIspPost* xisp_post_;
	XhlsIspPostParam xisp_post_param_;
	XhlsYuyvS2mm* xyuyv_s2mm_;
	XhlsYuyvS2mmParam xyuyv_s2mm_param_;
	XhlsVideoMm2s* xvideo_mm2s_;
	XhlsVideoMm2sParam xvideo_mm2s_param_;
	XhlsVideoPost* xvideo_post_;
	XhlsVideoPostParam xvideo_post_param_;
	XhlsYuyvS2mmVideo* xvideo_s2mm_;
	XhlsYuyvS2mmVideoParam xvideo_s2mm_param_;
	XhlsPreviewMm2s* xpreview_mm2s_;
	XhlsPreviewMm2sParam xpreview_mm2s_param_;
	XhlsPhotoMm2s* xphoto_mm2s_;
	XhlsPhotoMm2sParam xphoto_mm2s_param_;

    XIspTopParam xisp_top_param_;


	//class method----------------------------------------------------------------
    void (*init)(XIspTop* ths, func_menu_refresh menu_refresh, void* menu_arg);
    void (*start)(XIspTop* ths);
	void (*compute)(XIspTop* ths);
	u32 (*get_dna_status)(XIspTop* ths);

	//isr_handle
	void (*yuyv_s2mm_isr_handle)(XIspTop* ths);
	void (*video_mm2s_isr_handle)(XIspTop* ths);
	void (*photo_mm2s_isr_handle)(XIspTop* ths);

	
	


};




void XIspTop_(XIspTop* ths);


#ifdef __cplusplus
}
#endif


#endif /* SRC_XISP_TOP_H_ */
