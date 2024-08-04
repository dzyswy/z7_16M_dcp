// (c) Copyright 2011 - 2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
//------------------------------------------------------------------------------
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: $Revision: #2 $
//  \   \         
//  /   /         Filename: $File: //Groups/video_ip/demos/K7/xapp592_k7_sdi_demos/verilog/SDI_wrapper/x7gtx_sdi_control.v $
// /___/   /\     Timestamp: $DateTime: 2012/08/16 15:23:21 $
// \   \  /  \
//  \___\/\___\
//
// Description:
//  This module handles general control of SDI mode changes for the Xilinx 7-series
//  GTX transceiver. It also contains the RX input bit rate detection module.
//------------------------------------------------------------------------------
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.

`timescale 1 ns / 1 ns

module x7gtx_sdi_control #( 
    parameter FXDCLK_FREQ           = 27000000,     // Frequency, in hertz, of fixed frequency clock
    parameter TXPMARESETDLY_MSB     = 15,           // Width of TXPMARESET delay counter
    parameter PLLLOCKDLY            = 4)            // Width of the PLL lock delay counter
(
    input   wire        clk,                        // Fixed clock

// TX related signals
    input   wire        txusrclk,                   // Connect to same clock as drives GTX TXUSRCLK2
    input   wire [1:0]  txmode,                     // TX mode select: 00=HD, 01=SD, 10=3G (synchronous to txusrclk)
    input   wire        txpllreset,                 // Connect to signal driving {Q|C}PLLRESET
    input   wire        txplllock,                  // Connect to {Q|C}PLLLOCK output of GTX
    input   wire        txpllrange,                 // 0 for CPLL or QPLL range 1, 1 for QPLL range 2
    input   wire        tx_m,                       // TX bit rate select (0=1000/1000, 1=1000/1001)
    input   wire [1:0]  txsysclksel_m_0,            // value to output on TXSYSCLKSEL when tx_m is 0
    input   wire [1:0]  txsysclksel_m_1,            // value to output on TXSYSCLKSEL when tx_m is 1
    output  wire        gttxreset,                  // Connect to GTTXRESET input of GTX
    output  wire        txpmareset,                 // Connect to TXPMARESET input of GTX
    output  reg [2:0]   txrate = 3'b011,            // Connect to TXRATE input of GTX
    output  reg [1:0]   txsysclksel = 2'b00,        // Connect to TXSYSCLKSEL port of GTX when doing dynamic clock source switching
    output  reg         txslew = 1'b0,              // Slew rate control signal for SDI cable driver

// RX related signals
    input   wire        rxusrclk,                   // Connect to same clock as drives GTX RXUSRCLK2
    input   wire [1:0]  rxmode,                     // RX mode select: 00=HD, 01=SD, 10=3G (sync with rxusrclk)
    input   wire        rxpllreset,                 // Connect to signal driving {Q|C}PLLRESET
    input   wire        rxplllock,                  // Connect to {Q|C}PLLLOCK output of GTX
    input   wire        rxpllrange,                 // 0 for CPLL or QPLL range 1, 1 for QPLL range 2
    input   wire        rxresetdone,                // Connect to the RXRESETDONE port of the GTX
    output  wire        gtrxreset,                  // Connect to GTRXRESET input of GTX
    output  reg  [2:0]  rxrate = 3'b011,            // Connect to RXRATE port of GTX
    output  wire        rxcdrhold,                  // Connect to RXCDRHOLD port of GTX
    output  wire        rx_m,                       // Indicates received bit rate: 1=/1.001 rate, 0 = /1 rate

// SD-SDI DRU signals
    input   wire         dru_rst,                   // Sync reset input for DRU
    input   wire [19:0]  data_in,                   // 11X oversampled data input vector
    output  reg  [9:0]   sd_data = 0,               // Recovered SD-SDI data
    output  wire         sd_data_strobe,            // Asserted high when an output data word is ready
    output  wire [19:0]  recclk_txdata,             // Optional output data for recovering a clock using transitter

// DRP signals -- The DRP is used to change the RXCDR_CFG attribute depending
// on the RX SDI mode. Connect these signal to the DRP of the GTX associated
// with the SDI RX. If the SDI RX function is not used (TX-only) then these
// signals don't need to be connected to the GTX.
    input   wire        drpclk,                     // Connect to GTX DRP clock
    input   wire        drprdy,                     // Connect to GTX DRPRDY port
    output  wire [8:0]  drpaddr,                    // Connect to GTX DRPADDR port
    output  wire [15:0] drpdi,                      // Connect to GTX DRPDI port
    output  wire        drpen,                      // Connect to GTX DRPEN port
    output  wire        drpwe                       // Connect to GTX DRPWE port
);

//
// These parameters define the encoding of the txmode and rxmode ports.
//
localparam MODE_HD = 2'b00;
localparam MODE_SD = 2'b01;
localparam MODE_3G = 2'b10;

//
// These parameters define the encoding of the txrate and rxrate ports.
//
localparam RATE_DIV_2 = 3'b010;
localparam RATE_DIV_4 = 3'b011;
localparam RATE_DIV_8 = 3'b100;

reg  [1:0]                  txmode_reg = 2'b00;
reg  [1:0]                  rxmode_reg = 2'b00;
wire [3:0]                  samv;
wire [9:0]                  sam;
wire [9:0]                  dru_dout;
wire                        dru_drdy;

reg  [TXPMARESETDLY_MSB:0]  txpmareset_dly = 0;
reg                         txpmareset_dly_stop = 1'b0;
reg  [2:0]                  txplllock_sync = 0;
wire                        txpmareset_dly_tc;
reg                         txpmareset1 = 1'b0;
reg                         txpmareset2 = 1'b0;
reg  [3:0]                  tx_m_sync = 4'b0000;
wire                        tx_m_change;
reg  [5:0]                  sequencer = 6'b000100;          // assert ld_clksel after FPGA configuration
wire                        assert_txpmareset;
wire                        negate_txpmareset;
wire                        ld_clksel;
wire                        pll_gtrxreset;
wire                        drp_gtrxreset;

//------------------------------------------------------------------------------
// RXRATE and TXRATE logic
//
// This section of logic generates the RXRATE and TXRATE signal to the GTX to
// set the PLL dividers properly based on the current SDI mode (SD, HD, or 3G).
//

//
// Input registers for rxmode & txmode.
//
always @ (posedge txusrclk)
begin
    txmode_reg <= txmode;
end
                                                                                                                                               
always @ (posedge rxusrclk)
begin
    rxmode_reg <= rxmode;
end

//
// Set the RXRATE and TXRATE output ports based on the SDI mode.
//
function [2:0] pll_rate;
    input           range;
    input [1:0]     mode;

    if (range == 1'b0)
        if (mode == MODE_HD)
            pll_rate = RATE_DIV_4;
        else
            pll_rate = RATE_DIV_2;
    else
        if (mode == MODE_HD)
            pll_rate = RATE_DIV_8;
        else
            pll_rate = RATE_DIV_4;
endfunction

always @ (posedge txusrclk)
    txrate <= pll_rate(txpllrange, txmode_reg);

always @ (posedge rxusrclk)
    rxrate <= pll_rate(rxpllrange, rxmode_reg);


//------------------------------------------------------------------------------
// Generate the txslew signal to control the slew rate of the external SDI cable
// driver.
//
always @ (posedge txusrclk)
    txslew <= txmode_reg == MODE_SD;

//------------------------------------------------------------------------------
// RX reset state machine
//
x7gtx_reset_control #(
    .PLLLOCKDLY     (PLLLOCKDLY))
RX_RESET (
    .clk            (clk),
    .pll_reset      (rxpllreset),
    .pll_lock       (rxplllock),
    .gtxreset       (pll_gtrxreset));

//------------------------------------------------------------------------------
// TX reset state machine
//
x7gtx_reset_control #(
    .PLLLOCKDLY     (PLLLOCKDLY))
TX_RESET (
    .clk            (clk),
    .pll_reset      (txpllreset),
    .pll_lock       (txplllock),
    .gtxreset       (gttxreset));

//------------------------------------------------------------------------------
// RX bit rate detection
//
sdi_rate_detect #(
    .REFCLK_FREQ     (FXDCLK_FREQ))
RATE0 (
    .refclk     (clk),
    .recvclk    (rxusrclk),
    .std        (rxmode[1]),
    .rate_change(),
    .enable     (rxresetdone),
    .drift      (),
    .rate       (rx_m));

//------------------------------------------------------------------------------
// 11X oversampling data recovery unit for SD-SDI
//
dru NIDRU (
    .DT_IN      (data_in),
    .CENTER_F   (37'b0000111010001101011111110100101111011),
    .G1         (5'b00110),
    .G1_P       (5'b10000),
    .G2         (5'b00111),
    .CLK        (rxusrclk),
    .RST        (~dru_rst),         // The NI-DRU reset is asserted low
    .RST_FREQ   (1'b1),
    .VER        (),
    .EN         (1'b1),
    .INTEG      (),
    .DIRECT     (),
    .CTRL       (),
    .PH_OUT     (),
    .RECCLK     (recclk_txdata),
    .SAMV       (samv),
    .SAM        (sam));

dru_bshift10to10 DRUBSHIFT (
    .CLK        (rxusrclk),
    .RST        (~dru_rst),
    .DIN        ({8'b0, sam[1:0]}),
    .DV         ({2'b0, samv[1:0]}),
    .DV10       (dru_drdy),
    .DOUT10     (dru_dout));

always @ (posedge rxusrclk)
    if (dru_drdy)
        sd_data <= dru_dout;

assign sd_data_strobe = dru_drdy;

//------------------------------------------------------------------------------
// This code asserts TXPMARESET for one clock cycle a long delay after CPLLLOCK
// is asserted. The delay is 2^(TXPMARESETDELY_MSB+1) * (period of clk).
//
assign txpmareset_dly_tc = txpmareset_dly == {TXPMARESETDLY_MSB+1 {1'b1}};

always @ (posedge clk)
    txplllock_sync <= {txplllock_sync[1:0], txplllock};

always @ (posedge clk)
    if (~txplllock_sync[2])
        txpmareset_dly <= 0;
    else if (~txpmareset_dly_stop)
        txpmareset_dly <= txpmareset_dly + 1;

always @ (posedge clk)
    if (~txplllock_sync[2])
        txpmareset_dly_stop <= 1'b0;
    else if (txpmareset_dly_tc)
        txpmareset_dly_stop <= 1'b1;

always @ (posedge clk)
    txpmareset1 <= txpmareset_dly_tc;

//------------------------------------------------------------------------------
// This logic handles dynamic changes to TXSYSCLKSEL to switch the GTX TX clock
// source between the QPLL and the CPLL. TXPMARESET must be asserted during the
// time that TXSYSCLKSEL changes.
//

//
// Synchronize the tx_m input to clk and detect when it changes. A change on
// tx_m signals that the TX clock has been switched between the QPLL and the CPLL.
//
always @ (posedge clk)
    tx_m_sync <= {tx_m_sync[2:0], tx_m};

assign tx_m_change = ^tx_m_sync[3:2];

//
// When a tx_m_change occurs, assert TXPMARESET, then change TXSYSCLKSEL, then
// negate TXPMARESET.
//
always @ (posedge clk)
    sequencer <= {sequencer[4:0], tx_m_change};

assign assert_txpmareset = sequencer[0];
assign negate_txpmareset = sequencer[5];
assign ld_clksel = sequencer[2];

always @ (posedge clk)
    if (assert_txpmareset)
        txpmareset2 <= 1'b1;
    else if (negate_txpmareset)
        txpmareset2 <= 1'b0;

//
// The TXSYSCLKSEL register
//
always @ (posedge clk)
    if (ld_clksel)
        txsysclksel <= tx_m_sync[2] ? txsysclksel_m_1 : txsysclksel_m_0;


assign txpmareset = txpmareset1 | txpmareset2;

//------------------------------------------------------------------------------
// DRP controller
//
// The DRP controller changes the RXCDR_CFG attribute dynamically depending on the
// SDI mode of the RX.
//

x7gtx_sdi_drp_control SDIDRPCTRL
(
    .clk                (drpclk),
    .rst                (1'b0),
    .rx_mode            (rxmode),
    .drprdy             (drprdy),
    .drpaddr            (drpaddr),
    .drpdi              (drpdi),
    .drpen              (drpen),
    .drpwe              (drpwe),
    .rxcdrhold          (rxcdrhold),
    .gtrxreset          (drp_gtrxreset));

assign gtrxreset = drp_gtrxreset | pll_gtrxreset;

endmodule