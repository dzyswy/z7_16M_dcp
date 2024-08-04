
`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

/// An AXI4-Lite interface.
interface axi_lite_if #(
	parameter DW = -1,
	parameter AW = -1
)(
	input clk,
	input rstn
);
	localparam SW = DW / 8;
	typedef logic [AW-1:0] 	addr_t;
	typedef logic [DW-1:0] 	data_t;
	typedef logic [SW-1:0] 	strb_t;
	typedef logic [1:0] 	resp_t;
	
	// AW channel
	addr_t         	awaddr;
	logic           awvalid;
	logic           awready;
	// W channel
	data_t          wdata;
	strb_t          wstrb;
	logic           wvalid;
	logic           wready;
	// B channel
	resp_t 			bresp;
	logic           bvalid;
	logic           bready;
	// AR channel
	addr_t         	araddr;
	logic           arvalid;
	logic           arready;
	// R channel
	data_t          rdata;
	resp_t 			rresp;
	logic           rvalid;
	logic           rready;

  modport m (
	input clk, rstn,
    output awaddr, awvalid, input awready,
    output wdata, wstrb, wvalid, input wready,
    input bresp, bvalid, output bready,
    output araddr, arvalid, input arready,
    input rdata, rresp, rvalid, output rready
  );

  modport s (
	input clk, rstn,
    input awaddr, awvalid, output awready,
    input wdata, wstrb, wvalid, output wready,
    output bresp, bvalid, input bready,
    input araddr, arvalid, output arready,
    output rdata, rresp, rvalid, input rready
  );

endinterface

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

