`timescale 1ps/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: luster
// Engineer: lz
// 
// Create Date: 2021/09/06 17:36:48
// Design Name: 
// Module Name: sdi_in_out_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sdi_in_out_top(

    //--------MGT REFCLKs-------
    input   wire            ref_gbtclk0_in_n,    // 148.5 MHz clock from FMC board
    input   wire            ref_gbtclk0_in_p, 

    input   wire            ref_gbtclk1_in_n,    // 148.5 MHz clock from FMC board
    input   wire            ref_gbtclk1_in_p,       

    //--------sdi rx in-----------
    input   wire            sdi_rx_n,
    input   wire            sdi_rx_p,

    //--------sdi tx out ---------------
    output  wire            sdi_tx_n,
    output  wire            sdi_tx_p,

    input   wire            i_rst,

    output  wire            o_video_in_clk,
    output  wire            o_video_in_hblank,
    output  wire            o_video_in_vblank,
    output  wire            o_video_in_active_vid_en,
    output  wire    [15:0]  o_video_in_data,

    output  wire            o_video_in_rstn,

    output wire            o_video_out_clk,
    input  wire            i_video_out_hblank,
    input  wire            i_video_out_vblank,
    input  wire            i_video_out_active_vid_en,
    input  wire    [15:0]  i_video_out_data
);





//----------------def params-------------------------



//-------------def localparams------------------------
localparam PLLRST_DLY_MSB = 12;     // GTX PLL reset duration is ~55ms, terminal count is when MSB of counter is 1
localparam PLLSTRT_DLY_MSB = 38;    // 1/74.25MHz * 38 = 511 ns, shift reg must be 1 bit wider than required by the timeout period                  

    //----------def vars----------------------------
    wire        clk_100M;
    wire        mgtclk_148_5;
    wire        mgtclk_148_35;
    wire        clk_74_25;
    wire        clk_74_25_in;

    wire        Si5324_LOL;
    reg  [PLLRST_DLY_MSB:0]   pllreset_dly = 0;
    wire        pllreset_x;
    wire        pllreset_tc;
    reg         gtxpllreset = 1'b0;
    wire        x1_qplllock;
    reg  [PLLSTRT_DLY_MSB:0] pllreset_startup_dly = 0;
    wire        startup_cpllreset;

    reg         i2c_mux_reset_ff = 1'b0;
    wire        Si5324_rst;

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
    wire [1:0]  tx2_mode;
    
    (* mark_debug = "TRUE" *) wire [19:0] tx2_sdi_data;
    wire [9:0] tx2_hd_y;
    wire [9:0] tx2_hd_c;
    (* mark_debug = "TRUE" *) wire [10:0] tx2_hd_ln;
    
    
    // // TX3 signals
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
    wire        rx2_bit_rate;
    wire        rx2_drprdy;
    wire [8:0]  rx2_drpaddr;
    wire [15:0] rx2_drpdi;
    wire        rx2_drpen;
    wire        rx2_drpwe;

(* mark_debug = "TRUE" *)wire rx2_cdrlocked;
(* mark_debug = "TRUE" *)wire [9:0] rx2_ds1a;
(* mark_debug = "TRUE" *)wire [9:0] rx2_ds2a;
(* mark_debug = "TRUE" *)wire rx2_trs;
(* mark_debug = "TRUE" *)wire rx2_sav;
(* mark_debug = "TRUE" *)wire rx2_eav;
(* mark_debug = "TRUE" *)wire [10:0] rx2_ln;
    
    (* mark_debug = "TRUE" *) wire [19:0] tx3_sdi_data;
    (* mark_debug = "TRUE" *) wire [9:0] tx3_hd_y;
    (* mark_debug = "TRUE" *) wire [9:0] tx3_hd_c;
    (* mark_debug = "TRUE" *) wire [10:0] tx3_hd_ln;

    // // RX3 signals
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

    wire        rx3_cdrlocked;
    wire [9:0]  rx3_ds1a;
    wire [9:0]  rx3_ds2a;
    wire        rx3_trs;
    wire        rx3_sav;
    wire        rx3_eav;
    wire [10:0] rx3_ln;


    wire vid_hblank_in_0;
    wire vid_vblank_in_0;
    wire vid_active_vid_en_in_0;
    wire [15:0] vid_data_in_0;      
        
    (* mark_debug = "TRUE" *)wire vid_io_out_active_video_0;
    (* mark_debug = "TRUE" *)wire vid_io_out_hblank_0;
    (* mark_debug = "TRUE" *)wire vid_io_out_vblank_0;
    (* mark_debug = "TRUE" *)wire [15:0] vid_io_out_data;
    
    wire video_in_loss_n;
    
//------------------------------------start here-------------------------------

//
// This is the 148.5 MHz MGT reference clock input from FMC SDI mezzanine board.
// The ODIV2 output is used to provide a global 74.25 MHz clock to the FPGA
// used as the GTX DRP clock and fixed frequency clock for the SDI wrapper.
// It is also sent out to the Si5324 on the KC705 to be converted to a 148.35 MHz
// reference clock for the GTX transceivers.
//
IBUFDS_GTE2 MGTCLKIN0 (
    .I          (ref_gbtclk0_in_p),
    .IB         (ref_gbtclk0_in_n),
    .CEB        (1'b0),
    .O          (mgtclk_148_5),
    .ODIV2      (clk_74_25_in)
);

BUFG BUFG74_25 (
    .I          (clk_74_25_in),
    .O          (clk_74_25)
);

//
// 148.35 MHz MGT reference clock input from Si5324. It is generated by the 
// from the 74.25 MHz clock (clk_74_25).
//
IBUFDS_GTE2 TXMGTCLKIN (
    .I          (ref_gbtclk1_in_p),
    .IB         (ref_gbtclk1_in_n),
    .CEB        (1'b0),
    .O          (mgtclk_148_35),
    .ODIV2      ()
);

//
// RX & TX global clock buffers for SDI channels
//
// BUFG BUFGTX1 (
    // .I          (tx1_outclk),
    // .O          (tx1_usrclk));

// BUFG BUFGRX1 (
    // .I          (rx1_outclk),
    // .O          (rx1_usrclk));

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

// BUFG BUFGTX4 (
    // .I          (tx4_outclk),
    // .O          (tx4_usrclk));

// BUFG BUFGRX4 (
    // .I          (rx4_outclk),
    // .O          (rx4_usrclk));


//----------------------------------------------------
// SDI RX/TX modules

k7_sdi_rxtx SDI2 (
    .clk                        (clk_74_25),

    .tx_usrclk                  (tx2_usrclk     ),
    .tx_gttxreset               (tx2_gttxreset  ),
    .tx_txdata                  (tx2_txdata     ),
    .tx_ratedone                (tx2_ratedone   ),
    .tx_resetdone               (tx2_resetdone  ),
    .tx_pmareset                (tx2_pmareset   ),
    .tx_sysclksel               (tx2_sysclksel  ),
    .tx_rate                    (tx2_rate       ),
    .tx_plllock                 (tx2_cplllock & x1_qplllock),
    .tx_slew                    (tx2_slew       ),
    .tx_userrdy                 (tx2_userrdy    ),
    .tx_pllreset                (gtxpllreset    ),
    .tx_txen                    (               ),

    .tx_mode_in                 (tx2_mode       ),
    
    .tx_bitrate_sel_in          (1'b0),
    .tx_framerate_sel_in        (1'b1),
    .tx_hd_c_in                 (tx2_hd_c),
    .tx_hd_y_in                 (tx2_hd_y),
    .tx_line_number_in          (tx2_hd_ln),
    
    .rx_usrclk                  (rx2_usrclk),
    .rx_gtrxreset               (rx2_gtrxreset),
    .rx_resetdone               (rx2_resetdone),
    .rx_rate                    (rx2_rate),
    .rx_ratedone                (rx2_ratedone),
    .rx_cdrhold                 (rx2_cdrhold),
    .rx_rxdata                  (rx2_rxdata),
    .rx_locked                  (rx2_locked),
    .rx_userrdy                 (rx2_userrdy),
    .rx_pllreset                (gtxpllreset),
    .rx_plllock                 (x1_qplllock),
    .rx_mode                    (rx2_mode),
    .rx_level_b                 (rx2_level_b),
    .rx_t_family                (rx2_t_family),
    .rx_t_rate                  (rx2_t_rate),
    .rx_t_scan                  (rx2_t_scan),
    .rx_m                       (rx2_bit_rate),

    .drpclk                     (clk_74_25),
    .drprdy                     (rx2_drprdy),
    .drpaddr                    (rx2_drpaddr),
    .drpdi                      (rx2_drpdi),
    .drpen                      (rx2_drpen),
    .drpwe                      (rx2_drpwe),
    
    .rx_line_number_a_out       (rx2_ln),
    .rx_ds1a_out                (rx2_ds1a),
    .rx_ds2a_out                (rx2_ds2a),
    .rx_eav_out                 (rx2_eav),
    .rx_sav_out                 (rx2_sav),
    .rx_trs_out                 (rx2_trs)
  
);

assign rx2_mode = 2'b00;
assign tx2_mode = 2'b00;

assign rx3_mode = 2'b00;
assign tx3_mode = 2'b00;


k7_sdi_rxtx SDI3 (
    .clk                            (clk_74_25),

    .tx_usrclk                      (tx3_usrclk),
    .tx_gttxreset                   (tx3_gttxreset),
    .tx_txdata                      (tx3_txdata),
    .tx_ratedone                    (tx3_ratedone),
    .tx_resetdone                   (tx3_resetdone),
    .tx_pmareset                    (tx3_pmareset),
    .tx_sysclksel                   (tx3_sysclksel),
    .tx_rate                        (tx3_rate),
    .tx_plllock                     (tx3_cplllock & x1_qplllock),
    .tx_slew                        (tx3_slew),
    .tx_userrdy                     (tx3_userrdy),
    .tx_pllreset                    (gtxpllreset),
    .tx_txen                        (),
    
    .tx_mode_in                     (tx3_mode),
    
    .tx_bitrate_sel_in              (1'b0),
    .tx_framerate_sel_in            (1'b1),
    .tx_hd_c_in                     (tx3_hd_c),
    .tx_hd_y_in                     (tx3_hd_y),
    .tx_line_number_in              (tx3_hd_ln),
    
    .rx_usrclk                      (rx3_usrclk     ),
    .rx_gtrxreset                   (rx3_gtrxreset  ),
    .rx_resetdone                   (rx3_resetdone  ),
    .rx_rate                        (rx3_rate       ),
    .rx_ratedone                    (rx3_ratedone   ),
    .rx_cdrhold                     (rx3_cdrhold    ),
    .rx_rxdata                      (rx3_rxdata     ),
    .rx_locked                      (rx3_locked     ),
    .rx_userrdy                     (rx3_userrdy    ),
    .rx_pllreset                    (gtxpllreset    ),
    .rx_plllock                     (x1_qplllock    ),
    .rx_mode                        (rx3_mode       ),
    .rx_level_b                     (rx3_level_b    ),
    .rx_t_family                    (rx3_t_family   ),
    .rx_t_rate                      (rx3_t_rate     ),
    .rx_t_scan                      (rx3_t_scan     ),
    .rx_m                           (rx3_bit_rate   ),

    .drpclk                         (clk_74_25      ),
    .drprdy                         (rx3_drprdy     ),
    .drpaddr                        (rx3_drpaddr    ),
    .drpdi                          (rx3_drpdi      ),
    .drpen                          (rx3_drpen      ),
    .drpwe                          (rx3_drpwe      ),
    
    .rx_line_number_a_out           (rx3_ln         ),
    .rx_ds1a_out                    (rx3_ds1a       ),
    .rx_ds2a_out                    (rx3_ds2a       ),
    .rx_eav_out                     (rx3_eav        ),
    .rx_sav_out                     (rx3_sav        ),
    .rx_trs_out                     (rx3_trs        )
);

//------------------------------------------------------------------------------
// GTX wrapper
//
k7gtx_sdi_wrapper GTX
(   
    //_____________________________________________________________________
    //_____________________________________________________________________
    //GT1  (X0Y1)

    .GT1_DRPADDR_IN                 (rx2_drpaddr),
    .GT1_DRPCLK_IN                  (clk_74_25),
    .GT1_DRPDI_IN                   (rx2_drpdi),
    .GT1_DRPDO_OUT                  (),
    .GT1_DRPEN_IN                   (rx2_drpen),
    .GT1_DRPRDY_OUT                 (rx2_drprdy),
    .GT1_DRPWE_IN                   (rx2_drpwe),
    //----------------------- Channel - Ref Clock Ports ------------------------
    .GT1_GTREFCLK0_IN               (mgtclk_148_35),
    //------------------------------ Channel PLL -------------------------------
    .GT1_CPLLFBCLKLOST_OUT          (),
    .GT1_CPLLLOCK_OUT               (tx2_cplllock),
    .GT1_CPLLLOCKDETCLK_IN          (clk_74_25),
    .GT1_CPLLREFCLKLOST_OUT         (),
    .GT1_CPLLRESET_IN               (gtxpllreset),
    //----------------------------- Eye Scan Ports -----------------------------
    .GT1_EYESCANDATAERROR_OUT       (),
    //----------------------------- Receive Ports ------------------------------
    .GT1_RXUSERRDY_IN               (rx2_userrdy),
    //----------------- Receive Ports - RX Data Path interface -----------------
    .GT1_GTRXRESET_IN               (rx2_gtrxreset),
    .GT1_RXDATA_OUT                 (rx2_rxdata),
    .GT1_RXOUTCLK_OUT               (rx2_outclk),
    .GT1_RXUSRCLK_IN                (rx2_usrclk),
    .GT1_RXUSRCLK2_IN               (rx2_usrclk),
    //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    .GT1_GTXRXN_IN                  (sdi_rx_n),
    .GT1_GTXRXP_IN                  (sdi_rx_p),
    .GT1_RXCDRHOLD_IN               (rx2_cdrhold),
    .GT1_RXCDRLOCK_OUT              (rx2_cdrlocked),
    .GT1_RXELECIDLE_OUT             (),
    //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
    .GT1_RXBUFRESET_IN              (1'b0),
    .GT1_RXBUFSTATUS_OUT            (),
    //---------------------- Receive Ports - RX PLL Ports ----------------------
    .GT1_RXRATE_IN                  (rx2_rate),
    .GT1_RXRATEDONE_OUT             (rx2_ratedone),
    .GT1_RXRESETDONE_OUT            (rx2_resetdone),
    //----------------------------- Transmit Ports -----------------------------
    .GT1_TXPOSTCURSOR_IN            (5'b00000),
    .GT1_TXPRECURSOR_IN             (5'b00000),
    .GT1_TXSYSCLKSEL_IN             (tx2_sysclksel),
    .GT1_TXUSERRDY_IN               (tx2_userrdy),
    //---------- Transmit Ports - TX Buffer and Phase Alignment Ports ----------
    .GT1_TXBUFSTATUS_OUT            (tx2_bufstatus),
    //---------------- Transmit Ports - TX Data Path interface -----------------
    .GT1_GTTXRESET_IN               (tx2_gttxreset),
    .GT1_TXDATA_IN                  (tx2_txdata),
    .GT1_TXOUTCLK_OUT               (tx2_outclk),
    .GT1_TXOUTCLKFABRIC_OUT         (),
    .GT1_TXOUTCLKPCS_OUT            (),
    .GT1_TXPCSRESET_IN              (tx2_bufstatus[1]),
    .GT1_TXPMARESET_IN              (tx2_pmareset),
    .GT1_TXUSRCLK_IN                (tx2_usrclk),
    .GT1_TXUSRCLK2_IN               (tx2_usrclk),
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    .GT1_GTXTXN_OUT                 (   ),
    .GT1_GTXTXP_OUT                 (   ),
    .GT1_TXDIFFCTRL_IN              (4'b1011),
    //--------------------- Transmit Ports - TX PLL Ports ----------------------
    .GT1_TXRATE_IN                  (tx2_rate),
    .GT1_TXRATEDONE_OUT             (tx2_ratedone),
    .GT1_TXRESETDONE_OUT            (tx2_resetdone),

    //_____________________________________________________________________
    //_____________________________________________________________________
    //GT2  (X0Y2)

    .GT2_DRPADDR_IN                 (rx3_drpaddr),
    .GT2_DRPCLK_IN                  (clk_74_25),
    .GT2_DRPDI_IN                   (rx3_drpdi),
    .GT2_DRPDO_OUT                  (),
    .GT2_DRPEN_IN                   (rx3_drpen),
    .GT2_DRPRDY_OUT                 (rx3_drprdy),
    .GT2_DRPWE_IN                   (rx3_drpwe),
    //----------------------- Channel - Ref Clock Ports ------------------------
    .GT2_GTREFCLK0_IN               (mgtclk_148_35),
    //------------------------------ Channel PLL -------------------------------
    .GT2_CPLLFBCLKLOST_OUT          (),
    .GT2_CPLLLOCK_OUT               (tx3_cplllock),
    .GT2_CPLLLOCKDETCLK_IN          (clk_74_25),
    .GT2_CPLLREFCLKLOST_OUT         (),
    .GT2_CPLLRESET_IN               (gtxpllreset),
    //----------------------------- Eye Scan Ports -----------------------------
    .GT2_EYESCANDATAERROR_OUT       (),
    //----------------------------- Receive Ports ------------------------------
    .GT2_RXUSERRDY_IN               (rx3_userrdy),
    //----------------- Receive Ports - RX Data Path interface -----------------
    .GT2_GTRXRESET_IN               (rx3_gtrxreset),
    .GT2_RXDATA_OUT                 (rx3_rxdata),
    .GT2_RXOUTCLK_OUT               (rx3_outclk),
    .GT2_RXUSRCLK_IN                (rx3_usrclk),
    .GT2_RXUSRCLK2_IN               (rx3_usrclk),
    //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    .GT2_GTXRXN_IN                  (   ),
    .GT2_GTXRXP_IN                  (   ),
    .GT2_RXCDRHOLD_IN               (rx3_cdrhold),
    .GT2_RXCDRLOCK_OUT              (),
    .GT2_RXELECIDLE_OUT             (),
    //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
    .GT2_RXBUFRESET_IN              (1'b0),
    .GT2_RXBUFSTATUS_OUT            (),
    //---------------------- Receive Ports - RX PLL Ports ----------------------
    .GT2_RXRATE_IN                  (rx3_rate),
    .GT2_RXRATEDONE_OUT             (rx3_ratedone),
    .GT2_RXRESETDONE_OUT            (rx3_resetdone),
    //----------------------------- Transmit Ports -----------------------------
    .GT2_TXPOSTCURSOR_IN            (5'b00000),
    .GT2_TXPRECURSOR_IN             (5'b00000),
    .GT2_TXSYSCLKSEL_IN             (tx3_sysclksel),
    .GT2_TXUSERRDY_IN               (tx3_userrdy),
    //---------- Transmit Ports - TX Buffer and Phase Alignment Ports ----------
    .GT2_TXBUFSTATUS_OUT            (tx3_bufstatus),
    //---------------- Transmit Ports - TX Data Path interface -----------------
    .GT2_GTTXRESET_IN               (tx3_gttxreset),
    .GT2_TXDATA_IN                  (tx3_txdata),
    .GT2_TXOUTCLK_OUT               (tx3_outclk),
    .GT2_TXOUTCLKFABRIC_OUT         (),
    .GT2_TXOUTCLKPCS_OUT            (),
    .GT2_TXPCSRESET_IN              (tx3_bufstatus[1]),
    .GT2_TXPMARESET_IN              (tx3_pmareset),
    .GT2_TXUSRCLK_IN                (tx3_usrclk),
    .GT2_TXUSRCLK2_IN               (tx3_usrclk),
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    .GT2_GTXTXN_OUT                 (sdi_tx_n   ),
    .GT2_GTXTXP_OUT                 (sdi_tx_p   ),
    .GT2_TXDIFFCTRL_IN              (4'b1011),
    //--------------------- Transmit Ports - TX PLL Ports ----------------------
    .GT2_TXRATE_IN                  (tx3_rate),
    .GT2_TXRATEDONE_OUT             (tx3_ratedone),
    .GT2_TXRESETDONE_OUT            (tx3_resetdone),

//____________________________COMMON PORTS________________________________
    //-------------------- Common Block  - Ref Clock Ports ---------------------
    .GT0_GTREFCLK0_COMMON_IN        (mgtclk_148_5),
    //----------------------- Common Block - QPLL Ports ------------------------
    .GT0_QPLLLOCK_OUT               (x1_qplllock),
    .GT0_QPLLLOCKDETCLK_IN          (clk_74_25),
    .GT0_QPLLREFCLKLOST_OUT         (),
    .GT0_QPLLRESET_IN               (gtxpllreset)
);


//----------------sdi to video format-------------
sdi2video_converter sdi2video_conv_inst0 (
    //----global signals
    .rst(i_rst),
    .clk_sdi(rx2_usrclk),
    //.clk_vid(),
    
    //---- input sdi smpte frame
    .rx_ds1a(rx2_ds1a),
    .rx_ds2a(rx2_ds2a),    
    .rx_trs(rx2_trs),
    .rx_sav(rx2_sav),
    .rx_eav(rx2_eav),
    .rx_line_number(rx2_ln),

    //---- output video frame
    .vid_hblank(vid_hblank_in_0),
    .vid_vblank(vid_vblank_in_0),
    .vid_active_vid_en(vid_active_vid_en_in_0),
    .vid_data(vid_data_in_0)
    
);

    assign  o_video_in_clk = rx2_usrclk;
    assign  o_video_in_hblank = vid_hblank_in_0;
    assign  o_video_in_vblank = vid_vblank_in_0;
    assign  o_video_in_active_vid_en = vid_active_vid_en_in_0;
    assign  o_video_in_data = vid_data_in_0; 


    (* mark_debug = "TRUE" *)wire               mark_vid_in_hblank_in_0;
    (* mark_debug = "TRUE" *)wire               mark_vid_in_vblank_in_0;
    (* mark_debug = "TRUE" *)wire               mark_vid_in_active_vid_en_in_0;
    (* mark_debug = "TRUE" *)wire [15:0]        mark_vid_in_data_in_0;     

    (* mark_debug = "TRUE" *)reg [1:0]          mark_vid_in_hblank_reg;
    (* mark_debug = "TRUE" *)reg [1:0]          mark_vid_in_vblank_rdg;
    (* mark_debug = "TRUE" *)reg [15:0]         mark_vid_in_pix_cnt;
    (* mark_debug = "TRUE" *)reg [15:0]         mark_vid_in_line_cnt;   
    always @(posedge rx2_usrclk) begin
        if (i_rst) begin
            mark_vid_in_hblank_reg <= 0;
            mark_vid_in_vblank_rdg <= 0;
            mark_vid_in_pix_cnt <= 0;
            mark_vid_in_line_cnt <= 0;
        end
        else begin
            mark_vid_in_hblank_reg <= {mark_vid_in_hblank_reg[0],vid_hblank_in_0};
            mark_vid_in_vblank_rdg <= {mark_vid_in_vblank_rdg[0],vid_vblank_in_0};
            if (mark_vid_in_vblank_rdg == 2'b10) begin
                mark_vid_in_pix_cnt <= 0;
                mark_vid_in_line_cnt <= 0;               
            end
            
            if (mark_vid_in_hblank_reg == 2'b10) begin
                mark_vid_in_line_cnt <= mark_vid_in_line_cnt + 1;
            end

            mark_vid_in_pix_cnt <= 0;
            if (vid_active_vid_en_in_0 == 1'b1) begin
                mark_vid_in_pix_cnt <= mark_vid_in_pix_cnt + 1;
            end        
        end
    end    

    assign mark_vid_in_hblank_in_0          = vid_hblank_in_0       ;
    assign mark_vid_in_vblank_in_0          = vid_vblank_in_0       ;
    assign mark_vid_in_active_vid_en_in_0   = vid_active_vid_en_in_0;
    assign mark_vid_in_data_in_0            = vid_data_in_0         ;  




video_loss_detector vid_loss_detec_inst0(
    .clk_sdi(rx2_usrclk),
    .rst(i_rst),
    
    .vid_in_vblank(vid_vblank_in_0),
    .vid_in_hblank(vid_hblank_in_0),
    
    .vid_in_loss_n(video_in_loss_n)
        
);

    assign o_video_in_rstn = video_in_loss_n;


    assign o_video_out_clk = tx3_usrclk;
    assign vid_io_out_active_video_0    = i_video_out_active_vid_en;
    assign vid_io_out_hblank_0          = i_video_out_hblank;
    assign vid_io_out_vblank_0          = i_video_out_vblank;
    assign vid_io_out_data              = i_video_out_data;

//-------------------video to smpte -----------------------------
video2smpte_converter video2smpte_conv_inst0 (
    //----global signals
    .rst(i_rst),
    //.clk_sdi(),
    .clk_vid(tx3_usrclk),
    
    //---- input video frame
    .vid_hblank(vid_io_out_hblank_0),
    .vid_vblank(vid_io_out_vblank_0),
    .vid_active_vid_en(vid_io_out_active_video_0),
    .vid_data_y(vid_io_out_data[7:0]),
    .vid_data_c(vid_io_out_data[15:8]),
    
    //---- output sdi smpte frame
    .tx_sdi_data(tx3_sdi_data),
    .tx_sdi_line_number(tx3_hd_ln)

);

assign tx3_hd_y = tx3_sdi_data[9:0];
assign tx3_hd_c = tx3_sdi_data[19:10];



endmodule
