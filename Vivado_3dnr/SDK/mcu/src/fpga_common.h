#ifndef __FPGA_COMMON_H
#define __FPGA_COMMON_H

#include <stdio.h>
#include "math.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xil_io.h"


#ifdef __cplusplus
extern "C" {
#endif


typedef unsigned char	u8;
typedef unsigned short	u16;
typedef unsigned long	u32;
typedef unsigned long long u64;


union UnU32Float {
	u32 i;
	float f;
};


union UnU64Double {
	u64 i;
	double f;
};


#define DEBUG		1

#if DEBUG
//#define plog(...)			xil_printf(__VA_ARGS__)
#define plog(...)			printf(__VA_ARGS__)
#else
#define plog(...)
#endif


#define syslog(...)			xil_printf(__VA_ARGS__)
//#define syslog(...)			printf(__VA_ARGS__)

#define ABS_DEC(a, b)		(((a) > (b)) ? ((a) - (b)) : ((b) - (a)))
#define STD_MIN(a, b)       (((a) > (b)) ? (b) : (a))
#define STD_MAX(a, b)       (((a) > (b)) ? (a) : (b))


typedef void (*func_menu_refresh)(void* arg, u32* menu_ptr);
typedef void (*func_set_exp_time)(void* arg, u32 value);


u32 float_to_u32(float value);
float u32_to_float(u32 value);
double u64_to_double(u64 value);



//--------------------------------------------------------------------------------------

typedef struct FpgaObj FpgaObj;

struct FpgaObj {
	//class member------------------------------------------------------------------
	u8 is_init_;

	//class method-------------------------------------------------------------------

};


void FpgaObj_(FpgaObj* ths);





#ifdef __cplusplus
}
#endif


#endif

