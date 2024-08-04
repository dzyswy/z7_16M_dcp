
`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

module axi_conv_cfg
#(
	parameter CFG_DATA_WIDTH 				= 32,
	parameter CFG_ADDR_WIDTH 				= 32,
	parameter AXI_ADDR_WIDTH 				= 32,
	parameter AXI_DATA_WIDTH 				= 32,
	parameter SIM 							= "FALSE",
	parameter DEBUG							= "FALSE"
)
(
	//------------------------------------------------
	// Port define
	//------------------------------------------------
	input									i_axi_clk,
	input									i_axi_rst,
	
	//--s_axi_lite 被动 发送寄存器
	input 	[AXI_ADDR_WIDTH - 1 : 0]		s_axi_araddr,
	output 									s_axi_arready,
	input 									s_axi_arvalid,
		
	input 	[AXI_ADDR_WIDTH - 1 : 0]		s_axi_awaddr,
	output 									s_axi_awready,
	input 									s_axi_awvalid,
		
	input 									s_axi_bready,
	output 	[1:0]							s_axi_bresp,
	output 									s_axi_bvalid,
		
	output 	[AXI_DATA_WIDTH - 1 : 0]		s_axi_rdata,
	input 									s_axi_rready,
	output 	[1:0]							s_axi_rresp,
	output 									s_axi_rvalid,
		
	input 	[AXI_DATA_WIDTH - 1 : 0]		s_axi_wdata,
	output 									s_axi_wready,
	input	[3:0]							s_axi_wstrb,
	input 									s_axi_wvalid,
	
	//------------------------------------------------
	// Port define
	//------------------------------------------------				
	
	output									m_cfg_wr_en,
	output 	[CFG_DATA_WIDTH - 1 : 0]		m_cfg_wr_data,
	output 	[CFG_ADDR_WIDTH - 1 : 0]		m_cfg_addr,
	output									m_cfg_rd_en,
	input									m_cfg_rd_vld,
	input	[CFG_DATA_WIDTH - 1 : 0]		m_cfg_rd_data,
	input 									m_cfg_busy
);

	//----------------------------------------------------------------------------------------------
	// BitWidth(x) function
	//----------------------------------------------------------------------------------------------
	function integer BitWidth (input integer depth);
	begin
		for(BitWidth = 0; depth>0; BitWidth = BitWidth + 1) 
			depth = depth >> 1;
	end
	endfunction

	//----------------------------------------------------------------------------------------------
	// Fsm define
	//----------------------------------------------------------------------------------------------
	typedef enum logic [2:0]{
		IDLE 		= 3'd0,
		WR_ADDR		= 3'd1,
		WR_DATA		= 3'd2,
		WR_RESP		= 3'd3,
		RD_ADDR		= 3'd4,
		CFG_RD_DATA	= 3'd5,
		RD_DATA		= 3'd6
	} Fsm_e;


	//----------------------------------------------------------------------------------------------
	// struct define
	//----------------------------------------------------------------------------------------------
	typedef struct {
		Fsm_e 							state;
		logic 							s_axi_arready;
		logic 							s_axi_awready;
		logic 							s_axi_wready;
		logic 							s_axi_rvalid;
		logic [AXI_DATA_WIDTH - 1 : 0]	s_axi_rdata;
		logic 							s_axi_bvalid;
		
		logic 							cfg_wr_en;
		logic [CFG_DATA_WIDTH - 1 : 0]	cfg_wr_data;
		logic 							cfg_rd_en;
		logic [CFG_ADDR_WIDTH - 1 : 0] 	cfg_addr;
  	} axi_conv_cfg_s;

	//----------------------------------------------------------------------------------------------
	// Register define
	//----------------------------------------------------------------------------------------------
  	axi_conv_cfg_s r,rn;


	logic 							m_cfg_rd_vld_i;
	logic [CFG_DATA_WIDTH - 1 : 0] 	m_cfg_rd_data_i;
	logic 							m_cfg_busy_i;
	
	//----------------------------------------------------------------------------------------------
	// combinatorial always
	//----------------------------------------------------------------------------------------------
	always_comb begin	
		rn = r;
		
		case(r.state)
		IDLE: begin
			rn.cfg_rd_en 		= 1'b0;
			rn.cfg_wr_en 		= 1'b0;
			rn.s_axi_arready 	= 1'b0;
			rn.s_axi_awready 	= 1'b0;
			rn.s_axi_bvalid		= 1'b0;
			if(s_axi_arvalid) begin
				rn.s_axi_arready 	= 1'b1;
				rn.state 			= RD_ADDR;
			end 
			else if(s_axi_awvalid) begin
				rn.s_axi_awready	= 1'b1;
				rn.state			= WR_ADDR;
			end
		end
		
		WR_ADDR: begin
			if(s_axi_awvalid & s_axi_awready) begin
				rn.s_axi_awready	= 1'b0;
				rn.cfg_addr			= s_axi_awaddr;
				rn.state			= WR_DATA;
				rn.s_axi_wready		= 1'b1;
			end
		end
		
		WR_DATA: begin
			if(s_axi_wready & s_axi_wvalid) begin
				rn.s_axi_wready		= 1'b0;
				rn.state			= WR_RESP;
				rn.cfg_wr_en		= 1'b1;
				rn.cfg_wr_data		= s_axi_wdata[CFG_DATA_WIDTH - 1 : 0];
				rn.s_axi_bvalid		= 1'b1;
			end
		end
		
		WR_RESP: begin // 
			if(m_cfg_wr_en & !m_cfg_busy_i) begin
				rn.cfg_wr_en = 1'b0;
			end
			if(s_axi_bvalid & s_axi_bready) begin
				rn.s_axi_bvalid = 1'b0;
			end
			
			if(rn.cfg_wr_en == 1'b0 && rn.s_axi_bvalid == 1'b0) begin
				rn.state = IDLE;
			end
		end
		
		RD_ADDR: begin
			if(s_axi_arvalid & s_axi_arready) begin
				rn.s_axi_arready	= 1'b0;
				rn.cfg_addr			= s_axi_araddr;
				rn.state			= CFG_RD_DATA;
				rn.cfg_rd_en		= 1'b1;
			end
		end
		
		CFG_RD_DATA: begin
			if(!m_cfg_busy_i)begin
				rn.cfg_rd_en = 1'b0;
			end
		
			if(m_cfg_rd_vld_i) begin
				rn.s_axi_rvalid = 1'b1;
				rn.s_axi_rdata	= m_cfg_rd_data_i[AXI_DATA_WIDTH - 1 : 0];
				rn.state		= RD_DATA;
			end
		end
		
		RD_DATA: begin
			if(s_axi_rvalid & s_axi_rready) begin
				rn.s_axi_rvalid = 1'b0;
				rn.state		= IDLE;
			end
		end
		
		default:;
		endcase
	end
	//----------------------------------------------------------------------------------------------
	// internal assignment
	//----------------------------------------------------------------------------------------------
	assign m_cfg_rd_vld_i	= m_cfg_rd_vld;
	assign m_cfg_rd_data_i	= m_cfg_rd_data;
	assign m_cfg_busy_i		= m_cfg_busy;
	
	//----------------------------------------------------------------------------------------------
	// output assignment 
	//----------------------------------------------------------------------------------------------
	assign m_cfg_addr 	= r.cfg_addr;
	assign m_cfg_rd_en	= r.cfg_rd_en;
	assign m_cfg_wr_en	= r.cfg_wr_en;
	assign m_cfg_wr_data= r.cfg_wr_data;
	
	assign s_axi_arready= r.s_axi_arready;
	assign s_axi_awready= r.s_axi_awready;
	assign s_axi_rvalid	= r.s_axi_rvalid;
	assign s_axi_rdata	= r.s_axi_rdata;
	assign s_axi_rresp	= 2'd0;
	assign s_axi_wready	= r.s_axi_wready;
	assign s_axi_bvalid	= r.s_axi_bvalid;
	assign s_axi_bresp	= 2'd0;

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
	always_ff @(posedge i_axi_clk) begin
		r <= #1 rn;
		if(i_axi_rst == 1'b1) begin
			r.state			<= #1 IDLE;
			r.s_axi_arready	<= #1 1'b0;
			r.s_axi_awready	<= #1 1'b0;
			r.s_axi_wready	<= #1 1'b0;
			r.s_axi_rvalid	<= #1 1'b0;
			r.s_axi_rdata	<= #1 {AXI_DATA_WIDTH{1'b0}};
			r.s_axi_bvalid	<= #1 1'b0;
			r.cfg_wr_en		<= #1 1'b0;
			r.cfg_wr_data	<= #1 {CFG_DATA_WIDTH{1'b0}};
			r.cfg_rd_en		<= #1 1'b0;
			r.cfg_addr		<= #1 {CFG_ADDR_WIDTH{1'b0}};
		end
	end

endmodule

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

