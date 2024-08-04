
`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

module apb_conv_cfg 
#(
	parameter APB_DATA_WIDTH = 32,
	parameter APB_ADDR_WIDTH = 32,
	parameter CFG_DATA_WIDTH = 32,
	parameter CFG_ADDR_WIDTH = 32,
	parameter SIM 	= "FALSE",
	parameter DEBUG	= "FALSE"
)
(
	//------------------------------------------------
	// apb clk rst
	//------------------------------------------------
	input 							i_apb_clk,
	input 							i_apb_rst,
	//------------------------------------------------
	// apb Port define
	//------------------------------------------------
    output  [APB_DATA_WIDTH - 1:0] 	o_apb_prdata,                            
    output                  		o_apb_pready,
    output                  		o_apb_pslverr, 
    input   [APB_ADDR_WIDTH - 1:0]  i_apb_paddr, 
    input                   		i_apb_penable, 
    input                   		i_apb_psel, 
    input   [APB_DATA_WIDTH - 1:0]  i_apb_pwdata, 
    input                   		i_apb_pwrite,
	
	//------------------------------------------------
	// reg Port define
	//------------------------------------------------
	output 							o_cfg_wr_en,
	output  [CFG_ADDR_WIDTH - 1:0]	o_cfg_addr,
	output  [CFG_DATA_WIDTH - 1:0]	o_cfg_wr_data,
	output 							o_cfg_rd_en,
	input 							i_cfg_rd_vld,
	input 	[CFG_DATA_WIDTH - 1:0] 	i_cfg_rd_data
);

	//----------------------------------------------------------------------------------------------
	// output assignment
	//----------------------------------------------------------------------------------------------
	logic cfg_rd_en;
	logic cfg_rd_en_r;
	
	assign o_apb_pslverr 	= 1'b0;
	assign o_apb_prdata  	= i_cfg_rd_data;    
	assign o_apb_pready  	= i_cfg_rd_vld | o_cfg_wr_en;
	
	assign o_cfg_wr_data	= i_apb_pwdata;
	assign o_cfg_addr		= i_apb_paddr;
	
	assign o_cfg_wr_en		= i_apb_psel && i_apb_pwrite && i_apb_penable;
	
	assign cfg_rd_en		= i_apb_psel && !i_apb_pwrite && i_apb_penable;
	
	always_ff@(posedge i_apb_clk) begin
		if(i_apb_rst == 1'b1)
			cfg_rd_en_r <= 1'b0;
		else
			cfg_rd_en_r <= cfg_rd_en;
	end
	
	assign o_cfg_rd_en = cfg_rd_en & (!cfg_rd_en_r);

endmodule

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

