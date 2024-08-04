/*
 * fpga_top.cpp
 *
 *  Created on: 2022��2��9��
 *      Author: Administrator
 */

/*
 * fpga_top.cpp
 *
 *  Created on: 2022��1��26��
 *      Author: Administrator
 */

#include "fpga_top.h"



extern const char* ISP_LIB_NAME;
extern u32 ISP_LIB_VERSION;

//--------------------------------------------------------------------------------------
static void init(FpgaTop* ths);
static void process(FpgaTop* ths);



static u32 get_ms(FpgaTop* ths);
static u64 get_us(FpgaTop* ths);
static void debug_info(FpgaTop* ths);
static int intc_init(FpgaTop* ths);
static void enable_all_irq(FpgaTop* ths);
static void disable_all_irq(FpgaTop* ths);

static void sensor_vs_isr_handle(FpgaTop* sys);
static void yuyv_s2mm_isr_handle(FpgaTop* sys);
static void video_mm2s_isr_handle(FpgaTop* sys);
static void photo_mm2s_isr_handle(FpgaTop* sys);

void FpgaTop_(FpgaTop* ths)
{
	FpgaObj_(&ths->obj_);
	//class param ------------------------------------

	ths->version_ = SOFTWARE_VERSION;









	//class struct
	PsUart_(&ths->host_uart_);
	HostCommand_(&ths->xhost_cmd_, ths, &ths->host_uart_);

	//eeprom
	XlnxI2c_(&ths->xeeprom_i2c_, EEPROM_IIC_REGS_ADDR, 0x10000);
	ConfigParam_(&ths->xconfig_, ths, &ths->xeeprom_i2c_);


	XlnxSpi_(&ths->xsensor_spi_, SENSOR_SPI_REGS_ADDR, 0x10000);
	CmosSensor_(&ths->xsensor_, SENSOR_TOP_REGS_ADDR, 0x10000);

	//xisp_top---------------------------------------------
	//resolution
	ths->xisp_top_.dma_frame_width_ = 4096;
	ths->xisp_top_.dma_frame_height_ = 3280;
	ths->xisp_top_.isp_width_ = 4096;
	ths->xisp_top_.isp_height_ = 3280;
	ths->xisp_top_.video_width_ = 1280;
	ths->xisp_top_.video_height_ = 1024;
	ths->xisp_top_.photo_width_ = 4096;
	ths->xisp_top_.photo_height_ = 3278;
	//ddr base
	ths->xisp_top_.pl_ddr_mem0_base_ = PL_DDR_BASE_ADDR;
	ths->xisp_top_.pl_ddr_mem1_base_ = PL_DDR_BASE_ADDR + ths->xisp_top_.dma_frame_width_ * ths->xisp_top_.dma_frame_height_ * 2 * 16;
	ths->xisp_top_.ps_ddr_mem0_base_ = 0x10000000;
	//reg base
	ths->xisp_top_.xdna_phy_base_ = XLNX_DNA_REGS_ADDR;
	ths->xisp_top_.xisp_3a_phy_base_ = ISP_3A_REGS_ADDR;
	ths->xisp_top_.xisp_post_phy_base_ = ISP_POST_REGS_ADDR;
	ths->xisp_top_.xyuyv_s2mm_phy_base_ = YUYV_S2MM_REGS_ADDR;
	ths->xisp_top_.xvideo_mm2s_phy_base_ = VIDEO_MM2S_REGS_ADDR;
	ths->xisp_top_.xvideo_post_phy_base_ = VIDEO_POST_REGS_ADDR;
	ths->xisp_top_.xvideo_s2mm_phy_base_ = VIDEO_S2MM_REGS_ADDR;
	ths->xisp_top_.xpreview_mm2s_phy_base_ = PREVIEW_MM2S_REGS_ADDR;
	ths->xisp_top_.xphoto_mm2s_phy_base_ = PHOTO_MM2S_REGS_ADDR;
	XIspTop_(&ths->xisp_top_);




	//menu_osd
	MenuOsd_(&ths->xmenu_, ths);



	//item_param ----------------------------------------------------------

	//sensor_vs
	ItemParamUint_(&ths->param_sensor_vs_frame_count_, &ths->xsensor_.sensor_vs_frame_count_, ITEM_PARAM_READ_ONLY, 0, 32767, 0, 1, "sensor_vs:%d");

	//uart irq
	ItemParamUint_(&ths->param_host_uart_irq_count_, &ths->host_uart_.irq_count_, ITEM_PARAM_READ_ONLY, 0, 32767, 0, 1, "host_uart:%d");


	//class method-------------------------------------------------------------------
	ths->init = init;
	ths->process = process;
	ths->get_ms = get_ms;
	ths->get_us = get_us;


	usleep(100000);

}

static void init(FpgaTop* ths)
{
	stamp_timer_init(&ths->sys_timer_, SYS_TIMER_DEV_ID);
	stamp_timer_start(&ths->sys_timer_);

	ths->host_uart_.init(&ths->host_uart_, ths, 128, HOST_UART_DEV_ID, 115200, XUARTPS_FORMAT_8_BITS, XUARTPS_FORMAT_NO_PARITY, XUARTPS_FORMAT_1_STOP_BIT);
	ths->xeeprom_i2c_.init(&ths->xeeprom_i2c_, ths, 0x57);

	plog("camera boot ....\r\n");
//	syslog("ISP_LIB_NAME: %s\r\n", ISP_LIB_NAME);
//	syslog("ISP_LIB_VERSION: 0x%x\r\n", ISP_LIB_VERSION);




	usleep(50000);
	ths->xsensor_spi_.init(&ths->xsensor_spi_, ths);
	ths->xsensor_.init(&ths->xsensor_, ths);
	usleep(50000);

	//xisp_top_ init
	ths->xisp_top_.min_exp_time_ = 50;
	ths->xisp_top_.max_exp_time_ = 20000;
	ths->xisp_top_.step_exp_time_ = 6.35;
	ths->xisp_top_.xsensor_ = &ths->xsensor_;
	ths->xisp_top_.set_exp_time = ths->xsensor_.set_exp_time;
	ths->xisp_top_.init(&ths->xisp_top_, ths->xmenu_.refresh_menu, &ths->xmenu_);


	//menu_osd
	ths->xmenu_.init(&ths->xmenu_);
	ths->xmenu_.set_menu_mode(&ths->xmenu_, 0);

	//Config Param
	ths->xconfig_.load_config(&ths->xconfig_);

	//passwd ----------------------------------
//	u32 passwd = 0;
//	ths->xisp_top_.param_xlnx_passwd0_.param_.set_value(&ths->xisp_top_.param_xlnx_passwd0_.param_, &passwd);
//	ths->xisp_top_.param_xlnx_passwd1_.param_.set_value(&ths->xisp_top_.param_xlnx_passwd1_.param_, &passwd);
//	ths->xisp_top_.param_xlnx_passwd2_.param_.set_value(&ths->xisp_top_.param_xlnx_passwd2_.param_, &passwd);
//	ths->xisp_top_.param_xlnx_passwd3_.param_.set_value(&ths->xisp_top_.param_xlnx_passwd3_.param_, &passwd);



	//xisp_top_ start
	ths->xisp_top_.start(&ths->xisp_top_);


	intc_init(ths);

	enable_all_irq(ths);


}


static void process(FpgaTop* ths)
{
	plog("camera boot ok, goto while loop....\r\n");

	while(1)
	{

		ths->xhost_cmd_.process(&ths->xhost_cmd_, 1000);
		debug_info(ths);

		ths->xisp_top_.compute(&ths->xisp_top_);

	}

}






static void debug_info(FpgaTop* ths)
{
	static u32 tv0 = 0;

	u32 tv1 = ths->get_ms(ths);
	u32 dlt_time = ABS_DEC(tv0, tv1);
	if (dlt_time < 1000) {
		return;
	}
	tv0 = tv1;

	plog("time=%d, sensor_vs=%d, yuyv_s2mm=%d, video_mm2s=%d, photo_mm2s=%d\r\n", ths->get_ms(ths),
			ths->xsensor_.sensor_vs_frame_count_,
			ths->xisp_top_.yuyv_s2mm_frame_count_, ths->xisp_top_.video_mm2s_frame_count_, ths->xisp_top_.photo_mm2s_frame_count_);



}



static u32 get_ms(FpgaTop* ths)
{
	return get_timestamp_ms(&ths->sys_timer_);
}

static u64 get_us(FpgaTop* ths)
{
	return get_timestamp_us(&ths->sys_timer_);
}


static int intc_init(FpgaTop* ths)
{
	int Status;

	XScuGic_Config *IntcConfig; /* Config for interrupt controller */

	/* Initialize the interrupt controller driver */
	IntcConfig = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
	if (NULL == IntcConfig) {
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(&ths->xintc_, IntcConfig, IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Connect the interrupt controller interrupt handler to the
	 * hardware interrupt handling logic in the processor.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XScuGic_InterruptHandler, &ths->xintc_);

	/*
	 * Connect a device driver handler that will be called when an
	 * interrupt for the device occurs, the device driver handler
	 * performs the specific interrupt processing for the device
	 */


	Status = XScuGic_Connect(&ths->xintc_, HOST_UART_IRQ_ID, (Xil_ExceptionHandler) ps_uart_isr_handle, (void *) &ths->host_uart_);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = XScuGic_Connect(&ths->xintc_, SENSOR_VS_IRQ_ID, (Xil_ExceptionHandler) sensor_vs_isr_handle, (void *)ths);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	Status = XScuGic_Connect(&ths->xintc_, YUYV_S2MM_IRQ_ID, (Xil_ExceptionHandler) yuyv_s2mm_isr_handle, (void *)ths);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = XScuGic_Connect(&ths->xintc_, VIDEO_MM2S_IRQ_ID, (Xil_ExceptionHandler) video_mm2s_isr_handle, (void *)ths);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = XScuGic_Connect(&ths->xintc_, PHOTO_MM2S_IRQ_ID, (Xil_ExceptionHandler) photo_mm2s_isr_handle, (void *)ths);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XScuGic_SetPriorityTriggerType(&ths->xintc_, SENSOR_VS_IRQ_ID, 0xa0, 0x3);

	/* Enable interrupts */
	 Xil_ExceptionEnable();

	return XST_SUCCESS;

}



static void enable_all_irq(FpgaTop* ths)
{

	XScuGic_Enable(&ths->xintc_, HOST_UART_IRQ_ID);
	XScuGic_Enable(&ths->xintc_, SENSOR_VS_IRQ_ID);
	XScuGic_Enable(&ths->xintc_, YUYV_S2MM_IRQ_ID);
	XScuGic_Enable(&ths->xintc_, VIDEO_MM2S_IRQ_ID);
	XScuGic_Enable(&ths->xintc_, PHOTO_MM2S_IRQ_ID);
}

static void disable_all_irq(FpgaTop* ths)
{
	XScuGic_Disable(&ths->xintc_, HOST_UART_IRQ_ID);
	XScuGic_Disable(&ths->xintc_, SENSOR_VS_IRQ_ID);
	XScuGic_Disable(&ths->xintc_, YUYV_S2MM_IRQ_ID);
	XScuGic_Disable(&ths->xintc_, VIDEO_MM2S_IRQ_ID);
	XScuGic_Disable(&ths->xintc_, PHOTO_MM2S_IRQ_ID);
}

static void sensor_vs_isr_handle(FpgaTop* sys)
{
	XScuGic* xintc = &sys->xintc_;

	XScuGic_Disable(xintc, SENSOR_VS_IRQ_ID);

	sys->xsensor_.read_back_param(&sys->xsensor_);

	XScuGic_Enable(xintc, SENSOR_VS_IRQ_ID);
}

static void yuyv_s2mm_isr_handle(FpgaTop* sys)
{
	XScuGic* xintc = &sys->xintc_;

	XScuGic_Disable(xintc, YUYV_S2MM_IRQ_ID);

	sys->xisp_top_.yuyv_s2mm_isr_handle(&sys->xisp_top_);

	XScuGic_Enable(xintc, YUYV_S2MM_IRQ_ID);
}

static void video_mm2s_isr_handle(FpgaTop* sys)
{
	XScuGic* xintc = &sys->xintc_;

	XScuGic_Disable(xintc, VIDEO_MM2S_IRQ_ID);

	sys->xisp_top_.video_mm2s_isr_handle(&sys->xisp_top_);

	if (sys->xisp_top_.get_dna_status(&sys->xisp_top_) == 0x3) {
		sys->xhost_cmd_.feedback(&sys->xhost_cmd_);
	}



	XScuGic_Enable(xintc, VIDEO_MM2S_IRQ_ID);
}

static void photo_mm2s_isr_handle(FpgaTop* sys)
{
	XScuGic* xintc = &sys->xintc_;

	XScuGic_Disable(xintc, PHOTO_MM2S_IRQ_ID);
	sys->xisp_top_.photo_mm2s_isr_handle(&sys->xisp_top_);

	XScuGic_Enable(xintc, PHOTO_MM2S_IRQ_ID);
}
















