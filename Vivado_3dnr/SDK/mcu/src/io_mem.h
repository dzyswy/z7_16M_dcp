#ifndef __IO_MEM_H
#define __IO_MEM_H

#include "fpga_common.h"

#ifdef __cplusplus
extern "C" {
#endif


#define BIT(nr)			(1 << (nr))
#define GENMASK(h, l)   ((((1) << ((h) - (l) + 1)) - 1) << (l))


#define IOMEM_REG_SET_VALUE(result, value, mask, shift) 		(result) &= (~(mask));\
																(result) |= (value) << (shift)

#define IOMEM_REG_SET_BIT(result, mask) 						(result) |= (mask)
#define IOMEM_REG_CLR_BIT(result, mask)							(result) &= (~(mask))

#define IOMEM_REG_GET_VALUE(value, mask, shift)					(((value) & (mask)) >> (shift))
#define IOMEM_REG_GET_BIT(value, mask)							((((value) & (mask)) == 0) ? 0 : 1)





//--------------------------------------------------------------------------------------

typedef struct RegMem RegMem;

struct RegMem {
	FpgaObj obj_;

	volatile u32 phy_base_;
	volatile u32 total_size_;


	void (*set_value)(RegMem* ths, u32 offset, u32 value);
	void (*set_value_float)(RegMem* ths, u32 offset, float value);

	u32 (*get_value)(RegMem* ths, u32 offset);
	float (*get_value_float)(RegMem* ths, u32 offset);

	void (*set_value_bits)(RegMem* ths, u32 offset, u32 value, u32 mask, u32 shift);
	void (*set_value_bit)(RegMem* ths, u32 offset, u32 mask, u32 value);
	void (*set_bit)(RegMem* ths, u32 offset, u32 mask);
	void (*clr_bit)(RegMem* ths, u32 offset, u32 mask);

};


void RegMem_(RegMem* ths, u32 phy_base, u32 total_size);


#ifdef __cplusplus
}
#endif


#endif

