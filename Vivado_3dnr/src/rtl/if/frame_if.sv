
`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// interface declaration
//--------------------------------------------------------------------------------------------------

interface frame_if
#(
	parameter DW 	= -1
)
(
	input clk,
	input rstn
);

	//----------------------------------------------------------------------------------------------
	// logic define
	//----------------------------------------------------------------------------------------------
	logic				frame_vs;
	logic				frame_hs;
	logic				frame_de;
	logic [DW-1:0]		frame_data;
    logic	            frame_vsync; 
    logic	            frame_hsync;
	
	
	//----------------------------------------------------------------------------------------------
	// modport define
	//----------------------------------------------------------------------------------------------	
	modport s (
		input clk,rstn,
		input frame_vsync,frame_hsync,frame_vs,frame_hs,frame_de,frame_data
	);
	
	
	modport m (
		input clk,rstn,
		output frame_vsync,frame_hsync,frame_vs,frame_hs,frame_de,frame_data
	);
	
	

endinterface

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

