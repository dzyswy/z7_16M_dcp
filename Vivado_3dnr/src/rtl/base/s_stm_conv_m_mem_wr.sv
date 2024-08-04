
`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

module s_stm_conv_m_mem_wr
#(
	parameter USE_FIFO		 = "TRUE",
	parameter MAX_BURST_LEN	 = 256,
	parameter AXI_ADDR_WIDTH = 32,
	parameter AXI_DATA_WIDTH = 64,
	parameter SIM 			 = "FALSE",
	parameter DEBUG			 = "FALSE"
)
(
	//------------------------------------------------
	// Port define
	//------------------------------------------------
	input											i_clk,//&&Clk, Freq_m = 200
	input											i_rst,//&&Rst, Synclk = i_clk,
	
	input 											i_clr_vld,
	output											o_clr_rdy,
			
	input	[31:0]									i_ctrl_wr_b_len,
	input	[AXI_ADDR_WIDTH - 1:0]					i_ctrl_wr_addr,// 鍙栦綆鍦板潃浣滀负鍋忕Щ閲�
	input 											i_ctrl_wr_vld,
	output 											o_ctrl_wr_rdy,
		
	input 	[AXI_DATA_WIDTH - 1 : 0]				s_axis_tdata,
	input											s_axis_tlast,
	input											s_axis_tvld,
	output											s_axis_trdy,
		
	output 	[2:0]									o_err,
	//------------------------------------------------
	// AXI MEM
	//------------------------------------------------
	input 											m_axi_awready,
	output  										m_axi_awvalid,
	output  [AXI_ADDR_WIDTH - 1 : 0]				m_axi_awaddr,
	output  [BitWidth(MAX_BURST_LEN - 1) - 1 : 0]	m_axi_awlen,
		
	input 											m_axi_wready,
	output 											m_axi_wvalid,
	output  [AXI_DATA_WIDTH - 1 : 0]				m_axi_wdata,
	output  [AXI_DATA_WIDTH/8 - 1: 0]  				m_axi_wstrb,
	output  										m_axi_wlast,
								
	output 											m_axi_bready,
	input 											m_axi_bvalid,
	input  	[1:0] 									m_axi_bresp,

	output	[1:0]									m_axi_awburst,
	output	[3:0]									m_axi_awcache,
	output	[0:0]									m_axi_awlock,
	output	[2:0]									m_axi_awprot,
	output	[3:0]									m_axi_awqos,
	output	[2:0]									m_axi_awsize,	
	output	[3:0]									m_axi_awregion
	
);
	//------------------------------------------------
	// BitWidth(x) function
	//------------------------------------------------
	function integer BitWidth (input integer depth);
	begin
		for(BitWidth = 0; depth>0; BitWidth = BitWidth + 1) 
			depth = depth >> 1;
	end
	endfunction
	
	localparam REM_D_WIDTH 	= BitWidth(AXI_DATA_WIDTH/8 - 1); 	// 鏁版嵁浣欐暟鐨勪綅瀹�
	localparam BURST_WIDTH 	= BitWidth(MAX_BURST_LEN);			// 涓�娆＄獊鍙戠殑BYTE鏁伴噺,澶氫竴浣嶏紝鏂逛究璁℃暟
	//----------------------------------------------------------------------------------------------
	// Fsm define
	//----------------------------------------------------------------------------------------------
	typedef enum logic [2:0] {
		IDLE 		= 3'd0,
		WAIT_BURST	= 3'd1,	
		WR_ADDR		= 3'd2,
		WR_DATA		= 3'd3
	} Fsm_e;

	//----------------------------------------------------------------------------------------------
	// struct define
	//----------------------------------------------------------------------------------------------
	typedef struct {
		Fsm_e							state;
		logic 							len_err;
		logic 							bresp_err;
		logic [31:0]					tt_burst_len;
		logic [AXI_ADDR_WIDTH - 1 : 0] 	axi_awaddr;
		logic [BURST_WIDTH - 1 : 0]		axi_awlen;
		logic [BURST_WIDTH - 1 : 0]		axi_cnt;
		logic 							axi_awvalid;
		logic 							axi_data_en;
		logic 							axi_bready;
		logic 							ctrl_wr_rdy;
		logic 							clr_rdy;
  	} s_stm_conv_m_mem_wr_s;

	//----------------------------------------------------------------------------------------------
	// Register define
	//----------------------------------------------------------------------------------------------
  	s_stm_conv_m_mem_wr_s r,rn;
	logic 							tx_axis_tvalid;	
	logic 							tx_axis_tready;	
	logic [AXI_DATA_WIDTH - 1 : 0]	tx_axis_tdata;	
	logic 							tx_axis_tlast;	
	logic [9:0]						axis_data_cnt;
	logic 							buf_vld;
	logic 							wr_rst_busy;
	logic 							rd_rst_busy;
					
	logic 							s_axis_trdy_i;
	logic 							tx_axis_tvalid_i;
	//----------------------------------------------------------------------------------------------
	// combinatorial always
	//----------------------------------------------------------------------------------------------
	always_comb begin	
		rn = r;
		
		if(m_axi_bvalid & m_axi_bready) begin
			rn.axi_bready = 1'b0;
			if(m_axi_bresp != 3'd0) begin
				rn.bresp_err = 1'b1;
			end
		end	
		
		case (r.state)
		IDLE: begin
			rn.clr_rdy		= 1'b1;
			rn.axi_data_en	= 1'b0;
			rn.axi_awvalid	= 1'b0;
			rn.tt_burst_len	= 32'd0;
			rn.ctrl_wr_rdy	= 1'b1;
			rn.axi_awaddr	= {AXI_ADDR_WIDTH{1'b0}};
			rn.axi_awlen	= {BURST_WIDTH{1'b0}};			

			if(i_ctrl_wr_vld & o_ctrl_wr_rdy) begin
				rn.ctrl_wr_rdy		= 1'b0;
				rn.axi_awaddr 		= i_ctrl_wr_addr; //  褰撳墠涓嶈绠楀亸绉婚噺			
				rn.state			= WAIT_BURST;
				
				if(i_ctrl_wr_b_len[REM_D_WIDTH - 1 : 0] != {REM_D_WIDTH{1'b0}})begin
					rn.tt_burst_len 	= i_ctrl_wr_b_len[31:REM_D_WIDTH] + 1'b1;
				end else begin
					rn.tt_burst_len 	= i_ctrl_wr_b_len[31:REM_D_WIDTH];
				end
				
				rn.axi_awlen 		= rn.tt_burst_len[BURST_WIDTH - 2 : 0];
				if(rn.tt_burst_len[31:BURST_WIDTH - 1] != 0) begin
					rn.axi_awlen = MAX_BURST_LEN;
				end
			end
			
			if(i_clr_vld == 1'b1) begin
				rn.ctrl_wr_rdy	= 1'b0;
				rn.len_err 		= 1'b0;
				rn.bresp_err	= 1'b0;
				rn.state		= IDLE;
			end
		end
		
		WAIT_BURST: begin
			if(i_clr_vld & r.clr_rdy)begin
				rn.state		= IDLE;	
			end else if(buf_vld == 1'b1 && rn.axi_bready == 1'b0) begin
				rn.clr_rdy		= 1'b0;
				rn.axi_awvalid 	= 1'b1;
				rn.state		= WR_ADDR;
			end
		end
		
		WR_ADDR: begin
			if(m_axi_awvalid & m_axi_awready) begin
				rn.axi_awvalid 	= 1'b0;
				rn.axi_awaddr	= r.axi_awaddr + (r.axi_awlen << REM_D_WIDTH);
				rn.axi_cnt		= r.axi_awlen;
				rn.axi_data_en	= 1'b1;
				rn.state		= WR_DATA;
			end
		end
		
		WR_DATA: begin
			if(m_axi_wvalid & m_axi_wready) begin
				rn.axi_cnt = r.axi_cnt - 1'b1;
				if(m_axi_wlast == 1'b1) begin
					rn.axi_bready	= 1'b1;
					rn.axi_data_en	= 1'b0;
					rn.tt_burst_len	= r.tt_burst_len - r.axi_awlen;
					
					rn.axi_awlen 	= rn.tt_burst_len[BURST_WIDTH - 2 : 0];
					if(rn.tt_burst_len[31:BURST_WIDTH - 1] != 0) begin
						rn.axi_awlen = MAX_BURST_LEN;
					end
					
					if(rn.tt_burst_len == 32'd0) begin
						rn.axi_awlen 	= {BURST_WIDTH{1'b0}};
						rn.state		= IDLE;
						rn.ctrl_wr_rdy	= 1'b1;
						if(i_clr_vld == 1'b1) begin
							rn.ctrl_wr_rdy	= 1'b0;
						end
						rn.clr_rdy		= 1'b1;
					end else begin
						rn.state		= WAIT_BURST;
						rn.clr_rdy		= 1'b1;
					end
				end
			end
		end
		default:;
		endcase
	end
	
	//----------------------------------------------------------------------------------------------
	// internal assignment
	//----------------------------------------------------------------------------------------------
	generate 
		if(USE_FIFO == "TRUE") begin
			// assign buf_vld = (axis_data_cnt >= r.axi_awlen && axis_data_cnt != 10'd0) ? 1'b1 : 1'b0;
			assign buf_vld = (axis_data_cnt >= r.axi_awlen && r.axi_awlen != 0) ? 1'b1 : 1'b0;
		end else begin
			assign buf_vld = 1'b1;
		end
	endgenerate
	
	//----------------------------------------------------------------------------------------------
	// output assignment
	//----------------------------------------------------------------------------------------------
	assign m_axi_awvalid	= r.axi_awvalid;
	assign m_axi_awaddr		= r.axi_awaddr;
	assign m_axi_awlen		= r.axi_awlen - 1'b1;
	assign m_axi_wvalid		= (r.axi_data_en == 1'b1)? tx_axis_tvalid : 1'b0;
	assign m_axi_wdata		= tx_axis_tdata;
	assign m_axi_wstrb		= {AXI_DATA_WIDTH/8{1'b1}};
	assign m_axi_wlast		= (r.axi_cnt == 1'b1) ? 1'b1 : 1'b0;
	assign m_axi_bready		= r.axi_bready;

	assign m_axi_awburst	= 2'd1;
	assign m_axi_awcache	= 4'd3;
	assign m_axi_awlock		= 1'b0;
	assign m_axi_awprot		= 3'd000;
	assign m_axi_awqos		= 4'd0;
	assign m_axi_awsize		= $clog2(AXI_DATA_WIDTH/8);
	assign m_axi_awregion	= 4'd0;


	
	assign o_ctrl_wr_rdy	= r.ctrl_wr_rdy;
	assign o_err			= {1'b0, r.bresp_err, r.len_err};
	assign o_clr_rdy		= r.clr_rdy;
	//----------------------------------------------------------------------------------------------
	// Debug Signal
	//----------------------------------------------------------------------------------------------
	generate
		if(DEBUG == "TRUE") begin
			(*mark_debug = "true"*) logic [2:0] mark_state;
			assign mark_state = r.state;
		end
	endgenerate

	//----------------------------------------------------------------------------------------------
	// sequential always
	//----------------------------------------------------------------------------------------------	
	always_ff @(posedge i_clk) begin
		r <= rn;
		if(i_rst == 1'b1) begin
			r.state			<= IDLE;
			r.len_err		<= 1'b0;
			r.bresp_err		<= 1'b0;
			r.tt_burst_len	<= 32'd0;
			r.axi_awaddr	<= {AXI_ADDR_WIDTH{1'b0}};
			r.axi_awlen		<= {BURST_WIDTH{1'b0}};
			r.axi_awvalid	<= 1'b0;
			r.axi_data_en	<= 1'b0;
			r.axi_bready	<= 1'b0;
			r.ctrl_wr_rdy	<= 1'b0;
			r.clr_rdy		<= 1'b0;
			r.axi_cnt		<= {BURST_WIDTH{1'b0}};
		end
	end
	
	//----------------------------------------------------------------------------------------------
	// fifo 
	//----------------------------------------------------------------------------------------------
	assign tx_axis_tready	= (r.axi_data_en == 1'b1)? m_axi_wready : 1'b0;
	generate 
		if(USE_FIFO == "TRUE") begin
	
			assign s_axis_trdy 		= s_axis_trdy_i; //!wr_rst_busy & s_axis_trdy_i;
			assign tx_axis_tvalid	= tx_axis_tvalid_i; //tx_axis_tvalid_i & !rd_rst_busy;
			
			
			axi_fifo_64x512 
			u_axi_fifo_64x512 (
				.wr_rst_busy		(	wr_rst_busy							),      // output wire wr_rst_busy
				.rd_rst_busy		(	rd_rst_busy							),      // output wire rd_rst_busy
				.s_aclk				(	i_clk								),     	// input wire s_aclk
				.s_aresetn			(	(!i_rst)&(!(r.clr_rdy & i_clr_vld))	),      // input wire s_aresetn
				.s_axis_tvalid		(	s_axis_tvld							),  	// input wire s_axis_tvalid
				.s_axis_tready		(	s_axis_trdy_i						),  	// output wire s_axis_tready
				.s_axis_tdata		(	s_axis_tdata						),    	// input wire [63 : 0] s_axis_tdata
				.s_axis_tlast		(	s_axis_tlast						),    	// input wire s_axis_tlast
				.m_axis_tvalid		(	tx_axis_tvalid_i					),  	// output wire m_axis_tvalid
				.m_axis_tready		(	tx_axis_tready						),  	// input wire m_axis_tready
				.m_axis_tdata		(	tx_axis_tdata						),    	// output wire [63 : 0] m_axis_tdata
				.m_axis_tlast		(	tx_axis_tlast						),    	// output wire m_axis_tlast
				.axis_data_count	( 	axis_data_cnt						)
			);
			
		end else begin
			assign tx_axis_tvalid 	= s_axis_tvld;
			assign tx_axis_tdata	= s_axis_tdata;
			assign tx_axis_tlast	= s_axis_tlast;
			assign s_axis_trdy		= tx_axis_tready;
		end
	endgenerate

	(* mark_debug = "true" *)logic											mark_wrddr_awready;
	(* mark_debug = "true" *)logic  										mark_wrddr_awvalid;
	(* mark_debug = "true" *)logic  [AXI_ADDR_WIDTH - 1 : 0]				mark_wrddr_awaddr;
	(* mark_debug = "true" *)logic											mark_wrddr_wready;
	(* mark_debug = "true" *)logic 											mark_wrddr_wvalid;
	(* mark_debug = "true" *)logic  [AXI_DATA_WIDTH - 1 : 0]				mark_wrddr_wdata;
	(* mark_debug = "true" *)logic  										mark_wrddr_wlast;							
	(* mark_debug = "true" *)logic 											mark_wrddr_bready;
	(* mark_debug = "true" *)logic											mark_wrddr_bvalid;
	(* mark_debug = "true" *)logic 	[1:0] 									mark_wrddr_bresp;


	assign mark_wrddr_awready	= m_axi_awready;
	assign mark_wrddr_awvalid	= m_axi_awvalid;
	assign mark_wrddr_awaddr	= m_axi_awaddr;
	assign mark_wrddr_wready	= m_axi_wready;
	assign mark_wrddr_wvalid	= m_axi_wvalid;
	assign mark_wrddr_wdata		= m_axi_wdata;
	assign mark_wrddr_wlast		= m_axi_wlast;	
	assign mark_wrddr_bready	= m_axi_bready;
	assign mark_wrddr_bvalid	= m_axi_bvalid;
	assign mark_wrddr_bresp		= m_axi_bresp;





	
endmodule

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

