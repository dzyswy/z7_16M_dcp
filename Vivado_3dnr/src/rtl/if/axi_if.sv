
`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

interface axi_if
#(
	parameter DW 	= 32,
	parameter AW 	= 32,
	parameter IW	= 1,
	parameter UID	= 1
)
(	
	input clk,
	input rstn
);
	localparam SW = DW / 8;
	typedef logic [IW - 1 : 0]	id_t;
	typedef logic [AW - 1 : 0] 	addr_t;
	typedef logic [DW - 1 : 0] 	data_t;
	typedef logic [SW - 1 : 0] 	strb_t;
	typedef logic [UID - 1 : 0] user_t;

	typedef logic [1 : 0] 		burst_t; 	// 2'b01	AXI Transaction Burst Type.

	typedef logic [1 : 0] 		resp_t;		//			AXI Transaction Response Type.

	typedef logic [3 : 0] 		cache_t;	// 4'b0010	AXI Transaction Cacheability Type.

	typedef logic [2 : 0] 		prot_t;		// 3'd0		AXI Transaction Protection Type.

	typedef logic [3 : 0] 		qos_t;		// 4'd0		AXI Transaction Quality of Service Type.

	typedef logic [3 : 0] 		region_t;	// 4'd0		AXI Transaction Region Type.

	typedef logic [7 : 0] 		len_t;		//			AXI Transaction Length Type.

	typedef logic [2 : 0] 		size_t;		//$clog2(DW/8 - 1)	AXI Transaction Size Type.
	
	id_t              		awid;
	addr_t            		awaddr;
	len_t    				awlen;
	size_t   				awsize;
	burst_t  				awburst;
	logic             		awlock;
	cache_t  				awcache;
	prot_t   				awprot;
	qos_t    				awqos;
	region_t 				awregion;
	user_t            		awuser;
	logic             		awvalid;
	logic             		awready;
			
	data_t            		wdata;
	strb_t            		wstrb;
	logic             		wlast;
	user_t            		wuser;
	logic             		wvalid;
	logic             		wready;
			
	id_t              		bid;
	resp_t   				bresp;
	user_t            		buser;
	logic             		bvalid;
	logic             		bready;
			
	id_t              		arid;
	addr_t            		araddr;
	len_t    				arlen;
	size_t   				arsize;
	burst_t  				arburst;
	logic             		arlock;
	cache_t  				arcache;
	prot_t   				arprot;
	qos_t    				arqos;
	region_t 				arregion;
	user_t            		aruser;
	logic             		arvalid;
	logic             		arready;
			
	id_t              		rid;
	data_t            		rdata;
	resp_t   				rresp;
	logic             		rlast;
	user_t            		ruser;
	logic             		rvalid;
	logic             		rready;

	modport m (
		input clk, rstn,
		output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awuser, awvalid, input awready,
		output wdata, wstrb, wlast, wuser, wvalid, input wready,
		input bid, bresp, buser, bvalid, output bready,
		output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aruser, arvalid, input arready,
		input rid, rdata, rresp, rlast, ruser, rvalid, output rready
	);

	modport s (
		input clk, rstn,
		input awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awuser, awvalid, output awready,
		input wdata, wstrb, wlast, wuser, wvalid, output wready,
		output bid, bresp, buser, bvalid, input bready,
		input arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aruser, arvalid, output arready,
		output rid, rdata, rresp, rlast, ruser, rvalid, input rready
	);

endinterface

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

