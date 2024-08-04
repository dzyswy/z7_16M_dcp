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


module sdi_in_out_top
#(
    parameter					CFG_CLK_FREQ			= 100000000,
	parameter                   SIM 					= "FALSE",
	parameter                   DEBUG					= "FALSE"
)
(

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

    //------------------------------------------------
    // Cfg Port
    //------------------------------------------------
    axi_lite_if.s           s_axil,

    //------------------------------------------------
    // Stream Port
    //------------------------------------------------
    axis_if.m               m_axis,

    output wire             o_video_in_clk,    
    frame_if.m              m_frame,
    

    output wire             o_video_out_clk,
    // input  wire            i_video_out_hblank,
    // input  wire            i_video_out_vblank,
    // input  wire            i_video_out_active_vid_en,
    // input  wire    [15:0]  i_video_out_data

    axis_if.s               s_axis,
    frame_if.s              s_frame
);

    //----------------------------------------------------------------------------------------------
    // wire  define
    //----------------------------------------------------------------------------------------------
    logic	[s_axil.DW - 1 : 0]		        s_cfg_wr_data;
    logic									s_cfg_wr_en;
    logic	[s_axil.AW - 1 : 0]		        s_cfg_addr;
    logic									s_cfg_rd_en;
    logic									s_cfg_rd_vld;
    logic	[s_axil.DW - 1 : 0]		        s_cfg_rd_data;
    logic 									s_cfg_busy;

    logic 									sdi_rst;
    logic 									sdi_data_vld;
    logic 	[15:0]		                    image_w;	
    logic 	[15:0]		                    image_h;	
    logic 	[15:0]		                    offset_x;	
    logic 	[15:0]		                    offset_y;

    logic	[m_axis.DW-1:0]                 m_axis_tdata;
    logic 				                    m_axis_tlast;
    logic 				                    m_axis_tvalid;
    logic 				                    m_axis_tuser;   	
    logic	[m_axis.DW/8-1:0]               m_axis_tkeep;
    logic				                    m_axis_tready;


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
    .I          (ref_gbtclk1_in_p),
    .IB         (ref_gbtclk1_in_n),
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
// IBUFDS_GTE2 TXMGTCLKIN (
//     .I          (ref_gbtclk1_in_p),
//     .IB         (ref_gbtclk1_in_n),
//     .CEB        (1'b0),
//     .O          (mgtclk_148_35),
//     .ODIV2      ()
// );
    assign mgtclk_148_35 = mgtclk_148_5;
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

// BUFG BUFGTX3 (
//     .I          (tx3_outclk),
//     .O          (tx3_usrclk));

// BUFG BUFGRX3 (
//     .I          (rx3_outclk),
//     .O          (rx3_usrclk));

// BUFG BUFGTX4 (
    // .I          (tx4_outclk),
    // .O          (tx4_usrclk));

// BUFG BUFGRX4 (
    // .I          (rx4_outclk),
    // .O          (rx4_usrclk));


//----------------------------------------------------
// SDI RX/TX modules

k7_sdi_rxtx SDI0 (
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


// k7_sdi_rxtx SDI3 (
//     .clk                            (clk_74_25),

//     .tx_usrclk                      (tx3_usrclk),
//     .tx_gttxreset                   (tx3_gttxreset),
//     .tx_txdata                      (tx3_txdata),
//     .tx_ratedone                    (tx3_ratedone),
//     .tx_resetdone                   (tx3_resetdone),
//     .tx_pmareset                    (tx3_pmareset),
//     .tx_sysclksel                   (tx3_sysclksel),
//     .tx_rate                        (tx3_rate),
//     .tx_plllock                     (tx3_cplllock & x1_qplllock),
//     .tx_slew                        (tx3_slew),
//     .tx_userrdy                     (tx3_userrdy),
//     .tx_pllreset                    (gtxpllreset),
//     .tx_txen                        (),
    
//     .tx_mode_in                     (tx3_mode),
    
//     // .tx_rst                         (sdi_rst),        
//     .tx_bitrate_sel_in              (1'b0),
//     .tx_framerate_sel_in            (1'b0), //(1'b1),
//     .tx_hd_c_in                     (tx3_hd_c),
//     .tx_hd_y_in                     (tx3_hd_y),
//     .tx_line_number_in              (tx3_hd_ln),
    
//     .rx_usrclk                      (rx3_usrclk     ),
//     .rx_gtrxreset                   (rx3_gtrxreset  ),
//     .rx_resetdone                   (rx3_resetdone  ),
//     .rx_rate                        (rx3_rate       ),
//     .rx_ratedone                    (rx3_ratedone   ),
//     .rx_cdrhold                     (rx3_cdrhold    ),
//     .rx_rxdata                      (rx3_rxdata     ),
//     .rx_locked                      (rx3_locked     ),
//     .rx_userrdy                     (rx3_userrdy    ),
//     .rx_pllreset                    (gtxpllreset    ),
//     .rx_plllock                     (x1_qplllock    ),
//     .rx_mode                        (rx3_mode       ),
//     .rx_level_b                     (rx3_level_b    ),
//     .rx_t_family                    (rx3_t_family   ),
//     .rx_t_rate                      (rx3_t_rate     ),
//     .rx_t_scan                      (rx3_t_scan     ),
//     .rx_m                           (rx3_bit_rate   ),

//     .drpclk                         (clk_74_25      ),
//     .drprdy                         (rx3_drprdy     ),
//     .drpaddr                        (rx3_drpaddr    ),
//     .drpdi                          (rx3_drpdi      ),
//     .drpen                          (rx3_drpen      ),
//     .drpwe                          (rx3_drpwe      ),
    
//     .rx_line_number_a_out           (rx3_ln         ),
//     .rx_ds1a_out                    (rx3_ds1a       ),
//     .rx_ds2a_out                    (rx3_ds2a       ),
//     .rx_eav_out                     (rx3_eav        ),
//     .rx_sav_out                     (rx3_sav        ),
//     .rx_trs_out                     (rx3_trs        )
// );

//------------------------------------------------------------------------------
// GTX wrapper
//
k7gtx_sdi_wrapper GTX
(   
    //_____________________________________________________________________
    //_____________________________________________________________________
    //GT1  (X0Y1)

    .GT0_DRPADDR_IN                 (rx2_drpaddr),
    .GT0_DRPCLK_IN                  (clk_74_25),
    .GT0_DRPDI_IN                   (rx2_drpdi),
    .GT0_DRPDO_OUT                  (),
    .GT0_DRPEN_IN                   (rx2_drpen),
    .GT0_DRPRDY_OUT                 (rx2_drprdy),
    .GT0_DRPWE_IN                   (rx2_drpwe),
    //----------------------- Channel - Ref Clock Ports ------------------------
    .GT0_GTREFCLK0_IN               (mgtclk_148_35),
    //------------------------------ Channel PLL -------------------------------
    .GT0_CPLLFBCLKLOST_OUT          (),
    .GT0_CPLLLOCK_OUT               (tx2_cplllock),
    .GT0_CPLLLOCKDETCLK_IN          (clk_74_25),
    .GT0_CPLLREFCLKLOST_OUT         (),
    .GT0_CPLLRESET_IN               (gtxpllreset),
    //----------------------------- Eye Scan Ports -----------------------------
    .GT0_EYESCANDATAERROR_OUT       (),
    //----------------------------- Receive Ports ------------------------------
    .GT0_RXUSERRDY_IN               (rx2_userrdy),
    //----------------- Receive Ports - RX Data Path interface -----------------
    .GT0_GTRXRESET_IN               (rx2_gtrxreset),
    .GT0_RXDATA_OUT                 (rx2_rxdata),
    .GT0_RXOUTCLK_OUT               (rx2_outclk),
    .GT0_RXUSRCLK_IN                (rx2_usrclk),
    .GT0_RXUSRCLK2_IN               (rx2_usrclk),
    //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    .GT0_GTXRXN_IN                  (sdi_rx_n),
    .GT0_GTXRXP_IN                  (sdi_rx_p),
    .GT0_RXCDRHOLD_IN               (rx2_cdrhold),
    .GT0_RXCDRLOCK_OUT              (rx2_cdrlocked),
    .GT0_RXELECIDLE_OUT             (),
    //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
    .GT0_RXBUFRESET_IN              (1'b0),
    .GT0_RXBUFSTATUS_OUT            (),
    //---------------------- Receive Ports - RX PLL Ports ----------------------
    .GT0_RXRATE_IN                  (rx2_rate),
    .GT0_RXRATEDONE_OUT             (rx2_ratedone),
    .GT0_RXRESETDONE_OUT            (rx2_resetdone),
    //----------------------------- Transmit Ports -----------------------------
    .GT0_TXPOSTCURSOR_IN            (5'b00000),
    .GT0_TXPRECURSOR_IN             (5'b00000),
    .GT0_TXSYSCLKSEL_IN             (tx2_sysclksel),
    .GT0_TXUSERRDY_IN               (tx2_userrdy),
    //---------- Transmit Ports - TX Buffer and Phase Alignment Ports ----------
    .GT0_TXBUFSTATUS_OUT            (tx2_bufstatus),
    //---------------- Transmit Ports - TX Data Path interface -----------------
    .GT0_GTTXRESET_IN               (tx2_gttxreset),
    .GT0_TXDATA_IN                  (tx2_txdata),
    .GT0_TXOUTCLK_OUT               (tx2_outclk),
    .GT0_TXOUTCLKFABRIC_OUT         (),
    .GT0_TXOUTCLKPCS_OUT            (),
    .GT0_TXPCSRESET_IN              (tx2_bufstatus[1]),
    .GT0_TXPMARESET_IN              (tx2_pmareset),
    .GT0_TXUSRCLK_IN                (tx2_usrclk),
    .GT0_TXUSRCLK2_IN               (tx2_usrclk),
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    .GT0_GTXTXN_OUT                 (sdi_tx_n   ),
    .GT0_GTXTXP_OUT                 (sdi_tx_p   ),
    .GT0_TXDIFFCTRL_IN              (4'b1011),
    //--------------------- Transmit Ports - TX PLL Ports ----------------------
    .GT0_TXRATE_IN                  (tx2_rate),
    .GT0_TXRATEDONE_OUT             (tx2_ratedone),
    .GT0_TXRESETDONE_OUT            (tx2_resetdone),

//____________________________COMMON PORTS________________________________
    //-------------------- Common Block  - Ref Clock Ports ---------------------
    .GT0_GTREFCLK0_COMMON_IN        (mgtclk_148_5),
    //----------------------- Common Block - QPLL Ports ------------------------
    .GT0_QPLLLOCK_OUT               (x1_qplllock),
    .GT0_QPLLLOCKDETCLK_IN          (clk_74_25),
    .GT0_QPLLREFCLKLOST_OUT         (),
    .GT0_QPLLRESET_IN               (gtxpllreset)
);


// //----------------sdi to video format-------------
// sdi2video_converter sdi2video_conv_inst0 (
//     //----global signals
//     .rst(i_rst),
//     .clk_sdi(rx2_usrclk),
//     //.clk_vid(),
    
//     //---- input sdi smpte frame
//     .rx_ds1a(rx2_ds1a),
//     .rx_ds2a(rx2_ds2a),    
//     .rx_trs(rx2_trs),
//     .rx_sav(rx2_sav),
//     .rx_eav(rx2_eav),
//     .rx_line_number(rx2_ln),

//     //---- output video frame
//     .vid_hblank(vid_hblank_in_0),
//     .vid_vblank(vid_vblank_in_0),
//     .vid_active_vid_en(vid_active_vid_en_in_0),
//     .vid_data(vid_data_in_0)
    
// );
    sdiconvstm
    #(
        .DW                 (   m_axis.DW           ),
        .SIM            	(   SIM                 ),
        .DEBUG          	(   DEBUG               ) 
    )   
    u_sdiconvstm    
    (   
        
        .i_rst              (   ~rx2_locked | sdi_rst),
        .i_clk              (   rx2_usrclk          ),
        .i_rx_ds1a          (   rx2_ds1a            ),
        .i_rx_ds2a          (   rx2_ds2a            ),    
        .i_rx_trs           (   rx2_trs             ),
        .i_rx_sav           (   rx2_sav             ),
        .i_rx_eav           (   rx2_eav             ),
        .i_rx_line_number   (   rx2_ln              ),

        .i_cmr_vld        	(   sdi_data_vld        ), 

        .i_image_w          (   image_w             ),			
        .i_image_h          (   image_h             ),	
        .i_offset_x         (   offset_x            ),			
        .i_offset_y         (   offset_y            ),

        .i_axis_clk     	(   m_axis.clk     	    ),//input  &&Clk, Freq_m = 200
        .i_axis_rst     	(   ~m_axis.rstn | sdi_rst),//input  &&Rst, Synclk = i_axis_clk

        .o_frame_vs         (   m_frame.frame_vs	),
        .o_frame_hs         (   m_frame.frame_hs	),
        .o_frame_de         (   m_frame.frame_de	),
        .o_frame_data       (   m_frame.frame_data	),

        .m_axis_tdata		(   m_axis_tdata		),
        .m_axis_tlast		(   m_axis_tlast		),
        .m_axis_tvalid		(   m_axis_tvalid		),
        .m_axis_tuser       (   m_axis_tuser		),	
        .m_axis_tkeep		(   m_axis_tkeep		),
        .m_axis_tready		(   m_axis_tready		)
    );	 

    assign m_axis.tdata = m_axis_tdata;
    assign m_axis.tlast = m_axis_tlast;
    assign m_axis.tvalid = m_axis_tvalid;
    assign m_axis.tuser = m_axis_tuser;   	
    assign m_axis.tkeep = m_axis_tkeep;
    assign m_axis_tready = m_axis.tready;


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

    assign mark_vid_in_hblank_in_0          = vid_hblank_in_0       ;
    assign mark_vid_in_vblank_in_0          = vid_vblank_in_0       ;
    assign mark_vid_in_active_vid_en_in_0   = vid_active_vid_en_in_0;
    assign mark_vid_in_data_in_0            = vid_data_in_0         ;  


    assign o_video_out_clk = tx2_usrclk;
    // assign vid_io_out_active_video_0    = i_video_out_active_vid_en;
    // assign vid_io_out_hblank_0          = i_video_out_hblank;
    // assign vid_io_out_vblank_0          = i_video_out_vblank;
    // assign vid_io_out_data              = i_video_out_data;
    
    assign vid_io_out_active_video_0    = s_frame.frame_de;
    assign vid_io_out_hblank_0          = ~s_frame.frame_hs;
    assign vid_io_out_vblank_0          = ~s_frame.frame_vs;
    assign vid_io_out_data              = s_frame.frame_data;



// //-------------------video to smpte -----------------------------
// video2smpte_converter #(
//     .STM("STM")
// )
// video2smpte_conv_inst0 (
//     //----global signals
//     .rst(sdi_rst),
//     //.clk_sdi(),
//     .clk_vid(tx3_usrclk),
    
//     //---- input video frame
//     .vid_hblank(vid_io_out_hblank_0),
//     .vid_vblank(vid_io_out_vblank_0),
//     .vid_active_vid_en(vid_io_out_active_video_0),
//     .vid_data_y(vid_io_out_data[7:0]),
//     .vid_data_c(vid_io_out_data[15:8]),


//     .i_stm_clk  (s_axis.clk             ),
//     .i_str_data (s_axis.tdata           ),
//     .i_str_vld  (s_axis.tvalid          ),
//     .i_str_user (s_axis.tuser           ),	
//     .i_str_last (s_axis.tlast           ),
//     .o_str_rdy  (s_axis.tready          ),

//     //---- output sdi smpte frame
//     .tx_sdi_data(tx3_sdi_data),
//     .tx_sdi_line_number(tx3_hd_ln)

// );


    StmConvSmpte u_StmConvSmpte
    (
        .rst                    (  sdi_rst                  ),
        .s_axis                 (  s_axis                   ),
        .i_sdi_clk              (  tx2_usrclk               ),
        .o_tx_sdi_data          (  tx2_sdi_data             ),
        .o_tx_sdi_line_number   (  tx2_hd_ln                )
    );


assign tx2_hd_y = tx2_sdi_data[9:0];
assign tx2_hd_c = tx2_sdi_data[19:10];


    //------------------------------------------------------------------------------------------------
    // Module Name : axi_conv_cfg                                                                     
    // Description : lite总线转标准读写接�?                                                                                 
    //------------------------------------------------------------------------------------------------
    axi_conv_cfg
    #(
        .CFG_DATA_WIDTH     ( s_axil.DW                ),
        .CFG_ADDR_WIDTH     ( s_axil.AW                ),
        .AXI_ADDR_WIDTH     ( s_axil.AW                ),
        .AXI_DATA_WIDTH     ( s_axil.DW                ), 
        .SIM                (                          ),
        .DEBUG              (                          )
    )
    u_axi_conv_cfg
    (
        .i_axi_clk          ( s_axil.clk                ),
        .i_axi_rst          ( ~s_axil.rstn              ),        
        .s_axi_araddr       ( s_axil.araddr             ),
        .s_axi_arready      ( s_axil.arready            ),
        .s_axi_arvalid      ( s_axil.arvalid            ),            
        .s_axi_awaddr       ( s_axil.awaddr             ),
        .s_axi_awready      ( s_axil.awready            ),
        .s_axi_awvalid      ( s_axil.awvalid            ),         
        .s_axi_bready       ( s_axil.bready             ),
        .s_axi_bresp        ( s_axil.bresp              ),
        .s_axi_bvalid       ( s_axil.bvalid             ),     
        .s_axi_rdata        ( s_axil.rdata              ),
        .s_axi_rready       ( s_axil.rready             ),
        .s_axi_rresp        ( s_axil.rresp              ),
        .s_axi_rvalid       ( s_axil.rvalid             ),     
        .s_axi_wdata        ( s_axil.wdata              ),
        .s_axi_wready       ( s_axil.wready             ),
        .s_axi_wstrb        ( s_axil.wstrb              ),
        .s_axi_wvalid       ( s_axil.wvalid             ),
        

        .m_cfg_wr_en  		( s_cfg_wr_en  		        ),//output 
        .m_cfg_addr   		( s_cfg_addr   		        ),//output 31:0
        .m_cfg_wr_data		( s_cfg_wr_data		        ),//output 31:0
        .m_cfg_rd_en  		( s_cfg_rd_en  		        ),//output 
        .m_cfg_rd_vld 		( s_cfg_rd_vld 		        ),//input 
        .m_cfg_rd_data		( s_cfg_rd_data		        ),//input 31:0
        .m_cfg_busy         ( s_cfg_busy                )
    );

	
    //------------------------------------------------------------------------------------------------
    // Module Name : vm_va_cl_cu_reg_cfg                                                              
    // Description : axi lite总线信号解析                                                                                 
    //------------------------------------------------------------------------------------------------
    sdi_cfg
    #(
        .CFG_DATA_WIDTH     ( s_axil.DW         ),
        .CFG_ADDR_WIDTH     ( s_axil.AW         ),
        .CFG_CLK_FREQ     	( CFG_CLK_FREQ     	),
        .SIM              	( SIM              	),
        .DEBUG            	( DEBUG            	) 
    )
    u_sdi_cfg
    (
        .i_cfg_clk        	( s_axil.clk        ),//input 
        .i_cfg_rst        	( ~s_axil.rstn      ),//input 
        .s_cfg_wr_en      	( s_cfg_wr_en    	),//input 
        .s_cfg_wr_data    	( s_cfg_wr_data    	),//input CFG_DATA_WIDTH - 1:0
        .s_cfg_addr       	( s_cfg_addr       	),//input CFG_ADDR_WIDTH - 1:0
        .s_cfg_rd_en      	( s_cfg_rd_en    	),//input 
        .s_cfg_rd_vld     	( s_cfg_rd_vld   	),//output 
        .s_cfg_rd_data    	( s_cfg_rd_data    	),//output CFG_DATA_WIDTH - 1:0
        .s_cfg_busy       	( s_cfg_busy     	),//output 

        
        .i_linkup           ( {3'd0,rx2_locked} ),//input 1:0  只代�? sdi 接口已经链接

        .o_cmr_rst        	( sdi_rst        	), //output 

        .o_image_w          ( image_w           ),			
        .o_image_h          ( image_h           ),	
        .o_offset_x         ( offset_x          ),			
        .o_offset_y         ( offset_y          ),

        .o_cmr_vld        	( sdi_data_vld      ) //output 
    );









endmodule
