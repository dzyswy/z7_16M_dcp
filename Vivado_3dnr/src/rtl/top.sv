`timescale 1ps/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: luster
// Engineer: lz
// 
// Create Date: 2022/08/18 
// Design Name: 
// Module Name: sensor_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// GMAX3809 sensor Configuration
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top
#(
    parameter   AXI_DW                      = 32,
    parameter   AXI_AW                      = 32,
    parameter   AXIL_DW                     = 32,
    parameter   AXIL_AW                     = 32,  
    parameter   LANE_NUM                    = 4, 
    parameter   QUADRANT_NUM                = 4,
    parameter   family                      = "7Series",
    parameter   SIM                         = "FALSE",
    parameter   DEBUG                       = "FALSE"
)
(   
    //------------------------------------------------
    // Zynq Port
    //------------------------------------------------
    inout [14:0]							DDR_addr,
    inout [2:0]								DDR_ba,
    inout 									DDR_cas_n,
    inout 									DDR_ck_n,
    inout 									DDR_ck_p,
    inout 									DDR_cke,
    inout 									DDR_cs_n,
    inout [3:0]								DDR_dm,
    inout [31:0]							DDR_dq,
    inout [3:0]								DDR_dqs_n,
    inout [3:0]								DDR_dqs_p,
    inout 									DDR_odt,
    inout 									DDR_ras_n,
    inout 									DDR_reset_n,
    inout 									DDR_we_n,
    inout 									FIXED_IO_ddr_vrn,
    inout									FIXED_IO_ddr_vrp,
    inout [53:0]							FIXED_IO_mio,
    inout 									FIXED_IO_ps_clk,
    inout 									FIXED_IO_ps_porb,
    inout 									FIXED_IO_ps_srstb,  

    //------------------------------------------------
    // PL DDR Port
    //------------------------------------------------
    // input 									i_ddr_clk_n,
    // input 									i_ddr_clk_p,		
    output [14:0]		        			DDR3_addr,
    output [2:0]		        			DDR3_ba,
    output			            			DDR3_cas_n,
    output [0:0]		        			DDR3_ck_n,
    output [0:0]		        			DDR3_ck_p,
    output [0:0]		        			DDR3_cke,
    output			            			DDR3_ras_n,
    output			            			DDR3_reset_n,
    output			            			DDR3_we_n,
    inout  [31:0]		        			DDR3_dq,
    inout  [3:0]		        			DDR3_dqs_n,
    inout  [3:0]		        			DDR3_dqs_p,
    output [0:0]		        			DDR3_cs_n,
    output [3:0]		        			DDR3_dm,
    output [0:0]		        			DDR3_odt, 

    //------------------------------------------------
    // clock
    //------------------------------------------------
    input                                   clk_27M_in,                              //pl clk  
    input                                   clk_24M_in, 
   
    //------------------------------------------------
    // Sensor
    //------------------------------------------------
    // output              sen_poweren,
    output              sen_sysrstn, 
    output              sen_sysstbn,
    output              sen_inclk,
    
    output              sen_sck,
    input               sen_sdi,
    output              sen_sdo,
    output              sen_csn,
    
        
    input               sen_vsync,
    input               sen_hsync,
    input               sen_trgexp,
    input               sen_tout0,

    // input               sen_trig_in, 
    // output              test_out,
    
    input               sen_clkin_p,
    input               sen_clkin_n,
    
    input   [15:0]      sen_datain_p,
    input   [15:0]      sen_datain_n,

    


    //------------------------------------------------
    // SDI Port define
    //------------------------------------------------
    input                                   i_sdi_gt_refclk0_n,
    input                                   i_sdi_gt_refclk0_p,	
    input                                   i_sdi_gt_refclk1_n,
    input                                   i_sdi_gt_refclk1_p,	
    input                                   sdi_rxn,          	
    input                                   sdi_rxp,          	
    output 	                                sdi_txn,          	
    output 	                                sdi_txp,

    //------------------------------------------------
    // IIC
    //------------------------------------------------
    inout                                   IIC_0_scl_io,
    inout                                   IIC_0_sda_io
    // inout                                   IIC_1_scl_io,
    // inout                                   IIC_1_sda_io,

    // output                                  fan_en,

    // output                                  o_LED0
    // output                                  o_LED1
);


//----------------------------------------------------------------------------------------------
// clock define
//----------------------------------------------------------------------------------------------

logic                                   clk_200M;
logic                                   clk_200M_rst_n;

logic                                   clk_100M;       
logic                                   clk_100M_rst_n;

logic                                   clk_160M;
logic                                   clk_160M_rst_n;

logic                                   clk_27M;
logic                                   clk_47M25;
logic                                   clk_27M_rst_n;



//----------------------------------------------------------------------------------------------
// interface define
//---------------------------------------------------------------------------------------------- 
localparam LITE_NUM			= 10;

axi_lite_if #(AXIL_DW, AXIL_AW) m_axilite[LITE_NUM-1:0] (clk_100M, clk_100M_rst_n);
axi_lite_if #(AXIL_DW, AXIL_AW) m_axil_isp[LITE_NUM-1:0] (clk_160M, clk_160M_rst_n);
 
 
axi_if #(.DW(128),  .AW(32)) m_axi_isp[7:0] (clk_160M, clk_160M_rst_n);
 


axis_if #(128, 1, 1, 1) m_bayer_in_axis (clk_160M, clk_160M_rst_n);  
axis_if #(24, 1, 1, 1)  m_video_out_axis (clk_160M, clk_160M_rst_n);  
axis_if #(16, 1, 1, 1)  m_preview_axis (clk_160M, clk_160M_rst_n);  
axis_if #(24, 1, 1, 1)  m_photo_out_axis (clk_160M, clk_160M_rst_n);
 
 

//----------------------------------------------------------------------------------------------
// logic define
//----------------------------------------------------------------------------------------------
logic clk_wiz_0_locked;
logic clk_wiz_1_locked;


logic sen_reset ;
logic sen_clk   ;
logic [191:0] sen_data  ;
logic sen_en    ;
logic sen_vs    ;

//----------------------------------------------------------------------------------------------
// clock
//----------------------------------------------------------------------------------------------
clk_wiz_0 u_clk_wiz_0 (
    .clk_in1        (   clk_27M_in          ),
    .clk_27M        (   clk_27M             ),
    .clk_47M25      (   clk_47M25           ),
    .locked         (   clk_wiz_0_locked    )
);
assign clk_27M_rst_n = clk_wiz_0_locked;


clk_wiz_1 u_clk_wiz_1 (
    .clk_in1        (   clk_24M_in          ), 
    .clk_200M       (   clk_200M            ),
    .locked         (   clk_wiz_1_locked    )
);
assign clk_200M_rst_n = clk_wiz_1_locked;

//----------------------------------------------------------------------------------------------
// sensor 
//----------------------------------------------------------------------------------------------
sensor_top # (
    .REF_FREQ           (   200.0               ),
    .DIFF_TERM          (   "TRUE"              ),
    .DEBUG              (   "FALSE"             )
) u_sensor (
    //------------------------------------------------
    // Axi Port
    //------------------------------------------------
    .s_axil             (   m_axilite[0]        ), 

    //------------------------------------------------
    // Control Port
    //------------------------------------------------
    .sen_poweren        (   sen_poweren         ),
    .sen_inclk_en       (   sen_inclk_en        ),
    .sen_sysrstn        (   sen_sysrstn         ),
    .sen_sysstbn        (   sen_sysstbn         ),

    .sen_exp_in         (   sen_tout0           ),

    //------------------------------------------------
    // LVDS Port
    //------------------------------------------------
    .refclkin           (   clk_200M            ), 
    .sen_clkin_p        (   sen_clkin_p         ),
    .sen_clkin_n        (   sen_clkin_n         ),
    .sen_datain_p       (   sen_datain_p        ),
    .sen_datain_n       (   sen_datain_n        ),



    .sen_reset          (   sen_reset           ),
    .sen_clk            (   sen_clk             ),
    .sen_dout           (   sen_data            ),
    .sen_en_out         (   sen_en              ),
    .sen_vs_out         (   sen_vs              ) 
); 

ODDR #(
    .DDR_CLK_EDGE       (   "SAME_EDGE"     ), // "OPPOSITE_EDGE" or "SAME_EDGE" 
    .INIT               (   1'b0            ),    // Initial value of Q: 1'b0 or 1'b1
    .SRTYPE             (   "SYNC"          ) // Set/Reset type: "SYNC" or "ASYNC" 
) u_sen_clk (   
    .Q                  (   sen_inclk       ), // 1-bit DDR output
    .C                  (   clk_27M         ), // 1-bit clock input
    .CE                 (   1'b1            ), // 1-bit clock enable input
    .D1                 (   1'b1            ), // 1-bit data input (positive edge)
    .D2                 (   1'b0            ), // 1-bit data input (negative edge)
    .R                  (   !sen_inclk_en   ), // 1-bit reset
    .S                  (   1'b0            )  // 1-bit set
);

(* mark_debug = "true" *)logic [191:0]  mark_sen_data  ;
(* mark_debug = "true" *)logic          mark_sen_en    ;
(* mark_debug = "true" *)logic          mark_sen_vs    ;
assign mark_sen_data = sen_data;
assign mark_sen_en   = sen_en;
assign mark_sen_vs   = sen_vs;



// (* mark_debug = "true" *)logic mark_clk_27M      ; 
// (* mark_debug = "true" *)logic mark_sen_poweren  ;
// (* mark_debug = "true" *)logic mark_sen_inclk_en ;
// (* mark_debug = "true" *)logic mark_sen_sysrstn  ;
// (* mark_debug = "true" *)logic mark_sen_sysstbn  ;
// (* mark_debug = "true" *)logic mark_sen_csn      ;
// (* mark_debug = "true" *)logic mark_sen_sck      ;
// (* mark_debug = "true" *)logic mark_sen_sdi      ;
// (* mark_debug = "true" *)logic mark_sen_sdo      ;

// always @(posedge clk_100M)  
// begin 
//     mark_clk_27M        <= clk_27M      ;
//     mark_sen_poweren    <= sen_poweren  ;
//     mark_sen_inclk_en   <= sen_inclk_en ;
//     mark_sen_sysrstn    <= sen_sysrstn  ;
//     mark_sen_sysstbn    <= sen_sysstbn  ;
//     mark_sen_csn        <= sen_csn      ;
//     mark_sen_sck        <= sen_sck      ;
//     mark_sen_sdi        <= sen_sdi      ;
//     mark_sen_sdo        <= sen_sdo      ;
// end

//----------------------------------------------------------------------------------------------
// sensor tpg
//----------------------------------------------------------------------------------------------

// logic [11:0]    sensor_tpg_data;
// logic           sensor_tpg_en;
// logic           sensor_tpg_vs;
// video_tpg # (
//     .DATA_WIDTH     (   12                  ),
//     .CHESS_WPOW     (   4                   ),
//     .CHESS_HPOW     (   4                   ),
//     .DEBUG          (   DEBUG               )
// ) u_sensor_tpg (
//     .rst_n          (   clk_wiz_0_locked    ),
//     .clk            (   clk_47M25           ),
//     .tpg_mode       (   4'd3                ),
//     .ACTIVE_WIDTH   (   16'd256             ),//16'd257
//     .ACTIVE_HEIGHT  (   16'd3280            ),
//     .FRAME_WIDTH    (   16'd300             ),
//     .FRAME_HEIGHT   (   16'd3500            ),
//     .HBLK_HSTART    (   16'd10              ),
//     .VBLK_VSTART    (   16'd2               ),
//     .HSYNC_HSTART   (   16'd10              ),
//     .HSYNC_HEND     (   16'd267             ),
//     .VSYNC_HSTART   (   16'd0               ),
//     .VSYNC_HEND     (   16'd0               ),
//     .VSYNC_VSTART   (   16'd1               ),
//     .VSYNC_VEND     (   16'd3284            ), 
//     .dout           (   sensor_tpg_data     ),
//     .en_out         (   sensor_tpg_en       ),
//     .hs_out         (                       ),
//     .vs_out         (   sensor_tpg_vs       )
// );

logic [191:0]   bayer_data;
logic           bayer_en;
logic           bayer_vs;
// assign bayer_data = {16{sensor_tpg_data}};
// assign bayer_en   = sensor_tpg_en;
// assign bayer_vs   = sensor_tpg_vs;
video_crop # (
    .DATA_WIDTH     (   192              )
) u_crop (
    .rst_n          (   !sen_reset      ),
    .clk            (   sen_clk         ),
    .CROP_X         (   16'd1           ),
    .CROP_Y         (   16'd8           ),
    .CROP_W         (   16'd256         ),
    .CROP_H         (   16'd3280        ),
    .din            (   sen_data        ),
    .en_in          (   sen_en          ),
    .vs_in          (   sen_vs          ),
    .dout           (   bayer_data      ),
    .en_out         (   bayer_en        ),
    .vs_out         (   bayer_vs        ) 
);


//----------------------------------------------------------------------------------------------
// isp_top
//----------------------------------------------------------------------------------------------
 
logic yuyv_s2mm_irq;
logic yuyv_mm2s_video_irq;
logic yuyv_mm2s_photo_irq;

isp_top u_isp_top (
    //-------------------
    //---clock   ------	
    //-------------------	 

    .clk_100M                           (   clk_100M                    ),  
    .clk_100M_rst_n                     (   clk_100M_rst_n              ),
    .clk_160M                           (   clk_160M                    ),
    .clk_160M_rst_n                     (   clk_160M_rst_n              ),
    .clk_sensor                         (   sen_clk                     ),// sen_clk 
    .clk_sensor_rst_n                   (   !sen_reset                  ),// !sen_reset


    //-------------------
    //---interrupt   ------
    //------------------- 
    .yuyv_s2mm_irq                      (   yuyv_s2mm_irq               ),
    .yuyv_mm2s_video_irq                (   yuyv_mm2s_video_irq         ),
    .yuyv_mm2s_photo_irq                (   yuyv_mm2s_photo_irq         ),

    //-------------------
    //---sensor in   ------
    //-------------------
    .sensor_din                          (   bayer_data                 ),
    .sensor_en_in                        (   bayer_en                   ),
    .sensor_vs_in                        (   bayer_vs                   ),

    
    //-------------------
    //---video out   ------
    //-------------------
    .m_video_out_axis_tdata             (   m_video_out_axis.tdata      ),
    .m_video_out_axis_tlast             (   m_video_out_axis.tlast      ),
    .m_video_out_axis_tuser             (   m_video_out_axis.tuser      ),
    .m_video_out_axis_tvalid            (   m_video_out_axis.tvalid     ),
    .m_video_out_axis_tready            (   m_video_out_axis.tready     ),

    //-------------------
    //---preview out   ------
    //-------------------
    .m_preview_axis_tdata               (   m_preview_axis.tdata        ),
    .m_preview_axis_tlast               (   m_preview_axis.tlast        ),
    .m_preview_axis_tuser               (   m_preview_axis.tuser        ),
    .m_preview_axis_tvalid              (   m_preview_axis.tvalid       ),
    .m_preview_axis_tready              (   m_preview_axis.tready       ),

    //-------------------
    //---photo out   ------
    //-------------------
    .m_photo_out_axis_tdata             (   m_photo_out_axis.tdata      ),
    .m_photo_out_axis_tlast             (   m_photo_out_axis.tlast      ),
    .m_photo_out_axis_tuser             (   m_photo_out_axis.tuser      ),
    .m_photo_out_axis_tvalid            (   m_photo_out_axis.tvalid     ),
    .m_photo_out_axis_tready            (   m_photo_out_axis.tready     ),

    //-------------------
    //---axi mm   ------
    //-------------------
    .s_axi_isp0_araddr                  (   m_axi_isp[0].araddr         ),
    .s_axi_isp0_arburst                 (   m_axi_isp[0].arburst        ),
    .s_axi_isp0_arcache                 (   m_axi_isp[0].arcache        ),
    .s_axi_isp0_arlen                   (   m_axi_isp[0].arlen          ),
    .s_axi_isp0_arlock                  (   m_axi_isp[0].arlock         ),
    .s_axi_isp0_arprot                  (   m_axi_isp[0].arprot         ),
    .s_axi_isp0_arqos                   (   m_axi_isp[0].arqos          ),
    .s_axi_isp0_arready                 (   m_axi_isp[0].arready        ), 
    .s_axi_isp0_arsize                  (   m_axi_isp[0].arsize         ),
    .s_axi_isp0_arvalid                 (   m_axi_isp[0].arvalid        ),
    .s_axi_isp0_awaddr                  (   m_axi_isp[0].awaddr         ),
    .s_axi_isp0_awburst                 (   m_axi_isp[0].awburst        ),
    .s_axi_isp0_awcache                 (   m_axi_isp[0].awcache        ),
    .s_axi_isp0_awlen                   (   m_axi_isp[0].awlen          ),
    .s_axi_isp0_awlock                  (   m_axi_isp[0].awlock         ),
    .s_axi_isp0_awprot                  (   m_axi_isp[0].awprot         ),
    .s_axi_isp0_awqos                   (   m_axi_isp[0].awqos          ),
    .s_axi_isp0_awready                 (   m_axi_isp[0].awready        ), 
    .s_axi_isp0_awsize                  (   m_axi_isp[0].awsize         ),
    .s_axi_isp0_awvalid                 (   m_axi_isp[0].awvalid        ),
    .s_axi_isp0_bready                  (   m_axi_isp[0].bready         ),
    .s_axi_isp0_bresp                   (   m_axi_isp[0].bresp          ),
    .s_axi_isp0_bvalid                  (   m_axi_isp[0].bvalid         ),
    .s_axi_isp0_rdata                   (   m_axi_isp[0].rdata          ),
    .s_axi_isp0_rlast                   (   m_axi_isp[0].rlast          ),
    .s_axi_isp0_rready                  (   m_axi_isp[0].rready         ),
    .s_axi_isp0_rresp                   (   m_axi_isp[0].rresp          ),
    .s_axi_isp0_rvalid                  (   m_axi_isp[0].rvalid         ),
    .s_axi_isp0_wdata                   (   m_axi_isp[0].wdata          ),
    .s_axi_isp0_wlast                   (   m_axi_isp[0].wlast          ),
    .s_axi_isp0_wready                  (   m_axi_isp[0].wready         ),
    .s_axi_isp0_wstrb                   (   m_axi_isp[0].wstrb          ),
    .s_axi_isp0_wvalid                  (   m_axi_isp[0].wvalid         ),

    .s_axi_isp1_araddr                  (   m_axi_isp[1].araddr         ),
    .s_axi_isp1_arburst                 (   m_axi_isp[1].arburst        ),
    .s_axi_isp1_arcache                 (   m_axi_isp[1].arcache        ),
    .s_axi_isp1_arlen                   (   m_axi_isp[1].arlen          ),
    .s_axi_isp1_arlock                  (   m_axi_isp[1].arlock         ),
    .s_axi_isp1_arprot                  (   m_axi_isp[1].arprot         ),
    .s_axi_isp1_arqos                   (   m_axi_isp[1].arqos          ),
    .s_axi_isp1_arready                 (   m_axi_isp[1].arready        ), 
    .s_axi_isp1_arsize                  (   m_axi_isp[1].arsize         ),
    .s_axi_isp1_arvalid                 (   m_axi_isp[1].arvalid        ),
    .s_axi_isp1_awaddr                  (   m_axi_isp[1].awaddr         ),
    .s_axi_isp1_awburst                 (   m_axi_isp[1].awburst        ),
    .s_axi_isp1_awcache                 (   m_axi_isp[1].awcache        ),
    .s_axi_isp1_awlen                   (   m_axi_isp[1].awlen          ),
    .s_axi_isp1_awlock                  (   m_axi_isp[1].awlock         ),
    .s_axi_isp1_awprot                  (   m_axi_isp[1].awprot         ),
    .s_axi_isp1_awqos                   (   m_axi_isp[1].awqos          ),
    .s_axi_isp1_awready                 (   m_axi_isp[1].awready        ), 
    .s_axi_isp1_awsize                  (   m_axi_isp[1].awsize         ),
    .s_axi_isp1_awvalid                 (   m_axi_isp[1].awvalid        ),
    .s_axi_isp1_bready                  (   m_axi_isp[1].bready         ),
    .s_axi_isp1_bresp                   (   m_axi_isp[1].bresp          ),
    .s_axi_isp1_bvalid                  (   m_axi_isp[1].bvalid         ),
    .s_axi_isp1_rdata                   (   m_axi_isp[1].rdata          ),
    .s_axi_isp1_rlast                   (   m_axi_isp[1].rlast          ),
    .s_axi_isp1_rready                  (   m_axi_isp[1].rready         ),
    .s_axi_isp1_rresp                   (   m_axi_isp[1].rresp          ),
    .s_axi_isp1_rvalid                  (   m_axi_isp[1].rvalid         ),
    .s_axi_isp1_wdata                   (   m_axi_isp[1].wdata          ),
    .s_axi_isp1_wlast                   (   m_axi_isp[1].wlast          ),
    .s_axi_isp1_wready                  (   m_axi_isp[1].wready         ),
    .s_axi_isp1_wstrb                   (   m_axi_isp[1].wstrb          ),
    .s_axi_isp1_wvalid                  (   m_axi_isp[1].wvalid         ),

    .s_axi_isp2_araddr                  (   m_axi_isp[2].araddr         ),
    .s_axi_isp2_arburst                 (   m_axi_isp[2].arburst        ),
    .s_axi_isp2_arcache                 (   m_axi_isp[2].arcache        ),
    .s_axi_isp2_arlen                   (   m_axi_isp[2].arlen          ),
    .s_axi_isp2_arlock                  (   m_axi_isp[2].arlock         ),
    .s_axi_isp2_arprot                  (   m_axi_isp[2].arprot         ),
    .s_axi_isp2_arqos                   (   m_axi_isp[2].arqos          ),
    .s_axi_isp2_arready                 (   m_axi_isp[2].arready        ), 
    .s_axi_isp2_arsize                  (   m_axi_isp[2].arsize         ),
    .s_axi_isp2_arvalid                 (   m_axi_isp[2].arvalid        ),
    .s_axi_isp2_awaddr                  (   m_axi_isp[2].awaddr         ),
    .s_axi_isp2_awburst                 (   m_axi_isp[2].awburst        ),
    .s_axi_isp2_awcache                 (   m_axi_isp[2].awcache        ),
    .s_axi_isp2_awlen                   (   m_axi_isp[2].awlen          ),
    .s_axi_isp2_awlock                  (   m_axi_isp[2].awlock         ),
    .s_axi_isp2_awprot                  (   m_axi_isp[2].awprot         ),
    .s_axi_isp2_awqos                   (   m_axi_isp[2].awqos          ),
    .s_axi_isp2_awready                 (   m_axi_isp[2].awready        ), 
    .s_axi_isp2_awsize                  (   m_axi_isp[2].awsize         ),
    .s_axi_isp2_awvalid                 (   m_axi_isp[2].awvalid        ),
    .s_axi_isp2_bready                  (   m_axi_isp[2].bready         ),
    .s_axi_isp2_bresp                   (   m_axi_isp[2].bresp          ),
    .s_axi_isp2_bvalid                  (   m_axi_isp[2].bvalid         ),
    .s_axi_isp2_rdata                   (   m_axi_isp[2].rdata          ),
    .s_axi_isp2_rlast                   (   m_axi_isp[2].rlast          ),
    .s_axi_isp2_rready                  (   m_axi_isp[2].rready         ),
    .s_axi_isp2_rresp                   (   m_axi_isp[2].rresp          ),
    .s_axi_isp2_rvalid                  (   m_axi_isp[2].rvalid         ),
    .s_axi_isp2_wdata                   (   m_axi_isp[2].wdata          ),
    .s_axi_isp2_wlast                   (   m_axi_isp[2].wlast          ),
    .s_axi_isp2_wready                  (   m_axi_isp[2].wready         ),
    .s_axi_isp2_wstrb                   (   m_axi_isp[2].wstrb          ),
    .s_axi_isp2_wvalid                  (   m_axi_isp[2].wvalid         ),

    .s_axi_isp3_araddr                  (   m_axi_isp[3].araddr         ),
    .s_axi_isp3_arburst                 (   m_axi_isp[3].arburst        ),
    .s_axi_isp3_arcache                 (   m_axi_isp[3].arcache        ),
    .s_axi_isp3_arlen                   (   m_axi_isp[3].arlen          ),
    .s_axi_isp3_arlock                  (   m_axi_isp[3].arlock         ),
    .s_axi_isp3_arprot                  (   m_axi_isp[3].arprot         ),
    .s_axi_isp3_arqos                   (   m_axi_isp[3].arqos          ),
    .s_axi_isp3_arready                 (   m_axi_isp[3].arready        ), 
    .s_axi_isp3_arsize                  (   m_axi_isp[3].arsize         ),
    .s_axi_isp3_arvalid                 (   m_axi_isp[3].arvalid        ),
    .s_axi_isp3_awaddr                  (   m_axi_isp[3].awaddr         ),
    .s_axi_isp3_awburst                 (   m_axi_isp[3].awburst        ),
    .s_axi_isp3_awcache                 (   m_axi_isp[3].awcache        ),
    .s_axi_isp3_awlen                   (   m_axi_isp[3].awlen          ),
    .s_axi_isp3_awlock                  (   m_axi_isp[3].awlock         ),
    .s_axi_isp3_awprot                  (   m_axi_isp[3].awprot         ),
    .s_axi_isp3_awqos                   (   m_axi_isp[3].awqos          ),
    .s_axi_isp3_awready                 (   m_axi_isp[3].awready        ), 
    .s_axi_isp3_awsize                  (   m_axi_isp[3].awsize         ),
    .s_axi_isp3_awvalid                 (   m_axi_isp[3].awvalid        ),
    .s_axi_isp3_bready                  (   m_axi_isp[3].bready         ),
    .s_axi_isp3_bresp                   (   m_axi_isp[3].bresp          ),
    .s_axi_isp3_bvalid                  (   m_axi_isp[3].bvalid         ),
    .s_axi_isp3_rdata                   (   m_axi_isp[3].rdata          ),
    .s_axi_isp3_rlast                   (   m_axi_isp[3].rlast          ),
    .s_axi_isp3_rready                  (   m_axi_isp[3].rready         ),
    .s_axi_isp3_rresp                   (   m_axi_isp[3].rresp          ),
    .s_axi_isp3_rvalid                  (   m_axi_isp[3].rvalid         ),
    .s_axi_isp3_wdata                   (   m_axi_isp[3].wdata          ),
    .s_axi_isp3_wlast                   (   m_axi_isp[3].wlast          ),
    .s_axi_isp3_wready                  (   m_axi_isp[3].wready         ),
    .s_axi_isp3_wstrb                   (   m_axi_isp[3].wstrb          ),
    .s_axi_isp3_wvalid                  (   m_axi_isp[3].wvalid         ),

    .s_axi_isp4_araddr                  (   m_axi_isp[4].araddr         ),
    .s_axi_isp4_arburst                 (   m_axi_isp[4].arburst        ),
    .s_axi_isp4_arcache                 (   m_axi_isp[4].arcache        ),
    .s_axi_isp4_arlen                   (   m_axi_isp[4].arlen          ),
    .s_axi_isp4_arlock                  (   m_axi_isp[4].arlock         ),
    .s_axi_isp4_arprot                  (   m_axi_isp[4].arprot         ),
    .s_axi_isp4_arqos                   (   m_axi_isp[4].arqos          ),
    .s_axi_isp4_arready                 (   m_axi_isp[4].arready        ), 
    .s_axi_isp4_arsize                  (   m_axi_isp[4].arsize         ),
    .s_axi_isp4_arvalid                 (   m_axi_isp[4].arvalid        ),
    .s_axi_isp4_awaddr                  (   m_axi_isp[4].awaddr         ),
    .s_axi_isp4_awburst                 (   m_axi_isp[4].awburst        ),
    .s_axi_isp4_awcache                 (   m_axi_isp[4].awcache        ),
    .s_axi_isp4_awlen                   (   m_axi_isp[4].awlen          ),
    .s_axi_isp4_awlock                  (   m_axi_isp[4].awlock         ),
    .s_axi_isp4_awprot                  (   m_axi_isp[4].awprot         ),
    .s_axi_isp4_awqos                   (   m_axi_isp[4].awqos          ),
    .s_axi_isp4_awready                 (   m_axi_isp[4].awready        ), 
    .s_axi_isp4_awsize                  (   m_axi_isp[4].awsize         ),
    .s_axi_isp4_awvalid                 (   m_axi_isp[4].awvalid        ),
    .s_axi_isp4_bready                  (   m_axi_isp[4].bready         ),
    .s_axi_isp4_bresp                   (   m_axi_isp[4].bresp          ),
    .s_axi_isp4_bvalid                  (   m_axi_isp[4].bvalid         ),
    .s_axi_isp4_rdata                   (   m_axi_isp[4].rdata          ),
    .s_axi_isp4_rlast                   (   m_axi_isp[4].rlast          ),
    .s_axi_isp4_rready                  (   m_axi_isp[4].rready         ),
    .s_axi_isp4_rresp                   (   m_axi_isp[4].rresp          ),
    .s_axi_isp4_rvalid                  (   m_axi_isp[4].rvalid         ),
    .s_axi_isp4_wdata                   (   m_axi_isp[4].wdata          ),
    .s_axi_isp4_wlast                   (   m_axi_isp[4].wlast          ),
    .s_axi_isp4_wready                  (   m_axi_isp[4].wready         ),
    .s_axi_isp4_wstrb                   (   m_axi_isp[4].wstrb          ),
    .s_axi_isp4_wvalid                  (   m_axi_isp[4].wvalid         ),

    .s_axi_isp5_araddr                  (   m_axi_isp[5].araddr         ),
    .s_axi_isp5_arburst                 (   m_axi_isp[5].arburst        ),
    .s_axi_isp5_arcache                 (   m_axi_isp[5].arcache        ),
    .s_axi_isp5_arlen                   (   m_axi_isp[5].arlen          ),
    .s_axi_isp5_arlock                  (   m_axi_isp[5].arlock         ),
    .s_axi_isp5_arprot                  (   m_axi_isp[5].arprot         ),
    .s_axi_isp5_arqos                   (   m_axi_isp[5].arqos          ),
    .s_axi_isp5_arready                 (   m_axi_isp[5].arready        ), 
    .s_axi_isp5_arsize                  (   m_axi_isp[5].arsize         ),
    .s_axi_isp5_arvalid                 (   m_axi_isp[5].arvalid        ),
    .s_axi_isp5_awaddr                  (   m_axi_isp[5].awaddr         ),
    .s_axi_isp5_awburst                 (   m_axi_isp[5].awburst        ),
    .s_axi_isp5_awcache                 (   m_axi_isp[5].awcache        ),
    .s_axi_isp5_awlen                   (   m_axi_isp[5].awlen          ),
    .s_axi_isp5_awlock                  (   m_axi_isp[5].awlock         ),
    .s_axi_isp5_awprot                  (   m_axi_isp[5].awprot         ),
    .s_axi_isp5_awqos                   (   m_axi_isp[5].awqos          ),
    .s_axi_isp5_awready                 (   m_axi_isp[5].awready        ), 
    .s_axi_isp5_awsize                  (   m_axi_isp[5].awsize         ),
    .s_axi_isp5_awvalid                 (   m_axi_isp[5].awvalid        ),
    .s_axi_isp5_bready                  (   m_axi_isp[5].bready         ),
    .s_axi_isp5_bresp                   (   m_axi_isp[5].bresp          ),
    .s_axi_isp5_bvalid                  (   m_axi_isp[5].bvalid         ),
    .s_axi_isp5_rdata                   (   m_axi_isp[5].rdata          ),
    .s_axi_isp5_rlast                   (   m_axi_isp[5].rlast          ),
    .s_axi_isp5_rready                  (   m_axi_isp[5].rready         ),
    .s_axi_isp5_rresp                   (   m_axi_isp[5].rresp          ),
    .s_axi_isp5_rvalid                  (   m_axi_isp[5].rvalid         ),
    .s_axi_isp5_wdata                   (   m_axi_isp[5].wdata          ),
    .s_axi_isp5_wlast                   (   m_axi_isp[5].wlast          ),
    .s_axi_isp5_wready                  (   m_axi_isp[5].wready         ),
    .s_axi_isp5_wstrb                   (   m_axi_isp[5].wstrb          ),
    .s_axi_isp5_wvalid                  (   m_axi_isp[5].wvalid         ),

    .s_axi_isp6_araddr                  (   m_axi_isp[6].araddr         ),
    .s_axi_isp6_arburst                 (   m_axi_isp[6].arburst        ),
    .s_axi_isp6_arcache                 (   m_axi_isp[6].arcache        ),
    .s_axi_isp6_arlen                   (   m_axi_isp[6].arlen          ),
    .s_axi_isp6_arlock                  (   m_axi_isp[6].arlock         ),
    .s_axi_isp6_arprot                  (   m_axi_isp[6].arprot         ),
    .s_axi_isp6_arqos                   (   m_axi_isp[6].arqos          ),
    .s_axi_isp6_arready                 (   m_axi_isp[6].arready        ), 
    .s_axi_isp6_arsize                  (   m_axi_isp[6].arsize         ),
    .s_axi_isp6_arvalid                 (   m_axi_isp[6].arvalid        ),
    .s_axi_isp6_awaddr                  (   m_axi_isp[6].awaddr         ),
    .s_axi_isp6_awburst                 (   m_axi_isp[6].awburst        ),
    .s_axi_isp6_awcache                 (   m_axi_isp[6].awcache        ),
    .s_axi_isp6_awlen                   (   m_axi_isp[6].awlen          ),
    .s_axi_isp6_awlock                  (   m_axi_isp[6].awlock         ),
    .s_axi_isp6_awprot                  (   m_axi_isp[6].awprot         ),
    .s_axi_isp6_awqos                   (   m_axi_isp[6].awqos          ),
    .s_axi_isp6_awready                 (   m_axi_isp[6].awready        ), 
    .s_axi_isp6_awsize                  (   m_axi_isp[6].awsize         ),
    .s_axi_isp6_awvalid                 (   m_axi_isp[6].awvalid        ),
    .s_axi_isp6_bready                  (   m_axi_isp[6].bready         ),
    .s_axi_isp6_bresp                   (   m_axi_isp[6].bresp          ),
    .s_axi_isp6_bvalid                  (   m_axi_isp[6].bvalid         ),
    .s_axi_isp6_rdata                   (   m_axi_isp[6].rdata          ),
    .s_axi_isp6_rlast                   (   m_axi_isp[6].rlast          ),
    .s_axi_isp6_rready                  (   m_axi_isp[6].rready         ),
    .s_axi_isp6_rresp                   (   m_axi_isp[6].rresp          ),
    .s_axi_isp6_rvalid                  (   m_axi_isp[6].rvalid         ),
    .s_axi_isp6_wdata                   (   m_axi_isp[6].wdata          ),
    .s_axi_isp6_wlast                   (   m_axi_isp[6].wlast          ),
    .s_axi_isp6_wready                  (   m_axi_isp[6].wready         ),
    .s_axi_isp6_wstrb                   (   m_axi_isp[6].wstrb          ),
    .s_axi_isp6_wvalid                  (   m_axi_isp[6].wvalid         ),
 

    //-------------------
    //---axi lite   ------	
    //-------------------	
    .m_axil0_araddr                     (   m_axilite[1].araddr         ),
    .m_axil0_arready                    (   m_axilite[1].arready        ),
    .m_axil0_arvalid                    (   m_axilite[1].arvalid        ),
    .m_axil0_awaddr                     (   m_axilite[1].awaddr         ),
    .m_axil0_awready                    (   m_axilite[1].awready        ),
    .m_axil0_awvalid                    (   m_axilite[1].awvalid        ),
    .m_axil0_bready                     (   m_axilite[1].bready         ),
    .m_axil0_bresp                      (   m_axilite[1].bresp          ),
    .m_axil0_bvalid                     (   m_axilite[1].bvalid         ),
    .m_axil0_rdata                      (   m_axilite[1].rdata          ),
    .m_axil0_rready                     (   m_axilite[1].rready         ),
    .m_axil0_rresp                      (   m_axilite[1].rresp          ),
    .m_axil0_rvalid                     (   m_axilite[1].rvalid         ),
    .m_axil0_wdata                      (   m_axilite[1].wdata          ),
    .m_axil0_wready                     (   m_axilite[1].wready         ),
    .m_axil0_wstrb                      (   m_axilite[1].wstrb          ),
    .m_axil0_wvalid                     (   m_axilite[1].wvalid         ),

    //-------------------
    //---axi lite   ------
    //-------------------
    .m_axil_isp0_araddr                 (   m_axil_isp[0].araddr        ),
    .m_axil_isp0_arready                (   m_axil_isp[0].arready       ),
    .m_axil_isp0_arvalid                (   m_axil_isp[0].arvalid       ),
    .m_axil_isp0_awaddr                 (   m_axil_isp[0].awaddr        ),
    .m_axil_isp0_awready                (   m_axil_isp[0].awready       ),
    .m_axil_isp0_awvalid                (   m_axil_isp[0].awvalid       ),
    .m_axil_isp0_bready                 (   m_axil_isp[0].bready        ),
    .m_axil_isp0_bresp                  (   m_axil_isp[0].bresp         ),
    .m_axil_isp0_bvalid                 (   m_axil_isp[0].bvalid        ),
    .m_axil_isp0_rdata                  (   m_axil_isp[0].rdata         ),
    .m_axil_isp0_rready                 (   m_axil_isp[0].rready        ),
    .m_axil_isp0_rresp                  (   m_axil_isp[0].rresp         ),
    .m_axil_isp0_rvalid                 (   m_axil_isp[0].rvalid        ),
    .m_axil_isp0_wdata                  (   m_axil_isp[0].wdata         ),
    .m_axil_isp0_wready                 (   m_axil_isp[0].wready        ),
    .m_axil_isp0_wstrb                  (   m_axil_isp[0].wstrb         ),
    .m_axil_isp0_wvalid                 (   m_axil_isp[0].wvalid        ),

    .m_axil_isp1_araddr                 (   m_axil_isp[1].araddr        ),
    .m_axil_isp1_arready                (   m_axil_isp[1].arready       ),
    .m_axil_isp1_arvalid                (   m_axil_isp[1].arvalid       ),
    .m_axil_isp1_awaddr                 (   m_axil_isp[1].awaddr        ),
    .m_axil_isp1_awready                (   m_axil_isp[1].awready       ),
    .m_axil_isp1_awvalid                (   m_axil_isp[1].awvalid       ),
    .m_axil_isp1_bready                 (   m_axil_isp[1].bready        ),
    .m_axil_isp1_bresp                  (   m_axil_isp[1].bresp         ),
    .m_axil_isp1_bvalid                 (   m_axil_isp[1].bvalid        ),
    .m_axil_isp1_rdata                  (   m_axil_isp[1].rdata         ),
    .m_axil_isp1_rready                 (   m_axil_isp[1].rready        ),
    .m_axil_isp1_rresp                  (   m_axil_isp[1].rresp         ),
    .m_axil_isp1_rvalid                 (   m_axil_isp[1].rvalid        ),
    .m_axil_isp1_wdata                  (   m_axil_isp[1].wdata         ),
    .m_axil_isp1_wready                 (   m_axil_isp[1].wready        ),
    .m_axil_isp1_wstrb                  (   m_axil_isp[1].wstrb         ),
    .m_axil_isp1_wvalid                 (   m_axil_isp[1].wvalid        ),

    .m_axil_isp2_araddr                 (   m_axil_isp[2].araddr        ),
    .m_axil_isp2_arready                (   m_axil_isp[2].arready       ),
    .m_axil_isp2_arvalid                (   m_axil_isp[2].arvalid       ),
    .m_axil_isp2_awaddr                 (   m_axil_isp[2].awaddr        ),
    .m_axil_isp2_awready                (   m_axil_isp[2].awready       ),
    .m_axil_isp2_awvalid                (   m_axil_isp[2].awvalid       ),
    .m_axil_isp2_bready                 (   m_axil_isp[2].bready        ),
    .m_axil_isp2_bresp                  (   m_axil_isp[2].bresp         ),
    .m_axil_isp2_bvalid                 (   m_axil_isp[2].bvalid        ),
    .m_axil_isp2_rdata                  (   m_axil_isp[2].rdata         ),
    .m_axil_isp2_rready                 (   m_axil_isp[2].rready        ),
    .m_axil_isp2_rresp                  (   m_axil_isp[2].rresp         ),
    .m_axil_isp2_rvalid                 (   m_axil_isp[2].rvalid        ),
    .m_axil_isp2_wdata                  (   m_axil_isp[2].wdata         ),
    .m_axil_isp2_wready                 (   m_axil_isp[2].wready        ),
    .m_axil_isp2_wstrb                  (   m_axil_isp[2].wstrb         ),
    .m_axil_isp2_wvalid                 (   m_axil_isp[2].wvalid        ),

    .m_axil_isp3_araddr                 (   m_axil_isp[3].araddr        ),
    .m_axil_isp3_arready                (   m_axil_isp[3].arready       ),
    .m_axil_isp3_arvalid                (   m_axil_isp[3].arvalid       ),
    .m_axil_isp3_awaddr                 (   m_axil_isp[3].awaddr        ),
    .m_axil_isp3_awready                (   m_axil_isp[3].awready       ),
    .m_axil_isp3_awvalid                (   m_axil_isp[3].awvalid       ),
    .m_axil_isp3_bready                 (   m_axil_isp[3].bready        ),
    .m_axil_isp3_bresp                  (   m_axil_isp[3].bresp         ),
    .m_axil_isp3_bvalid                 (   m_axil_isp[3].bvalid        ),
    .m_axil_isp3_rdata                  (   m_axil_isp[3].rdata         ),
    .m_axil_isp3_rready                 (   m_axil_isp[3].rready        ),
    .m_axil_isp3_rresp                  (   m_axil_isp[3].rresp         ),
    .m_axil_isp3_rvalid                 (   m_axil_isp[3].rvalid        ),
    .m_axil_isp3_wdata                  (   m_axil_isp[3].wdata         ),
    .m_axil_isp3_wready                 (   m_axil_isp[3].wready        ),
    .m_axil_isp3_wstrb                  (   m_axil_isp[3].wstrb         ),
    .m_axil_isp3_wvalid                 (   m_axil_isp[3].wvalid        ),

    .m_axil_isp4_araddr                 (   m_axil_isp[4].araddr        ),
    .m_axil_isp4_arready                (   m_axil_isp[4].arready       ),
    .m_axil_isp4_arvalid                (   m_axil_isp[4].arvalid       ),
    .m_axil_isp4_awaddr                 (   m_axil_isp[4].awaddr        ),
    .m_axil_isp4_awready                (   m_axil_isp[4].awready       ),
    .m_axil_isp4_awvalid                (   m_axil_isp[4].awvalid       ),
    .m_axil_isp4_bready                 (   m_axil_isp[4].bready        ),
    .m_axil_isp4_bresp                  (   m_axil_isp[4].bresp         ),
    .m_axil_isp4_bvalid                 (   m_axil_isp[4].bvalid        ),
    .m_axil_isp4_rdata                  (   m_axil_isp[4].rdata         ),
    .m_axil_isp4_rready                 (   m_axil_isp[4].rready        ),
    .m_axil_isp4_rresp                  (   m_axil_isp[4].rresp         ),
    .m_axil_isp4_rvalid                 (   m_axil_isp[4].rvalid        ),
    .m_axil_isp4_wdata                  (   m_axil_isp[4].wdata         ),
    .m_axil_isp4_wready                 (   m_axil_isp[4].wready        ),
    .m_axil_isp4_wstrb                  (   m_axil_isp[4].wstrb         ),
    .m_axil_isp4_wvalid                 (   m_axil_isp[4].wvalid        ),

    .m_axil_isp5_araddr                 (   m_axil_isp[5].araddr        ),
    .m_axil_isp5_arready                (   m_axil_isp[5].arready       ),
    .m_axil_isp5_arvalid                (   m_axil_isp[5].arvalid       ),
    .m_axil_isp5_awaddr                 (   m_axil_isp[5].awaddr        ),
    .m_axil_isp5_awready                (   m_axil_isp[5].awready       ),
    .m_axil_isp5_awvalid                (   m_axil_isp[5].awvalid       ),
    .m_axil_isp5_bready                 (   m_axil_isp[5].bready        ),
    .m_axil_isp5_bresp                  (   m_axil_isp[5].bresp         ),
    .m_axil_isp5_bvalid                 (   m_axil_isp[5].bvalid        ),
    .m_axil_isp5_rdata                  (   m_axil_isp[5].rdata         ),
    .m_axil_isp5_rready                 (   m_axil_isp[5].rready        ),
    .m_axil_isp5_rresp                  (   m_axil_isp[5].rresp         ),
    .m_axil_isp5_rvalid                 (   m_axil_isp[5].rvalid        ),
    .m_axil_isp5_wdata                  (   m_axil_isp[5].wdata         ),
    .m_axil_isp5_wready                 (   m_axil_isp[5].wready        ),
    .m_axil_isp5_wstrb                  (   m_axil_isp[5].wstrb         ),
    .m_axil_isp5_wvalid                 (   m_axil_isp[5].wvalid        ),

    .m_axil_isp6_araddr                 (   m_axil_isp[6].araddr        ),
    .m_axil_isp6_arready                (   m_axil_isp[6].arready       ),
    .m_axil_isp6_arvalid                (   m_axil_isp[6].arvalid       ),
    .m_axil_isp6_awaddr                 (   m_axil_isp[6].awaddr        ),
    .m_axil_isp6_awready                (   m_axil_isp[6].awready       ),
    .m_axil_isp6_awvalid                (   m_axil_isp[6].awvalid       ),
    .m_axil_isp6_bready                 (   m_axil_isp[6].bready        ),
    .m_axil_isp6_bresp                  (   m_axil_isp[6].bresp         ),
    .m_axil_isp6_bvalid                 (   m_axil_isp[6].bvalid        ),
    .m_axil_isp6_rdata                  (   m_axil_isp[6].rdata         ),
    .m_axil_isp6_rready                 (   m_axil_isp[6].rready        ),
    .m_axil_isp6_rresp                  (   m_axil_isp[6].rresp         ),
    .m_axil_isp6_rvalid                 (   m_axil_isp[6].rvalid        ),
    .m_axil_isp6_wdata                  (   m_axil_isp[6].wdata         ),
    .m_axil_isp6_wready                 (   m_axil_isp[6].wready        ),
    .m_axil_isp6_wstrb                  (   m_axil_isp[6].wstrb         ),
    .m_axil_isp6_wvalid                 (   m_axil_isp[6].wvalid        ),

    .m_axil_isp7_araddr                 (   m_axil_isp[7].araddr        ),
    .m_axil_isp7_arready                (   m_axil_isp[7].arready       ),
    .m_axil_isp7_arvalid                (   m_axil_isp[7].arvalid       ),
    .m_axil_isp7_awaddr                 (   m_axil_isp[7].awaddr        ),
    .m_axil_isp7_awready                (   m_axil_isp[7].awready       ),
    .m_axil_isp7_awvalid                (   m_axil_isp[7].awvalid       ),
    .m_axil_isp7_bready                 (   m_axil_isp[7].bready        ),
    .m_axil_isp7_bresp                  (   m_axil_isp[7].bresp         ),
    .m_axil_isp7_bvalid                 (   m_axil_isp[7].bvalid        ),
    .m_axil_isp7_rdata                  (   m_axil_isp[7].rdata         ),
    .m_axil_isp7_rready                 (   m_axil_isp[7].rready        ),
    .m_axil_isp7_rresp                  (   m_axil_isp[7].rresp         ),
    .m_axil_isp7_rvalid                 (   m_axil_isp[7].rvalid        ),
    .m_axil_isp7_wdata                  (   m_axil_isp[7].wdata         ),
    .m_axil_isp7_wready                 (   m_axil_isp[7].wready        ),
    .m_axil_isp7_wstrb                  (   m_axil_isp[7].wstrb         ),
    .m_axil_isp7_wvalid                 (   m_axil_isp[7].wvalid        )

);

//----------------------------------------------------------------------------------------------
// Video output
//----------------------------------------------------------------------------------------------
(* mark_debug = "true" *)logic [23 : 0] video_data;
(* mark_debug = "true" *)logic video_en; 
(* mark_debug = "true" *)logic video_vs;
axis2video # (
    .DATA_WIDTH         (   24              ),
    .FIFO_DEEP          (   2048            ),
    .DEBUG              (   DEBUG           )
) u_video_vtc (
    .rst_n              (   clk_160M_rst_n              ),
    .clk                (   clk_160M                    ),
    .ACTIVE_WIDTH       (   16'd1280                    ),
    .ACTIVE_HEIGHT      (   16'd1024                    ),
    .s_axis_aclk        (   clk_160M                    ),
    .s_axis_tdata       (   m_video_out_axis.tdata      ),
    .s_axis_tlast       (   m_video_out_axis.tlast      ),
    .s_axis_tuser       (   m_video_out_axis.tuser      ),
    .s_axis_tvalid      (   m_video_out_axis.tvalid     ),
    .s_axis_tready      (   m_video_out_axis.tready     ),
    .dout               (   video_data                  ),
    .en_out             (   video_en                    ),
    .vs_out             (   video_vs                    ),
    .overflow           (                               ),
    .underflow          (                               )    
);





//----------------------------------------------------------------------------------------------
// Photo output
//----------------------------------------------------------------------------------------------
(* mark_debug = "true" *)logic [23 : 0] photo_data;
(* mark_debug = "true" *)logic photo_en;
(* mark_debug = "true" *)logic photo_hs;
(* mark_debug = "true" *)logic photo_vs;

axis2video_vtc_freerun # (
    .DATA_WIDTH         (   24              ),
    .FIFO_DEEP          (   8192            ),
    .DEBUG              (   DEBUG           )
) u_photo_vtc (
    .rst_n              (   clk_160M_rst_n              ),
    .clk                (   clk_160M                    ),
    .FIFO_FILL_LEN      (   16'd4096                    ),
    .ACTIVE_WIDTH       (   16'd4096                    ),
    .ACTIVE_HEIGHT      (   16'd3278                    ),
    .FRAME_WIDTH        (   16'd8000                    ),
    .FRAME_HEIGHT       (   16'd4000                    ),  
    .HBLK_HSTART        (   16'd200                     ),
    .VBLK_VSTART        (   16'd10                      ),
    .HSYNC_HSTART       (   16'd100                     ),
    .HSYNC_HEND         (   16'd5000                    ),
    .VSYNC_HSTART       (   16'd0                       ),
    .VSYNC_HEND         (   16'd0                       ),
    .VSYNC_VSTART       (   16'd9                       ),
    .VSYNC_VEND         (   16'd3500                    ),
    .s_axis_aclk        (   clk_160M                    ),
    .s_axis_tdata       (   m_photo_out_axis.tdata      ),
    .s_axis_tlast       (   m_photo_out_axis.tlast      ),
    .s_axis_tuser       (   m_photo_out_axis.tuser      ),
    .s_axis_tvalid      (   m_photo_out_axis.tvalid     ),
    .s_axis_tready      (   m_photo_out_axis.tready     ),
    .dout               (   photo_data                  ),
    .en_out             (   photo_en                    ),
    .hs_out             (   photo_hs                    ),
    .vs_out             (   photo_vs                    ),
    .overflow           (                               ),
    .underflow          (                               ),
    .axis_lock_out      (                               ),
    .lost_lock_out      (                               )
);
 


//----------------------------------------------------------------------------------------------
// SDI output
//----------------------------------------------------------------------------------------------

// logic [7:0] tpg_data;
// axis_tpg # (
//     .DATA_WIDTH     (   8                   ),
//     .CHESS_WPOW     (   4                   ),
//     .CHESS_HPOW     (   4                   ),
//     .DEBUG          (   DEBUG               )
// ) u_tpg (
//     .rst_n          (   !sdi_tx_usrrst          ),
//     .ACTIVE_WIDTH   (   16'd1920                ),
//     .ACTIVE_HEIGHT  (   16'd1080                ),
//     .tpg_mode       (   4'd1                    ),
//     .m_axis_aclk    (   sdi_tx_usrclk           ),
//     .m_axis_tdata   (   tpg_data                ),
//     .m_axis_tlast   (   m_preview_axis.tlast  ),
//     .m_axis_tuser   (   m_preview_axis.tuser  ),
//     .m_axis_tvalid  (   m_preview_axis.tvalid ),
//     .m_axis_tready  (   m_preview_axis.tready )
// );
// assign m_preview_axis.tdata = {8'h80, tpg_data};

// (* mark_debug = "true" *)logic [7:0] mark_video_axis_tdata ;
// (* mark_debug = "true" *)logic mark_video_axis_tlast ;
// (* mark_debug = "true" *)logic mark_video_axis_tuser ;
// (* mark_debug = "true" *)logic mark_video_axis_tvalid;
// (* mark_debug = "true" *)logic mark_video_axis_tready;

// assign mark_video_axis_tdata    = tpg_data;
// assign mark_video_axis_tlast    = m_preview_axis.tlast ;
// assign mark_video_axis_tuser    = m_preview_axis.tuser ;
// assign mark_video_axis_tvalid   = m_preview_axis.tvalid;
// assign mark_video_axis_tready   = m_preview_axis.tready;

//----------------------------------------------------------------------------------------------
// SDI output
//----------------------------------------------------------------------------------------------
wire mgtclk_148_5;
wire mgtclk_148_35;
wire clk_74_25_in;
wire clk_74_25;


logic sdi_tx_usrclk;
logic sdi_tx_usrrst;
logic tx_fabric_reset;
logic [9:0] sdi_y_data;
logic [9:0] sdi_c_data;
logic [15:0] sdi_line_data;

(* mark_debug = "true" *)logic [9:0] mark_sdi_y_data ;
(* mark_debug = "true" *)logic [9:0] mark_sdi_c_data ;
(* mark_debug = "true" *)logic [15:0] mark_sdi_line_data ;
assign mark_sdi_y_data      = sdi_y_data;
assign mark_sdi_c_data      = sdi_c_data;
assign mark_sdi_line_data   = sdi_line_data;


// assign clk_74M25 = clk_74_25;
IBUFDS_GTE2 MGTCLKIN0 (
    .I          (   i_sdi_gt_refclk0_p  ),
    .IB         (   i_sdi_gt_refclk0_n  ),
    .CEB        (   1'b0                ),
    .O          (   mgtclk_148_5        ),
    .ODIV2      (   clk_74_25_in        )
);

BUFG BUFG74_25 (
    .I          (   clk_74_25_in        ),
    .O          (   clk_74_25           )
);

IBUFDS_GTE2 MGTCLKIN1 (
    .I          (   i_sdi_gt_refclk1_p  ),
    .IB         (   i_sdi_gt_refclk1_n  ),
    .CEB        (   1'b0                ),
    .O          (   mgtclk_148_35       ),
    .ODIV2      (                       )
);

StmConvSmpte u_StmConvSmpte
(
    .i_rst                  (  sdi_tx_usrrst            ),
    .i_video_mode           (  3'd2                     ),//0:1080P24 1:1080P25 2:1080P30 3:1080P50 4:1080P60
    .s_axis                 (  m_preview_axis           ),
    .i_sdi_clk              (  sdi_tx_usrclk            ),
    .o_tx_sdi_data          (  {sdi_c_data,sdi_y_data}  ),
    .o_tx_sdi_line_number   (  sdi_line_data[10:0]      )
);

sdi_gt_top u_sdi_gt_top(
    // //--------MGT REFCLKs-------
    .mgtclk_148_5           (   mgtclk_148_5        ),    // 148.5 MHz clock from FMC board
    .mgtclk_148_35          (   mgtclk_148_35       ),    // 148.5 MHz clock from FMC board
    .clk_74_25              (   clk_74_25           ),

    .o_tx_clk               (   sdi_tx_usrclk       ),
    .o_tx_reset             (   sdi_tx_usrrst       ),
    .i_tx_line              (   sdi_line_data[10:0] ),
    .i_tx_c                 (   sdi_c_data          ),
    .i_tx_y                 (   sdi_y_data          ), 

    .i_tx_m                 (   1'b0                ),  // 0 = select 148.5 MHz refclk, 1 = select 148.35 MHz refclk
    .i_tx_mode              (   2'b00               ),  // 00 = HD,24/25/30HZ    10 = 3G,50/60HZ
    .i_framerate_sel        (   1'b1                ),  // 0 -- 25/50Hz, 1 -- 24/30/60Hz   

    .sdi_tx_p               (   sdi_txp             ),
    .sdi_tx_n               (   sdi_txn             ),
    .sdi_rx_p               (   sdi_rxp             ),
    .sdi_rx_n               (   sdi_rxn             )
);



//-------------------
//---system_wrapper  ---	
//-------------------
system_wrapper u_system_wrapper
(
    //-------------------			
    //PS			
    //-------------------			
    .DDR_addr							(	DDR_addr					),
    .DDR_ba								(	DDR_ba						),
    .DDR_cas_n							(	DDR_cas_n					),
    .DDR_ck_n							(	DDR_ck_n					),
    .DDR_ck_p							(	DDR_ck_p					),
    .DDR_cke							(	DDR_cke						),
    .DDR_cs_n							(	DDR_cs_n					),
    .DDR_dm								(	DDR_dm						),
    .DDR_dq								(	DDR_dq						),
    .DDR_dqs_n							(	DDR_dqs_n					),
    .DDR_dqs_p							(	DDR_dqs_p					),
    .DDR_odt							(	DDR_odt						),
    .DDR_ras_n							(	DDR_ras_n					),
    .DDR_reset_n						(	DDR_reset_n					),
    .DDR_we_n							(	DDR_we_n					),
            
    .FIXED_IO_ddr_vrn					(	FIXED_IO_ddr_vrn			),
    .FIXED_IO_ddr_vrp					(	FIXED_IO_ddr_vrp			),
    .FIXED_IO_mio						(	FIXED_IO_mio				),
    .FIXED_IO_ps_clk					(	FIXED_IO_ps_clk				),
    .FIXED_IO_ps_porb					(	FIXED_IO_ps_porb			),
    .FIXED_IO_ps_srstb					(	FIXED_IO_ps_srstb			),
    
    //-------------------			
    //PL DDR				
    //-------------------	
    // .ddr_ref_clk_n						(	i_ddr_clk_n					),
    // .ddr_ref_clk_p						(	i_ddr_clk_p					), 
    .DDR3_addr							(	DDR3_addr					),
    .DDR3_ba							(	DDR3_ba						),
    .DDR3_cas_n							(	DDR3_cas_n					),
    .DDR3_ck_n							(	DDR3_ck_n					),
    .DDR3_ck_p							(	DDR3_ck_p					),
    .DDR3_cke							(	DDR3_cke					),
    .DDR3_cs_n							(	DDR3_cs_n					),
    .DDR3_dm							(	DDR3_dm						),
    .DDR3_dq							(	DDR3_dq						),
    .DDR3_dqs_n							(	DDR3_dqs_n					),
    .DDR3_dqs_p							(	DDR3_dqs_p					),
    .DDR3_odt							(	DDR3_odt					),
    .DDR3_ras_n							(	DDR3_ras_n					),
    .DDR3_reset_n						(	DDR3_reset_n				),
    .DDR3_we_n							(	DDR3_we_n					),
    .init_calib_complete                (                               ),


    //-------------------
    //---Interrupt ------	
    //-------------------
    // .irq0_in                            (   bayer_s2mm_irq              ),
    // .irq1_in                            (   bayer_mm2s_irq              ),
    .irq2_in                            (   sen_vs                      ),
    .irq3_in                            (   yuyv_s2mm_irq               ),
    .irq4_in                            (   yuyv_mm2s_video_irq         ),
    .irq5_in                            (   yuyv_mm2s_photo_irq         ),
 

    //-------------------
    //---IIC ------	
    //-------------------
    .IIC_0_scl_io                       (   IIC_0_scl_io                ),
    .IIC_0_sda_io                       (   IIC_0_sda_io                ),
    // .IIC_1_scl_io                       (   IIC_1_scl_io                ),
    // .IIC_1_sda_io                       (   IIC_1_sda_io                ),


    //-------------------
    //---clock   ------	
    //-------------------	
    .clk_200M                           (   clk_200M                    ),
    .clk_160M                           (   clk_160M                    ),
    .clk_160M_rst_n                     (   clk_160M_rst_n              ),

 
    .clk_100M                           (	clk_100M                    ),
    .clk_100M_rst_n                     (	clk_100M_rst_n              ),

    //-------------------            
    // sensor spi            
    //-------------------            
    .sen_csn                            (   sen_csn                     ),
    .sen_sck                            (   sen_sck                     ),
    .sen_sdi                            (   sen_sdi                     ),
    .sen_sdo                            (   sen_sdo                     ),


    //-------------------
    //---axi mm   ------
    //-------------------
    .s_axi_isp0_araddr                  (   m_axi_isp[0].araddr         ),
    .s_axi_isp0_arburst                 (   m_axi_isp[0].arburst        ),
    .s_axi_isp0_arcache                 (   m_axi_isp[0].arcache        ),
    .s_axi_isp0_arlen                   (   m_axi_isp[0].arlen          ),
    .s_axi_isp0_arlock                  (   m_axi_isp[0].arlock         ),
    .s_axi_isp0_arprot                  (   m_axi_isp[0].arprot         ),
    .s_axi_isp0_arqos                   (   m_axi_isp[0].arqos          ),
    .s_axi_isp0_arready                 (   m_axi_isp[0].arready        ), 
    .s_axi_isp0_arsize                  (   m_axi_isp[0].arsize         ),
    .s_axi_isp0_arvalid                 (   m_axi_isp[0].arvalid        ),
    .s_axi_isp0_awaddr                  (   m_axi_isp[0].awaddr         ),
    .s_axi_isp0_awburst                 (   m_axi_isp[0].awburst        ),
    .s_axi_isp0_awcache                 (   m_axi_isp[0].awcache        ),
    .s_axi_isp0_awlen                   (   m_axi_isp[0].awlen          ),
    .s_axi_isp0_awlock                  (   m_axi_isp[0].awlock         ),
    .s_axi_isp0_awprot                  (   m_axi_isp[0].awprot         ),
    .s_axi_isp0_awqos                   (   m_axi_isp[0].awqos          ),
    .s_axi_isp0_awready                 (   m_axi_isp[0].awready        ), 
    .s_axi_isp0_awsize                  (   m_axi_isp[0].awsize         ),
    .s_axi_isp0_awvalid                 (   m_axi_isp[0].awvalid        ),
    .s_axi_isp0_bready                  (   m_axi_isp[0].bready         ),
    .s_axi_isp0_bresp                   (   m_axi_isp[0].bresp          ),
    .s_axi_isp0_bvalid                  (   m_axi_isp[0].bvalid         ),
    .s_axi_isp0_rdata                   (   m_axi_isp[0].rdata          ),
    .s_axi_isp0_rlast                   (   m_axi_isp[0].rlast          ),
    .s_axi_isp0_rready                  (   m_axi_isp[0].rready         ),
    .s_axi_isp0_rresp                   (   m_axi_isp[0].rresp          ),
    .s_axi_isp0_rvalid                  (   m_axi_isp[0].rvalid         ),
    .s_axi_isp0_wdata                   (   m_axi_isp[0].wdata          ),
    .s_axi_isp0_wlast                   (   m_axi_isp[0].wlast          ),
    .s_axi_isp0_wready                  (   m_axi_isp[0].wready         ),
    .s_axi_isp0_wstrb                   (   m_axi_isp[0].wstrb          ),
    .s_axi_isp0_wvalid                  (   m_axi_isp[0].wvalid         ),

    .s_axi_isp1_araddr                  (   m_axi_isp[1].araddr         ),
    .s_axi_isp1_arburst                 (   m_axi_isp[1].arburst        ),
    .s_axi_isp1_arcache                 (   m_axi_isp[1].arcache        ),
    .s_axi_isp1_arlen                   (   m_axi_isp[1].arlen          ),
    .s_axi_isp1_arlock                  (   m_axi_isp[1].arlock         ),
    .s_axi_isp1_arprot                  (   m_axi_isp[1].arprot         ),
    .s_axi_isp1_arqos                   (   m_axi_isp[1].arqos          ),
    .s_axi_isp1_arready                 (   m_axi_isp[1].arready        ), 
    .s_axi_isp1_arsize                  (   m_axi_isp[1].arsize         ),
    .s_axi_isp1_arvalid                 (   m_axi_isp[1].arvalid        ),
    .s_axi_isp1_awaddr                  (   m_axi_isp[1].awaddr         ),
    .s_axi_isp1_awburst                 (   m_axi_isp[1].awburst        ),
    .s_axi_isp1_awcache                 (   m_axi_isp[1].awcache        ),
    .s_axi_isp1_awlen                   (   m_axi_isp[1].awlen          ),
    .s_axi_isp1_awlock                  (   m_axi_isp[1].awlock         ),
    .s_axi_isp1_awprot                  (   m_axi_isp[1].awprot         ),
    .s_axi_isp1_awqos                   (   m_axi_isp[1].awqos          ),
    .s_axi_isp1_awready                 (   m_axi_isp[1].awready        ), 
    .s_axi_isp1_awsize                  (   m_axi_isp[1].awsize         ),
    .s_axi_isp1_awvalid                 (   m_axi_isp[1].awvalid        ),
    .s_axi_isp1_bready                  (   m_axi_isp[1].bready         ),
    .s_axi_isp1_bresp                   (   m_axi_isp[1].bresp          ),
    .s_axi_isp1_bvalid                  (   m_axi_isp[1].bvalid         ),
    .s_axi_isp1_rdata                   (   m_axi_isp[1].rdata          ),
    .s_axi_isp1_rlast                   (   m_axi_isp[1].rlast          ),
    .s_axi_isp1_rready                  (   m_axi_isp[1].rready         ),
    .s_axi_isp1_rresp                   (   m_axi_isp[1].rresp          ),
    .s_axi_isp1_rvalid                  (   m_axi_isp[1].rvalid         ),
    .s_axi_isp1_wdata                   (   m_axi_isp[1].wdata          ),
    .s_axi_isp1_wlast                   (   m_axi_isp[1].wlast          ),
    .s_axi_isp1_wready                  (   m_axi_isp[1].wready         ),
    .s_axi_isp1_wstrb                   (   m_axi_isp[1].wstrb          ),
    .s_axi_isp1_wvalid                  (   m_axi_isp[1].wvalid         ),

    .s_axi_isp2_araddr                  (   m_axi_isp[2].araddr         ),
    .s_axi_isp2_arburst                 (   m_axi_isp[2].arburst        ),
    .s_axi_isp2_arcache                 (   m_axi_isp[2].arcache        ),
    .s_axi_isp2_arlen                   (   m_axi_isp[2].arlen          ),
    .s_axi_isp2_arlock                  (   m_axi_isp[2].arlock         ),
    .s_axi_isp2_arprot                  (   m_axi_isp[2].arprot         ),
    .s_axi_isp2_arqos                   (   m_axi_isp[2].arqos          ),
    .s_axi_isp2_arready                 (   m_axi_isp[2].arready        ), 
    .s_axi_isp2_arsize                  (   m_axi_isp[2].arsize         ),
    .s_axi_isp2_arvalid                 (   m_axi_isp[2].arvalid        ),
    .s_axi_isp2_awaddr                  (   m_axi_isp[2].awaddr         ),
    .s_axi_isp2_awburst                 (   m_axi_isp[2].awburst        ),
    .s_axi_isp2_awcache                 (   m_axi_isp[2].awcache        ),
    .s_axi_isp2_awlen                   (   m_axi_isp[2].awlen          ),
    .s_axi_isp2_awlock                  (   m_axi_isp[2].awlock         ),
    .s_axi_isp2_awprot                  (   m_axi_isp[2].awprot         ),
    .s_axi_isp2_awqos                   (   m_axi_isp[2].awqos          ),
    .s_axi_isp2_awready                 (   m_axi_isp[2].awready        ), 
    .s_axi_isp2_awsize                  (   m_axi_isp[2].awsize         ),
    .s_axi_isp2_awvalid                 (   m_axi_isp[2].awvalid        ),
    .s_axi_isp2_bready                  (   m_axi_isp[2].bready         ),
    .s_axi_isp2_bresp                   (   m_axi_isp[2].bresp          ),
    .s_axi_isp2_bvalid                  (   m_axi_isp[2].bvalid         ),
    .s_axi_isp2_rdata                   (   m_axi_isp[2].rdata          ),
    .s_axi_isp2_rlast                   (   m_axi_isp[2].rlast          ),
    .s_axi_isp2_rready                  (   m_axi_isp[2].rready         ),
    .s_axi_isp2_rresp                   (   m_axi_isp[2].rresp          ),
    .s_axi_isp2_rvalid                  (   m_axi_isp[2].rvalid         ),
    .s_axi_isp2_wdata                   (   m_axi_isp[2].wdata          ),
    .s_axi_isp2_wlast                   (   m_axi_isp[2].wlast          ),
    .s_axi_isp2_wready                  (   m_axi_isp[2].wready         ),
    .s_axi_isp2_wstrb                   (   m_axi_isp[2].wstrb          ),
    .s_axi_isp2_wvalid                  (   m_axi_isp[2].wvalid         ),

    .s_axi_isp3_araddr                  (   m_axi_isp[3].araddr         ),
    .s_axi_isp3_arburst                 (   m_axi_isp[3].arburst        ),
    .s_axi_isp3_arcache                 (   m_axi_isp[3].arcache        ),
    .s_axi_isp3_arlen                   (   m_axi_isp[3].arlen          ),
    .s_axi_isp3_arlock                  (   m_axi_isp[3].arlock         ),
    .s_axi_isp3_arprot                  (   m_axi_isp[3].arprot         ),
    .s_axi_isp3_arqos                   (   m_axi_isp[3].arqos          ),
    .s_axi_isp3_arready                 (   m_axi_isp[3].arready        ), 
    .s_axi_isp3_arsize                  (   m_axi_isp[3].arsize         ),
    .s_axi_isp3_arvalid                 (   m_axi_isp[3].arvalid        ),
    .s_axi_isp3_awaddr                  (   m_axi_isp[3].awaddr         ),
    .s_axi_isp3_awburst                 (   m_axi_isp[3].awburst        ),
    .s_axi_isp3_awcache                 (   m_axi_isp[3].awcache        ),
    .s_axi_isp3_awlen                   (   m_axi_isp[3].awlen          ),
    .s_axi_isp3_awlock                  (   m_axi_isp[3].awlock         ),
    .s_axi_isp3_awprot                  (   m_axi_isp[3].awprot         ),
    .s_axi_isp3_awqos                   (   m_axi_isp[3].awqos          ),
    .s_axi_isp3_awready                 (   m_axi_isp[3].awready        ), 
    .s_axi_isp3_awsize                  (   m_axi_isp[3].awsize         ),
    .s_axi_isp3_awvalid                 (   m_axi_isp[3].awvalid        ),
    .s_axi_isp3_bready                  (   m_axi_isp[3].bready         ),
    .s_axi_isp3_bresp                   (   m_axi_isp[3].bresp          ),
    .s_axi_isp3_bvalid                  (   m_axi_isp[3].bvalid         ),
    .s_axi_isp3_rdata                   (   m_axi_isp[3].rdata          ),
    .s_axi_isp3_rlast                   (   m_axi_isp[3].rlast          ),
    .s_axi_isp3_rready                  (   m_axi_isp[3].rready         ),
    .s_axi_isp3_rresp                   (   m_axi_isp[3].rresp          ),
    .s_axi_isp3_rvalid                  (   m_axi_isp[3].rvalid         ),
    .s_axi_isp3_wdata                   (   m_axi_isp[3].wdata          ),
    .s_axi_isp3_wlast                   (   m_axi_isp[3].wlast          ),
    .s_axi_isp3_wready                  (   m_axi_isp[3].wready         ),
    .s_axi_isp3_wstrb                   (   m_axi_isp[3].wstrb          ),
    .s_axi_isp3_wvalid                  (   m_axi_isp[3].wvalid         ),

    .s_axi_isp4_araddr                  (   m_axi_isp[4].araddr         ),
    .s_axi_isp4_arburst                 (   m_axi_isp[4].arburst        ),
    .s_axi_isp4_arcache                 (   m_axi_isp[4].arcache        ),
    .s_axi_isp4_arlen                   (   m_axi_isp[4].arlen          ),
    .s_axi_isp4_arlock                  (   m_axi_isp[4].arlock         ),
    .s_axi_isp4_arprot                  (   m_axi_isp[4].arprot         ),
    .s_axi_isp4_arqos                   (   m_axi_isp[4].arqos          ),
    .s_axi_isp4_arready                 (   m_axi_isp[4].arready        ), 
    .s_axi_isp4_arsize                  (   m_axi_isp[4].arsize         ),
    .s_axi_isp4_arvalid                 (   m_axi_isp[4].arvalid        ),
    .s_axi_isp4_awaddr                  (   m_axi_isp[4].awaddr         ),
    .s_axi_isp4_awburst                 (   m_axi_isp[4].awburst        ),
    .s_axi_isp4_awcache                 (   m_axi_isp[4].awcache        ),
    .s_axi_isp4_awlen                   (   m_axi_isp[4].awlen          ),
    .s_axi_isp4_awlock                  (   m_axi_isp[4].awlock         ),
    .s_axi_isp4_awprot                  (   m_axi_isp[4].awprot         ),
    .s_axi_isp4_awqos                   (   m_axi_isp[4].awqos          ),
    .s_axi_isp4_awready                 (   m_axi_isp[4].awready        ), 
    .s_axi_isp4_awsize                  (   m_axi_isp[4].awsize         ),
    .s_axi_isp4_awvalid                 (   m_axi_isp[4].awvalid        ),
    .s_axi_isp4_bready                  (   m_axi_isp[4].bready         ),
    .s_axi_isp4_bresp                   (   m_axi_isp[4].bresp          ),
    .s_axi_isp4_bvalid                  (   m_axi_isp[4].bvalid         ),
    .s_axi_isp4_rdata                   (   m_axi_isp[4].rdata          ),
    .s_axi_isp4_rlast                   (   m_axi_isp[4].rlast          ),
    .s_axi_isp4_rready                  (   m_axi_isp[4].rready         ),
    .s_axi_isp4_rresp                   (   m_axi_isp[4].rresp          ),
    .s_axi_isp4_rvalid                  (   m_axi_isp[4].rvalid         ),
    .s_axi_isp4_wdata                   (   m_axi_isp[4].wdata          ),
    .s_axi_isp4_wlast                   (   m_axi_isp[4].wlast          ),
    .s_axi_isp4_wready                  (   m_axi_isp[4].wready         ),
    .s_axi_isp4_wstrb                   (   m_axi_isp[4].wstrb          ),
    .s_axi_isp4_wvalid                  (   m_axi_isp[4].wvalid         ),

    .s_axi_isp5_araddr                  (   m_axi_isp[5].araddr         ),
    .s_axi_isp5_arburst                 (   m_axi_isp[5].arburst        ),
    .s_axi_isp5_arcache                 (   m_axi_isp[5].arcache        ),
    .s_axi_isp5_arlen                   (   m_axi_isp[5].arlen          ),
    .s_axi_isp5_arlock                  (   m_axi_isp[5].arlock         ),
    .s_axi_isp5_arprot                  (   m_axi_isp[5].arprot         ),
    .s_axi_isp5_arqos                   (   m_axi_isp[5].arqos          ),
    .s_axi_isp5_arready                 (   m_axi_isp[5].arready        ), 
    .s_axi_isp5_arsize                  (   m_axi_isp[5].arsize         ),
    .s_axi_isp5_arvalid                 (   m_axi_isp[5].arvalid        ),
    .s_axi_isp5_awaddr                  (   m_axi_isp[5].awaddr         ),
    .s_axi_isp5_awburst                 (   m_axi_isp[5].awburst        ),
    .s_axi_isp5_awcache                 (   m_axi_isp[5].awcache        ),
    .s_axi_isp5_awlen                   (   m_axi_isp[5].awlen          ),
    .s_axi_isp5_awlock                  (   m_axi_isp[5].awlock         ),
    .s_axi_isp5_awprot                  (   m_axi_isp[5].awprot         ),
    .s_axi_isp5_awqos                   (   m_axi_isp[5].awqos          ),
    .s_axi_isp5_awready                 (   m_axi_isp[5].awready        ), 
    .s_axi_isp5_awsize                  (   m_axi_isp[5].awsize         ),
    .s_axi_isp5_awvalid                 (   m_axi_isp[5].awvalid        ),
    .s_axi_isp5_bready                  (   m_axi_isp[5].bready         ),
    .s_axi_isp5_bresp                   (   m_axi_isp[5].bresp          ),
    .s_axi_isp5_bvalid                  (   m_axi_isp[5].bvalid         ),
    .s_axi_isp5_rdata                   (   m_axi_isp[5].rdata          ),
    .s_axi_isp5_rlast                   (   m_axi_isp[5].rlast          ),
    .s_axi_isp5_rready                  (   m_axi_isp[5].rready         ),
    .s_axi_isp5_rresp                   (   m_axi_isp[5].rresp          ),
    .s_axi_isp5_rvalid                  (   m_axi_isp[5].rvalid         ),
    .s_axi_isp5_wdata                   (   m_axi_isp[5].wdata          ),
    .s_axi_isp5_wlast                   (   m_axi_isp[5].wlast          ),
    .s_axi_isp5_wready                  (   m_axi_isp[5].wready         ),
    .s_axi_isp5_wstrb                   (   m_axi_isp[5].wstrb          ),
    .s_axi_isp5_wvalid                  (   m_axi_isp[5].wvalid         ),

    .s_axi_isp6_araddr                  (   m_axi_isp[6].araddr         ),
    .s_axi_isp6_arburst                 (   m_axi_isp[6].arburst        ),
    .s_axi_isp6_arcache                 (   m_axi_isp[6].arcache        ),
    .s_axi_isp6_arlen                   (   m_axi_isp[6].arlen          ),
    .s_axi_isp6_arlock                  (   m_axi_isp[6].arlock         ),
    .s_axi_isp6_arprot                  (   m_axi_isp[6].arprot         ),
    .s_axi_isp6_arqos                   (   m_axi_isp[6].arqos          ),
    .s_axi_isp6_arready                 (   m_axi_isp[6].arready        ), 
    .s_axi_isp6_arsize                  (   m_axi_isp[6].arsize         ),
    .s_axi_isp6_arvalid                 (   m_axi_isp[6].arvalid        ),
    .s_axi_isp6_awaddr                  (   m_axi_isp[6].awaddr         ),
    .s_axi_isp6_awburst                 (   m_axi_isp[6].awburst        ),
    .s_axi_isp6_awcache                 (   m_axi_isp[6].awcache        ),
    .s_axi_isp6_awlen                   (   m_axi_isp[6].awlen          ),
    .s_axi_isp6_awlock                  (   m_axi_isp[6].awlock         ),
    .s_axi_isp6_awprot                  (   m_axi_isp[6].awprot         ),
    .s_axi_isp6_awqos                   (   m_axi_isp[6].awqos          ),
    .s_axi_isp6_awready                 (   m_axi_isp[6].awready        ), 
    .s_axi_isp6_awsize                  (   m_axi_isp[6].awsize         ),
    .s_axi_isp6_awvalid                 (   m_axi_isp[6].awvalid        ),
    .s_axi_isp6_bready                  (   m_axi_isp[6].bready         ),
    .s_axi_isp6_bresp                   (   m_axi_isp[6].bresp          ),
    .s_axi_isp6_bvalid                  (   m_axi_isp[6].bvalid         ),
    .s_axi_isp6_rdata                   (   m_axi_isp[6].rdata          ),
    .s_axi_isp6_rlast                   (   m_axi_isp[6].rlast          ),
    .s_axi_isp6_rready                  (   m_axi_isp[6].rready         ),
    .s_axi_isp6_rresp                   (   m_axi_isp[6].rresp          ),
    .s_axi_isp6_rvalid                  (   m_axi_isp[6].rvalid         ),
    .s_axi_isp6_wdata                   (   m_axi_isp[6].wdata          ),
    .s_axi_isp6_wlast                   (   m_axi_isp[6].wlast          ),
    .s_axi_isp6_wready                  (   m_axi_isp[6].wready         ),
    .s_axi_isp6_wstrb                   (   m_axi_isp[6].wstrb          ),
    .s_axi_isp6_wvalid                  (   m_axi_isp[6].wvalid         ),
 

    // //-------------------
    // //---axi lite   ------	
    // //-------------------	
    .m_axil0_araddr                     (   m_axilite[0].araddr         ),
    .m_axil0_arready                    (   m_axilite[0].arready        ),
    .m_axil0_arvalid                    (   m_axilite[0].arvalid        ),
    .m_axil0_awaddr                     (   m_axilite[0].awaddr         ),
    .m_axil0_awready                    (   m_axilite[0].awready        ),
    .m_axil0_awvalid                    (   m_axilite[0].awvalid        ),
    .m_axil0_bready                     (   m_axilite[0].bready         ),
    .m_axil0_bresp                      (   m_axilite[0].bresp          ),
    .m_axil0_bvalid                     (   m_axilite[0].bvalid         ),
    .m_axil0_rdata                      (   m_axilite[0].rdata          ),
    .m_axil0_rready                     (   m_axilite[0].rready         ),
    .m_axil0_rresp                      (   m_axilite[0].rresp          ),
    .m_axil0_rvalid                     (   m_axilite[0].rvalid         ),
    .m_axil0_wdata                      (   m_axilite[0].wdata          ),
    .m_axil0_wready                     (   m_axilite[0].wready         ),
    .m_axil0_wstrb                      (   m_axilite[0].wstrb          ),
    .m_axil0_wvalid                     (   m_axilite[0].wvalid         ),

    .m_axil1_araddr						(	m_axilite[1].araddr		    ),
    .m_axil1_arready					(	m_axilite[1].arready		),
    .m_axil1_arvalid					(	m_axilite[1].arvalid		),
    .m_axil1_awaddr						(	m_axilite[1].awaddr		    ),
    .m_axil1_awready					(	m_axilite[1].awready		),
    .m_axil1_awvalid					(	m_axilite[1].awvalid		),
    .m_axil1_bready						(	m_axilite[1].bready		    ),
    .m_axil1_bresp						(	m_axilite[1].bresp			),
    .m_axil1_bvalid						(	m_axilite[1].bvalid		    ),
    .m_axil1_rdata						(	m_axilite[1].rdata			),
    .m_axil1_rready						(	m_axilite[1].rready		    ),
    .m_axil1_rresp						(	m_axilite[1].rresp			),
    .m_axil1_rvalid						(	m_axilite[1].rvalid		    ),
    .m_axil1_wdata						(	m_axilite[1].wdata			),
    .m_axil1_wready						(	m_axilite[1].wready		    ),
    .m_axil1_wstrb						(	m_axilite[1].wstrb			),
    .m_axil1_wvalid						(	m_axilite[1].wvalid		    ),

    .m_axil2_araddr						(	m_axilite[2].araddr		    ),
    .m_axil2_arready					(	m_axilite[2].arready		),
    .m_axil2_arvalid					(	m_axilite[2].arvalid		),
    .m_axil2_awaddr						(	m_axilite[2].awaddr		    ),
    .m_axil2_awready					(	m_axilite[2].awready		),
    .m_axil2_awvalid					(	m_axilite[2].awvalid		),
    .m_axil2_bready						(	m_axilite[2].bready		    ),
    .m_axil2_bresp						(	m_axilite[2].bresp			),
    .m_axil2_bvalid						(	m_axilite[2].bvalid		    ),
    .m_axil2_rdata						(	m_axilite[2].rdata			),
    .m_axil2_rready						(	m_axilite[2].rready		    ),
    .m_axil2_rresp						(	m_axilite[2].rresp			),
    .m_axil2_rvalid						(	m_axilite[2].rvalid		    ),
    .m_axil2_wdata						(	m_axilite[2].wdata			),
    .m_axil2_wready						(	m_axilite[2].wready		    ),
    .m_axil2_wstrb						(	m_axilite[2].wstrb			),
    .m_axil2_wvalid						(	m_axilite[2].wvalid		    ),

    .m_axil3_araddr						(	m_axilite[3].araddr		    ),
    .m_axil3_arready					(	m_axilite[3].arready		),
    .m_axil3_arvalid					(	m_axilite[3].arvalid		),
    .m_axil3_awaddr						(	m_axilite[3].awaddr		    ),
    .m_axil3_awready					(	m_axilite[3].awready		),
    .m_axil3_awvalid					(	m_axilite[3].awvalid		),
    .m_axil3_bready						(	m_axilite[3].bready		    ),
    .m_axil3_bresp						(	m_axilite[3].bresp			),
    .m_axil3_bvalid						(	m_axilite[3].bvalid		    ),
    .m_axil3_rdata						(	m_axilite[3].rdata			),
    .m_axil3_rready						(	m_axilite[3].rready		    ),
    .m_axil3_rresp						(	m_axilite[3].rresp			),
    .m_axil3_rvalid						(	m_axilite[3].rvalid		    ),
    .m_axil3_wdata						(	m_axilite[3].wdata			),
    .m_axil3_wready						(	m_axilite[3].wready		    ),
    .m_axil3_wstrb						(	m_axilite[3].wstrb			),
    .m_axil3_wvalid						(	m_axilite[3].wvalid		    ),


    //-------------------
    //---axi lite   ------
    //-------------------
    .m_axil_isp0_araddr                 (   m_axil_isp[0].araddr        ),
    .m_axil_isp0_arready                (   m_axil_isp[0].arready       ),
    .m_axil_isp0_arvalid                (   m_axil_isp[0].arvalid       ),
    .m_axil_isp0_awaddr                 (   m_axil_isp[0].awaddr        ),
    .m_axil_isp0_awready                (   m_axil_isp[0].awready       ),
    .m_axil_isp0_awvalid                (   m_axil_isp[0].awvalid       ),
    .m_axil_isp0_bready                 (   m_axil_isp[0].bready        ),
    .m_axil_isp0_bresp                  (   m_axil_isp[0].bresp         ),
    .m_axil_isp0_bvalid                 (   m_axil_isp[0].bvalid        ),
    .m_axil_isp0_rdata                  (   m_axil_isp[0].rdata         ),
    .m_axil_isp0_rready                 (   m_axil_isp[0].rready        ),
    .m_axil_isp0_rresp                  (   m_axil_isp[0].rresp         ),
    .m_axil_isp0_rvalid                 (   m_axil_isp[0].rvalid        ),
    .m_axil_isp0_wdata                  (   m_axil_isp[0].wdata         ),
    .m_axil_isp0_wready                 (   m_axil_isp[0].wready        ),
    .m_axil_isp0_wstrb                  (   m_axil_isp[0].wstrb         ),
    .m_axil_isp0_wvalid                 (   m_axil_isp[0].wvalid        ),

    .m_axil_isp1_araddr                 (   m_axil_isp[1].araddr        ),
    .m_axil_isp1_arready                (   m_axil_isp[1].arready       ),
    .m_axil_isp1_arvalid                (   m_axil_isp[1].arvalid       ),
    .m_axil_isp1_awaddr                 (   m_axil_isp[1].awaddr        ),
    .m_axil_isp1_awready                (   m_axil_isp[1].awready       ),
    .m_axil_isp1_awvalid                (   m_axil_isp[1].awvalid       ),
    .m_axil_isp1_bready                 (   m_axil_isp[1].bready        ),
    .m_axil_isp1_bresp                  (   m_axil_isp[1].bresp         ),
    .m_axil_isp1_bvalid                 (   m_axil_isp[1].bvalid        ),
    .m_axil_isp1_rdata                  (   m_axil_isp[1].rdata         ),
    .m_axil_isp1_rready                 (   m_axil_isp[1].rready        ),
    .m_axil_isp1_rresp                  (   m_axil_isp[1].rresp         ),
    .m_axil_isp1_rvalid                 (   m_axil_isp[1].rvalid        ),
    .m_axil_isp1_wdata                  (   m_axil_isp[1].wdata         ),
    .m_axil_isp1_wready                 (   m_axil_isp[1].wready        ),
    .m_axil_isp1_wstrb                  (   m_axil_isp[1].wstrb         ),
    .m_axil_isp1_wvalid                 (   m_axil_isp[1].wvalid        ),

    .m_axil_isp2_araddr                 (   m_axil_isp[2].araddr        ),
    .m_axil_isp2_arready                (   m_axil_isp[2].arready       ),
    .m_axil_isp2_arvalid                (   m_axil_isp[2].arvalid       ),
    .m_axil_isp2_awaddr                 (   m_axil_isp[2].awaddr        ),
    .m_axil_isp2_awready                (   m_axil_isp[2].awready       ),
    .m_axil_isp2_awvalid                (   m_axil_isp[2].awvalid       ),
    .m_axil_isp2_bready                 (   m_axil_isp[2].bready        ),
    .m_axil_isp2_bresp                  (   m_axil_isp[2].bresp         ),
    .m_axil_isp2_bvalid                 (   m_axil_isp[2].bvalid        ),
    .m_axil_isp2_rdata                  (   m_axil_isp[2].rdata         ),
    .m_axil_isp2_rready                 (   m_axil_isp[2].rready        ),
    .m_axil_isp2_rresp                  (   m_axil_isp[2].rresp         ),
    .m_axil_isp2_rvalid                 (   m_axil_isp[2].rvalid        ),
    .m_axil_isp2_wdata                  (   m_axil_isp[2].wdata         ),
    .m_axil_isp2_wready                 (   m_axil_isp[2].wready        ),
    .m_axil_isp2_wstrb                  (   m_axil_isp[2].wstrb         ),
    .m_axil_isp2_wvalid                 (   m_axil_isp[2].wvalid        ),

    .m_axil_isp3_araddr                 (   m_axil_isp[3].araddr        ),
    .m_axil_isp3_arready                (   m_axil_isp[3].arready       ),
    .m_axil_isp3_arvalid                (   m_axil_isp[3].arvalid       ),
    .m_axil_isp3_awaddr                 (   m_axil_isp[3].awaddr        ),
    .m_axil_isp3_awready                (   m_axil_isp[3].awready       ),
    .m_axil_isp3_awvalid                (   m_axil_isp[3].awvalid       ),
    .m_axil_isp3_bready                 (   m_axil_isp[3].bready        ),
    .m_axil_isp3_bresp                  (   m_axil_isp[3].bresp         ),
    .m_axil_isp3_bvalid                 (   m_axil_isp[3].bvalid        ),
    .m_axil_isp3_rdata                  (   m_axil_isp[3].rdata         ),
    .m_axil_isp3_rready                 (   m_axil_isp[3].rready        ),
    .m_axil_isp3_rresp                  (   m_axil_isp[3].rresp         ),
    .m_axil_isp3_rvalid                 (   m_axil_isp[3].rvalid        ),
    .m_axil_isp3_wdata                  (   m_axil_isp[3].wdata         ),
    .m_axil_isp3_wready                 (   m_axil_isp[3].wready        ),
    .m_axil_isp3_wstrb                  (   m_axil_isp[3].wstrb         ),
    .m_axil_isp3_wvalid                 (   m_axil_isp[3].wvalid        ),

    .m_axil_isp4_araddr                 (   m_axil_isp[4].araddr        ),
    .m_axil_isp4_arready                (   m_axil_isp[4].arready       ),
    .m_axil_isp4_arvalid                (   m_axil_isp[4].arvalid       ),
    .m_axil_isp4_awaddr                 (   m_axil_isp[4].awaddr        ),
    .m_axil_isp4_awready                (   m_axil_isp[4].awready       ),
    .m_axil_isp4_awvalid                (   m_axil_isp[4].awvalid       ),
    .m_axil_isp4_bready                 (   m_axil_isp[4].bready        ),
    .m_axil_isp4_bresp                  (   m_axil_isp[4].bresp         ),
    .m_axil_isp4_bvalid                 (   m_axil_isp[4].bvalid        ),
    .m_axil_isp4_rdata                  (   m_axil_isp[4].rdata         ),
    .m_axil_isp4_rready                 (   m_axil_isp[4].rready        ),
    .m_axil_isp4_rresp                  (   m_axil_isp[4].rresp         ),
    .m_axil_isp4_rvalid                 (   m_axil_isp[4].rvalid        ),
    .m_axil_isp4_wdata                  (   m_axil_isp[4].wdata         ),
    .m_axil_isp4_wready                 (   m_axil_isp[4].wready        ),
    .m_axil_isp4_wstrb                  (   m_axil_isp[4].wstrb         ),
    .m_axil_isp4_wvalid                 (   m_axil_isp[4].wvalid        ),

    .m_axil_isp5_araddr                 (   m_axil_isp[5].araddr        ),
    .m_axil_isp5_arready                (   m_axil_isp[5].arready       ),
    .m_axil_isp5_arvalid                (   m_axil_isp[5].arvalid       ),
    .m_axil_isp5_awaddr                 (   m_axil_isp[5].awaddr        ),
    .m_axil_isp5_awready                (   m_axil_isp[5].awready       ),
    .m_axil_isp5_awvalid                (   m_axil_isp[5].awvalid       ),
    .m_axil_isp5_bready                 (   m_axil_isp[5].bready        ),
    .m_axil_isp5_bresp                  (   m_axil_isp[5].bresp         ),
    .m_axil_isp5_bvalid                 (   m_axil_isp[5].bvalid        ),
    .m_axil_isp5_rdata                  (   m_axil_isp[5].rdata         ),
    .m_axil_isp5_rready                 (   m_axil_isp[5].rready        ),
    .m_axil_isp5_rresp                  (   m_axil_isp[5].rresp         ),
    .m_axil_isp5_rvalid                 (   m_axil_isp[5].rvalid        ),
    .m_axil_isp5_wdata                  (   m_axil_isp[5].wdata         ),
    .m_axil_isp5_wready                 (   m_axil_isp[5].wready        ),
    .m_axil_isp5_wstrb                  (   m_axil_isp[5].wstrb         ),
    .m_axil_isp5_wvalid                 (   m_axil_isp[5].wvalid        ),

    .m_axil_isp6_araddr                 (   m_axil_isp[6].araddr        ),
    .m_axil_isp6_arready                (   m_axil_isp[6].arready       ),
    .m_axil_isp6_arvalid                (   m_axil_isp[6].arvalid       ),
    .m_axil_isp6_awaddr                 (   m_axil_isp[6].awaddr        ),
    .m_axil_isp6_awready                (   m_axil_isp[6].awready       ),
    .m_axil_isp6_awvalid                (   m_axil_isp[6].awvalid       ),
    .m_axil_isp6_bready                 (   m_axil_isp[6].bready        ),
    .m_axil_isp6_bresp                  (   m_axil_isp[6].bresp         ),
    .m_axil_isp6_bvalid                 (   m_axil_isp[6].bvalid        ),
    .m_axil_isp6_rdata                  (   m_axil_isp[6].rdata         ),
    .m_axil_isp6_rready                 (   m_axil_isp[6].rready        ),
    .m_axil_isp6_rresp                  (   m_axil_isp[6].rresp         ),
    .m_axil_isp6_rvalid                 (   m_axil_isp[6].rvalid        ),
    .m_axil_isp6_wdata                  (   m_axil_isp[6].wdata         ),
    .m_axil_isp6_wready                 (   m_axil_isp[6].wready        ),
    .m_axil_isp6_wstrb                  (   m_axil_isp[6].wstrb         ),
    .m_axil_isp6_wvalid                 (   m_axil_isp[6].wvalid        ),

    .m_axil_isp7_araddr                 (   m_axil_isp[7].araddr        ),
    .m_axil_isp7_arready                (   m_axil_isp[7].arready       ),
    .m_axil_isp7_arvalid                (   m_axil_isp[7].arvalid       ),
    .m_axil_isp7_awaddr                 (   m_axil_isp[7].awaddr        ),
    .m_axil_isp7_awready                (   m_axil_isp[7].awready       ),
    .m_axil_isp7_awvalid                (   m_axil_isp[7].awvalid       ),
    .m_axil_isp7_bready                 (   m_axil_isp[7].bready        ),
    .m_axil_isp7_bresp                  (   m_axil_isp[7].bresp         ),
    .m_axil_isp7_bvalid                 (   m_axil_isp[7].bvalid        ),
    .m_axil_isp7_rdata                  (   m_axil_isp[7].rdata         ),
    .m_axil_isp7_rready                 (   m_axil_isp[7].rready        ),
    .m_axil_isp7_rresp                  (   m_axil_isp[7].rresp         ),
    .m_axil_isp7_rvalid                 (   m_axil_isp[7].rvalid        ),
    .m_axil_isp7_wdata                  (   m_axil_isp[7].wdata         ),
    .m_axil_isp7_wready                 (   m_axil_isp[7].wready        ),
    .m_axil_isp7_wstrb                  (   m_axil_isp[7].wstrb         ),
    .m_axil_isp7_wvalid                 (   m_axil_isp[7].wvalid        )

                
);


endmodule