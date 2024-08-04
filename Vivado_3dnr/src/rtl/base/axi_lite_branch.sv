// *************************************************************************************************
// Vendor 			: Luster
// Author 			: liu jun
// Filename 		: z7_PcieGraber_Sdi_top
// Date Created 	: 2021.10.25
// Version 			: V1.0
// -------------------------------------------------------------------------------------------------
// File description	:
// 将一路lite总线分割成两路总线，分割地址任意
// -------------------------------------------------------------------------------------------------
// Revision History :
//		
//
// *************************************************************************************************

`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

module m_lite_branch
#(
	parameter TIMEOUT_VAL		= 30000,
	parameter AXI_DATA_WIDTH 	= 32,
	parameter AXI_ADDR_WIDTH 	= 32,
    parameter BRANCH_ADDR		= 32'h00400000,
    parameter BRANCH_RANGE		= 32'h00001000,
	parameter SIM 				= "FALSE",
	parameter DEBUG				= "FALSE"
)
(
	input									i_clk,  
	input 									i_rstn, 

	//------------------------------------------------
	// s_axi_port
	//------------------------------------------------
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
	// m0_axi_port
	//------------------------------------------------
	output  [AXI_ADDR_WIDTH - 1 : 0]		m0_axi_araddr,
	input 									m0_axi_arready,
	output 									m0_axi_arvalid,
	                                         
	output 	[AXI_ADDR_WIDTH - 1 : 0]		m0_axi_awaddr,
	input 									m0_axi_awready,
	output 									m0_axi_awvalid,
	                                         
	output 									m0_axi_bready,
	input 	[1:0]							m0_axi_bresp,
	input 									m0_axi_bvalid,
	                                         
	input 	[AXI_DATA_WIDTH - 1 : 0]		m0_axi_rdata,
	output 									m0_axi_rready,
	input 	[1:0]							m0_axi_rresp,
	input 									m0_axi_rvalid,
	                                         
	output 	[AXI_DATA_WIDTH - 1 : 0]		m0_axi_wdata,
	input 									m0_axi_wready,
	output 	[AXI_DATA_WIDTH/8 - 1 : 0]		m0_axi_wstrb,
	output 									m0_axi_wvalid,
	
	//------------------------------------------------
	// m1_axi_port
	//------------------------------------------------
	output  [AXI_ADDR_WIDTH - 1 : 0]		m1_axi_araddr,
	input 									m1_axi_arready,
	output 									m1_axi_arvalid,
	                                         
	output 	[AXI_ADDR_WIDTH - 1 : 0]		m1_axi_awaddr,
	input 									m1_axi_awready,
	output 									m1_axi_awvalid,
	                                         
	output 									m1_axi_bready,
	input 	[1:0]							m1_axi_bresp,
	input 									m1_axi_bvalid,
	                                         
	input 	[AXI_DATA_WIDTH - 1 : 0]		m1_axi_rdata,
	output 									m1_axi_rready,
	input 	[1:0]							m1_axi_rresp,
	input 									m1_axi_rvalid,
	                                         
	output 	[AXI_DATA_WIDTH - 1 : 0]		m1_axi_wdata,
	input 									m1_axi_wready,
	output 	[AXI_DATA_WIDTH/8 - 1 : 0]		m1_axi_wstrb,
	output 									m1_axi_wvalid

);

    localparam BLK_WIDTH = $clog2(BRANCH_RANGE); // 26

	//----------------------------------------------------------------------------------------------
	// Fsm define
	//----------------------------------------------------------------------------------------------
	typedef enum logic [2:0]{
		IDLE		= 3'd0,
		WR_ADDR		= 3'd1,
		WR_DATA		= 3'd2,
		WR_BRESP 	= 3'd3,
		RD_ADDR		= 3'd4,
		RD_DATA		= 3'd5
	} Fsm_e;
	
	//----------------------------------------------------------------------------------------------
	// struct define
	//----------------------------------------------------------------------------------------------
	typedef struct {
		Fsm_e							state;
		logic [1:0]						ch_en;
		logic [AXI_ADDR_WIDTH - 1 : 0]	axi_addr;
		logic 							s_axi_arready;
		logic 							s_axi_awready;
		logic 							s_axi_wready;
		logic 							m0_axi_arvalid;
		logic 							m1_axi_arvalid;
		logic 							m0_axi_awvalid;
		logic 							m1_axi_awvalid;
		logic [AXI_DATA_WIDTH - 1 : 0]	axi_wr_data;
		logic 							m0_axi_wvalid;
		logic 							m1_axi_wvalid;
		logic 							s_axi_bvalid;
		logic 							m0_axi_bready;
		logic 							m1_axi_bready;
		logic 							s_axi_rvalid;
		logic 							m0_axi_rready;
		logic 							m1_axi_rready;
		logic [AXI_DATA_WIDTH - 1 : 0]	s_axi_rdata;
		logic [15:0]					timeoutcnt;
		logic [4:0]						err_mask;
  	} m_lite_branch_s;
	
	//----------------------------------------------------------------------------------------------
	// Register define
	//----------------------------------------------------------------------------------------------
  	m_lite_branch_s r,rn;

	//----------------------------------------------------------------------------------------------
	// combinatorial always
	//----------------------------------------------------------------------------------------------
	always_comb begin	
		rn 	= r;

		//------------------------------------------------------------------------------------------
		// axi clk domain
		//------------------------------------------------------------------------------------------
		case (r.state)
		IDLE: begin
			rn.s_axi_arready 	= 1'b0;
			rn.s_axi_awready 	= 1'b0;
			rn.s_axi_wready		= 1'b0;
			rn.m0_axi_arvalid	= 1'b0;
			rn.m1_axi_arvalid	= 1'b0;
			rn.m0_axi_awvalid	= 1'b0;
			rn.m1_axi_awvalid	= 1'b0;
			rn.axi_wr_data		= {AXI_DATA_WIDTH{1'b0}};
			rn.m0_axi_wvalid	= 1'b0;
			rn.m1_axi_wvalid	= 1'b0;
			rn.s_axi_bvalid		= 1'b0;
			rn.m0_axi_bready	= 1'b0;
			rn.m1_axi_bready	= 1'b0;
			rn.s_axi_rdata		= {AXI_DATA_WIDTH{1'b0}};
			rn.timeoutcnt		= 16'd0;
			
			if(s_axi_arvalid) begin
				rn.s_axi_arready = 1'b1;
                if(s_axi_araddr < BRANCH_ADDR)begin
                    rn.axi_addr 			= s_axi_araddr;
                    rn.ch_en[0] 			= 1'b1;
                    rn.m0_axi_arvalid		= 1'b1;
                end else begin
                    rn.axi_addr 			= s_axi_araddr[BLK_WIDTH - 1:0];
                    rn.ch_en[1] 			= 1'b1;
                    rn.m1_axi_arvalid		= 1'b1;
                end
				rn.state = RD_ADDR;
			end
			else if(s_axi_awvalid) begin
				rn.s_axi_awready = 1'b1;
				rn.s_axi_wready = 1'b1;
				rn.s_axi_bvalid = 1'b1;
				
                if(s_axi_awaddr < BRANCH_ADDR)begin
                    rn.axi_addr 			= s_axi_awaddr;
                    rn.ch_en[0] 			= 1'b1;
                end else begin
                    rn.axi_addr 			= s_axi_awaddr[BLK_WIDTH - 1:0];
                    rn.ch_en[1] 			= 1'b1;
                end
				rn.state = WR_ADDR;
			end
		end
		
		// 先将s_axi_wr接口缓存
		WR_ADDR: begin
			rn.timeoutcnt = r.timeoutcnt + 1'b1;
			
			if(s_axi_awvalid & s_axi_awready) begin
				rn.s_axi_awready = 1'b0;
			end
			
			if(s_axi_wvalid & s_axi_wready) begin
				rn.axi_wr_data 	= s_axi_wdata;
				rn.s_axi_wready	= 1'b0;
			end
			
			if(s_axi_bvalid & s_axi_bready) begin
				rn.s_axi_bvalid = 1'b0;
			end
			
			if((r.s_axi_awready == 1'b0 && r.s_axi_wready == 1'b0 && r.s_axi_bvalid == 1'b0)||
				r.timeoutcnt >= TIMEOUT_VAL) begin
				rn.timeoutcnt 	= 16'd0;
				if(r.ch_en[0]) begin
					rn.m0_axi_awvalid = 1'b1;
					rn.m0_axi_wvalid = 1'b1;
				end
				
				if(r.ch_en[1]) begin
					rn.m1_axi_awvalid = 1'b1;
					rn.m1_axi_wvalid = 1'b1;
				end
				
				rn.state = IDLE;
				if(r.ch_en != 0) begin
					rn.state = WR_DATA;
				end
				
				if(r.timeoutcnt >= TIMEOUT_VAL) begin
					rn.err_mask[0]		= 1'b1;
					rn.m0_axi_awvalid 	= 1'b0;
					rn.m0_axi_wvalid 	= 1'b0;
					rn.m1_axi_awvalid 	= 1'b0;
					rn.m1_axi_wvalid 	= 1'b0;
					rn.s_axi_awready 	= 1'b0;
					rn.s_axi_wready 	= 1'b0;
					rn.s_axi_bvalid 	= 1'b0;			
					rn.state 			= IDLE;
				end	
			end
		end
		
		WR_DATA: begin
			rn.timeoutcnt = r.timeoutcnt + 1'b1;
			if(m0_axi_awvalid & m0_axi_awready) begin
				rn.m0_axi_awvalid = 1'b0;
			end
			
			if(m1_axi_awvalid & m1_axi_awready) begin
				rn.m1_axi_awvalid = 1'b0;
			end
			
			if(m0_axi_wvalid & m0_axi_wready) begin
				rn.m0_axi_wvalid = 1'b0;
			end
			
			if(m1_axi_wvalid & m1_axi_wready) begin
				rn.m1_axi_wvalid = 1'b0;
			end
			
			if((rn.m0_axi_awvalid == 1'b0 && rn.m1_axi_awvalid == 1'b0 &&
				rn.m0_axi_wvalid == 1'b0 && rn.m1_axi_wvalid == 1'b0) || 
				r.timeoutcnt >= TIMEOUT_VAL)begin
				rn.timeoutcnt 	= 16'd0;
				if(r.ch_en[0] == 1'b1) begin
					rn.m0_axi_bready = 1'b1;
				end
				if(r.ch_en[1] == 1'b1) begin
					rn.m1_axi_bready = 1'b1;
				end
				
				rn.state = WR_BRESP;
				if(r.timeoutcnt >= TIMEOUT_VAL) begin
					rn.err_mask[1]	 	= 1'b1;
					rn.m1_axi_bready 	= 1'b0;
					rn.m0_axi_bready 	= 1'b0;
					rn.m0_axi_awvalid 	= 1'b0;
					rn.m1_axi_awvalid 	= 1'b0;
					rn.m0_axi_wvalid 	= 1'b0;
					rn.m1_axi_wvalid 	= 1'b0;
					rn.state 			= IDLE;
				end	
			end
			
		end
		
		WR_BRESP: begin
			rn.timeoutcnt = r.timeoutcnt + 1'b1;
			
			if(m0_axi_bvalid & m0_axi_bready) begin
				rn.m0_axi_bready = 1'b0;
			end
			
			if(m1_axi_bvalid & m1_axi_bready) begin
				rn.m1_axi_bready = 1'b0;
			end
			
			if(r.timeoutcnt >= TIMEOUT_VAL) begin
				rn.m0_axi_bready = 1'b0;
				rn.m1_axi_bready = 1'b0;
				rn.state 		= IDLE;
				rn.timeoutcnt 	= 16'd0;
				rn.err_mask[2]	= 1'b1;
				rn.ch_en		= 2'd0;
			end
			
			if(rn.m0_axi_bready == 1'b0 && rn.m1_axi_bready == 1'b0) begin
				rn.state 		= IDLE;
				rn.timeoutcnt 	= 16'd0;
				rn.ch_en		= 2'd0;
			end
		end
		
		RD_ADDR: begin
			rn.timeoutcnt = r.timeoutcnt + 1'b1;
		
			if(s_axi_arvalid & s_axi_arready) begin
				rn.s_axi_arready = 1'b0;
			end
			
			if(m0_axi_arvalid & m0_axi_arready) begin
				rn.m0_axi_arvalid = 1'b0;
			end
			
			if(m1_axi_arvalid & m1_axi_arready) begin
				rn.m1_axi_arvalid = 1'b0;
			end
			
			if(rn.s_axi_arready == 1'b0 && r.timeoutcnt == TIMEOUT_VAL) begin
				rn.m0_axi_awvalid = 1'b0;
				rn.m1_axi_awvalid = 1'b0;
				rn.s_axi_rvalid = 1'b1;
				rn.s_axi_rdata	= {28'd0,1'b1,r.err_mask[2:0]};
				rn.state 		= RD_DATA;
				rn.timeoutcnt 	= 16'd0;
				rn.err_mask[3]	= 1'b1;
				rn.ch_en		= 2'd0;
			end
			
			if(rn.s_axi_arready == 1'b0 && rn.m0_axi_arvalid == 1'b0 && 
				rn.m1_axi_arvalid == 1'b0) begin
				
				if(m0_axi_rvalid & r.ch_en[0]) begin
					rn.s_axi_rdata 		= m0_axi_rdata;
					rn.m0_axi_rready 	= 1'b1;
					rn.s_axi_rvalid 	= 1'b1;
					rn.state 			= RD_DATA;
					rn.timeoutcnt 		= 16'd0;
				end
				
				if(m1_axi_rvalid & r.ch_en[1]) begin
					rn.s_axi_rdata 		= m1_axi_rdata;
					rn.m1_axi_rready 	= 1'b1;
					rn.s_axi_rvalid 	= 1'b1;
					rn.state 			= RD_DATA;
					rn.timeoutcnt 		= 16'd0;
				end
				
			end
		end
		
		RD_DATA: begin
			rn.timeoutcnt = r.timeoutcnt + 1'b1;
		
			if(s_axi_rvalid & s_axi_rready) begin
				rn.s_axi_rvalid = 1'b0;
			end
			
			if(m0_axi_rvalid & m0_axi_rready) begin
				rn.m0_axi_rready = 1'b0;
			end
			
			if(m1_axi_rvalid & m1_axi_rready) begin
				rn.m1_axi_rready = 1'b0;
			end
			
			if(rn.s_axi_rvalid == 1'b0 && r.timeoutcnt == TIMEOUT_VAL) begin// 此截断延迟比较小
				rn.m0_axi_rready 	= 1'b0;
				rn.m1_axi_rready 	= 1'b0;
				rn.ch_en			= 2'd0;
				rn.state 			= IDLE;
				rn.timeoutcnt 		= 16'd0;
				rn.err_mask[4]		= 1'b1;
			end
			
			if(rn.s_axi_rvalid == 1'b0 && rn.m0_axi_rready == 1'b0 && rn.m1_axi_rready == 1'b0)begin
				rn.ch_en		= 2'd0;
				rn.state 		= IDLE;
				rn.timeoutcnt 	= 16'd0;
			end
		end
		
		default:;
		endcase
		
	end
	//----------------------------------------------------------------------------------------------
	// output assignment
	//----------------------------------------------------------------------------------------------


	assign s_axi_arready 	= r.s_axi_arready;
	assign s_axi_awready 	= r.s_axi_awready;
	assign s_axi_bresp	 	= 2'd0;
	assign s_axi_bvalid	 	= r.s_axi_bvalid;
	assign s_axi_rdata	 	= r.s_axi_rdata;
	assign s_axi_rresp		= 2'd0;
	assign s_axi_rvalid		= r.s_axi_rvalid;
	assign s_axi_wready		= r.s_axi_wready;

	assign m0_axi_araddr	= r.axi_addr;	
	assign m0_axi_arvalid	= r.m0_axi_arvalid;	                                      
	assign m0_axi_awaddr	= r.axi_addr;	
	assign m0_axi_awvalid	= r.m0_axi_awvalid;	                                     
	assign m0_axi_bready	= r.m0_axi_bready;	                                     
	assign m0_axi_rready	= r.m0_axi_rready;  
	assign m0_axi_wdata		= r.axi_wr_data;		
	assign m0_axi_wstrb		= {AXI_DATA_WIDTH/8{1'b1}};
	assign m0_axi_wvalid	= r.m0_axi_wvalid;	
	
	assign m1_axi_araddr	= r.axi_addr;	
	assign m1_axi_arvalid	= r.m1_axi_arvalid;	                                      
	assign m1_axi_awaddr	= r.axi_addr;	
	assign m1_axi_awvalid	= r.m1_axi_awvalid;	                                     
	assign m1_axi_bready	= r.m1_axi_bready;	                                     
	assign m1_axi_rready	= r.m1_axi_rready;
	assign m1_axi_wdata		= r.axi_wr_data;		
	assign m1_axi_wstrb		= {AXI_DATA_WIDTH/8{1'b1}};		
	assign m1_axi_wvalid	= r.m1_axi_wvalid;	

	assign o_err = r.err_mask;
	//----------------------------------------------------------------------------------------------
	// Debug Signal
	//----------------------------------------------------------------------------------------------
	generate
		if(DEBUG == "TRUE") begin
			(*mark_debug = "true"*) Fsm_e mark_state;
			(*mark_debug = "true"*) logic [4:0] mark_err;
			assign mark_state = r.state;
			assign mark_err = o_err;
		end
	endgenerate

	//----------------------------------------------------------------------------------------------
	// sequential always
	//----------------------------------------------------------------------------------------------	
	always_ff @(posedge i_clk) begin
		r <= rn;
		if(i_rstn == 1'b1) begin
			r.state			<= IDLE;
			r.ch_en			<= 2'd0;
			r.axi_addr		<= {AXI_ADDR_WIDTH{1'b0}};
			r.s_axi_arready	<= 1'b0;
			r.s_axi_awready	<= 1'b0;
			r.s_axi_wready	<= 1'b0;
			r.m0_axi_arvalid<= 1'b0;
			r.m1_axi_arvalid<= 1'b0;
			r.m0_axi_awvalid<= 1'b0;
			r.m1_axi_awvalid<= 1'b0;
			r.axi_wr_data	<= {AXI_DATA_WIDTH{1'b0}};
			r.m0_axi_wvalid	<= 1'b0;
			r.m1_axi_wvalid	<= 1'b0;
			r.s_axi_bvalid	<= 1'b0;
			r.m0_axi_bready	<= 1'b0;
			r.m1_axi_bready	<= 1'b0;
			r.s_axi_rvalid	<= 1'b0;
			r.m0_axi_rready <= 1'b0;
			r.m1_axi_rready <= 1'b0;
			r.s_axi_rdata	<= {AXI_DATA_WIDTH{1'b0}};
			r.timeoutcnt	<= 16'd0;
			r.err_mask		<= 5'd0;
		end
	end
	


endmodule

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

