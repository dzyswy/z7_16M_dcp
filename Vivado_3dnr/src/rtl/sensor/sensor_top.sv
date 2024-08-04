`timescale 1ns/1ps

module sensor_top # (
    parameter real  REF_FREQ        = 200.0, 
    parameter       DIFF_TERM       = "FALSE",      // Enable internal LVDS termination 
    parameter       DEBUG           = "FALSE"
) (
    //------------------------------------------------
    // Axi Port
    //------------------------------------------------
    axi_lite_if.s                       s_axil,

    //------------------------------------------------
    // Control Port
    //------------------------------------------------
    output              sen_poweren,
    output              sen_inclk_en,
    output              sen_sysrstn,
    output              sen_sysstbn,

    input               sen_exp_in,


    //------------------------------------------------
    // LVDS Port
    //------------------------------------------------
    input               refclkin, 
    input               sen_clkin_p,
    input               sen_clkin_n,
    input   [15:0]      sen_datain_p,
    input   [15:0]      sen_datain_n,

    output              sen_reset,
    output              sen_clk,
    output  [191:0]     sen_dout,
    output              sen_en_out,
    output              sen_vs_out 
);


logic    [s_axil.DW - 1 : 0]                s_cfg_wr_data;
logic                                       s_cfg_wr_en;
logic    [s_axil.AW - 1 : 0]                s_cfg_addr;
logic                                       s_cfg_rd_en;
logic                                       s_cfg_rd_vld;
logic    [s_axil.DW - 1 : 0]                s_cfg_rd_data;
logic                                       s_cfg_busy;


logic                idelay_rdy;





//------------------------------------------------------------------------------------------------
// Module Name : axi_conv_cfg                                                                     
// Description : lite总线转标准读写接                                                                                 
//------------------------------------------------------------------------------------------------
axi_conv_cfg # (
    .CFG_DATA_WIDTH     (   s_axil.DW               ),
    .CFG_ADDR_WIDTH     (   s_axil.AW               ),
    .AXI_ADDR_WIDTH     (   s_axil.AW               ),
    .AXI_DATA_WIDTH     (   s_axil.DW               ), 
    .SIM                (                           ),
    .DEBUG              (                           )
) u_axi_conv_cfg (
    .i_axi_clk          (   s_axil.clk              ),
    .i_axi_rst          (   ~s_axil.rstn            ),        
    .s_axi_araddr       (   s_axil.araddr           ),
    .s_axi_arready      (   s_axil.arready          ),
    .s_axi_arvalid      (   s_axil.arvalid          ),            
    .s_axi_awaddr       (   s_axil.awaddr           ),
    .s_axi_awready      (   s_axil.awready          ),
    .s_axi_awvalid      (   s_axil.awvalid          ),         
    .s_axi_bready       (   s_axil.bready           ),
    .s_axi_bresp        (   s_axil.bresp            ),
    .s_axi_bvalid       (   s_axil.bvalid           ),     
    .s_axi_rdata        (   s_axil.rdata            ),
    .s_axi_rready       (   s_axil.rready           ),
    .s_axi_rresp        (   s_axil.rresp            ),
    .s_axi_rvalid       (   s_axil.rvalid           ),     
    .s_axi_wdata        (   s_axil.wdata            ),
    .s_axi_wready       (   s_axil.wready           ),
    .s_axi_wstrb        (   s_axil.wstrb            ),
    .s_axi_wvalid       (   s_axil.wvalid           ),
    

    .m_cfg_wr_en        (   s_cfg_wr_en             ),//output 
    .m_cfg_addr         (   s_cfg_addr              ),//output 31:0
    .m_cfg_wr_data      (   s_cfg_wr_data           ),//output 31:0
    .m_cfg_rd_en        (   s_cfg_rd_en             ),//output 
    .m_cfg_rd_vld       (   s_cfg_rd_vld            ),//input 
    .m_cfg_rd_data      (   s_cfg_rd_data           ),//input 31:0
    .m_cfg_busy         (   s_cfg_busy              )
);


//------------------------------------------------------------------------------------------------
// Module Name : vtc_cfg                                                              
// Description : axi lite总线信号解析                                                                                 
//------------------------------------------------------------------------------------------------
logic senvtc_reset;
logic serdes_reset;
logic [15 : 0] ACTIVE_WIDTH  ;
logic [15 : 0] ACTIVE_HEIGHT ;
logic [15 : 0] FRAME_WIDTH   ;
logic [15 : 0] FRAME_HEIGHT  ; 
logic [47:0] SOF_PATTERN   ;
logic [47:0] SOL_PATTERN   ;
logic [47:0] EOL_PATTERN   ;
logic [47:0] EOF_PATTERN   ;

logic [15:0] CHECK_SEARCH_LINE ;
logic [15:0] CHECK_PATTERN_NUM ;
logic [7:0] EYE_RANGE         ;
logic SERDES_BIT_REVERSE;
logic [7:0] SERDES_SLIP_NUM   ;
logic [7:0] SERDES_DELAY_NUM  ;
logic SERDES_MANUL_MODE ;
logic serdes_start             ;
logic stream_on             ;
logic sen_lock      ;
logic sen_done      ;
logic [31:0] stats_exp_time  ;
logic [31:0] stats_gray_sum_L;
logic [31:0] stats_gray_sum_H;

sensor_top_cfg # (
    .CFG_DATA_WIDTH     (   s_axil.DW               ),
    .CFG_ADDR_WIDTH     (   s_axil.AW               ), 
    .DEBUG              (   DEBUG                  ) //"TRUE"
) u_axil_cfg (
    .i_cfg_clk          (   s_axil.clk              ),//input 
    .i_cfg_rst          (   ~s_axil.rstn            ),//input 
    .s_cfg_wr_en        (   s_cfg_wr_en             ),//input 
    .s_cfg_wr_data      (   s_cfg_wr_data           ),//input CFG_DATA_WIDTH - 1:0
    .s_cfg_addr         (   s_cfg_addr              ),//input CFG_ADDR_WIDTH - 1:0
    .s_cfg_rd_en        (   s_cfg_rd_en             ),//input 
    .s_cfg_rd_vld       (   s_cfg_rd_vld            ),//output 
    .s_cfg_rd_data      (   s_cfg_rd_data           ),//output CFG_DATA_WIDTH - 1:0
    .s_cfg_busy         (   s_cfg_busy              ),//output 

    .o_senvtc_reset         (   senvtc_reset        ),
    .o_serdes_reset         (   serdes_reset        ),
    .o_sen_poweren          (   sen_poweren         ),
    .o_sen_inclk_en         (   sen_inclk_en        ),
    .o_sen_sysrstn          (   sen_sysrstn         ),
    .o_sen_sysstbn          (   sen_sysstbn         ), 
    .o_SERDES_BIT_REVERSE   (   SERDES_BIT_REVERSE  ),
    .o_SERDES_MANUL_MODE    (   SERDES_MANUL_MODE   ),
    .o_serdes_start         (   serdes_start        ),
    .o_stream_on            (   stream_on           ),
    .o_ACTIVE_WIDTH         (   ACTIVE_WIDTH        ),
    .o_ACTIVE_HEIGHT        (   ACTIVE_HEIGHT       ),
    .o_FRAME_WIDTH          (   FRAME_WIDTH         ),
    .o_FRAME_HEIGHT         (   FRAME_HEIGHT        ), 
    .o_SOF_PATTERN          (   SOF_PATTERN         ),
    .o_SOL_PATTERN          (   SOL_PATTERN         ),
    .o_EOL_PATTERN          (   EOL_PATTERN         ),
    .o_EOF_PATTERN          (   EOF_PATTERN         ),
    .o_CHECK_SEARCH_LINE    (   CHECK_SEARCH_LINE   ),
    .o_CHECK_PATTERN_NUM    (   CHECK_PATTERN_NUM   ),
    .o_EYE_RANGE            (   EYE_RANGE           ),
    .o_SERDES_SLIP_NUM      (   SERDES_SLIP_NUM     ),
    .o_SERDES_DELAY_NUM     (   SERDES_DELAY_NUM    ),
    .i_sen_lock             (   sen_lock            ),
    .i_sen_done             (   sen_done            ),
    .i_stats_exp_time       (   stats_exp_time      ),
    .i_stats_gray_sum_L     (   stats_gray_sum_L    ),
    .i_stats_gray_sum_H     (   stats_gray_sum_H    )
    
);




IDELAYCTRL icontrol (                          // Instantiate input delay control block
    .REFCLK             (   refclkin                ),
    .RST                (   serdes_reset            ),
    .RDY                (   idelay_rdy              )
);
 


rx_channel_1to12_ddr # (
    .D                  (   16                      ),
    .REF_FREQ           (   REF_FREQ                ),
    .DIFF_TERM          (   DIFF_TERM               ),
    .DEBUG              (   DEBUG                   ) //"TRUE"
) u_rx (
    .clkin_p            (   sen_clkin_p             ),
    .clkin_n            (   sen_clkin_n             ),
    .datain_p           (   sen_datain_p            ),
    .datain_n           (   sen_datain_n            ),
    .reset              (   serdes_reset            ),
    .idelay_rdy         (   idelay_rdy              ),
    .SOF_PATTERN        (   SOF_PATTERN             ),
    .SOL_PATTERN        (   SOL_PATTERN             ),
    .EOL_PATTERN        (   EOL_PATTERN             ),
    .EOF_PATTERN        (   EOF_PATTERN             ), 
    .ACTIVE_WIDTH       (   ACTIVE_WIDTH            ),
    .FRAME_WIDTH        (   FRAME_WIDTH             ),
    .CHECK_SEARCH_LINE  (   CHECK_SEARCH_LINE       ),
    .CHECK_PATTERN_NUM  (   CHECK_PATTERN_NUM       ),
    .EYE_RANGE          (   EYE_RANGE               ),
    .SERDES_BIT_REVERSE (   SERDES_BIT_REVERSE      ),
    .SERDES_SLIP_NUM    (   SERDES_SLIP_NUM         ),
    .SERDES_DELAY_NUM   (   SERDES_DELAY_NUM        ),
    .SERDES_MANUL_MODE  (   SERDES_MANUL_MODE       ),
    .start              (   serdes_start            ), 
    .stream_on_in       (   stream_on               ),
    .px_reset           (   sen_reset               ),
    .px_clk             (   sen_clk                 ), 
    .sen_dout           (   sen_dout                ),
    .sen_en_out         (   sen_en_out              ),
    .sen_vs_out         (   sen_vs_out              ),
    .sen_lock_out       (   sen_lock                ),
    .sen_done_out       (   sen_done                )
);



sensor_stats # (
    .D                  (   16                      ), 
    .DEBUG              (   DEBUG                   ) //"TRUE"
) u_stats (
    .px_clk             (   sen_clk                 ),
    .px_reset           (   sen_reset               ),
    .exp_in             (   sen_exp_in              ),
    .din                (   sen_dout                ),
    .en_in              (   sen_en_out              ),
    .vs_in              (   sen_vs_out              ),
    .exp_time_out       (   stats_exp_time          ),
    .gray_sum_L_out     (   stats_gray_sum_L        ),
    .gray_sum_H_out     (   stats_gray_sum_H        )
);















endmodule


