#ifndef __BOARD_PARAM_H
#define __BOARD_PARAM_H


#include "xparameters.h"


#define SOFTWARE_VERSION		0x24080400
#define FACTORY_VERSION			 "24080400"

//--------------------------------- ddr base  -------------------------------------------//
#define PL_DDR_BASE_ADDR					0x80000000
#define PS_DDR_BASE_ADDR					0x00000000

//--------------------------------- board info  -------------------------------------------//
#define HAS_MCU_DDR						1

//--------------------------------- define  -------------------------------------------//








//--------------------------------- DEV_ID --------------------------------------------//

#define SYS_TIMER_DEV_ID				XPAR_TMRCTR_0_DEVICE_ID
#define HOST_UART_DEV_ID				XPAR_PS7_UART_0_DEVICE_ID



//--------------------------------- REGS_ADDR -------------------------------------------//
#define EEPROM_IIC_REGS_ADDR			XPAR_ZYNQ_AXI_IIC_0_BASEADDR
#define SENSOR_SPI_REGS_ADDR			XPAR_SPI_0_BASEADDR

#define SENSOR_TOP_REGS_ADDR			XPAR_M_AXIL0_BASEADDR
#define XLNX_DNA_REGS_ADDR				XPAR_M_AXIL1_BASEADDR



#define ISP_3A_REGS_ADDR				XPAR_M_AXIL_ISP0_BASEADDR
#define ISP_POST_REGS_ADDR				XPAR_M_AXIL_ISP1_BASEADDR
#define YUYV_S2MM_REGS_ADDR				XPAR_M_AXIL_ISP2_BASEADDR
#define VIDEO_MM2S_REGS_ADDR			XPAR_M_AXIL_ISP3_BASEADDR
#define VIDEO_POST_REGS_ADDR			XPAR_M_AXIL_ISP4_BASEADDR
#define VIDEO_S2MM_REGS_ADDR			XPAR_M_AXIL_ISP5_BASEADDR
#define PREVIEW_MM2S_REGS_ADDR			XPAR_M_AXIL_ISP6_BASEADDR
#define PHOTO_MM2S_REGS_ADDR			XPAR_M_AXIL_ISP7_BASEADDR

//--------------------------------- IRQ_ID ---------------------------------------------//
#define HOST_UART_IRQ_ID				XPAR_XUARTPS_0_INTR
#define SENSOR_VS_IRQ_ID				XPS_FPGA2_INT_ID
#define YUYV_S2MM_IRQ_ID				XPS_FPGA3_INT_ID
#define VIDEO_MM2S_IRQ_ID				XPS_FPGA4_INT_ID
#define PHOTO_MM2S_IRQ_ID				XPS_FPGA5_INT_ID



#endif


