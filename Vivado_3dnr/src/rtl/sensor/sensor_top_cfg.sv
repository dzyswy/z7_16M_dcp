
`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

module sensor_top_cfg # (
    parameter CFG_DATA_WIDTH     = 32,
    parameter CFG_ADDR_WIDTH     = 32, 
    parameter DEBUG              = "FALSE"
) (
    //------------------------------------------------
    // Cfg Port define
    //------------------------------------------------
    input                                       i_cfg_clk,
    input                                       i_cfg_rst,
    
    input                                       s_cfg_wr_en,
    input     [CFG_DATA_WIDTH - 1:0]            s_cfg_wr_data,
    input     [CFG_ADDR_WIDTH - 1:0]            s_cfg_addr,
    input                                       s_cfg_rd_en,
    output                                      s_cfg_rd_vld,
    output    [CFG_DATA_WIDTH - 1:0]            s_cfg_rd_data,
    output                                      s_cfg_busy,
    
    //------------------------------------------------
    // Param port
    //------------------------------------------------

    output              o_senvtc_reset          ,
    output              o_serdes_reset          ,
    output              o_sen_poweren           ,
    output              o_sen_inclk_en          ,
    output              o_sen_sysrstn           ,
    output              o_sen_sysstbn           , 
    output              o_SERDES_BIT_REVERSE    ,
    output              o_SERDES_MANUL_MODE     ,
    output              o_serdes_start          ,
    output              o_stream_on             ,
    
    
    output  [15:0]      o_ACTIVE_WIDTH          ,
    output  [15:0]      o_ACTIVE_HEIGHT         ,
    output  [15:0]      o_FRAME_WIDTH           ,
    output  [15:0]      o_FRAME_HEIGHT          , 
    
    output  [47:0]      o_SOF_PATTERN           ,
    output  [47:0]      o_SOL_PATTERN           ,
    output  [47:0]      o_EOL_PATTERN           ,
    output  [47:0]      o_EOF_PATTERN           ,
    
    output  [15:0]      o_CHECK_SEARCH_LINE     ,
    output  [15:0]      o_CHECK_PATTERN_NUM     ,
    output  [7:0]       o_EYE_RANGE             ,
        
    output [7:0]        o_SERDES_SLIP_NUM       ,
    output [7:0]        o_SERDES_DELAY_NUM      ,
        
    input               i_sen_lock              ,
    input               i_sen_done              ,
    input   [31:0]      i_stats_exp_time        ,
    input   [31:0]      i_stats_gray_sum_L      ,
    input   [31:0]      i_stats_gray_sum_H      
);

localparam  ADDR_CTRL       = 6'd0;//RW           
localparam  ADDR_STATUS     = 6'd1;//RW 
localparam  ADDR_02         = 6'd2;//RW
localparam  ADDR_03         = 6'd3;//RW
localparam  ADDR_04         = 6'd4;//RW
localparam  ADDR_05         = 6'd5;//RW
localparam  ADDR_06         = 6'd6;//RW
localparam  ADDR_07         = 6'd7;//RW
localparam  ADDR_08         = 6'd8;//RW
localparam  ADDR_09         = 6'd9;//RW
localparam  ADDR_10         = 6'd10;//RW
localparam  ADDR_11         = 6'd11;//RW
localparam  ADDR_12         = 6'd12;//RW
localparam  ADDR_13         = 6'd13;//RW
localparam  ADDR_14         = 6'd14;//RW
localparam  ADDR_15         = 6'd15;//RW 
localparam  ADDR_16         = 6'd16;//RW 

//----------------------------------------------------------------------------------------------
// struct define
//----------------------------------------------------------------------------------------------
typedef struct {

    logic   [31:0]      cfg_ctrl  ;
    logic   [31:0]      cfg_status; 
    logic   [31:0]      cfg_data02;
    logic   [31:0]      cfg_data03;
    logic   [31:0]      cfg_data04;
    logic   [31:0]      cfg_data05;
    logic   [31:0]      cfg_data06;
    logic   [31:0]      cfg_data07;
    logic   [31:0]      cfg_data08;
    logic   [31:0]      cfg_data09;
    logic   [31:0]      cfg_data10;
    logic   [31:0]      cfg_data11;
    logic   [31:0]      cfg_data12;
    logic   [31:0]      cfg_data13;
    logic   [31:0]      cfg_data14;
    logic   [31:0]      cfg_data15;
    logic   [31:0]      cfg_data16;

    logic               cfg_rd_vld;
    logic   [31:0]      cfg_rd_data;
} cfg_s;


//----------------------------------------------------------------------------------------------
// Register define
//----------------------------------------------------------------------------------------------
cfg_s rc, rcn;
wire    [31:0]  comb_status;
wire    [31:0]  comb_data14;
wire    [31:0]  comb_data15;
wire    [31:0]  comb_data16;

//----------------------------------------------------------------------------------------------
// sequential always
//----------------------------------------------------------------------------------------------    
always_ff @(posedge i_cfg_clk) begin
    rc <= #1 rcn;
    if(i_cfg_rst == 1'b1) begin

 
        rc.cfg_ctrl         <= #1 'b0;
        rc.cfg_status       <= #1 'b0;
        rc.cfg_data02       <= #1 'b0;
        rc.cfg_data03       <= #1 'b0;
        rc.cfg_data04       <= #1 'b0;
        rc.cfg_data05       <= #1 'b0;
        rc.cfg_data06       <= #1 'b0;
        rc.cfg_data07       <= #1 'b0;
        rc.cfg_data08       <= #1 'b0;
        rc.cfg_data09       <= #1 'b0;
        rc.cfg_data10       <= #1 'b0;
        rc.cfg_data11       <= #1 'b0;
        rc.cfg_data12       <= #1 'b0;
        rc.cfg_data13       <= #1 'b0;
        rc.cfg_data14       <= #1 'b0;
        rc.cfg_data15       <= #1 'b0;
        rc.cfg_data16       <= #1 'b0;
    
        rc.cfg_rd_vld       <= #1 'b0;
        rc.cfg_rd_data      <= #1 'd0;


    end
end


//----------------------------------------------------------------------------------------------
// combinatorial always
//----------------------------------------------------------------------------------------------
always_comb begin    
    rcn = rc;
    //------------------------------------------------------------------------------------------
    // Config clk domain
    //------------------------------------------------------------------------------------------
 

    if(s_cfg_wr_en) begin
        case(s_cfg_addr[7:2]) 

            ADDR_CTRL       :   rcn.cfg_ctrl     = s_cfg_wr_data[31:0]; 
            ADDR_STATUS     :   rcn.cfg_status   = s_cfg_wr_data[31:0]; 
            ADDR_02         :   rcn.cfg_data02   = s_cfg_wr_data[31:0];
            ADDR_03         :   rcn.cfg_data03   = s_cfg_wr_data[31:0];
            ADDR_04         :   rcn.cfg_data04   = s_cfg_wr_data[31:0];
            ADDR_05         :   rcn.cfg_data05   = s_cfg_wr_data[31:0];
            ADDR_06         :   rcn.cfg_data06   = s_cfg_wr_data[31:0];
            ADDR_07         :   rcn.cfg_data07   = s_cfg_wr_data[31:0];
            ADDR_08         :   rcn.cfg_data08   = s_cfg_wr_data[31:0];
            ADDR_09         :   rcn.cfg_data09   = s_cfg_wr_data[31:0];
            ADDR_10         :   rcn.cfg_data10   = s_cfg_wr_data[31:0];
            ADDR_11         :   rcn.cfg_data11   = s_cfg_wr_data[31:0];
            ADDR_12         :   rcn.cfg_data12   = s_cfg_wr_data[31:0];
            ADDR_13         :   rcn.cfg_data13   = s_cfg_wr_data[31:0];
            ADDR_14         :   rcn.cfg_data14   = s_cfg_wr_data[31:0];
            ADDR_15         :   rcn.cfg_data15   = s_cfg_wr_data[31:0]; 
            ADDR_16         :   rcn.cfg_data16   = s_cfg_wr_data[31:0]; 

            default:;
        endcase
    end

    rcn.cfg_rd_vld = 1'b0;
    if(s_cfg_rd_en) begin
        rcn.cfg_rd_vld = 1'b1;
        case(s_cfg_addr[7:2])

            ADDR_CTRL       :   rcn.cfg_rd_data = rc.cfg_ctrl  ;
            ADDR_STATUS     :   rcn.cfg_rd_data = comb_status  ;
            ADDR_02         :   rcn.cfg_rd_data = rc.cfg_data02;
            ADDR_03         :   rcn.cfg_rd_data = rc.cfg_data03;
            ADDR_04         :   rcn.cfg_rd_data = rc.cfg_data04;
            ADDR_05         :   rcn.cfg_rd_data = rc.cfg_data05;
            ADDR_06         :   rcn.cfg_rd_data = rc.cfg_data06;
            ADDR_07         :   rcn.cfg_rd_data = rc.cfg_data07;
            ADDR_08         :   rcn.cfg_rd_data = rc.cfg_data08;
            ADDR_09         :   rcn.cfg_rd_data = rc.cfg_data09;
            ADDR_10         :   rcn.cfg_rd_data = rc.cfg_data10;
            ADDR_11         :   rcn.cfg_rd_data = rc.cfg_data11;
            ADDR_12         :   rcn.cfg_rd_data = rc.cfg_data12;
            ADDR_13         :   rcn.cfg_rd_data = rc.cfg_data13;
            ADDR_14         :   rcn.cfg_rd_data = comb_data14;
            ADDR_15         :   rcn.cfg_rd_data = comb_data15; 
            ADDR_16         :   rcn.cfg_rd_data = comb_data16; 

            default:;
        endcase
    end
     

end

//----------------------------------------------------------------------------------------------
// output assignment
//----------------------------------------------------------------------------------------------

assign s_cfg_rd_vld         = rc.cfg_rd_vld;
assign s_cfg_rd_data        = rc.cfg_rd_data;
assign s_cfg_busy           = rc.cfg_rd_vld;


assign o_senvtc_reset           = rc.cfg_ctrl[0];
assign o_serdes_reset           = rc.cfg_ctrl[1];
assign o_sen_poweren            = rc.cfg_ctrl[2];
assign o_sen_inclk_en           = rc.cfg_ctrl[3];
assign o_sen_sysrstn            = rc.cfg_ctrl[4];
assign o_sen_sysstbn            = rc.cfg_ctrl[5];
assign o_SERDES_BIT_REVERSE     = rc.cfg_ctrl[6];
assign o_SERDES_MANUL_MODE      = rc.cfg_ctrl[7];
assign o_serdes_start           = rc.cfg_ctrl[8];
assign o_stream_on              = rc.cfg_ctrl[9];

assign o_ACTIVE_WIDTH       = rc.cfg_data02[15:0]  ;
assign o_ACTIVE_HEIGHT      = rc.cfg_data02[31:16] ;
assign o_FRAME_WIDTH        = rc.cfg_data03[15:0]   ;
assign o_FRAME_HEIGHT       = rc.cfg_data03[31:16]  ;

assign o_SOF_PATTERN        = {rc.cfg_data05[15:0], rc.cfg_data04[31:0]};
assign o_SOL_PATTERN        = {rc.cfg_data07[15:0], rc.cfg_data06[31:0]};
assign o_EOL_PATTERN        = {rc.cfg_data09[15:0], rc.cfg_data08[31:0]};
assign o_EOF_PATTERN        = {rc.cfg_data11[15:0], rc.cfg_data10[31:0]};




assign o_CHECK_SEARCH_LINE      = rc.cfg_data12[15:0]   ;
assign o_CHECK_PATTERN_NUM      = rc.cfg_data12[31:16]  ;
assign o_EYE_RANGE              = rc.cfg_data13[7:0]    ;
assign o_SERDES_SLIP_NUM        = rc.cfg_data13[15:8]   ;
assign o_SERDES_DELAY_NUM       = rc.cfg_data13[23:16]  ;

assign comb_status = {30'b0, i_sen_lock, i_sen_done};
assign comb_data14 = i_stats_exp_time;
assign comb_data15 = i_stats_gray_sum_L;
assign comb_data16 = i_stats_gray_sum_H;

//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
if(DEBUG == "TRUE") begin


    (* mark_debug = "true" *)logic               mark_o_senvtc_reset        ;
    (* mark_debug = "true" *)logic               mark_o_serdes_reset        ;
    (* mark_debug = "true" *)logic               mark_o_sen_poweren         ;
    (* mark_debug = "true" *)logic               mark_o_sen_inclk_en        ;
    (* mark_debug = "true" *)logic               mark_o_sen_sysrstn         ;
    (* mark_debug = "true" *)logic               mark_o_sen_sysstbn         ; 
    (* mark_debug = "true" *)logic               mark_o_SERDES_BIT_REVERSE  ;
    (* mark_debug = "true" *)logic               mark_o_SERDES_MANUL_MODE   ;
    (* mark_debug = "true" *)logic               mark_o_serdes_start        ;
    (* mark_debug = "true" *)logic               mark_o_stream_on           ;
    (* mark_debug = "true" *)logic   [15:0]      mark_o_ACTIVE_WIDTH        ;
    (* mark_debug = "true" *)logic   [15:0]      mark_o_ACTIVE_HEIGHT       ;
    (* mark_debug = "true" *)logic   [15:0]      mark_o_FRAME_WIDTH         ;
    (* mark_debug = "true" *)logic   [15:0]      mark_o_FRAME_HEIGHT        ; 
    (* mark_debug = "true" *)logic   [47:0]      mark_o_SOF_PATTERN         ;
    (* mark_debug = "true" *)logic   [47:0]      mark_o_SOL_PATTERN         ;
    (* mark_debug = "true" *)logic   [47:0]      mark_o_EOL_PATTERN         ;
    (* mark_debug = "true" *)logic   [47:0]      mark_o_EOF_PATTERN         ;
    (* mark_debug = "true" *)logic   [15:0]      mark_o_CHECK_SEARCH_LINE   ;
    (* mark_debug = "true" *)logic   [15:0]      mark_o_CHECK_PATTERN_NUM   ;
    (* mark_debug = "true" *)logic   [7:0]       mark_o_EYE_RANGE           ;

    (* mark_debug = "true" *)logic  [7:0]        mark_o_SERDES_SLIP_NUM     ;
    (* mark_debug = "true" *)logic  [7:0]        mark_o_SERDES_DELAY_NUM    ;
        
    (* mark_debug = "true" *)logic               mark_i_sen_lock            ;
    (* mark_debug = "true" *)logic               mark_i_sen_done            ;   
    (* mark_debug = "true" *)logic   [31:0]      mark_i_stats_exp_time      ;
    (* mark_debug = "true" *)logic   [31:0]      mark_i_stats_gray_sum_L    ; 
    (* mark_debug = "true" *)logic   [31:0]      mark_i_stats_gray_sum_H    ;  

   
    assign mark_o_senvtc_reset                  = o_senvtc_reset      ;
    assign mark_o_serdes_reset                  = o_serdes_reset      ;
    assign mark_o_sen_poweren                   = o_sen_poweren       ;
    assign mark_o_sen_inclk_en                  = o_sen_inclk_en      ;
    assign mark_o_sen_sysrstn                   = o_sen_sysrstn       ;
    assign mark_o_sen_sysstbn                   = o_sen_sysstbn       ; 
    assign mark_o_SERDES_BIT_REVERSE            = o_SERDES_BIT_REVERSE;
    assign mark_o_SERDES_MANUL_MODE             = o_SERDES_MANUL_MODE ;
    assign mark_o_serdes_start                  = o_serdes_start      ;
    assign mark_o_stream_on                     = o_stream_on         ;
    assign mark_o_ACTIVE_WIDTH                  = o_ACTIVE_WIDTH      ;
    assign mark_o_ACTIVE_HEIGHT                 = o_ACTIVE_HEIGHT     ;
    assign mark_o_FRAME_WIDTH                   = o_FRAME_WIDTH       ;
    assign mark_o_FRAME_HEIGHT                  = o_FRAME_HEIGHT      ; 
    assign mark_o_SOF_PATTERN                   = o_SOF_PATTERN       ;
    assign mark_o_SOL_PATTERN                   = o_SOL_PATTERN       ;
    assign mark_o_EOL_PATTERN                   = o_EOL_PATTERN       ;
    assign mark_o_EOF_PATTERN                   = o_EOF_PATTERN       ;
    assign mark_o_CHECK_SEARCH_LINE             = o_CHECK_SEARCH_LINE ;
    assign mark_o_CHECK_PATTERN_NUM             = o_CHECK_PATTERN_NUM ;
    assign mark_o_EYE_RANGE                     = o_EYE_RANGE         ;
    assign mark_o_SERDES_SLIP_NUM               = o_SERDES_SLIP_NUM   ;
    assign mark_o_SERDES_DELAY_NUM              = o_SERDES_DELAY_NUM  ;
    assign mark_i_sen_lock                      = i_sen_lock          ;
    assign mark_i_sen_done                      = i_sen_done          ;   

    assign mark_i_stats_exp_time                = i_stats_exp_time  ;
    assign mark_i_stats_gray_sum_L              = i_stats_gray_sum_L;
    assign mark_i_stats_gray_sum_H              = i_stats_gray_sum_H;

end
endgenerate





endmodule

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

