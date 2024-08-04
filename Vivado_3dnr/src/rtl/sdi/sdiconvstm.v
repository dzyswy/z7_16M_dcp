
// *************************************************************************************************
// Vendor 			: 
// Author 			: liu jun 
// Filename 		: cl_data_splice
// Date Created 	: 2021.12.30
// Version 			: V1.0
// -------------------------------------------------------------------------------------------------
// File description	:
// -------------------------------------------------------------------------------------------------
`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

module sdiconvstm
#(
    parameter   DW              = 16,
	parameter   SIM             = "FALSE",
	parameter   DEBUG           = "FALSE"
)
(

    input               i_clk,
    input               i_rst,
        
    input [9:0]         i_rx_ds1a,
    input [9:0]         i_rx_ds2a,    
    input               i_rx_trs,
    input               i_rx_sav,
    input               i_rx_eav,
    input [10:0]        i_rx_line_number,

    input               i_cmr_vld,

	input 	[15:0]      i_image_w,			
	input 	[15:0]      i_image_h,	
	input 	[15:0]      i_offset_x,			
	input 	[15:0]      i_offset_y,    
    //---- output video frame

    input               i_axis_clk,
    input               i_axis_rst,    


    output	            o_frame_vs, 
    output	            o_frame_hs,
    output	            o_frame_de,
    output	[DW-1:0]    o_frame_data,

    output	[DW-1:0]    m_axis_tdata,
    output 				m_axis_tlast,
    output 				m_axis_tvalid,
    output 				m_axis_tuser,   	
    output	[DW/8-1:0]  m_axis_tkeep,
    input 				m_axis_tready
);

    //-----------def local params--------------
    localparam [10:0] VVALID_START_LINE_NUMBER   = 11'd42;
    localparam [10:0] VVALID_END_LINE_NUMBER   = 11'd1122;


    //----------------------------------------------------------------------------------------------
    // Register define
    //----------------------------------------------------------------------------------------------
    reg     [2:0]           cmr_vld;
    reg                     cmr_vld_flag;

	reg 	[15:0]          image_w[1:0];			
	reg 	[15:0]          image_h[1:0];	
	reg 	[15:0]          offset_x[1:0];			
	reg 	[15:0]          offset_y[1:0];

    reg     [9:0]           rx_ds1a[1:0];
    reg     [9:0]           rx_ds2a[1:0];   
    reg     [1:0]           rx_trs;
    reg     [1:0]           rx_sav;
    reg     [1:0]           rx_eav;
    reg     [10:0]          rx_line_number[1:0];

    reg     [10:0]          pix_cnt;
    reg     [10:0]          line_cnt;    
    reg                     vs;
    reg                     hs;
    reg                     de; 
    reg     [DW-1:0]        data;       

    reg                     resize_vld;
    reg     [DW-1:0]        m_data;
    reg 			        m_vld;
    reg 			        m_last;
    reg 			        m_user;

    reg	                    frame_vs; 
    reg	                    frame_hs;
    reg	                    frame_de;
    reg	[DW-1:0]            frame_data;

    wire    [DW+2:0]        fifo_din;
    wire 			        fifo_wr_en;
    wire    [DW+2:0]        fifo_dout;
    wire 			        fifo_rd_en;
    wire 			        fifo_full;
    wire 			        fifo_empty; 

	wire	[DW-1:0]        str_data;
	wire	                str_user;    
	wire	                str_vld;
	wire	                str_last;
	wire	                str_rdy;  

    //--------------------start here---------------------------------------
    always @(posedge i_clk)
    begin
        cmr_vld             <= {cmr_vld[1:0],i_cmr_vld};  

        image_w[0]          <= i_image_w;
        image_h[0]          <= i_image_h;    
        offset_x[0]         <= i_offset_x;
        offset_y[0]         <= i_offset_y;

        image_w[1]          <= image_w[0]; 
        image_h[1]          <= image_h[0];   
        offset_x[1]         <= offset_x[0];
        offset_y[1]         <= offset_y[0];


        rx_ds1a[0]          <= i_rx_ds1a         ;
        rx_ds2a[0]          <= i_rx_ds2a         ;    
        rx_trs[0]           <= i_rx_trs          ;
        rx_sav[0]           <= i_rx_sav          ;
        rx_eav[0]           <= i_rx_eav          ;
        rx_line_number[0]   <= i_rx_line_number  ; 

        rx_ds1a[1]          <= rx_ds1a[0]         ;
        rx_ds2a[1]          <= rx_ds2a[0]         ;    
        rx_trs[1]           <= rx_trs[0]          ;
        rx_sav[1]           <= rx_sav[0]          ;
        rx_eav[1]           <= rx_eav[0]          ;
        rx_line_number[1]   <= rx_line_number[0]  ;                 
    end

    always @(posedge i_clk)
    begin
        if(i_rst == 1'b1)begin
            pix_cnt <= 0;
            line_cnt <= 0;
            vs <= 0;
            hs <= 0;
            de <= 0;
            data <= 0;

            resize_vld <= 0;
            m_vld <= 0;
            m_data <= 16'd0;
            m_last <= 0;
            m_user <= 0;

            frame_vs <= 0;
            frame_hs <= 0;
            frame_de <= 0;
            frame_data <= 0;

            cmr_vld_flag  <= 0;
        end
        else begin
            if (cmr_vld[2:1] == 2'b01) begin
                cmr_vld_flag  <= 1;
            end
            if (cmr_vld_flag == 1'b1) begin
                if(rx_trs[1:0] == 2'b01  && (rx_line_number[0] == VVALID_START_LINE_NUMBER))begin
                    vs <= 1'b1;
                end
                else if(rx_trs[1:0] == 2'b01 && (rx_line_number[0] == VVALID_END_LINE_NUMBER))begin
                    vs <= 1'b0;
                end                 
            end
            else begin
                vs <= 1'b0;
            end

            if (vs == 1'b1) begin
                if(rx_trs[1] == 1'b1 && rx_sav[1] == 1'b1)begin
                    hs <= 1'b1;
                    line_cnt <= line_cnt + 1'd1;
                end
                else if(rx_trs[1] == 1'b1 && rx_eav[1] == 1'b1)begin
                    hs <= 1'b0;
                end                 
            end
            else begin
                hs <= 1'b0;
                line_cnt <= 0;
            end

            if (vs == 1'b1) begin
                pix_cnt <= pix_cnt + 1'd1;
                if(rx_trs[1] == 1'b1 && rx_sav[1] == 1'b1)begin
                    pix_cnt <= 1'b1;
                end

                if(rx_trs[1] == 1'b1 && rx_sav[1] == 1'b1)begin
                    de <= 1'b1;
                end
                else if(rx_trs[0])begin
                    de <= 1'b0;
                end                 
            end
            else begin
                pix_cnt <= 0;
                de <= 1'b0;
            end
            data <= {rx_ds2a[0][9:2], rx_ds1a[0][9:2]};


            if (de == 1'd1 && line_cnt == (offset_y[1] + 1) && pix_cnt == (offset_x[1] + 1)) begin
                m_user <= 1'b1;
            end
            else begin
                m_user <= 1'b0;
            end

            if(de == 1'd1 && line_cnt >= (offset_y[1] + 1) && line_cnt <= (offset_y[1] + image_h[1]) && pix_cnt >= (offset_x[1] + 1) && pix_cnt <= (offset_x[1] + image_w[1]))begin
                m_vld <= 1'b1;              
            end 
            else begin
                m_vld <= 1'b0; 
            end 

            m_last <= 1'b0;
            if(de == 1'd1 && pix_cnt == (offset_x[1] + image_w[1]))begin
                m_last <= 1'b1; 
            end
            m_data <= data;

            frame_vs <= vs;
            frame_hs <= m_vld;
            frame_de <= m_vld;
            frame_data <= m_data;
        end        
    end

    
    //产生stream �?
	assign str_data = fifo_dout[DW-1:0];
	assign str_user = fifo_dout[DW+2];   
	assign str_vld = fifo_dout[DW+1] & !fifo_empty;
	assign str_last = fifo_dout[DW];

    assign fifo_wr_en	 	= m_vld;
    assign fifo_din			= {m_user,m_vld,m_last,m_data};
    assign fifo_rd_en		= str_vld & str_rdy;
    fifo_sdi_16x512 u_fifo_sdi_16x512 (
        .rst            (   i_rst | i_axis_rst),  // input wire rst

        .wr_clk         (   i_clk       ),  // input wire wr_clk
        .din            (   fifo_din    ),  // input wire [15 : 0] din
        .wr_en          (   fifo_wr_en  ),  // input wire wr_en
        .full           (               ),  // output wire full

        .rd_clk         (   i_axis_clk   ),  // input wire rd_clk
        .rd_en          (   fifo_rd_en  ),  // input wire rd_en
        .dout           (   fifo_dout   ),  // output wire [15 : 0] dout
        .empty          (   fifo_empty  ),  // output wire empty

        .wr_rst_busy    (               ),  // output wire wr_rst_busy
        .rd_rst_busy    (               )   // output wire rd_rst_busy
    );

    str_ppl
    #(
        .WIDTH          (   DW              )
    ) 
    u_str_ppl_out
    (   
        .i_clk          (   i_axis_clk       ),
        .i_rst          (   i_axis_rst       ),
        .i_str_data     (   str_data        ),
        .i_str_vld      (   str_vld         ),
        .i_str_user     (   str_user        ),
        .i_str_last     (   str_last        ),
        .o_str_rdy      (   str_rdy         ),

        .o_str_data     (   m_axis_tdata      ),
        .o_str_vld      (   m_axis_tvalid     ),
        .o_str_user     (   m_axis_tuser      ),
        .o_str_last     (   m_axis_tlast      ),
        .i_str_rdy      (   m_axis_tready     )
    );
    assign m_axis_tkeep = 2'b11;


    //----------------------------------------------------------------------------------------------
    // output assignment
    //----------------------------------------------------------------------------------------------
    assign	o_frame_vs = frame_vs;
    assign	o_frame_hs = frame_hs;
    assign	o_frame_de = frame_de;
    assign	o_frame_data = frame_data;

    generate
        if(DEBUG == "TRUE") begin

            (* mark_debug = "true" *)wire   [9:0]                   mark_sdi_rx_ds1a;
            (* mark_debug = "true" *)wire   [9:0]                   mark_sdi_rx_ds2a;   
            (* mark_debug = "true" *)wire                           mark_sdi_rx_trs;
            (* mark_debug = "true" *)wire                           mark_sdi_rx_sav;
            (* mark_debug = "true" *)wire                           mark_sdi_rx_eav;
            (* mark_debug = "true" *)wire   [10:0]                  mark_sdi_rx_line_number;

            (* mark_debug = "true" *)wire 	[15:0]                  mark_sdi_image_w;			
            (* mark_debug = "true" *)wire 	[15:0]                  mark_sdi_image_h;	
            (* mark_debug = "true" *)wire 	[15:0]                  mark_sdi_offset_x;			
            (* mark_debug = "true" *)wire 	[15:0]                  mark_sdi_offset_y;

            (* mark_debug = "true" *)wire 	[10:0]                  mark_sdi_pix_cnt;
            (* mark_debug = "true" *)wire 	[10:0]                  mark_sdi_line_cnt;    
            (* mark_debug = "true" *)wire 	                        mark_sdi_vs;
            (* mark_debug = "true" *)wire 	                        mark_sdi_hs;
            (* mark_debug = "true" *)wire 	                        mark_sdi_de; 
            (* mark_debug = "true" *)wire 	[DW-1:0]                mark_sdi_data;

            (* mark_debug = "true" *)wire 	[DW-1:0]                mark_sdi_m_data;
            (* mark_debug = "true" *)wire 			                mark_sdi_m_vld;
            (* mark_debug = "true" *)wire 			                mark_sdi_m_last;
            (* mark_debug = "true" *)wire 			                mark_sdi_m_user;

            (* mark_debug = "true" *)reg 	[31:0]   		        mark_sdi_stm_cnt;

            (* mark_debug = "true" *)wire	[DW - 1 : 0]            mark_sdi_str_data ;
            (* mark_debug = "true" *)wire	                        mark_sdi_str_user ;    
            (* mark_debug = "true" *)wire	                        mark_sdi_str_vld ;
            (* mark_debug = "true" *)wire	                        mark_sdi_str_last ;
            (* mark_debug = "true" *)wire	                        mark_sdi_str_rdy ;

            (* mark_debug = "true" *)reg   [31:0]   	            mark_sdi_wr_ddr_cnt;

            assign mark_sdi_rx_ds1a         = i_rx_ds1a         ;
            assign mark_sdi_rx_ds2a         = i_rx_ds2a         ;   
            assign mark_sdi_rx_trs          = i_rx_trs          ;
            assign mark_sdi_rx_sav          = i_rx_sav          ;
            assign mark_sdi_rx_eav          = i_rx_eav          ;
            assign mark_sdi_rx_line_number  = i_rx_line_number  ;

            assign mark_sdi_image_w         = image_w[1];
            assign mark_sdi_image_h         = image_h[1];
            assign mark_sdi_offset_x        = offset_x[1];
            assign mark_sdi_offset_y        = offset_y[1];            

            assign mark_sdi_pix_cnt     = pix_cnt     ;
            assign mark_sdi_line_cnt    = line_cnt    ; 
            assign mark_sdi_vs          = vs          ;
            assign mark_sdi_hs          = hs          ;
            assign mark_sdi_de          = de          ; 
            assign mark_sdi_data        = data        ;

            assign mark_sdi_m_data = m_data;
            assign mark_sdi_m_vld = m_vld;
            assign mark_sdi_m_last = m_last;
            assign mark_sdi_m_user = m_user;
         
            assign mark_sdi_str_data = str_data ;
            assign mark_sdi_str_user = str_user ; 
            assign mark_sdi_str_vld = str_vld ;
            assign mark_sdi_str_last = str_last ;
            assign mark_sdi_str_rdy = str_rdy ; 

            always@(posedge i_clk) begin
                if (m_user) begin
                    mark_sdi_stm_cnt <=  32'd1;
                end
                else if(m_vld)begin
                    mark_sdi_stm_cnt <=  mark_sdi_stm_cnt + 32'd1;     	
                end
            end         
         
            

            always@(posedge i_axis_clk) begin
                if (str_user) begin
                    mark_sdi_wr_ddr_cnt <= 32'd1;
                end
                else if(str_vld & str_rdy)begin
                    mark_sdi_wr_ddr_cnt <=  mark_sdi_wr_ddr_cnt + 32'd1;     	
                end
            end
        end
    endgenerate	





endmodule





