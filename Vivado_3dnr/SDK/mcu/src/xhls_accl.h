#ifndef __XHLS_ACCL_H
#define __XHLS_ACCL_H



#include "io_mem.h"

#ifdef __cplusplus
extern "C" {
#endif


//¼Ä´æÆ÷Æ«ÒÆ
#define XHLS_REG_CTRL_START                     BIT(0)
#define XHLS_REG_CTRL_DONE                      BIT(1)
#define XHLS_REG_CTRL_IDLE                      BIT(2)
#define XHLS_REG_CTRL_READY                     BIT(3)
#define XHLS_REG_CTRL_AUTO_RESTART              BIT(7)
#define XHLS_REG_GIE                            0x04
#define XHLS_REG_GIE_GIE                        BIT(0)
#define XHLS_REG_IER                            0x08
#define XHLS_REG_IER_DONE                       BIT(0)
#define XHLS_REG_IER_READY                      BIT(1)
#define XHLS_REG_ISR                            0x0c
#define XHLS_REG_ISR_DONE                       BIT(0)
#define XHLS_REG_ISR_READY                      BIT(1)
#define XHLS_REG_ROWS                           0x10
#define XHLS_REG_COLS                           0x18


//HLSÆ«ÒÆ
#define HLS_LOW16_MASK					GENMASK(15, 0)
#define HLS_LOW16_SHIFT					0
#define HLS_HIGH16_MASK					GENMASK(31, 16)
#define HLS_HIGH16_SHIFT				16

#define HLS_LOW8_MASK					GENMASK(7, 0)
#define HLS_LOW8_SHIFT					0
#define HLS_HIGH8_MASK					GENMASK(15, 8)
#define HLS_HIGH8_SHIFT					8




//--------------------------------------------------------------------------------------


typedef struct XhlsIp XhlsIp;

struct XhlsIp {
	RegMem regs_;
	u32 frame_count_;

	void (*init)(XhlsIp* ths);
	void (*process)(XhlsIp* ths);

	void (*set_ap)(XhlsIp* ths, u32 value);

	void (*set_ap_start_value)(XhlsIp* ths, int value);

	void (*set_ap_auto_restart_value)(XhlsIp* ths, int value);
	void (*set_gie_gie_value)(XhlsIp* ths, int value);

	void (*set_ier_done_value)(XhlsIp* ths, int value);

	void (*set_ier_ready_value)(XhlsIp* ths, int value);



	void (*set_isr)(XhlsIp* ths, u32 value);
	u32 (*get_ap)(XhlsIp* ths);

	u32 (*get_gie)(XhlsIp* ths);
	u32 (*get_ier)(XhlsIp* ths);
	u32 (*get_isr)(XhlsIp* ths);

	void (*enable_irq)(XhlsIp* ths);
	void (*disable_irq)(XhlsIp* ths);
	int (*clear_irq)(XhlsIp* ths);

};


void XhlsIp_(XhlsIp* ths, u32 phy_base, u32 total_size);








#ifdef __cplusplus
}
#endif




#endif
