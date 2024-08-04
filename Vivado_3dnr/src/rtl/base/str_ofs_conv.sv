
// *************************************************************************************************
// Vendor 			: 
// Author 			: liu jun
// Filename 		: str_ofs_conv
// Date Created 	: 2021.10.17
// Version 			: V1.0
// -------------------------------------------------------------------------------------------------
// File description	:
//		为了满足地址对齐需求，根据s_ofs，m_ofs，对数据进行shift。
// -------------------------------------------------------------------------------------------------
// Revision History :
// *************************************************************************************************

`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

module str_ofs_conv
#(
	parameter DATA_WIDTH								= 512,
	parameter BYTE_WIDTH								= 8,
	parameter MODE										= 0, // 0 normal, 1 i_conv_s_ofs = 0, 2 i_conv_m_ofs = 0
	parameter BLK_B_NUM									= 1,
	parameter SIM 										= "FALSE",
	parameter DEBUG										= "FALSE"
)
(
	//------------------------------------------------
	// Port define
	//------------------------------------------------
	input												i_clk,	//&&Clk
	input												i_rst,	//&&Rst
	
	input 												i_conv_vld,
	output 												o_conv_rdy,
	input 	[log2(DATA_WIDTH/BYTE_WIDTH - 1) - 1 : 0]	i_conv_s_ofs,
	input 	[log2(DATA_WIDTH/BYTE_WIDTH - 1) - 1 : 0]	i_conv_m_ofs,
	
	input 	[DATA_WIDTH - 1 : 0]						s_axis_tdata,
	input 	[DATA_WIDTH/BYTE_WIDTH - 1 : 0]				s_axis_tkeep,
	input 												s_axis_tlast,
	input												s_axis_tvld,
	output 												s_axis_trdy,
				
	output 	[DATA_WIDTH - 1 : 0]						m_axis_tdata,
	output 	[DATA_WIDTH/BYTE_WIDTH - 1 : 0] 			m_axis_tkeep,
	output												m_axis_tlast,
	output 												m_axis_tvld,
	input 												m_axis_trdy
);
	//------------------------------------------------
	// log2(x) function
	//------------------------------------------------
	function integer log2 (input integer depth);
	begin
		for(log2 = 0; depth>0; log2 = log2 + 1) depth = depth >> 1;
	end
	endfunction
	
	localparam BYTE_CNT				= DATA_WIDTH/BYTE_WIDTH;
	localparam SHIFTER_BYTE_CNT 	= BYTE_CNT*2 - 1;
	localparam NEW_BYTE_POS_MAX 	= SHIFTER_BYTE_CNT - BYTE_CNT;
	localparam NEW_BYTE_POS_WIDTH	= $clog2(NEW_BYTE_POS_MAX);
	localparam NEXT_BYTE_POS_MAX 	= SHIFTER_BYTE_CNT;
	localparam NEXT_BYTE_POS_WIDTH	= $clog2(NEXT_BYTE_POS_MAX);
	localparam CONV_OFS_WIDTH 		= $clog2(DATA_WIDTH/BYTE_WIDTH - 1);
	localparam BLK_B_WIDTH			= $clog2(BLK_B_NUM - 1);
	
	
	//----------------------------------------------------------------------------------------------
	// struct define
	//----------------------------------------------------------------------------------------------
	typedef struct {
		logic [BYTE_WIDTH - 1 : 0] 						sft_data [SHIFTER_BYTE_CNT - 1 : 0];
		logic [SHIFTER_BYTE_CNT - 1 : 0]				sft_keep;
		logic 											sft_last;
		logic 											sft_vld;
		logic 											rcv_last;
		logic [NEXT_BYTE_POS_WIDTH - 1 : 0]				next_byte_pos;
		logic 											next_byte_flag;// 表示正/负的flag
		logic 											trans_en;
		logic [CONV_OFS_WIDTH - 1 : 0]					first_ofs;
  	} str_ofs_conv_s;

	//----------------------------------------------------------------------------------------------
	// Register define
	//----------------------------------------------------------------------------------------------
  	str_ofs_conv_s r,rn;
	genvar idx, idx0;
	integer i, j, cnt;
	integer byte_cnt;
	//
	logic [SHIFTER_BYTE_CNT * BYTE_WIDTH - 1 : 0] 	oa_data;
	logic [BYTE_WIDTH - 1 : 0] 						oa_data_array [SHIFTER_BYTE_CNT - 1 : 0];
	logic [SHIFTER_BYTE_CNT - 1 : 0]				oa_keep;
	logic [NEW_BYTE_POS_WIDTH - 1 : 0]				new_byte_pos;
	logic [CONV_OFS_WIDTH - 1 : 0]					conv_s_ofs,conv_m_ofs;
	//----------------------------------------------------------------------------------------------
	// internal assignment
	//----------------------------------------------------------------------------------------------
	generate
		for (idx = 0; idx < SHIFTER_BYTE_CNT; idx = idx + 1) begin
			assign oa_data_array[idx] = oa_data[(idx + 1) * BYTE_WIDTH - 1 : idx * BYTE_WIDTH];
		end
		for (idx = 0; idx < BYTE_CNT; idx = idx + 1) begin
			assign m_axis_tdata[(idx + 1) * BYTE_WIDTH - 1 : idx * BYTE_WIDTH] = r.sft_data[idx];
		end
		
		// if(MODE != 1) begin
			// assign oa_data = (r.next_byte_flag == 1'b1) ? s_axis_tdata << new_byte_pos * BYTE_WIDTH : s_axis_tdata >> new_byte_pos * BYTE_WIDTH;
			// assign oa_keep = (r.next_byte_flag == 1'b1) ? s_axis_tkeep << new_byte_pos : s_axis_tkeep >> new_byte_pos;
		// end else begin
			// assign oa_data = s_axis_tdata << new_byte_pos * BYTE_WIDTH;
			// assign oa_keep = s_axis_tkeep << new_byte_pos;
		// end
		assign oa_data = s_axis_tdata << new_byte_pos * BYTE_WIDTH;
		assign oa_keep = s_axis_tkeep << new_byte_pos;
		
		
	endgenerate
	
	assign conv_s_ofs 	= (MODE == 1)? {CONV_OFS_WIDTH{1'b0}} : {i_conv_s_ofs[CONV_OFS_WIDTH - 1 : BLK_B_WIDTH], {BLK_B_WIDTH{1'b0}}};
	assign conv_m_ofs 	= (MODE == 2)? {CONV_OFS_WIDTH{1'b0}} : {i_conv_m_ofs[CONV_OFS_WIDTH - 1 : BLK_B_WIDTH], {BLK_B_WIDTH{1'b0}}};
	assign new_byte_pos = r.next_byte_pos[NEW_BYTE_POS_WIDTH - 1 : 0];


	//----------------------------------------------------------------------------------------------
	// combinatorial always
	//----------------------------------------------------------------------------------------------
	always_comb begin	
		rn = r;
		
		if(m_axis_tvld & m_axis_trdy)begin
			// shift >> BYTE_CNT * BYTE_WIDTH
			rn.sft_keep[BYTE_CNT - 1] = 1'b0;
			for (i = 0; i < SHIFTER_BYTE_CNT - BYTE_CNT; i = i + 1) begin
				rn.sft_data[i] = r.sft_data[i + BYTE_CNT];
				rn.sft_keep[i] = r.sft_keep[i + BYTE_CNT];
			end
			rn.sft_keep[SHIFTER_BYTE_CNT - 1 : BYTE_CNT] = {(SHIFTER_BYTE_CNT - BYTE_CNT){1'b0}};			
		end
		
		if(s_axis_tvld & s_axis_trdy) begin
			for (i = 0; i < SHIFTER_BYTE_CNT; i = i + 1) begin
				if (oa_keep[i] == 1'b1) begin
					rn.sft_data[i] = oa_data_array[i];
					rn.sft_keep[i] = 1'b1;
				end
			end			
		end
		
		if(m_axis_tvld & m_axis_trdy & m_axis_tlast)begin
			rn.rcv_last = 1'b0;
		end
		if(s_axis_tvld & s_axis_trdy & s_axis_tlast) begin
			rn.rcv_last = 1'b1;
		end
	
		if (m_axis_tvld & m_axis_trdy) begin
			rn.next_byte_pos = r.next_byte_pos - BYTE_CNT;
			if(m_axis_tlast)
				rn.next_byte_pos = {NEXT_BYTE_POS_WIDTH{1'b0}};
		end
		
		if (s_axis_tvld & s_axis_trdy) begin
			byte_cnt = 0;
			for(cnt = 0; cnt < BYTE_CNT; cnt = cnt + 1)begin
				byte_cnt = byte_cnt + s_axis_tkeep[cnt];
			end
			
			// if (r.next_byte_flag == 1'b0 && MODE != 1) begin // 负数
				// rn.next_byte_pos 	= r.first_ofs + byte_cnt - rn.next_byte_pos;
				// rn.next_byte_flag	= 1'b1;
			// end else begin // 正数		
				// rn.next_byte_pos 	= r.first_ofs + byte_cnt + rn.next_byte_pos;
			// end
			rn.next_byte_pos = byte_cnt + rn.next_byte_pos;
			rn.first_ofs = {CONV_OFS_WIDTH{1'b0}};
		end
		
		if(m_axis_tvld & m_axis_trdy) begin
			rn.sft_vld = 1'b0;
		end
		if (rn.next_byte_pos >= BYTE_CNT || rn.rcv_last == 1'b1) begin
			rn.sft_vld = 1'b1;
		end
		
		if(m_axis_tvld & m_axis_trdy & m_axis_tlast) begin
			rn.sft_last = 1'b0;
			rn.trans_en = 1'b0;
		end
		if(rn.next_byte_pos <= BYTE_CNT && rn.rcv_last == 1'b1)begin
			rn.sft_last = 1'b1;
		end
		
		// 计算偏移量
		// if (i_conv_vld & o_conv_rdy) begin
			// if (conv_m_ofs >= conv_s_ofs) begin
				// rn.next_byte_pos 	= conv_m_ofs - conv_s_ofs;
				// rn.next_byte_flag	= 1'b1;
			// end else if(MODE != 1)begin //负数
				// rn.next_byte_pos 	= conv_s_ofs - conv_m_ofs;
				// rn.next_byte_flag	= 1'b0;
			// end
			// rn.first_ofs	= conv_s_ofs;
			// rn.trans_en 	= 1'b1;
		// end		
	end
	
	//----------------------------------------------------------------------------------------------
	// Debug Signal
	//----------------------------------------------------------------------------------------------
	assign o_conv_rdy	= !r.trans_en;
	assign m_axis_tkeep	= r.sft_keep;
	assign m_axis_tlast	= r.sft_last;
	assign m_axis_tvld	= r.sft_vld;
	assign s_axis_trdy 	= r.rcv_last == 1'b0 && ((r.next_byte_pos < BYTE_CNT) || m_axis_trdy == 1'b1);
	//----------------------------------------------------------------------------------------------
	// Debug Signal
	//----------------------------------------------------------------------------------------------
	generate
		if(DEBUG == "TRUE") begin

		end
	endgenerate

	//----------------------------------------------------------------------------------------------
	// sequential always
	//----------------------------------------------------------------------------------------------	
	always_ff @(posedge i_clk) begin
		r <= rn;
		if(i_rst == 1'b1) begin
			for(j = 0; j < SHIFTER_BYTE_CNT; j = j + 1)begin
				r.sft_data[j] <= {BYTE_WIDTH{1'b0}};
			end
			r.sft_keep 			<= {SHIFTER_BYTE_CNT{1'b0}};
			r.sft_last 			<= 1'b0;
			r.sft_vld			<= 1'b0;
			r.rcv_last			<= 1'b0;
			r.next_byte_pos		<= {NEXT_BYTE_POS_WIDTH{1'b0}};
			r.next_byte_flag	<= 1'b0;
			r.trans_en			<= 1'b0;
			r.first_ofs			<= {CONV_OFS_WIDTH{1'b0}};
		end
	end

endmodule

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

