
// *************************************************************************************************
// Vendor 			: 
// Author 			: liu jun 
// Filename 		: cl_data_splice
// Date Created 	: 2021.10.13
// Version 			: V1.0
// -------------------------------------------------------------------------------------------------
// File description	:
//  camerlink相机数据一行输入时，按照tap和bit位宽输入，输出的stream也是按照tap和bit位宽输出，不做任何转�?
// -------------------------------------------------------------------------------------------------
`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

module sdi_cfg
#(
    parameter CFG_DATA_WIDTH 	= 32,
    parameter CFG_ADDR_WIDTH 	= 32,
    parameter CFG_CLK_FREQ		= 200000000,
    parameter SIM 				= "FALSE",
    parameter DEBUG				= "FALSE"
)
(
    //------------------------------------------------
    // Cfg Port define
    //------------------------------------------------
    input									i_cfg_clk,
    input									i_cfg_rst,
    
    input									s_cfg_wr_en,
    input 	[CFG_DATA_WIDTH - 1:0]			s_cfg_wr_data,
    input 	[CFG_ADDR_WIDTH - 1:0]			s_cfg_addr,
    input									s_cfg_rd_en,
    output									s_cfg_rd_vld,
    output	[CFG_DATA_WIDTH - 1:0]			s_cfg_rd_data,
    output 									s_cfg_busy,

    //------------------------------------------------
    // Cmr port
    //------------------------------------------------
    input 	[3:0]							i_linkup,
    output 									o_cmr_rst,
	output 	[15:0]		                    o_image_w,			
	output 	[15:0]		                    o_image_h,	
	output 	[15:0]		                    o_offset_x,			
	output 	[15:0]		                    o_offset_y,
    output 									o_cmr_vld   
);

    localparam CTRL_ADDR			= 6'd0;//RW
    localparam STATE_ADDR			= 6'd1;//R    
    localparam WIDTH_ADDR			= 6'd2;//R 
    localparam HIGHT_ADDR			= 6'd3;//R 
    localparam OFFSET_X_ADDR        = 6'd4;//R 
    localparam OFFSET_Y_ADDR        = 6'd5;//R 
    //----------------------------------------------------------------------------------------------
    // struct define
    //----------------------------------------------------------------------------------------------
    typedef struct {
        logic 			cfg_cmr_vld;

        logic 			cfg_cmr_rst;
        logic [7:0]		cfg_cmr_rst_arry;
        logic 			cfg_cmr_rst_comb;
        
        logic [15:0]    width;
        logic [15:0]    hight;
        logic [15:0]    offset_x;
        logic [15:0]    offset_y;


        logic 			cfg_rd_vld;
        logic [31:0]	cfg_rd_data;
      } cfg_s;
    
    //----------------------------------------------------------------------------------------------
    // Register define
    //----------------------------------------------------------------------------------------------
    cfg_s rc, rcn;

    //----------------------------------------------------------------------------------------------
    // combinatorial always
    //----------------------------------------------------------------------------------------------
    always_comb begin	
        rcn = rc;
        //------------------------------------------------------------------------------------------
        // Config clk domain
        //------------------------------------------------------------------------------------------
        rcn.cfg_cmr_rst = 1'b0;

        if(s_cfg_wr_en) begin
            case(s_cfg_addr[7:2])
                CTRL_ADDR:          {rcn.cfg_cmr_vld,rcn.cfg_cmr_rst}    = s_cfg_wr_data[1:0];
                WIDTH_ADDR:         rcn.width       = s_cfg_wr_data[15:0];
                HIGHT_ADDR:         rcn.hight       = s_cfg_wr_data[15:0];
                OFFSET_X_ADDR:      rcn.offset_x    = s_cfg_wr_data[15:0];
                OFFSET_Y_ADDR:      rcn.offset_y    = s_cfg_wr_data[15:0];
            default:;
            endcase
        end

        rcn.cfg_rd_vld = 1'b0;
        if(s_cfg_rd_en) begin
            rcn.cfg_rd_vld = 1'b1;
            case(s_cfg_addr[7:2])
                CTRL_ADDR:      rcn.cfg_rd_data     = {30'd0,rc.cfg_cmr_vld,rc.cfg_cmr_rst};
                STATE_ADDR:     rcn.cfg_rd_data     = {28'd0, i_linkup};
                WIDTH_ADDR:     rcn.cfg_rd_data     = {16'd0, rc.width};
                HIGHT_ADDR:     rcn.cfg_rd_data     = {16'd0, rc.hight};
                OFFSET_X_ADDR:  rcn.cfg_rd_data     = {16'd0, rc.offset_x};
                OFFSET_Y_ADDR:  rcn.cfg_rd_data     = {16'd0, rc.offset_y};

            default:;
            endcase
        end
        
        rcn.cfg_cmr_rst_arry = {rc.cfg_cmr_rst_arry[6:0],rc.cfg_cmr_rst};
        rcn.cfg_cmr_rst_comb = |rc.cfg_cmr_rst_arry;
    end
    
    //----------------------------------------------------------------------------------------------
    // output assignment
    //----------------------------------------------------------------------------------------------
    assign o_cmr_rst		= rc.cfg_cmr_rst_comb;
    assign o_cmr_vld		= rc.cfg_cmr_vld;
    assign o_image_w        = rc.width;			
    assign o_image_h        = rc.hight;	
    assign o_offset_x       = rc.offset_x;			
    assign o_offset_y       = rc.offset_y;



    //----------------------------------------------------------------------------------------------
    // sequential always
    //----------------------------------------------------------------------------------------------	
    always_ff @(posedge i_cfg_clk) begin
        rc <= rcn;
        if(i_cfg_rst == 1'b1) begin
            rc.cfg_cmr_vld          <= 'd0;	
            rc.cfg_cmr_rst		    <= 'd0;			
            rc.cfg_cmr_rst_arry		<= 'd0;			
            rc.cfg_cmr_rst_comb		<= 'd0;

            rc.width                <= 'd0;
            rc.hight                <= 'd0;
            rc.offset_x             <= 'd0;
            rc.offset_y             <= 'd0;

            rc.cfg_rd_vld			<= 1'b0;
            rc.cfg_rd_data			<= 32'd0;
        end
    end

    //----------------------------------------------------------------------------------------------
    // Debug Signal
    //----------------------------------------------------------------------------------------------
    generate
        if(DEBUG == "TRUE") begin

        end
    endgenerate





endmodule

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

