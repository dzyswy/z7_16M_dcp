
`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

module m_mem_rd_conv_m_stm
#(
	parameter USE_FIFO			= "TRUE",
	parameter MAX_BURST_LEN	 	= 256,
	parameter AXI_ADDR_WIDTH 	= 32,
	parameter AXI_DATA_WIDTH 	= 64,
	parameter SIM 				= "FALSE",
	parameter DEBUG				= "FALSE"
)
(
	//------------------------------------------------
	// Port define
	//------------------------------------------------
	input											i_clk,
	input											i_rst,
	
	input 											i_clr_vld,
	output											o_clr_rdy,
			
	input	[31:0]									i_ctrl_rd_b_len,
	input	[AXI_ADDR_WIDTH - 1:0]					i_ctrl_rd_addr,// 取低地址作为偏移量
	input 											i_ctrl_rd_vld,
	output 											o_ctrl_rd_rdy,
		
	output 	[AXI_DATA_WIDTH - 1 : 0]				m_axis_tdata,
	output											m_axis_tlast,
	output											m_axis_tvld,
	input											m_axis_trdy,
		
	output 	[2:0]									o_err,
	//------------------------------------------------
	// m_axi_rd port
	//------------------------------------------------
	output 	[AXI_ADDR_WIDTH - 1:0]					m_axi_araddr,
	output 	[BitWidth(MAX_BURST_LEN - 1) - 1:0]		m_axi_arlen,
	input 											m_axi_arready,
	output 											m_axi_arvalid,
					
	input 	[AXI_DATA_WIDTH - 1:0]					m_axi_rdata,
	input 											m_axi_rlast,
	output 											m_axi_rready,
	input 	[1:0]									m_axi_rresp,
	input 											m_axi_rvalid,

	output	[1:0]									m_axi_arburst,
	output	[3:0]									m_axi_arcache,
	output	[0:0]									m_axi_arlock,
	output	[2:0]									m_axi_arprot,
	output	[3:0]									m_axi_arqos,
	output	[2:0]									m_axi_arsize,	
	output	[3:0]									m_axi_arregion


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
	
	localparam REM_D_WIDTH 	= BitWidth(AXI_DATA_WIDTH/8 - 1); 	// 数据余数的位宽
	localparam BURST_WIDTH 	= BitWidth(MAX_BURST_LEN);			// 一次突发的BYTE数量,多一位，方便计数
	//----------------------------------------------------------------------------------------------
	// Fsm define
	//----------------------------------------------------------------------------------------------
	typedef enum logic [2:0]{
		IDLE		= 3'd0,
		WAIT_BURST	= 3'd1,
		RD_ADDR		= 3'd2,
		RD_DATA		= 3'd3
	} Fsm_e;


	//----------------------------------------------------------------------------------------------
	// struct define
	//----------------------------------------------------------------------------------------------
	typedef struct {
		Fsm_e							state;
		logic 							len_err;
		logic 							bresp_err;
		logic [31:0]					tt_burst_len;
		logic [AXI_ADDR_WIDTH - 1 : 0]	axi_araddr;
		logic [BURST_WIDTH - 1 : 0]		axi_arlen;
		logic 							axi_arvalid;
		logic 							ctrl_rd_rdy;
		logic 							clr_rdy;
  	} m_mem_rd_conv_m_stm_s;

	//----------------------------------------------------------------------------------------------
	// Register define
	//----------------------------------------------------------------------------------------------
  	m_mem_rd_conv_m_stm_s r,rn;
	
	logic 			m_axi_rlast_i;
	logic	[9:0]	axis_data_cnt;
	logic 			buf_vld;
	logic 			wr_rst_busy;
	logic 			rd_rst_busy;
	
	logic 			m_axi_rready_i;
	logic 			m_axis_tvld_i;

	//----------------------------------------------------------------------------------------------
	// combinatorial always
	//----------------------------------------------------------------------------------------------
	always_comb begin	
		rn = r;
		
		if(m_axi_rvalid & m_axi_rready & m_axi_rlast)begin
			if(m_axi_rresp != 2'd0)begin
				rn.bresp_err = 1'b1;
			end
		end
		
		case (r.state)
		IDLE: begin
			rn.clr_rdy		= 1'b1;
			rn.axi_arvalid	= 1'b0;
			rn.tt_burst_len	= 32'd0;
			rn.ctrl_rd_rdy	= 1'b1;
			rn.axi_araddr	= {AXI_ADDR_WIDTH{1'b0}};
			rn.axi_arlen	= {BURST_WIDTH{1'b0}};
			rn.ctrl_rd_rdy	= 1'b1;
			
			if((i_ctrl_rd_vld & o_ctrl_rd_rdy) && i_ctrl_rd_b_len != 32'd0) begin
				rn.ctrl_rd_rdy		= 1'b0;
				rn.axi_araddr 		= i_ctrl_rd_addr; //  当前不计算偏移量			
				rn.state			= WAIT_BURST;
				
				// 总突发长度
				if(i_ctrl_rd_b_len[REM_D_WIDTH - 1 : 0] != {REM_D_WIDTH{1'b0}})begin // 有余数 ，长度加 1
					rn.tt_burst_len 	= i_ctrl_rd_b_len[31:REM_D_WIDTH] + 1'b1;
				end else begin
					rn.tt_burst_len 	= i_ctrl_rd_b_len[31:REM_D_WIDTH];
				end
				
				// 单次突发长度
				rn.axi_arlen = rn.tt_burst_len[BURST_WIDTH - 2 : 0];
				if(rn.tt_burst_len[31:BURST_WIDTH - 1] != 0) begin
					rn.axi_arlen = MAX_BURST_LEN;
				end
				
			end
			
			if(i_clr_vld == 1'b1) begin
				rn.ctrl_rd_rdy	= 1'b0;
				rn.len_err 		= 1'b0;
				rn.bresp_err	= 1'b0;
				rn.state		= IDLE;
			end
			
		end
		
		WAIT_BURST: begin
			if(i_clr_vld & r.clr_rdy)begin
				rn.state		= IDLE;	
			end else if(buf_vld == 1'b1) begin
				rn.clr_rdy		= 1'b0;
				rn.axi_arvalid 	= 1'b1;
				rn.state		= RD_ADDR;
			end
		end
		
		RD_ADDR: begin
			if(m_axi_arvalid & m_axi_arready) begin
				rn.axi_arvalid 	= 1'b0;
				rn.axi_araddr	= r.axi_araddr + (r.axi_arlen << REM_D_WIDTH);
				rn.state		= RD_DATA;
			end
		end
		
		RD_DATA: begin
			if(m_axi_rvalid & m_axi_rready) begin
				if(m_axi_rlast == 1'b1) begin
					rn.tt_burst_len	= r.tt_burst_len - r.axi_arlen;
					
					rn.axi_arlen 	= rn.tt_burst_len[BURST_WIDTH - 2 : 0];
					if(rn.tt_burst_len[31:BURST_WIDTH - 1] != 0) begin
						rn.axi_arlen = MAX_BURST_LEN;
					end
					
					if(rn.tt_burst_len == 32'd0) begin
						rn.axi_arlen 	= {BURST_WIDTH{1'b0}};
						rn.state		= IDLE;
						rn.ctrl_rd_rdy	= 1'b1;
						if(i_clr_vld == 1'b1) begin
							rn.ctrl_rd_rdy	= 1'b0;
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
		if(USE_FIFO == "TRUE")
			assign buf_vld 	= (axis_data_cnt <= 512 - r.axi_arlen && r.axi_arlen != 0) ? 1'b1 : 1'b0;
		else begin
			assign buf_vld 	= 1'b1;
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
			r.axi_araddr	<= {AXI_ADDR_WIDTH{1'b0}};
			r.axi_arlen		<= {BURST_WIDTH{1'b0}};
			r.axi_arvalid	<= 1'b0;
			r.ctrl_rd_rdy	<= 1'b0;
			r.clr_rdy		<= 1'b0;
		end
	end

	//----------------------------------------------------------------------------------------------
	// output assignment
	//----------------------------------------------------------------------------------------------	
	assign o_clr_rdy 		= r.clr_rdy;
	assign o_ctrl_rd_rdy	= r.ctrl_rd_rdy;
	
	assign o_err 			= {1'b0, r.bresp_err, r.len_err};
	
	assign m_axi_araddr		= r.axi_araddr;
	assign m_axi_arlen		= r.axi_arlen - 1'b1;
	assign m_axi_arvalid	= r.axi_arvalid;
	
	assign m_axi_arburst 	= 2'd1;
	assign m_axi_arcache	= 4'd3;
	assign m_axi_arlock		= 1'b0;
	assign m_axi_arprot		= 3'd0;
	assign m_axi_arqos 		= 4'd0;
	assign m_axi_arsize		= $clog2(AXI_DATA_WIDTH/8);
	assign m_axi_arregion	= 4'd0;

	//----------------------------------------------------------------------------------------------
	// fifo 
	//----------------------------------------------------------------------------------------------
	
	generate
		
		if(USE_FIFO == "TRUE") begin
			assign m_axi_rlast_i 	= (m_axi_rlast & m_axi_rvalid) && (r.tt_burst_len <= MAX_BURST_LEN);
			assign m_axi_rready		= m_axi_rready_i & !wr_rst_busy;
			assign m_axis_tvld 		= m_axis_tvld_i & !rd_rst_busy;
			
			axi_fifo_256x512 
			u_axi_fifo_256x512 (
				.wr_rst_busy		(	wr_rst_busy							),      // output wire wr_rst_busy
				.rd_rst_busy		(	rd_rst_busy							),      // output wire rd_rst_busy
				.s_aclk				(	i_clk								),     	// input wire s_aclk
				.s_aresetn			(	(!i_rst)&(!(r.clr_rdy & i_clr_vld))	),      // input wire s_aresetn
				.s_axis_tvalid		(	m_axi_rvalid						),  	// input wire s_axis_tvalid
				.s_axis_tready		(	m_axi_rready_i						),  	// output wire s_axis_tready
				.s_axis_tdata		(	m_axi_rdata							),    	// input wire [63 : 0] s_axis_tdata
				.s_axis_tlast		(	m_axi_rlast_i						),    	// input wire s_axis_tlast
				
				.m_axis_tvalid		(	m_axis_tvld_i						),  	// output wire m_axis_tvalid
				.m_axis_tready		(	m_axis_trdy							),  	// input wire m_axis_tready
				.m_axis_tdata		(	m_axis_tdata						),    	// output wire [63 : 0] m_axis_tdata
				.m_axis_tlast		(	m_axis_tlast						),    	// output wire m_axis_tlast
				.axis_data_count	( 	axis_data_cnt						)
			);
			
		end else begin // 不用fifo进行缓存。
			assign m_axi_rready	= m_axis_trdy;
			assign m_axis_tvld 	= m_axi_rvalid;
			assign m_axis_tdata = m_axi_rdata;
			assign m_axis_tlast = (m_axi_rlast & m_axi_rvalid) && (r.tt_burst_len <= MAX_BURST_LEN);
		end
		
	endgenerate


	(* mark_debug = "true" *)logic[AXI_ADDR_WIDTH - 1:0]				mark_rdddr_araddr;
	(* mark_debug = "true" *)logic[BitWidth(MAX_BURST_LEN - 1) - 1:0]	mark_rdddr_arlen;
	(* mark_debug = "true" *)logic										mark_rdddr_arready;
	(* mark_debug = "true" *)logic										mark_rdddr_arvalid;			
	(* mark_debug = "true" *)logic[AXI_DATA_WIDTH - 1:0]				mark_rdddr_rdata;
	(* mark_debug = "true" *)logic										mark_rdddr_rlast;
	(* mark_debug = "true" *)logic										mark_rdddr_rready;
	(* mark_debug = "true" *)logic[1:0]									mark_rdddr_rresp;
	(* mark_debug = "true" *)logic										mark_rdddr_rvalid;

	assign mark_rdddr_araddr	= m_axi_araddr;
	assign mark_rdddr_arlen		= m_axi_arlen;
	assign mark_rdddr_arready	= m_axi_arready;
	assign mark_rdddr_arvalid	= m_axi_arvalid;			
	assign mark_rdddr_rdata		= m_axi_rdata;
	assign mark_rdddr_rlast		= m_axi_rlast;
	assign mark_rdddr_rready	= m_axi_rready;
	assign mark_rdddr_rresp		= m_axi_rresp;
	assign mark_rdddr_rvalid	= m_axi_rvalid;


endmodule

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

