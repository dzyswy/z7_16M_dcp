
`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// interface declaration
//--------------------------------------------------------------------------------------------------

interface axis_if
#(
	parameter DW 	= -1,
	parameter UW	= -1,
	parameter DSTW	= -1,
	parameter IW	= -1
)
(
	input clk,
	input rstn
);

	//----------------------------------------------------------------------------------------------
	// typedef
	//----------------------------------------------------------------------------------------------

	localparam SW = DW / 8;
	typedef logic [IW - 1 : 0]		id_w;
	typedef logic [DW - 1 : 0] 		data_w;
	typedef logic [SW - 1 : 0] 		strb_w;
	typedef logic [UW - 1 : 0]		user_w;
	typedef logic [DSTW - 1 : 0]	dest_w;

	//----------------------------------------------------------------------------------------------
	// logic define
	//----------------------------------------------------------------------------------------------
	data_w			tdata;
	strb_w			tkeep;
	strb_w			tstrb;
	logic 			tvalid;
	logic 			tready;
	logic 			tlast;
	user_w			tuser;
	dest_w			tdest;
	id_w			tid;
	
	//----------------------------------------------------------------------------------------------
	// modport define
	//----------------------------------------------------------------------------------------------	
	modport m (
		input 	clk, rstn,
		output 	tdata, tkeep, tstrb, tvalid, tlast, tuser, tdest, tid, 
		input 	tready
	);

	modport s (
		input clk, rstn,
		input tdata, tkeep, tstrb, tvalid, tlast, tuser, tdest, tid, 
		output tready
	);

endinterface

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

