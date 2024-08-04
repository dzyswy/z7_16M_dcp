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
//  /   /         Filename: $File: //Groups/video_ip/demos/K7/xapp592_k7_sdi_demos/verilog/kc705_sdi_demo/k7_sdi_rxtx.v $
// /___/   /\     Timestamp: $DateTime: 2012/08/16 14:34:43 $
// \   \  /  \
//  \___\/\___\
//
// Description:
// This module is a wrapper around a set of modules that implement an independent
// SDI RX and TX. The SDI TX is driven by SD and HD video pattern generators. The
// TX and pattern generators are controlled by ChipScope. The output of the SDI RX
// is monitored by ChipScope.
//
// This module makes it easier to implement multi-channel SDI demos.
//
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

`timescale 1ns / 1ps

module k7_sdi_rxtx (
    input   wire        clk,                // 74.25 MHz clock

    input   wire        i_tx_m,             // 0 = select 148.5 MHz refclk, 1 = select 148.35 MHz refclk
    input   wire [1:0]  i_tx_mode,          // 00 = HD, 01 = SD, 10 = 3G
    input   wire        i_framerate_sel,    // 0 -- 50Hz, 1 -- 60Hz        

    input   [10:0]      tx_line,
    input   [9:0]       tx_c,
    input   [9:0]       tx_y,

// TX ports
    input   wire        tx_usrclk,
    output  wire        tx_gttxreset,
    output  wire [19:0] tx_txdata,
    input   wire        tx_ratedone,
    input   wire        tx_resetdone,
    output  wire        tx_pmareset,
    output  wire [1:0]  tx_sysclksel,
    output  wire [2:0]  tx_rate,
    input   wire        tx_plllock,
    output  wire        tx_slew,
    output  wire        tx_userrdy,
    input   wire        tx_pllreset,
    output  wire        tx_txen,
            
// RX ports
    input   wire        rx_usrclk,
    output  wire        rx_gtrxreset,
    input   wire        rx_resetdone,
    output  wire [2:0]  rx_rate,
    input   wire        rx_ratedone,
    output  wire        rx_cdrhold,
    input   wire [19:0] rx_rxdata,
    output  wire        rx_locked,
    output  wire        rx_userrdy,
    input   wire        rx_pllreset,
    input   wire        rx_plllock,
    output  wire [1:0]  rx_mode,
    output  wire        rx_level_b,
    output  wire [3:0]  rx_t_family,
    output  wire [3:0]  rx_t_rate,
    output  wire        rx_t_scan,
    output  wire        rx_m,
    input   wire        drpclk,
    input   wire        drprdy,
    output  wire [8:0]  drpaddr,
    output  wire [15:0] drpdi,
    output  wire        drpen,
    output  wire        drpwe,
	output 	reg 		rx_loss,
	output 	 wire      vid_pclk,
    output   wire       async_pclk,
// ChipScope control ports
    inout   wire [35:0] control0,
    inout   wire [35:0] control1,
    inout   wire [35:0] control2
);

//
// Internal signals
//

// TX signals
wire        tx_bitrate_sel;
// wire [1:0]  tx_mode;
reg [1:0]  tx_mode;
wire [1:0]  tx_mode_x;
wire [2:0]  tx_fmt_sel;
wire [1:0]  tx_pat;
reg         tx_M;
wire [9:0]  tx_hd_y;
wire [9:0]  tx_hd_c;
wire [9:0]  tx_pal_patgen;
wire [9:0]  tx_ntsc_patgen;
wire [9:0]  tx_sd;
// wire [10:0] tx_line;
reg  [2:0]  tx_fmt;
// wire [9:0]  tx_c;
// wire [9:0]  tx_y;
reg  [7:0]  tx_vpid_byte2;
wire        tx_din_rdy;
reg         tx_fabric_reset = 1'b0;
(* equivalent_register_removal = "no" *)
(* KEEP = "TRUE" *)
reg [2:0]   tx_ce = 3'b111;                    // 3 copies of the TX clock enable
(* equivalent_register_removal = "no" *)
(* KEEP = "TRUE" *)
reg         tx_sd_ce = 1'b0;                   // This is the SD-SDI TX clock enable
(* equivalent_register_removal = "no" *)
(* KEEP = "TRUE" *)
reg  [10:0] tx_gen_sd_ce = 11'b00000100001;    // Generates 5/6/5/6 cadence SD-SDI TX clock enable
wire        tx_ce_mux;                         // Used to generate the tx_ce signals

// RX signals
wire        rx_clr_errs;
wire        rx_mode_locked;
wire        rx_ce;
wire        rx_dout_rdy_3G;
wire [10:0] rx_ln_a;
wire [31:0] rx_a_vpid;
wire        rx_a_vpid_valid;
wire        rx_crc_err_a;
wire        rx_crc_err_b;
reg         rx_hd_crc_err = 1'b0;
wire        rx_crc_err_ab;
reg  [1:0]  rx_crc_err_edge = 2'b00;
reg  [15:0] rx_crc_err_count = 0;
wire [15:0] rx_err_count;
wire        rx_err_count_tc;
reg         rx_sd_clr_errs = 1'b0;
wire [15:0] rx_edh_errcnt;
wire [9:0]  rx_ds1a;
wire [9:0]  rx_ds2a;
wire [9:0]  rx_ds1b;
wire [9:0]  rx_ds2b;
wire        rx_eav;
wire        rx_sav;
wire        rx_crc_err;
wire        rx_manual_reset;

// ChipScope signals
wire [6:0]  tx_vio_sync_out;
wire [2:0]  tx_vio_async_out;
wire [1:0]  rx_vio_sync_out;
wire [68:0] rx_vio_async_in;
wire [1:0]  rx_vio_async_out;
wire [69:0] rx_trig0;

 wire [0:0] rx_mode_3G;
//------------------------------------------------------------------------------
// TX section
//

//
// Because of glitches on TXOUTCLK during changes to TXRATE and TXSYSCLKSEL, the
// SDI data path is reset when TXRATEDONE is low (taking care of TXSYSCLKSEL
// changes) and when TXRATEDONE is pulsed high (taking care of TXRATE changes).
//
always @ (posedge tx_usrclk)
    tx_fabric_reset <= tx_ratedone | ~tx_resetdone;

//
// TX clock enable generator
//
// sd_ce runs at 27 MHz and is asserted at a 5/6/5/6 cadence
// tx_ce is always 1 for 3G-SDI and HD-SDI and equal to sd_ce for SD-SDI
//
// Create 3 identical but separate copies of the clock enable for loading purposes.
//
always @ (posedge tx_usrclk)
    if (tx_fabric_reset)
        tx_gen_sd_ce <= 11'b00000100001;
    else
        tx_gen_sd_ce <= {tx_gen_sd_ce[9:0], tx_gen_sd_ce[10]};

always @ (posedge tx_usrclk)
    tx_sd_ce <= tx_gen_sd_ce[10];

assign tx_ce_mux = tx_mode == 2'b01 ? tx_gen_sd_ce[10] : 1'b1;

always @ (posedge tx_usrclk)
    tx_ce <= {3 {tx_ce_mux}};

//------------------------------------------------------------------------------
// Some logic to insure that the TX bit rate and video formats chosen by the
// user are never illegal.
//
// In 3G-SDI mode, only video formats 4 (1080p60) and 5 (1080p50) are legal.
//
// always @ (*)
//     if (tx_mode == 2'b10 && tx_fmt_sel[2:1] != 2'b10)
//         tx_fmt <= 3'b100;
//     else
//         tx_fmt <= tx_fmt_sel;

//
// In SD-SDI mode, tx_M must be 0. In HD and 3G modes, if the video format is
// 0 (720p50), 3 (1080i50), or 5 (1080p25), then tx_M must be 0.
//
// always @ (*)
//     if (tx_mode == 2'b01)          // In SD-SDI mode, tx_M must be 0
//         tx_M <= 1'b0;
//     else if (tx_fmt == 3'b000 || tx_fmt == 3'b011 || tx_fmt == 3'b101)
//         tx_M <= 1'b0;
//     else
//         tx_M <= tx_bitrate_sel;

//     reg  [15:0]  enable;
//     always @( posedge tx_usrclk) begin
//         if(tx_fabric_reset)begin
//             enable <= 'd0;
//         end
//         else begin
//             enable <= {enable[14:0],1'b1};
//         end
//     end    

// reg     [2:0]   video_mode;
// wire    [2:0]   video_mode_sel;
// reg     [1:0]   tx_mode_cfg;  // 00 = HD, 01 = SD, 10 = 3G
// reg             framerate_sel;  // 0 -- 25/50Hz, 1 -- 24/30/60Hz

// vio_1 your_instance_name (
//   .clk          (clk),                // input wire clk
//   .probe_out0   (video_mode_sel)  // output wire [2 : 0] probe_out0
// );


// always @ (posedge clk or posedge tx_fabric_reset)begin
//     if (tx_fabric_reset) begin
//         // 1080p 30
//         video_mode          <= 3'd2;
//         tx_mode_cfg             <= 2'b00;
//         framerate_sel       <= 1'b1;
//     end
//     else begin
//         case (tx_vio_sync_out[2:0])
//             3'd0:begin
//                 // 1080p 24
//                 video_mode          <= 3'd0;
//                 tx_mode_cfg             <= 2'b00;
//                 framerate_sel       <= 1'b1;               
//             end 
//             3'd1:begin
//                 // 1080p 25
//                 video_mode          <= 3'd1;
//                 tx_mode_cfg             <= 2'b00;
//                 framerate_sel       <= 1'b0;               
//             end 
//             3'd2:begin
//                 // 1080p 30
//                 video_mode          <= 3'd2;
//                 tx_mode_cfg             <= 2'b00;
//                 framerate_sel       <= 1'b1;               
//             end 
//             3'd3:begin
//                 // 1080p 50
//                 video_mode          <= 3'd3;
//                 tx_mode_cfg             <= 2'b10;
//                 framerate_sel       <= 1'b0;               
//             end 
//             3'd4:begin
//                 // 1080p 60
//                 video_mode          <= 3'd4;
//                 tx_mode_cfg             <= 2'b10;
//                 framerate_sel       <= 1'b1;               
//             end

//             default:; 
//         endcase
//     end
// end

//     sdi_pattern_gen  u0_patgen (
//     .i_clk              (   tx_usrclk          ),	
//     .i_rst              (   tx_fabric_reset    ),	

//     .i_video_mode       (   3'd4   ),

//     // .i_video_mode       (   tx_vio_sync_out[2:0]   ),

//     .i_sdi_enable       (   enable[15]  ),

//     .i_sdi_tx_data      (   {10'h15a,10'h3a5}),
//     .o_sdi_data_req     (   ),

//     .o_sdi_dout         (   {tx_y,tx_c}),
//     .o_sdi_ln           (   tx_line),
//     .o_sdi_wn           (   )
// );



always @ (posedge clk)begin
    // tx_M <= i_tx_m;
    // tx_mode <= tx_mode_x;
    // tx_fmt[0] <= tx_vio_sync_out[0];

    

    tx_M <= i_tx_m;
    tx_mode <= i_tx_mode;
    tx_fmt[0] <= i_framerate_sel;

    // tx_M <= i_tx_m;
    // tx_mode <= 2'b10;
    // tx_fmt[0] <= 1'b1;


end
    

//tx_mode:00 = HD, 01 = SD, 10 = 3G
///////////////////////////////////////
//tx_mode = 00 tx_pat = 00 tx_fmt_sel = 001/011 tx_bitrate_sel = 0
//tx_M = 0 tx_mode = 0  tx_fmt = 001/011 tx_pat = 0   1080i 50hz
///////////////////////////////////////
//tx_mode = 00 tx_pat = 00 tx_fmt_sel = 010 tx_bitrate_sel = 0
//tx_M = 0 tx_mode = 0  tx_fmt = 010 tx_pat = 0   1080i 60hz
///////////////////////////////////////
//tx_mode = 00 tx_pat = 00 tx_fmt_sel = 100 tx_bitrate_sel = 0
//tx_M = 0 tx_mode = 00  tx_fmt = 100 tx_pat = 0   1080P 30hz
///////////////////////////////////////
//tx_mode = 00 tx_pat = 00 tx_fmt_sel = 100 tx_bitrate_sel = 0
//tx_M = 0 tx_mode = 00  tx_fmt = 101 tx_pat = 0   1080P 25hz
///////////////////////////////////////
//tx_mode = 00 tx_pat = 00 tx_fmt_sel = 001 tx_bitrate_sel = 0
//tx_M = 0 tx_mode = 0  tx_fmt = 110 tx_pat = 0   1080P 24hz
///////////////////////////////////////
///////////////////////////////////////
///////////////////////////////////////
//tx_mode = 10 tx_pat = 00 tx_fmt_sel = 001 tx_bitrate_sel = 0
//tx_M = 0 tx_mode = 10  tx_fmt = 100 tx_pat = 0   1080P 50hz
///////////////////////////////////////
///////////////////////////////////////
//tx_mode = 10 tx_pat = 00 tx_fmt_sel = 100/110/111 tx_bitrate_sel = 0
//tx_M = 0 tx_mode = 10  tx_fmt = 101 tx_pat = 0   1080P 60hz
///////////////////////////////////////
///////////////////////////////////////


// //------------------------------------------------------------------------------
// // Video pattern generators
// //
// multigenHD VIDGEN (
//     .clk                (tx_usrclk),
//     .rst                (tx_fabric_reset),
//     .ce                 (1'b1),
//     .std                (tx_fmt),
//     .pattern            (tx_pat),
//     .user_opt           (2'b00),
//     .y                  (tx_hd_y),
//     .c                  (tx_hd_c),
//     .h_blank            (),
//     .v_blank            (),
//     .field              (),
//     .trs                (),
//     .xyz                (),
//     .line_num           (tx_line));

// vidgen_ntsc NTSC (
//     .clk_a              (tx_usrclk),
//     .rst_a              (tx_fabric_reset),
//     .ce_a               (tx_sd_ce),
//     .pattern_a          (tx_pat[0]),
//     .q_a                (tx_ntsc_patgen),
//     .h_sync_a           (),
//     .v_sync_a           (),
//     .field_a            (),
//     .clk_b              (1'b0),
//     .rst_b              (1'b0),
//     .ce_b               (1'b0),
//     .pattern_b          (1'b0),
//     .q_b                (),
//     .h_sync_b           (),
//     .v_sync_b           (),
//     .field_b            ());

// vidgen_pal PAL (
//     .clk_a              (tx_usrclk),
//     .rst_a              (tx_fabric_reset),
//     .ce_a               (tx_sd_ce),
//     .pattern_a          (tx_pat[0]),
//     .q_a                (tx_pal_patgen),
//     .h_sync_a           (),
//     .v_sync_a           (),
//     .field_a            (),
//     .clk_b              (1'b0),
//     .rst_b              (1'b0),
//     .ce_b               (1'b0),
//     .pattern_b          (1'b0),
//     .q_b                (),
//     .h_sync_b           (),
//     .v_sync_b           (),
//     .field_b            ());

    // pattern generator p0
    // 本模块生成sdi时序，此处采用了固定3gSDI 1080P输出
    // 可以通过配置select_std is_720p信号来调整输出制�???
    // {select_std,is_720p}=0000 1080P60
    // {select_std,is_720p}=0001 1080P50 
    // {select_std,is_720p}=0100 1080I60
    // {select_std,is_720p}=0101 720P60
    // {select_std,is_720p}=0110 1080P30
    // {select_std,is_720p}=10XX NTSC
    // {select_std,is_720p}=11XX PAL     
    // sdi_pattern_gen  u0_patgen (
    //     .clk            (   tx_usrclk       ),	
    //     .rst            (   tx_fabric_reset ),	
    //     .hd_sdn         (   1'b1            ),
    //     .select_std     (   tx_vio_sync_out[3:2]           ),
    //     .is_720p        (   tx_vio_sync_out[1:0]           ),
    //     .enable         (   enable[15]      ),
    //     .ln             (   tx_line),
    //     .wn             (   ),
            
    //     .vout           (   ),
    //     .data_req       (   ),
    //     .data           (   {10'h15a,10'h3a5}),
    //     .dout           (   {tx_y,tx_c}       ),
    //     .trs            (   )    
    // );

//     sdi_pattern_gen  u0_patgen (
//     .i_clk              (   tx_usrclk          ),	
//     .i_rst              (   tx_fabric_reset    ),	

//     .i_video_mode       (   tx_vio_sync_out[2:0]   ),

//     .i_sdi_enable       (   enable[15]  ),

//     .i_sdi_tx_data      (   {10'h15a,10'h3a5}),
//     .o_sdi_data_req     (   ),

//     .o_sdi_dout         (   {tx_y,tx_c}),
//     .o_sdi_ln           (   tx_line),
//     .o_sdi_wn           (   )
// );    

//
// Video pattern generator output muxes
//
assign tx_sd = tx_fmt[0] ? tx_pal_patgen : tx_ntsc_patgen;
// assign tx_c = tx_hd_c;
// assign tx_y = tx_mode == 2'b01 ? tx_sd : tx_hd_y;

assign tx_din_rdy = 1'b1;

always @ (*)
    if (tx_fmt[0])
        tx_vpid_byte2 = 8'hC9;      // 50 Hz
    else if (tx_M)
        tx_vpid_byte2 = 8'hCA;      // 59.94 Hz
    else
        tx_vpid_byte2 = 8'hCB;      // 60 Hz

//------------------------------------------------------------------------------
// SDI core wrapper including GTX control module
//
x7gtx_sdi_rxtx_wrapper #(
    .FXDCLK_FREQ        (74250000))
SDI (
    .clk                (clk),
    .rx_rst             (1'b0),
    .rx_usrclk          (rx_usrclk),
    .rx_frame_en        (1'b1),                     // Enable SDI framer
    .rx_mode_en         (3'b111),                   // Enable all three SDI protocols
    .rx_mode            (rx_mode),
    .rx_mode_HD         (),
    .rx_mode_SD         (),
    .rx_mode_3G         (rx_mode_3G),
    .rx_mode_locked     (rx_mode_locked),
    .rx_bit_rate        (rx_m),
    .rx_t_locked        (rx_locked),
    .rx_t_family        (rx_t_family),
    .rx_t_rate          (rx_t_rate),
    .rx_t_scan          (rx_t_scan),
    .rx_level_b_3G      (rx_level_b),
    .rx_ce_sd           (rx_ce),
    .rx_nsp             (),
    .rx_line_a          (rx_ln_a),
    .rx_a_vpid          (rx_a_vpid),
    .rx_a_vpid_valid    (rx_a_vpid_valid),
    .rx_b_vpid          (),
    .rx_b_vpid_valid    (),
    .rx_crc_err_a       (rx_crc_err_a),
    .rx_ds1a            (rx_ds1a),
    .rx_ds2a            (rx_ds2a),
    .rx_eav             (rx_eav),
    .rx_sav             (rx_sav),
    .rx_trs             (),
    .rx_line_b          (),
    .rx_dout_rdy_3G     (rx_dout_rdy_3G),
    .rx_crc_err_b       (rx_crc_err_b),
    .rx_ds1b            (rx_ds1b),
    .rx_ds2b            (rx_ds2b),
    .rx_edh_errcnt_en   (16'b0_00001_00001_00000),
    .rx_edh_clr_errcnt  (rx_sd_clr_errs),
    .rx_edh_ap          (),
    .rx_edh_ff          (),
    .rx_edh_anc         (),
    .rx_edh_ap_flags    (),
    .rx_edh_ff_flags    (),
    .rx_edh_anc_flags   (),
    .rx_edh_packet_flags(),
    .rx_edh_errcnt      (rx_edh_errcnt),
    .rx_pllrange        (1'b0),

    .tx_rst             (tx_fabric_reset),
    .tx_usrclk          (tx_usrclk),
    .tx_ce              (tx_ce),
    .tx_din_rdy         (tx_din_rdy),
    .tx_mode            (tx_mode),
    .tx_m               (tx_M),
    .tx_level_b_3G      (1'b0),             // In 3G-SDI mode, this demo only transmits level A
    .tx_insert_crc      (1'b1),
    .tx_insert_ln       (1'b1),
    .tx_insert_edh      (1'b1),
    .tx_insert_vpid     (tx_mode == 2'b10),
    .tx_overwrite_vpid  (1'b1),
    .tx_video_a_y_in    (tx_y),
    .tx_video_a_c_in    (tx_c),
    .tx_video_b_y_in    (10'b0),
    .tx_video_b_c_in    (10'b0),
    .tx_line_a          (tx_line),
    .tx_line_b          (tx_line),
    .tx_vpid_byte1      (8'h89),
    .tx_vpid_byte2      (tx_vpid_byte2),
    .tx_vpid_byte3      (8'h00),
    .tx_vpid_byte4a     (8'h09),
    .tx_vpid_byte4b     (8'h09),
    .tx_vpid_line_f1    (11'd10),
    .tx_vpid_line_f2    (11'b0),
    .tx_vpid_line_f2_en (1'b0),
    .tx_ds1a_out        (),
    .tx_ds2a_out        (),
    .tx_ds1b_out        (),
    .tx_ds2b_out        (),
    .tx_use_dsin        (1'b0),
    .tx_ds1a_in         (10'b0),
    .tx_ds2a_in         (10'b0),
    .tx_ds1b_in         (10'b0),
    .tx_ds2b_in         (10'b0),
    .tx_ce_align_err    (),
    .tx_slew            (tx_slew),
    .tx_pllrange        (1'b0),

    .gtx_rxdata         (rx_rxdata),
    .gtx_rxpllreset     (rx_pllreset),
    .gtx_rxplllock      (rx_plllock),
    .gtx_rxresetdone    (rx_resetdone),
    .gtx_gtrxreset      (rx_gtrxreset),
    .gtx_rxuserrdy      (rx_userrdy),
    .gtx_rxrate         (rx_rate),
    .gtx_rxcdrhold      (rx_cdrhold),
    .gtx_drpclk         (drpclk),
    .gtx_drprdy         (drprdy),
    .gtx_drpaddr        (drpaddr),
    .gtx_drpdi          (drpdi),
    .gtx_drpen          (drpen),
    .gtx_drpwe          (drpwe),

    .gtx_txdata         (tx_txdata),
    .gtx_txpllreset     (tx_pllreset),
    .gtx_txplllock      (tx_plllock),
    .gtx_gttxreset      (tx_gttxreset),
    .gtx_txuserrdy      (tx_userrdy),
    .gtx_txpmareset     (tx_pmareset),
    .gtx_txrate         (tx_rate),
    .gtx_txsysclksel    (tx_sysclksel));


//------------------------------------------------------------------------------
// CRC eror capture and counting logic
//
assign rx_crc_err_ab = rx_crc_err_a | (rx_mode == 2'b10 && rx_level_b && rx_crc_err_b);

always @ (posedge rx_usrclk)
    if (rx_clr_errs)
        rx_hd_crc_err <= 1'b0;
    else if (rx_crc_err_ab)
        rx_hd_crc_err <= 1'b1;

always @ (posedge rx_usrclk)
    rx_crc_err_edge <= {rx_crc_err_edge[0], rx_crc_err_ab};

always @ (posedge rx_usrclk)
    if (rx_clr_errs | ~rx_mode_locked)
        rx_crc_err_count <= 0;
    else if (rx_crc_err_edge[0] & ~rx_crc_err_edge[1] & ~rx_err_count_tc)
        rx_crc_err_count <= rx_crc_err_count + 1;

assign rx_err_count = rx_mode == 2'b01 ? rx_edh_errcnt : rx_crc_err_count;
assign rx_err_count_tc = rx_crc_err_count == 16'hffff;

always @ (posedge rx_usrclk)
    if (rx_clr_errs)
        rx_sd_clr_errs <= 1'b1;
    else if (rx_ce)
        rx_sd_clr_errs <= 1'b0;

assign rx_crc_err = rx_mode == 2'b01 ? rx_edh_errcnt != 0 : rx_hd_crc_err;

//------------------------------------------------------------------------------
wire [9:0] dly_a_y,dly_a_c,dly_b_y,dly_b_c;
wire [9:0] map_y;
wire [9:0] map_cb;
wire [9:0] map_cr;
wire [0:0] map_hs;
wire [0:0] map_vs;
wire [0:0] map_de;
wire [0:0] map_h;
wire [0:0] map_v;
wire [0:0] map_f;
//// sync signals ////
wire [0:0] sync_hs;
wire [0:0] sync_vs;

wire [0:0] sync_de;

wire [0:0] sync_h;
wire [0:0] sync_v;
wire [0:0] sync_f;
wire sync_h_normal,sync_v_normal,sync_f_normal;
wire map_h_normal,map_v_normal,map_f_normal;

reg [27:0] locked_cnt = 0;
reg rx_locked_r0,rx_locked_r1,rx_locked_r2,rx_locked_r3;
reg rx_mode_locked_r0,rx_mode_locked_r1,rx_mode_locked_r2,rx_mode_locked_r3;

reg [3:0] rx_t_family_r0,rx_t_family_r1,rx_t_family_r2,rx_t_family_r3;
wire vid_sof;
wire vid_f_sof;
wire vid_valid_de;
wire vid_tvalid;



//assign vid_tvalid =1;

//always @(posedge rx_usrclk)
//begin
//	rx_t_family_r0 <= rx_t_family;
//	rx_t_family_r1 <= rx_t_family_r0;
//	rx_t_family_r2 <= rx_t_family_r1;
//	rx_t_family_r3 <= rx_t_family_r2;
	
//    rx_locked_r0 <= rx_locked;
//    rx_locked_r1 <= rx_locked_r0;
//    rx_locked_r2 <= rx_locked_r1;
//    rx_locked_r3 <= rx_locked_r2;  
	
//	rx_mode_locked_r0 <= rx_mode_locked;
//    rx_mode_locked_r1 <= rx_mode_locked_r0;
//    rx_mode_locked_r2 <= rx_mode_locked_r1;
//    rx_mode_locked_r3 <= rx_mode_locked_r2;  


		
//	if((!rx_locked_r3)||(!rx_mode_locked_r3)||(rx_t_family_r3 != rx_t_family_r2))
//        locked_cnt <= 0;
//    else if(locked_cnt < 28'hfff_fffe)
//        locked_cnt <= locked_cnt + 1;	
//	if(locked_cnt < 28'h8ff_fff1)
//        rx_loss <= 1;
//    else
//        rx_loss <= 0;	
//end


//    proc_vid_delay u_proc_vid_delay (
//        .clk(rx_usrclk), 
//        .tvalid(vid_tvalid), 
//        .a_y_i(rx_ds1a), 
//        .a_c_i(rx_ds2a), 
//        .b_y_i(rx_ds1b), 
//        .b_c_i(rx_ds2b), 
//        .a_y_o(dly_a_y), 
//        .a_c_o(dly_a_c), 
//        .b_y_o(dly_b_y), 
//        .b_c_o(dly_b_c)
//        );

//image_format_map  u_image_format_map (
//        .clk(rx_usrclk),
//        .debug_o(), 
//        .a_vpid(rx_a_vpid), 
//        .a_vpid_valid(rx_a_vpid_valid), 
//        .mode(rx_mode), 
//        .mode_3G(rx_mode_3G), 
//        .level_b_3G(rx_level_b), 
//        .eav(rx_eav), 
//        .sav(rx_sav), 
//        .tvalid(vid_tvalid), 
//        .a_y(dly_a_y), 
//        .a_c(dly_a_c), 
//        .b_y(dly_b_y), 
//        .b_c(dly_b_c), 
         
//        .hs_i(sync_hs), 
//        .vs_i(sync_vs), 
//        .de_i(sync_de), 
        
//        .hn_i(sync_h_normal), 
//        .vn_i(sync_v_normal), 
//        .fn_i(sync_f_normal),   
        
//        .h_i(sync_h), 
//        .v_i(sync_v), 
//        .f_i(sync_f), 
//        .hs_o(map_hs), 
//        .vs_o(map_vs), 
//        .de_o(map_de), 
//        .hn_o(map_h_normal), 
//        .vn_o(map_v_normal), 
//        .fn_o(map_f_normal), 
        
//        .h_o(map_h), 
//        .v_o(map_v), 
//        .f_o(map_f), 
//        .y(map_y), 
//        .cb(map_cb), 
//        .cr(map_cr)
//        );
        
//sync_gen_V20 u_sync_gen_V20 (
//    .proc_clk(rx_usrclk), 
//    .vid_rst(rx_loss), 
//	 .vid_t_scan(rx_t_scan),
//    .vid_t_family(rx_t_family), 
//    .vid_h_normal(sync_h_normal), 
//    .vid_v_normal(sync_v_normal), 
//    .vid_f_normal(sync_f_normal), 

//    .vid_y(rx_ds1a), 
//    .eav(rx_eav), 
//    .sav(rx_sav), 
//    .tvalid(vid_tvalid), 
//    .sof(vid_sof), 
//    .f_sof(vid_f_sof),
//	.valid_de(vid_valid_de),
	
//    .vid_hs(sync_hs), 
//    .vid_vs(sync_vs), 
//    .vid_de(sync_de), 
//    .vid_h(sync_h), 
//    .vid_v(sync_v), 
//    .vid_f(sync_f)
//    );    
        
//sdi_clk_sel_V20 u_sdi_clk_sel_V20 (
//    .rx_usrclk(rx_usrclk), 
//    .sd_ce(rx_ce), 
//    .dout_rdy_3g(rx_dout_rdy_3g), 
//    .level_b(rx_level_b), 
//    .a_vpid(rx_a_vpid), 
//	.sync_hs(sync_hs),
//    .a_vpid_valid(rx_a_vpid_valid), 
//    .mode(rx_mode), 
//    .async_pclk(async_pclk),
//    .pixel_clk(vid_pclk)//pixel clock
//    );

// ChipScope modules

//tx_vio tx_vio (
//    .CONTROL    (control0),
//    .CLK        (tx_usrclk),
//    .SYNC_OUT   (tx_vio_sync_out),
//    .ASYNC_OUT  (tx_vio_async_out)
//);
// tx_vio1 tx_vio (
//   .clk(tx_usrclk),                // input wire clk
//   .probe_out0(tx_vio_sync_out),  // output wire [6 : 0] probe_out0
//   .probe_out1(tx_vio_async_out)  // output wire [2 : 0] probe_out1
// );

assign tx_bitrate_sel = tx_vio_async_out[0];
assign tx_txen = tx_vio_async_out[2];

assign tx_mode_x = tx_vio_sync_out[6:5];
// assign tx_mode = tx_mode_x == 2'b11 ? 2'b00 : tx_mode_x;
assign tx_fmt_sel = tx_vio_sync_out[2:0];
assign tx_pat = tx_vio_sync_out[4:3];
  
//rx_vio rx_vio (
//    .CONTROL    (control1),
//    .CLK        (rx_usrclk),
//    .SYNC_OUT   (rx_vio_sync_out),
//    .ASYNC_IN   (rx_vio_async_in),
//    .ASYNC_OUT  (rx_vio_async_out)
//);

//vio_0 rx_vio (
//  .clk(rx_usrclk),                // input wire clk
//  .probe_in0(rx_vio_async_in),    // input wire [68 : 0] probe_in0
//  .probe_out0(rx_vio_sync_out),  // output wire [1 : 0] probe_out0
//  .probe_out1(rx_vio_async_out)  // output wire [1 : 0] probe_out1
//);

assign rx_clr_errs = rx_vio_sync_out[0];
assign rx_manual_reset = rx_vio_async_out[0];

assign rx_vio_async_in = {rx_rate, rx_cdrhold, rx_t_scan, rx_t_rate, rx_err_count, 1'b0, rx_crc_err, rx_a_vpid_valid, rx_a_vpid[7:0], rx_a_vpid[15:8], 
                           rx_a_vpid[23:16], rx_a_vpid[31:24], rx_m, rx_level_b, rx_t_family, rx_mode_locked, rx_mode};

//ila rx_ila (
//    .CONTROL    (control2),
//    .CLK        (rx_usrclk),
//    .TRIG0      (rx_trig0));

//ila_0 rx_ila (
//	.clk(rx_usrclk), // input wire clk
//	.probe0(rx_trig0) // input wire [54:0] probe0
//);

assign rx_trig0 = {rx_locked,rx_mode,rx_t_family,rx_sav, rx_eav,rx_ds2b,rx_ds1b,rx_ds2a, rx_ds1a, rx_ln_a, rx_crc_err_ab, rx_ce};

endmodule

    
