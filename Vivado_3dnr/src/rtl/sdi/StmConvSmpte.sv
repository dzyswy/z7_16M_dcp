
// *************************************************************************************************
// Vendor 			: 
// Author 			: liu jun 
// Filename 		: video_timing_gen
// Date Created 	: 2021.12.30
// Version 			: V1.0
// -------------------------------------------------------------------------------------------------
// File description	:
// -------------------------------------------------------------------------------------------------
`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------


module StmConvSmpte
(
    //----global signals
    input               i_rst,
    
    axis_if.s           s_axis,

    input  [2:0]        i_video_mode,

    //---- output sdi smpte frame
    input               i_sdi_clk,
    output   [19:0]     o_tx_sdi_data,
    output   [10:0]     o_tx_sdi_line_number
);


    //----------------------------------------------------------------------------------------------
    // Fsm define
    //----------------------------------------------------------------------------------------------
    typedef enum logic [2:0]{
        IDLE 	 	= 3'd0,
        WAIT_TRIG   = 3'd1,
        WAIT_VS     = 3'd2,
        RD_DATA     = 3'd3,
        FLUSH       = 3'd4,
        WAIT_SOF    = 3'd5
    } Fsm_e;

    //----------------------------------------------------------------------------------------------
    // Register define
    //----------------------------------------------------------------------------------------------
    logic               fifo_rst;
    logic               fifo_wr;
    logic   [18:0]      fifo_din;
    logic               fifo_empty;  
    logic               fifo_wr_rst_busy;      
    logic               fifo_full; 
    logic   [18:0]      fifo_dout;
    logic               fifo_rd;
    logic               fifo_prog_full;
    logic   [13:0]      fifo_rd_data_count;
    logic               fifo_rd_rst_busy;



    logic   [7:0]       data_y_r;
    logic   [7:0]       data_c_r;
    logic               tuser;    
    logic               tvalid; 
    logic               tlast;


    Fsm_e               state;  

    logic	[15:0]      str_data;
    logic	            str_user;    
    logic	            str_vld;
    logic	            str_last;
    logic	            stm_flush;
    logic	            sdi_out_start;
    logic	            sdi_out_vld;    
    logic	[2:0]       vs;
    logic	[2:0]       hs;


    reg [7:0] shiftreg8_hfls;
    wire hori_first_line_start_vld;
    
    reg [4:0] fsm_gen_smpte;
    reg [12:0] word_count;
    reg [10:0] line_count;
    reg F;
    reg V;
    reg H;
    wire [2:0] FVH;   
    reg [9:0] calc_xyz;
    
    reg [9:0] data_stream1;
    reg [9:0] data_stream2;
    logic [9:0] fifo_dout_to_y;
    logic [9:0] fifo_dout_to_c;
    wire fifo_rd_req;
    wire sdi_fval;
    wire [9:0] sdi_y;
    wire [9:0] sdi_c;    
 
    wire [12:0] rd_data_count;

    wire [7:0] data_y;
    wire [7:0] data_c;
// vio_2 your_instance_name (
//   .clk          (s_axis.clk),                // input wire clk
//   .probe_out0   (data_y),  // output wire [7 : 0] probe_out0
//   .probe_out1   (data_c)  // output wire [7 : 0] probe_out1
// );



    //----------------------------------------------------------------------------------------------
    // stream 时钟�?
    //----------------------------------------------------------------------------------------------
    always @(posedge s_axis.clk)begin
        if(s_axis.tdata[7:0] < 8'd16)begin
            data_y_r <= 8'd16;
        end
        else if(s_axis.tdata[7:0] > 8'd235)begin
            data_y_r <= 8'd235;
        end
        else begin
            data_y_r <= s_axis.tdata[7:0];  
        end 


        if(s_axis.tdata[15:8] < 8'd16)begin
            data_c_r <= 8'd16;
        end
        else if(s_axis.tdata[15:8] > 8'd240)begin
            data_c_r <= 8'd240;
        end
        else begin
            data_c_r <= s_axis.tdata[15:8];   
        end

        tuser <= s_axis.tuser;    
        tvalid <= s_axis.tvalid;  
        tlast <= s_axis.tlast; 


        fifo_wr <= s_axis.tready & s_axis.tvalid;             

    end

    assign fifo_din = {tvalid,tuser,tlast,data_c_r,data_y_r};
    assign s_axis.tready = !fifo_prog_full & !fifo_wr_rst_busy;




    //------------fifo isolate--------------------
    fifo_hd_sdi_19x4096 
    fifo_u (
        .rst            (   i_rst             ),

        .wr_clk         (   s_axis.clk      ),   
        .wr_en          (   fifo_wr         ),
        .din            (   fifo_din        ),

        .rd_clk         (   i_sdi_clk       ),
        .rd_en          (   fifo_rd         ),    
        .dout           (   fifo_dout       ),

        .full           (   fifo_full       ),  // output wire full
        .empty          (   fifo_empty      ),  // output wire empty

        .prog_full      (   fifo_prog_full  ),
        .rd_data_count  (   fifo_rd_data_count),
        .wr_rst_busy    (   fifo_wr_rst_busy),  // output wire wr_rst_busy
        .rd_rst_busy    (   fifo_rd_rst_busy)  // output wire rd_rst_busy
    );



    //----------------------------------------------------------------------------------------------
    // stream 时钟�?
    //----------------------------------------------------------------------------------------------
	assign str_data = fifo_dout[s_axis.DW-1:0];
	assign str_user = fifo_dout[s_axis.DW+1];   
	assign str_vld = fifo_dout[s_axis.DW+2] & !fifo_empty & !fifo_rd_rst_busy;
	assign str_last = fifo_dout[s_axis.DW];

    always @(posedge i_sdi_clk)begin
        if(i_rst == 1'b1)begin
            state <= IDLE;
            sdi_out_start <= 1'd0;
            stm_flush <= 1'd0;
            vs <= 3'd0;
            hs <= 3'd0;
            sdi_out_vld <= 1'd0;            
        end
        else begin
            vs <= {vs[1:0],sdi_fval};
            // hs <= {hs[1:0],~H};             
            case (state)
                IDLE:begin
                    stm_flush <= 1'd0;
                    sdi_out_vld <= 1'd0;
                    if(str_vld == 1'b1)begin
                        if(str_user == 1'b1)begin
                            if(fifo_rd_data_count > 14'd8000)begin
                                state <= RD_DATA;
                                sdi_out_start <= 1'd1;
                            end  
                        end
                        else begin
                            stm_flush <= 1'd1;
                            state <= FLUSH;  
                        end
                    end
                end

                RD_DATA:begin 
                    stm_flush <= 1'd0;
                    sdi_out_vld <= 1'd1;
                    if (vs[2:1] == 2'b01) begin
                        state <= IDLE; 
                    end
                end            

                FLUSH:begin 
                    sdi_out_vld <= 1'd0;
                    sdi_out_start <= 1'd0;
                    if(fifo_empty)begin
                        state <= WAIT_SOF;
                    end
                    else if(str_last & str_vld) begin
                        stm_flush <= 1'd0;
                        state <= WAIT_SOF;
                    end               
                end
                WAIT_SOF:begin 
                    stm_flush <= 1'd0;
                    sdi_out_vld <= 1'd0;
                    if(str_vld == 1'b1) begin
                        if (str_user == 1'b1) begin
                            state <= IDLE;                        
                        end
                        else begin
                            state <= FLUSH;
                            stm_flush <= 1'd1;
                        end
                    end                
                end

                default: ;
            endcase
        end
    end

        
assign fifo_rd = stm_flush | (fifo_rd_req & sdi_out_vld);

always @(posedge i_sdi_clk)
begin
    shiftreg8_hfls <= {shiftreg8_hfls[6:0],sdi_out_start};
end


//使用首字跌落的FIFO，需要打一拍，使用正常FIFO就不需要
// assign fifo_dout_to_y = {fifo_dout[7:0], 2'b00};
// assign fifo_dout_to_c = {fifo_dout[15:8], 2'b00};
always @(posedge i_sdi_clk)
begin
    fifo_dout_to_y <= {fifo_dout[7:0], 2'b00};
    fifo_dout_to_c <= {fifo_dout[15:8], 2'b00};
end

assign hori_first_line_start_vld = shiftreg8_hfls[2];

    sdi_pattern_gen  u0_patgen (
    .i_clk              (   i_sdi_clk                   ),	
    .i_rst              (   i_rst                       ),	
    .i_video_mode       (   i_video_mode                ),
    .i_sdi_enable       (   hori_first_line_start_vld   ),
    .i_sdi_tx_data      (   {fifo_dout_to_y,fifo_dout_to_c}),
    .o_sdi_data_req     (   fifo_rd_req                 ),
    .o_sdi_fval         (   sdi_fval                    ),
    .o_sdi_dout         (   {sdi_y,sdi_c}               ),
    .o_sdi_ln           (   o_tx_sdi_line_number        ),
    .o_sdi_wn           (                               )
    );
    assign o_tx_sdi_data = {sdi_c,sdi_y};

// (* mark_debug = "true" *)Fsm_e              mark_smpet_state;  
// (* mark_debug = "true" *)logic              mark_smpet_fifo_wr;
// (* mark_debug = "true" *)logic  [18:0]      mark_smpet_fifo_din;
// (* mark_debug = "true" *)logic              mark_smpet_fifo_empty;  
// (* mark_debug = "true" *)logic              mark_smpet_fifo_wr_rst_busy;      
// (* mark_debug = "true" *)logic              mark_smpet_fifo_full; 
// (* mark_debug = "true" *)logic              mark_smpet_fifo_prog_full;
// (* mark_debug = "true" *)logic  [18:0]      mark_smpet_fifo_dout;
// (* mark_debug = "true" *)logic              mark_smpet_fifo_rd;
// (* mark_debug = "true" *)logic  [13:0]      mark_smpet_fifo_rd_data_count;
// (* mark_debug = "true" *)logic              mark_smpet_fifo_rd_rst_busy;
// (* mark_debug = "true" *)logic	[15:0]      mark_smpet_str_data;
// (* mark_debug = "true" *)logic	            mark_smpet_str_user;    
// (* mark_debug = "true" *)logic	            mark_smpet_str_vld;
// (* mark_debug = "true" *)logic	            mark_smpet_str_last;
// (* mark_debug = "true" *)logic	            mark_smpet_stm_flush;
// (* mark_debug = "true" *)logic	            mark_smpet_sdi_out_start;
// (* mark_debug = "true" *)logic	            mark_smpet_sdi_out_vld;    
// (* mark_debug = "true" *)logic	[2:0]       mark_smpet_vs;
// (* mark_debug = "true" *)logic	[2:0]       mark_smpet_hs;
// (* mark_debug = "true" *)logic	[4:0]       mark_smpet_fsm_gen_smpte;
// (* mark_debug = "true" *)logic	            mark_smpet_hori_first_line_start_vld;
// (* mark_debug = "true" *)logic              mark_smpet_tuser;    
// (* mark_debug = "true" *)logic              mark_smpet_tvalid; 
// (* mark_debug = "true" *)logic              mark_smpet_tlast;
// (* mark_debug = "true" *)logic	[15:0]      mark_smpet_tdata;
// (* mark_debug = "true" *)logic              mark_smpet_tready;
// (* mark_debug = "true" *)logic  [31:0]      mark_smpet_wr_fifo_cnt;
// (* mark_debug = "true" *)logic  [31:0]      mark_smpet_rd_fifo_cnt;


    // assign mark_smpet_tuser = s_axis.tuser;    
    // assign mark_smpet_tvalid = s_axis.tvalid;  
    // assign mark_smpet_tlast = s_axis.tlast; 
    // assign mark_smpet_tready = s_axis.tready;  
    // assign mark_smpet_tdata = s_axis.tdata;
    // assign mark_smpet_word_count = word_count; 
    // assign mark_smpet_line_count = line_count;         

    // always @(posedge s_axis.clk)
    // begin
    //     if (s_axis.tready & s_axis.tvalid & s_axis.tuser) begin
    //         mark_smpet_wr_fifo_cnt <= 32'd0;
    //     end
    //     else if (fifo_wr == 1'b1) begin
    //         mark_smpet_wr_fifo_cnt <= mark_smpet_wr_fifo_cnt + 32'd1;
    //     end
    // end

    // always @(posedge i_sdi_clk)
    // begin
    //     if (state == IDLE) begin
    //         mark_smpet_rd_fifo_cnt <= 32'd0;
    //     end
    //     else if (fifo_rd == 1'b1) begin
    //         mark_smpet_rd_fifo_cnt <= mark_smpet_rd_fifo_cnt + 32'd1;
    //     end
    // end


    // assign mark_smpet_fifo_wr            = fifo_wr            ;
    // assign mark_smpet_fifo_din           = fifo_din           ;
    // assign mark_smpet_fifo_empty         = fifo_empty         ;  
    // assign mark_smpet_fifo_wr_rst_busy   = fifo_wr_rst_busy   ;      
    // assign mark_smpet_fifo_full          = fifo_full          ; 
    // assign mark_smpet_fifo_dout          = fifo_dout          ;
    // assign mark_smpet_fifo_rd            = fifo_rd            ;
    // assign mark_smpet_fifo_rd_data_count = fifo_rd_data_count ;
    // assign mark_smpet_fifo_rd_rst_busy   = fifo_rd_rst_busy   ;
    // assign mark_smpet_fifo_prog_full     = fifo_prog_full     ;       


    // assign mark_smpet_str_data              = str_data          ;
    // assign mark_smpet_str_user              = str_user          ;    
    // assign mark_smpet_str_vld               = str_vld           ;
    // assign mark_smpet_str_last              = str_last          ;
    // assign mark_smpet_stm_flush             = stm_flush         ;
    // assign mark_smpet_sdi_out_start         = sdi_out_start     ;
    // assign mark_smpet_sdi_out_vld           = sdi_out_vld       ;    
    // assign mark_smpet_vs                    = vs                ;
    // assign mark_smpet_hs                    = hs                ;
    // assign mark_smpet_state                 = state             ;
    // assign mark_smpet_fsm_gen_smpte         = fsm_gen_smpte     ;
    // assign mark_smpet_hori_first_line_start_vld = hori_first_line_start_vld;


endmodule
