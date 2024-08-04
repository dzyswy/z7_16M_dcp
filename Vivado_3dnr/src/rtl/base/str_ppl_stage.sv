`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

module str_ppl_stage
#(
	parameter WIDTH	= 32,
	parameter MODE	= 0,//0,1
	parameter SIM 	= "FALSE",
	parameter DEBUG	= "FALSE"
)
(
	//------------------------------------------------
	// Port define
	//------------------------------------------------
	input						i_clk,
	input						i_rst,
	
	input 	[WIDTH - 1 : 0] 	inp_str_data,
	input 						inp_str_vld,
	output						inp_str_rdy,
	
	output 	[WIDTH - 1 : 0] 	oup_str_data,
	output 						oup_str_vld,
	input						oup_str_rdy

);

	generate
		//----------------------------------------------------------------------------------------------
		// Mode 0
		// vld 和 data 为寄存器，rdy为组合逻辑
		//----------------------------------------------------------------------------------------------
		if(MODE == 0) begin : MODE0
			logic 					oup_vld_i;
			logic 					inp_rdy_i;
			logic [WIDTH - 1 : 0]	oup_data_i;
			
			always@(posedge i_clk) begin
				if(i_rst == 1'b1) begin
					oup_vld_i <= 1'b0;
				end
				else if(inp_rdy_i == 1'b1) begin
					oup_vld_i <= inp_str_vld;
				end
				if(inp_rdy_i == 1'b1) begin
					oup_data_i <= inp_str_data;
				end
			end
			
			assign inp_rdy_i 	= oup_str_rdy | !oup_vld_i;
			assign inp_str_rdy	= inp_rdy_i;
			assign oup_str_vld	= oup_vld_i;
			assign oup_str_data	= oup_data_i;
		end
		//----------------------------------------------------------------------------------------------
		// Mode 1
		// vld，rdy， data 为寄存器
		//----------------------------------------------------------------------------------------------
		if(MODE == 1) begin : MODE1
			logic [WIDTH - 1 : 0] 	inp_data_stored;
			logic [WIDTH - 1 : 0] 	oup_data_next;
			logic 					stored;
			logic 					stored_set;
			logic 					stored_clr;
			logic 					oup_vld_next;
			logic 					oup_vld_i;
			logic 					inp_rdy_i;
			logic [WIDTH - 1 : 0]	oup_data_i;
			
			assign oup_data_next 	= (stored == 1'b1) ? inp_data_stored: inp_str_data;
			assign oup_vld_next		= stored | inp_str_vld;
			assign stored_clr		= oup_str_rdy;
			assign stored_set		= inp_str_vld & !oup_str_rdy & oup_vld_i & !stored;
			
			always@(posedge i_clk) begin
				if(i_rst == 1'b1) begin
					stored 		<= 1'b0;
					oup_vld_i	<= 1'b0;
				end
				else begin
					if(stored_clr == 1'b1) begin
						stored	<= 1'b0;
					end
					else if(stored_set == 1'b1) begin
						stored	<= 1'b1;
					end
					if(inp_rdy_i == 1'b1) begin
						oup_vld_i <= oup_vld_next;
					end
					if(stored_set == 1'b1) begin
						inp_data_stored	<= inp_str_data;
					end
					if(inp_rdy_i == 1'b1) begin
						oup_data_i <= oup_data_next;
					end
				end
			end
			
			assign oup_str_vld 	= oup_vld_i;
			assign inp_rdy_i	= oup_str_rdy | !oup_vld_i;
			assign inp_str_rdy	= !stored;
			assign oup_str_data	= oup_data_i;
		end
	endgenerate
endmodule

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

