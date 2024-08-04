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
// \   \   \/     Version: $Revision: #3 $
//  \   \         
//  /   /         Filename: $File: //Groups/video_ip/demos/K7/xapp592_k7_sdi_demos/verilog/kc705_sdi_demo/kc705_sdi_demo.v $
// /___/   /\     Timestamp: $DateTime: 2012/08/16 14:27:56 $
// \   \  /  \
//  \___\/\___\
//
// Description:
//      This is the top level module for the Quad SDI demo for Kintex-7 GTX 
//      transceivers. It runs on the KC705 board + TED SDI FMC board.
//------------------------------------------------------------------------------
//
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

`timescale 1ns / 1ps

module sdi_gt_top (
    // //--------MGT REFCLKs-------
    input   wire            mgtclk_148_5,    // 148.5 MHz clock from FMC board
    input   wire            mgtclk_148_35,    // 148.5 MHz clock from FMC board
    input   wire            clk_74_25,

    output  wire            o_tx_clk,
    output  wire            o_tx_reset,

    input   wire            i_tx_m,             // 0 = select 148.5 MHz refclk, 1 = select 148.35 MHz refclk
    input   wire [1:0]      i_tx_mode,          // 00 = HD, 01 = SD, 10 = 3G
    input   wire            i_framerate_sel,    // 0 -- 50Hz, 1 -- 60Hz        

    input   [10:0]          i_tx_line,
    input   [9:0]           i_tx_c,
    input   [9:0]           i_tx_y,    




    //--------sdi rx in-----------
    input   wire            sdi_rx_n,
    input   wire            sdi_rx_p,

    //--------sdi tx out ---------------
    output  wire            sdi_tx_n,
    output  wire            sdi_tx_p
);
                

//------------------------------------------------------------------------------
// Internal signals definitions

// Global signals
// TX1 signals
wire        tx1_outclk;
wire        tx1_usrclk;
wire        tx1_gttxreset;
wire [19:0] tx1_txdata;
wire        tx1_ratedone;
wire        tx1_resetdone;
wire        tx1_pmareset;
wire [1:0]  tx1_sysclksel;
wire [2:0]  tx1_rate;
wire        tx1_cplllock;
wire [1:0]  tx1_bufstatus;
wire        tx1_slew;
wire        tx1_userrdy;

// TX2 signals
wire        tx2_outclk;
wire        tx2_usrclk;
wire        tx2_gttxreset;
wire [19:0] tx2_txdata;
wire        tx2_ratedone;
wire        tx2_resetdone;
wire        tx2_pmareset;
wire [1:0]  tx2_sysclksel;
wire [2:0]  tx2_rate;
wire        tx2_cplllock;
wire [1:0]  tx2_bufstatus;
wire        tx2_slew;
wire        tx2_userrdy;

// TX3 signals
wire        tx3_outclk;
wire        tx3_usrclk;
wire        tx3_gttxreset;
wire [19:0] tx3_txdata;
wire        tx3_ratedone;
wire        tx3_resetdone;
wire        tx3_pmareset;
wire [1:0]  tx3_sysclksel;
wire [2:0]  tx3_rate;
wire        tx3_cplllock;
wire [1:0]  tx3_bufstatus;
wire        tx3_slew;
wire        tx3_txen;
wire        tx3_userrdy;

// TX4 signals
wire        tx4_outclk;
wire        tx4_usrclk;
wire        tx4_gttxreset;
wire [19:0] tx4_txdata;
wire        tx4_ratedone;
wire        tx4_resetdone;
wire        tx4_pmareset;
wire [1:0]  tx4_sysclksel;
wire [2:0]  tx4_rate;
wire        tx4_cplllock;
wire [1:0]  tx4_bufstatus;
wire        tx4_slew;
wire        tx4_txen;
wire        tx4_userrdy;

// RX1 signals
wire        rx1_gtrxreset;
wire        rx1_outclk;
wire        rx1_resetdone;
wire [2:0]  rx1_rate;
wire        rx1_ratedone;
wire        rx1_cdrhold;
wire        rx1_usrclk;
wire [19:0] rx1_rxdata;
wire        rx1_locked;
wire        rx1_userrdy;
wire [1:0]  rx1_mode;
wire        rx1_level_b;
wire [3:0]  rx1_t_family;
wire [3:0]  rx1_t_rate;
wire        rx1_t_scan;
wire        rx1_m;
wire        rx1_drprdy;
wire [8:0]  rx1_drpaddr;
wire [15:0] rx1_drpdi;
wire        rx1_drpen;
wire        rx1_drpwe;

// RX2 signals
wire        rx2_gtrxreset;
wire        rx2_outclk;
wire        rx2_resetdone;
wire [2:0]  rx2_rate;
wire        rx2_ratedone;
wire        rx2_cdrhold;
wire        rx2_usrclk;
wire [19:0] rx2_rxdata;
wire        rx2_locked;
wire        rx2_userrdy;
wire [1:0]  rx2_mode;
wire        rx2_level_b;
wire [3:0]  rx2_t_family;
wire [3:0]  rx2_t_rate;
wire        rx2_t_scan;
wire        rx2_m;
wire        rx2_drprdy;
wire [8:0]  rx2_drpaddr;
wire [15:0] rx2_drpdi;
wire        rx2_drpen;
wire        rx2_drpwe;

// RX3 signals
wire        rx3_gtrxreset;
wire        rx3_outclk;
wire        rx3_resetdone;
wire [2:0]  rx3_rate;
wire        rx3_ratedone;
wire        rx3_cdrhold;
wire        rx3_usrclk;
wire [19:0] rx3_rxdata;
wire        rx3_locked;
wire        rx3_userrdy;
wire [1:0]  rx3_mode;
wire        rx3_level_b;
wire [3:0]  rx3_t_family;
wire [3:0]  rx3_t_rate;
wire        rx3_t_scan;
wire        rx3_m;
wire        rx3_drprdy;
wire [8:0]  rx3_drpaddr;
wire [15:0] rx3_drpdi;
wire        rx3_drpen;
wire        rx3_drpwe;

// RX4 signals
wire        rx4_gtrxreset;
wire        rx4_outclk;
wire        rx4_resetdone;
wire [2:0]  rx4_rate;
wire        rx4_ratedone;
wire        rx4_cdrhold;
wire        rx4_usrclk;
wire [19:0] rx4_rxdata;
wire        rx4_locked;
wire        rx4_userrdy;
wire [1:0]  rx4_mode;
wire        rx4_level_b;
wire [3:0]  rx4_t_family;
wire [3:0]  rx4_t_rate;
wire        rx4_t_scan;
wire        rx4_m;
wire        rx4_drprdy;
wire [8:0]  rx4_drpaddr;
wire [15:0] rx4_drpdi;
wire        rx4_drpen;
wire        rx4_drpwe;

// wire   [10:0]      tx_line;
// wire   [9:0]       tx_c;
// wire   [9:0]       tx_y;


// // This is the 148.5 MHz MGT reference clock input from FMC SDI mezzanine board.
// // The ODIV2 output is used to provide a global 74.25 MHz clock to the FPGA
// // used as the GTX DRP clock and fixed frequency clock for the SDI wrapper.
// // It is also sent out to the Si5324 on the KC705 to be converted to a 148.35 MHz
// // reference clock for the GTX transceivers.
// //
// IBUFDS_GTE2 MGTCLKIN0 (
//     .I          (ref_gbtclk0_in_p),
//     .IB         (ref_gbtclk0_in_n),
//     .CEB        (1'b0),
//     .O          (mgtclk_148_5),
//     .ODIV2      (clk_74_25_in));

// BUFG BUFG74_25 (
//     .I          (clk_74_25_in),
//     .O          (clk_74_25));

// //
// // 148.35 MHz MGT reference clock input from Si5324. It is generated by the 
// // from the 74.25 MHz clock (clk_74_25).
// //
// IBUFDS_GTE2 TXMGTCLKIN (
//     .I          (ref_gbtclk1_in_p),
//     .IB         (ref_gbtclk1_in_n),
//     .CEB        (1'b0),
//     .O          (mgtclk_148_35),
//     .ODIV2      ());

//
// This output sends the 74.25 MHz clock to the Si5324.
//
//OBUFDS # (
//    .IOSTANDARD ("LVDS_25"))
//SI5324_CLKIN (
//    .I          (clk_74_25),
//    .O          (REC_CLOCK_C_P),
//    .OB         (REC_CLOCK_C_N));

//
// RX & TX global clock buffers for SDI channels
//
BUFG BUFGTX1 (
    .I          (tx1_outclk),
    .O          (tx1_usrclk));

BUFG BUFGRX1 (
    .I          (rx1_outclk),
    .O          (rx1_usrclk));

BUFG BUFGTX2 (
    .I          (tx2_outclk),
    .O          (tx2_usrclk));

BUFG BUFGRX2 (
    .I          (rx2_outclk),
    .O          (rx2_usrclk));

BUFG BUFGTX3 (
    .I          (tx3_outclk),
    .O          (tx3_usrclk));

BUFG BUFGRX3 (
    .I          (rx3_outclk),
    .O          (rx3_usrclk));

BUFG BUFGTX4 (
    .I          (tx4_outclk),
    .O          (tx4_usrclk));

BUFG BUFGRX4 (
    .I          (rx4_outclk),
    .O          (rx4_usrclk));




    wire tx1_fabric_reset;
    assign tx1_fabric_reset = tx1_ratedone | ~tx1_resetdone;

    assign o_tx_clk = tx1_usrclk;
    assign o_tx_reset = tx1_fabric_reset;

//     reg  [15:0]  enable;
//     always @( posedge tx1_usrclk) begin
//         if(tx1_fabric_reset)begin
//             enable <= 'd0;
//         end
//         else begin
//             enable <= {enable[14:0],1'b1};
//         end
//     end    

// // reg     [2:0]   video_mode;
// wire    [4:0]   video_mode_sel;

// vio_1 your_instance_name (
//   .clk          (tx1_usrclk),                // input wire clk
//   .probe_out0   (video_mode_sel)  // output wire [2 : 0] probe_out0
// );

//     sdi_pattern_gen  u0_patgen (
//     .i_clk              (   tx1_usrclk          ),	
//     .i_rst              (   tx1_fabric_reset    ),	

//     .i_video_mode       (   video_mode_sel[2:0]   ),
//     // .i_video_mode       (   3'd4   ),

//     .i_sdi_enable       (   enable[15]  ),

//     .i_sdi_tx_data      (   {10'h15a,10'h3a5}),
//     .o_sdi_data_req     (   ),

//     .o_sdi_dout         (   {tx_y,tx_c}),
//     .o_sdi_ln           (   tx_line),
//     .o_sdi_wn           (   )
// );



//------------------------------------------------------------------------------
// SDI RX/TX modules
k7_sdi_rxtx SDI1 (
   .clk                 (clk_74_25),

    .i_tx_m             (i_tx_m),           // 0 = select 148.5 MHz refclk, 1 = select 148.35 MHz refclk
    .i_tx_mode          (i_tx_mode),        // 00 = HD, 01 = SD, 10 = 3G
    .i_framerate_sel    (i_framerate_sel),  // 0 -- 50Hz, 1 -- 60Hz 

    .tx_line            (i_tx_line),
    .tx_c               (i_tx_c),
    .tx_y               (i_tx_y),

   .tx_usrclk      (tx1_usrclk),
   .tx_gttxreset   (tx1_gttxreset),
   .tx_txdata      (tx1_txdata),
   .tx_ratedone    (tx1_ratedone),
   .tx_resetdone   (tx1_resetdone),
   .tx_pmareset    (tx1_pmareset),
   .tx_sysclksel   (tx1_sysclksel),
   .tx_rate        (tx1_rate),
   .tx_plllock     (tx1_cplllock & x1_qplllock),
   .tx_slew        (tx1_slew),
   .tx_userrdy     (tx1_userrdy),
   .tx_pllreset    (gtxpllreset),
   .tx_txen        (),
   .rx_usrclk      (rx1_usrclk),
   .rx_gtrxreset   (rx1_gtrxreset),
   .rx_resetdone   (rx1_resetdone),
   .rx_rate        (rx1_rate),
   .rx_ratedone    (rx1_ratedone),
   .rx_cdrhold     (rx1_cdrhold),
   .rx_rxdata      (rx1_rxdata),
   .rx_locked      (rx1_locked),
   .rx_userrdy     (rx1_userrdy),
   .rx_pllreset    (gtxpllreset),
   .rx_plllock     (x1_qplllock),
   .rx_mode        (rx1_mode),
   .rx_level_b     (rx1_level_b),
   .rx_t_family    (rx1_t_family),
   .rx_t_rate      (rx1_t_rate),
   .rx_t_scan      (rx1_t_scan),
   .rx_m           (rx1_m),
   .drpclk         (clk_74_25),
   .drprdy         (rx1_drprdy),
   .drpaddr        (rx1_drpaddr),
   .drpdi          (rx1_drpdi),
   .drpen          (rx1_drpen),
   .drpwe          (rx1_drpwe),
   .control0       (control1),
   .control1       (control2),
   .control2       (control3));

// k7_sdi_rxtx SDI2 (
//     .clk            (clk_74_25),
//     .tx_usrclk      (tx2_usrclk),
//     .tx_gttxreset   (tx2_gttxreset),
//     .tx_txdata      (tx2_txdata),
//     .tx_ratedone    (tx2_ratedone),
//     .tx_resetdone   (tx2_resetdone),
//     .tx_pmareset    (tx2_pmareset),
//     .tx_sysclksel   (tx2_sysclksel),
//     .tx_rate        (tx2_rate),
//     .tx_plllock     (tx2_cplllock & x1_qplllock),
//     .tx_slew        (tx2_slew),
//     .tx_userrdy     (tx2_userrdy),
//     .tx_pllreset    (gtxpllreset),
//     .tx_txen        (),
//     .rx_usrclk      (rx2_usrclk),
//     .rx_gtrxreset   (rx2_gtrxreset),
//     .rx_resetdone   (rx2_resetdone),
//     .rx_rate        (rx2_rate),
//     .rx_ratedone    (rx2_ratedone),
//     .rx_cdrhold     (rx2_cdrhold),
//     .rx_rxdata      (rx2_rxdata),
//     .rx_locked      (rx2_locked),
//     .rx_userrdy     (rx2_userrdy),
//     .rx_pllreset    (gtxpllreset),
//     .rx_plllock     (x1_qplllock),
//     .rx_mode        (rx2_mode),
//     .rx_level_b     (rx2_level_b),
//     .rx_t_family    (rx2_t_family),
//     .rx_t_rate      (rx2_t_rate),
//     .rx_t_scan      (rx2_t_scan),
//     .rx_m           (rx2_m),
//     .drpclk         (clk_74_25),
//     .drprdy         (rx2_drprdy),
//     .drpaddr        (rx2_drpaddr),
//     .drpdi          (rx2_drpdi),
//     .drpen          (rx2_drpen),
//     .drpwe          (rx2_drpwe),
//     .control0       (control4),
//     .control1       (control5),
//     .control2       (control6));

// k7_sdi_rxtx SDI3 (
//     .clk            (clk_74_25),
//     .tx_usrclk      (tx3_usrclk),
//     .tx_gttxreset   (tx3_gttxreset),
//     .tx_txdata      (tx3_txdata),
//     .tx_ratedone    (tx3_ratedone),
//     .tx_resetdone   (tx3_resetdone),
//     .tx_pmareset    (tx3_pmareset),
//     .tx_sysclksel   (tx3_sysclksel),
//     .tx_rate        (tx3_rate),
//     .tx_plllock     (tx3_cplllock & x1_qplllock),
//     .tx_slew        (tx3_slew),
//     .tx_userrdy     (tx3_userrdy),
//     .tx_pllreset    (gtxpllreset),
//     .tx_txen        (tx3_txen),
//     .rx_usrclk      (rx3_usrclk),
//     .rx_gtrxreset   (rx3_gtrxreset),
//     .rx_resetdone   (rx3_resetdone),
//     .rx_rate        (rx3_rate),
//     .rx_ratedone    (rx3_ratedone),
//     .rx_cdrhold     (rx3_cdrhold),
//     .rx_rxdata      (rx3_rxdata),
//     .rx_locked      (rx3_locked),
//     .rx_userrdy     (rx3_userrdy),
//     .rx_pllreset    (gtxpllreset),
//     .rx_plllock     (x1_qplllock),
//     .rx_mode        (rx3_mode),
//     .rx_level_b     (rx3_level_b),
//     .rx_t_family    (rx3_t_family),
//     .rx_t_rate      (rx3_t_rate),
//     .rx_t_scan      (rx3_t_scan),
//     .rx_m           (rx3_m),
//     .drpclk         (clk_74_25),
//     .drprdy         (rx3_drprdy),
//     .drpaddr        (rx3_drpaddr),
//     .drpdi          (rx3_drpdi),
//     .drpen          (rx3_drpen),
//     .drpwe          (rx3_drpwe),
//     .control0       (control7),
//     .control1       (control8),
//     .control2       (control9));

//k7_sdi_rxtx SDI4 (
//    .clk            (clk_74_25),
//    .tx_usrclk      (tx4_usrclk),
//    .tx_gttxreset   (tx4_gttxreset),
//    .tx_txdata      (tx4_txdata),
//    .tx_ratedone    (tx4_ratedone),
//    .tx_resetdone   (tx4_resetdone),
//    .tx_pmareset    (tx4_pmareset),
//    .tx_sysclksel   (tx4_sysclksel),
//    .tx_rate        (tx4_rate),
//    .tx_plllock     (tx4_cplllock & x1_qplllock),
//    .tx_slew        (tx4_slew),
//    .tx_userrdy     (tx4_userrdy),
//    .tx_pllreset    (gtxpllreset),
//    .tx_txen        (tx4_txen),
//    .rx_usrclk      (rx4_usrclk),
//    .rx_gtrxreset   (rx4_gtrxreset),
//    .rx_resetdone   (rx4_resetdone),
//    .rx_rate        (rx4_rate),
//    .rx_ratedone    (rx4_ratedone),
//    .rx_cdrhold     (rx4_cdrhold),
//    .rx_rxdata      (rx4_rxdata),
//    .rx_locked      (rx4_locked),
//    .rx_userrdy     (rx4_userrdy),
//    .rx_pllreset    (gtxpllreset),
//    .rx_plllock     (x1_qplllock),
//    .rx_mode        (rx4_mode),
//    .rx_level_b     (rx4_level_b),
//    .rx_t_family    (rx4_t_family),
//    .rx_t_rate      (rx4_t_rate),
//    .rx_t_scan      (rx4_t_scan),
//    .rx_m           (rx4_m),
//    .drpclk         (clk_74_25),
//    .drprdy         (rx4_drprdy),
//    .drpaddr        (rx4_drpaddr),
//    .drpdi          (rx4_drpdi),
//    .drpen          (rx4_drpen),
//    .drpwe          (rx4_drpwe),
//    .control0       (control10),
//    .control1       (control11),
//    .control2       (control12));


//------------------------------------------------------------------------------
// GTX wrapper
//
k7gtx_sdi_wrapper GTX
(
    //_____________________________________________________________________
    //_____________________________________________________________________
   //GT0  (X0Y0)
   .GT0_DRPADDR_IN                 (rx1_drpaddr),
   .GT0_DRPCLK_IN                  (clk_74_25),
   .GT0_DRPDI_IN                   (rx1_drpdi),
   .GT0_DRPDO_OUT                  (),
   .GT0_DRPEN_IN                   (rx1_drpen),
   .GT0_DRPRDY_OUT                 (rx1_drprdy),
   .GT0_DRPWE_IN                   (rx1_drpwe),
   //----------------------- Channel - Ref Clock Ports ------------------------
   .GT0_GTREFCLK0_IN               (mgtclk_148_35),
   //------------------------------ Channel PLL -------------------------------
   .GT0_CPLLFBCLKLOST_OUT          (),
   .GT0_CPLLLOCK_OUT               (tx1_cplllock),
   .GT0_CPLLLOCKDETCLK_IN          (clk_74_25),
   .GT0_CPLLREFCLKLOST_OUT         (),
   .GT0_CPLLRESET_IN               (gtxpllreset),
   //----------------------------- Eye Scan Ports -----------------------------
   .GT0_EYESCANDATAERROR_OUT       (),
   //----------------------------- Receive Ports ------------------------------
   .GT0_RXUSERRDY_IN               (rx1_userrdy),
   //----------------- Receive Ports - RX Data Path interface -----------------
   .GT0_GTRXRESET_IN               (rx1_gtrxreset),
   .GT0_RXDATA_OUT                 (rx1_rxdata),
   .GT0_RXOUTCLK_OUT               (rx1_outclk),
   .GT0_RXUSRCLK_IN                (rx1_usrclk),
   .GT0_RXUSRCLK2_IN               (rx1_usrclk),
   //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
   .GT0_GTXRXN_IN                  (sdi_rx_n),
   .GT0_GTXRXP_IN                  (sdi_rx_p),
   .GT0_RXCDRHOLD_IN               (rx1_cdrhold),
   .GT0_RXCDRLOCK_OUT              (),
   .GT0_RXELECIDLE_OUT             (),
   //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
   .GT0_RXBUFRESET_IN              (1'b0),
   .GT0_RXBUFSTATUS_OUT            (),
   //---------------------- Receive Ports - RX PLL Ports ----------------------
   .GT0_RXRATE_IN                  (rx1_rate),
   .GT0_RXRATEDONE_OUT             (rx1_ratedone),
   .GT0_RXRESETDONE_OUT            (rx1_resetdone),
   //----------------------------- Transmit Ports -----------------------------
   .GT0_TXPOSTCURSOR_IN            (5'b00000),
   .GT0_TXPRECURSOR_IN             (5'b00000),
   .GT0_TXSYSCLKSEL_IN             (tx1_sysclksel),
   .GT0_TXUSERRDY_IN               (tx1_userrdy),
   //---------- Transmit Ports - TX Buffer and Phase Alignment Ports ----------
   .GT0_TXBUFSTATUS_OUT            (tx1_bufstatus),
   //---------------- Transmit Ports - TX Data Path interface -----------------
   .GT0_GTTXRESET_IN               (tx1_gttxreset),
   .GT0_TXDATA_IN                  (tx1_txdata),
   .GT0_TXOUTCLK_OUT               (tx1_outclk),
   .GT0_TXOUTCLKFABRIC_OUT         (),
   .GT0_TXOUTCLKPCS_OUT            (),
   .GT0_TXPCSRESET_IN              (tx1_bufstatus[1]),
   .GT0_TXPMARESET_IN              (tx1_pmareset),
   .GT0_TXUSRCLK_IN                (tx1_usrclk),
   .GT0_TXUSRCLK2_IN               (tx1_usrclk),
   //-------------- Transmit Ports - TX Driver and OOB signaling --------------
   .GT0_GTXTXN_OUT                 (sdi_tx_n),
   .GT0_GTXTXP_OUT                 (sdi_tx_p),
   .GT0_TXDIFFCTRL_IN              (4'b1011),
   //--------------------- Transmit Ports - TX PLL Ports ----------------------
   .GT0_TXRATE_IN                  (tx1_rate),
   .GT0_TXRATEDONE_OUT             (tx1_ratedone),
   .GT0_TXRESETDONE_OUT            (tx1_resetdone),





    // //_____________________________________________________________________
    // //_____________________________________________________________________
    // //GT1  (X0Y1)

    // .GT1_DRPADDR_IN                 (rx2_drpaddr),
    // .GT1_DRPCLK_IN                  (clk_74_25),
    // .GT1_DRPDI_IN                   (rx2_drpdi),
    // .GT1_DRPDO_OUT                  (),
    // .GT1_DRPEN_IN                   (rx2_drpen),
    // .GT1_DRPRDY_OUT                 (rx2_drprdy),
    // .GT1_DRPWE_IN                   (rx2_drpwe),
    // //----------------------- Channel - Ref Clock Ports ------------------------
    // .GT1_GTREFCLK0_IN               (mgtclk_148_35),
    // //------------------------------ Channel PLL -------------------------------
    // .GT1_CPLLFBCLKLOST_OUT          (),
    // .GT1_CPLLLOCK_OUT               (tx2_cplllock),
    // .GT1_CPLLLOCKDETCLK_IN          (clk_74_25),
    // .GT1_CPLLREFCLKLOST_OUT         (),
    // .GT1_CPLLRESET_IN               (gtxpllreset),
    // //----------------------------- Eye Scan Ports -----------------------------
    // .GT1_EYESCANDATAERROR_OUT       (),
    // //----------------------------- Receive Ports ------------------------------
    // .GT1_RXUSERRDY_IN               (rx2_userrdy),
    // //----------------- Receive Ports - RX Data Path interface -----------------
    // .GT1_GTRXRESET_IN               (rx2_gtrxreset),
    // .GT1_RXDATA_OUT                 (rx2_rxdata),
    // .GT1_RXOUTCLK_OUT               (rx2_outclk),
    // .GT1_RXUSRCLK_IN                (rx2_usrclk),
    // .GT1_RXUSRCLK2_IN               (rx2_usrclk),
    // //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    // .GT1_GTXRXN_IN                  (FMC_HPC_DP1_M2C_N),
    // .GT1_GTXRXP_IN                  (FMC_HPC_DP1_M2C_P),
    // .GT1_RXCDRHOLD_IN               (rx2_cdrhold),
    // .GT1_RXCDRLOCK_OUT              (),
    // .GT1_RXELECIDLE_OUT             (),
    // //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
    // .GT1_RXBUFRESET_IN              (1'b0),
    // .GT1_RXBUFSTATUS_OUT            (),
    // //---------------------- Receive Ports - RX PLL Ports ----------------------
    // .GT1_RXRATE_IN                  (rx2_rate),
    // .GT1_RXRATEDONE_OUT             (rx2_ratedone),
    // .GT1_RXRESETDONE_OUT            (rx2_resetdone),
    // //----------------------------- Transmit Ports -----------------------------
    // .GT1_TXPOSTCURSOR_IN            (5'b00000),
    // .GT1_TXPRECURSOR_IN             (5'b00000),
    // .GT1_TXSYSCLKSEL_IN             (tx2_sysclksel),
    // .GT1_TXUSERRDY_IN               (tx2_userrdy),
    // //---------- Transmit Ports - TX Buffer and Phase Alignment Ports ----------
    // .GT1_TXBUFSTATUS_OUT            (tx2_bufstatus),
    // //---------------- Transmit Ports - TX Data Path interface -----------------
    // .GT1_GTTXRESET_IN               (tx2_gttxreset),
    // .GT1_TXDATA_IN                  (tx2_txdata),
    // .GT1_TXOUTCLK_OUT               (tx2_outclk),
    // .GT1_TXOUTCLKFABRIC_OUT         (),
    // .GT1_TXOUTCLKPCS_OUT            (),
    // .GT1_TXPCSRESET_IN              (tx2_bufstatus[1]),
    // .GT1_TXPMARESET_IN              (tx2_pmareset),
    // .GT1_TXUSRCLK_IN                (tx2_usrclk),
    // .GT1_TXUSRCLK2_IN               (tx2_usrclk),
    // //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    // .GT1_GTXTXN_OUT                 (FMC_HPC_DP1_C2M_N),
    // .GT1_GTXTXP_OUT                 (FMC_HPC_DP1_C2M_P),
    // .GT1_TXDIFFCTRL_IN              (4'b1011),
    // //--------------------- Transmit Ports - TX PLL Ports ----------------------
    // .GT1_TXRATE_IN                  (tx2_rate),
    // .GT1_TXRATEDONE_OUT             (tx2_ratedone),
    // .GT1_TXRESETDONE_OUT            (tx2_resetdone),





    //_____________________________________________________________________
    //_____________________________________________________________________
    //GT2  (X0Y2)

    // .GT2_DRPADDR_IN                 (rx3_drpaddr),
    // .GT2_DRPCLK_IN                  (clk_74_25),
    // .GT2_DRPDI_IN                   (rx3_drpdi),
    // .GT2_DRPDO_OUT                  (),
    // .GT2_DRPEN_IN                   (rx3_drpen),
    // .GT2_DRPRDY_OUT                 (rx3_drprdy),
    // .GT2_DRPWE_IN                   (rx3_drpwe),
    // //----------------------- Channel - Ref Clock Ports ------------------------
    // .GT2_GTREFCLK0_IN               (mgtclk_148_35),
    // //------------------------------ Channel PLL -------------------------------
    // .GT2_CPLLFBCLKLOST_OUT          (),
    // .GT2_CPLLLOCK_OUT               (tx3_cplllock),
    // .GT2_CPLLLOCKDETCLK_IN          (clk_74_25),
    // .GT2_CPLLREFCLKLOST_OUT         (),
    // .GT2_CPLLRESET_IN               (gtxpllreset),
    // //----------------------------- Eye Scan Ports -----------------------------
    // .GT2_EYESCANDATAERROR_OUT       (),
    // //----------------------------- Receive Ports ------------------------------
    // .GT2_RXUSERRDY_IN               (rx3_userrdy),
    // //----------------- Receive Ports - RX Data Path interface -----------------
    // .GT2_GTRXRESET_IN               (rx3_gtrxreset),
    // .GT2_RXDATA_OUT                 (rx3_rxdata),
    // .GT2_RXOUTCLK_OUT               (rx3_outclk),
    // .GT2_RXUSRCLK_IN                (rx3_usrclk),
    // .GT2_RXUSRCLK2_IN               (rx3_usrclk),
    // //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    // .GT2_GTXRXN_IN                  (FMC_HPC_DP2_M2C_N),
    // .GT2_GTXRXP_IN                  (FMC_HPC_DP2_M2C_P),
    // .GT2_RXCDRHOLD_IN               (rx3_cdrhold),
    // .GT2_RXCDRLOCK_OUT              (),
    // .GT2_RXELECIDLE_OUT             (),
    // //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
    // .GT2_RXBUFRESET_IN              (1'b0),
    // .GT2_RXBUFSTATUS_OUT            (),
    // //---------------------- Receive Ports - RX PLL Ports ----------------------
    // .GT2_RXRATE_IN                  (rx3_rate),
    // .GT2_RXRATEDONE_OUT             (rx3_ratedone),
    // .GT2_RXRESETDONE_OUT            (rx3_resetdone),
    // //----------------------------- Transmit Ports -----------------------------
    // .GT2_TXPOSTCURSOR_IN            (5'b00000),
    // .GT2_TXPRECURSOR_IN             (5'b00000),
    // .GT2_TXSYSCLKSEL_IN             (tx3_sysclksel),
    // .GT2_TXUSERRDY_IN               (tx3_userrdy),
    // //---------- Transmit Ports - TX Buffer and Phase Alignment Ports ----------
    // .GT2_TXBUFSTATUS_OUT            (tx3_bufstatus),
    // //---------------- Transmit Ports - TX Data Path interface -----------------
    // .GT2_GTTXRESET_IN               (tx3_gttxreset),
    // .GT2_TXDATA_IN                  (tx3_txdata),
    // .GT2_TXOUTCLK_OUT               (tx3_outclk),
    // .GT2_TXOUTCLKFABRIC_OUT         (),
    // .GT2_TXOUTCLKPCS_OUT            (),
    // .GT2_TXPCSRESET_IN              (tx3_bufstatus[1]),
    // .GT2_TXPMARESET_IN              (tx3_pmareset),
    // .GT2_TXUSRCLK_IN                (tx3_usrclk),
    // .GT2_TXUSRCLK2_IN               (tx3_usrclk),
    // //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    // .GT2_GTXTXN_OUT                 (FMC_HPC_DP2_C2M_N),
    // .GT2_GTXTXP_OUT                 (FMC_HPC_DP2_C2M_P),
    // .GT2_TXDIFFCTRL_IN              (4'b1011),
    // //--------------------- Transmit Ports - TX PLL Ports ----------------------
    // .GT2_TXRATE_IN                  (tx3_rate),
    // .GT2_TXRATEDONE_OUT             (tx3_ratedone),
    // .GT2_TXRESETDONE_OUT            (tx3_resetdone),





//    //_____________________________________________________________________
//    //_____________________________________________________________________
//    //GT3  (X0Y3)
//    .GT3_DRPADDR_IN                 (rx4_drpaddr),
//    .GT3_DRPCLK_IN                  (clk_74_25),
//    .GT3_DRPDI_IN                   (rx4_drpdi),
//    .GT3_DRPDO_OUT                  (),
//    .GT3_DRPEN_IN                   (rx4_drpen),
//    .GT3_DRPRDY_OUT                 (rx4_drprdy),
//    .GT3_DRPWE_IN                   (rx4_drpwe),

//    //----------------------- Channel - Ref Clock Ports ------------------------
//    .GT3_GTREFCLK0_IN               (mgtclk_148_35),
//    //------------------------------ Channel PLL -------------------------------
//    .GT3_CPLLFBCLKLOST_OUT          (),
//    .GT3_CPLLLOCK_OUT               (tx4_cplllock),
//    .GT3_CPLLLOCKDETCLK_IN          (clk_74_25),
//    .GT3_CPLLREFCLKLOST_OUT         (),
//    .GT3_CPLLRESET_IN               (gtxpllreset),
//    //----------------------------- Eye Scan Ports -----------------------------
//    .GT3_EYESCANDATAERROR_OUT       (),
//    //----------------------------- Receive Ports ------------------------------
//    .GT3_RXUSERRDY_IN               (rx4_userrdy),
//    //----------------- Receive Ports - RX Data Path interface -----------------
//    .GT3_GTRXRESET_IN               (rx4_gtrxreset),
//    .GT3_RXDATA_OUT                 (rx4_rxdata),
//    .GT3_RXOUTCLK_OUT               (rx4_outclk),
//    .GT3_RXUSRCLK_IN                (rx4_usrclk),
//    .GT3_RXUSRCLK2_IN               (rx4_usrclk),
//    //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
//    .GT3_GTXRXN_IN                  (FMC_HPC_DP3_M2C_N),
//    .GT3_GTXRXP_IN                  (FMC_HPC_DP3_M2C_P),
//    .GT3_RXCDRHOLD_IN               (rx4_cdrhold),
//    .GT3_RXCDRLOCK_OUT              (),
//    .GT3_RXELECIDLE_OUT             (),
//    //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
//    .GT3_RXBUFRESET_IN              (1'b0),
//    .GT3_RXBUFSTATUS_OUT            (),
//    //---------------------- Receive Ports - RX PLL Ports ----------------------
//    .GT3_RXRATE_IN                  (rx4_rate),
//    .GT3_RXRATEDONE_OUT             (rx4_ratedone),
//    .GT3_RXRESETDONE_OUT            (rx4_resetdone),
//    //----------------------------- Transmit Ports -----------------------------
//    .GT3_TXPOSTCURSOR_IN            (5'b00000),
//    .GT3_TXPRECURSOR_IN             (5'b00000),
//    .GT3_TXSYSCLKSEL_IN             (tx4_sysclksel),
//    .GT3_TXUSERRDY_IN               (tx4_userrdy),
//    //---------- Transmit Ports - TX Buffer and Phase Alignment Ports ----------
//    .GT3_TXBUFSTATUS_OUT            (tx4_bufstatus),
//    //---------------- Transmit Ports - TX Data Path interface -----------------
//    .GT3_GTTXRESET_IN               (tx4_gttxreset),
//    .GT3_TXDATA_IN                  (tx4_txdata),
//    .GT3_TXOUTCLK_OUT               (tx4_outclk),
//    .GT3_TXOUTCLKFABRIC_OUT         (),
//    .GT3_TXOUTCLKPCS_OUT            (),
//    .GT3_TXPCSRESET_IN              (tx4_bufstatus[1]),
//    .GT3_TXPMARESET_IN              (tx4_pmareset),
//    .GT3_TXUSRCLK_IN                (tx4_usrclk),
//    .GT3_TXUSRCLK2_IN               (tx4_usrclk),
//    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
//    .GT3_GTXTXN_OUT                 (FMC_HPC_DP3_C2M_N),
//    .GT3_GTXTXP_OUT                 (FMC_HPC_DP3_C2M_P),
//    .GT3_TXDIFFCTRL_IN              (4'b1011),
//    //--------------------- Transmit Ports - TX PLL Ports ----------------------
//    .GT3_TXRATE_IN                  (tx4_rate),
//    .GT3_TXRATEDONE_OUT             (tx4_ratedone),
//    .GT3_TXRESETDONE_OUT            (tx4_resetdone),




//____________________________COMMON PORTS________________________________
    //-------------------- Common Block  - Ref Clock Ports ---------------------
    .GT0_GTREFCLK0_COMMON_IN        (mgtclk_148_5),
    //----------------------- Common Block - QPLL Ports ------------------------
    .GT0_QPLLLOCK_OUT               (x1_qplllock),
    .GT0_QPLLLOCKDETCLK_IN          (clk_74_25),
    .GT0_QPLLREFCLKLOST_OUT         (),
    .GT0_QPLLRESET_IN               (gtxpllreset)
);

endmodule

    
