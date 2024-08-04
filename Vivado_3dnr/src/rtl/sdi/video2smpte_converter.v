`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:  luster
// Engineer:  lz
// 
// Create Date:     20/08/2021 
// Design Name: 
// Module Name:    video2smpte_converter
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////


module video2smpte_converter#(
    parameter STM 	= "STM"
)
(
    //----global signals
    rst,
    clk_sdi,
    clk_vid,
    
    //---- input video frame
    vid_hblank,
    vid_vblank,
    vid_active_vid_en,
    vid_data_y,
    vid_data_c,
    
    i_stm_clk,
	i_str_data,
	i_str_vld,
	i_str_user,	
	i_str_last,
	o_str_rdy,



    
    //---- output sdi smpte frame
    tx_sdi_data,
    tx_sdi_line_number

    

);
//----global signals
input rst;
input clk_vid;
output wire clk_sdi;

//---- input sdi smpte frame
input vid_hblank;
input vid_vblank;
input vid_active_vid_en;
input [7:0] vid_data_y;
input [7:0] vid_data_c;

input 						i_stm_clk;
input 	[15:0]              i_str_data;
input 						i_str_vld;
input 						i_str_user;	
input 						i_str_last;
output						o_str_rdy;


//---- input video frame
output wire [19:0] tx_sdi_data;
output wire [10:0] tx_sdi_line_number;

//---------def params---------------------
parameter [11:0] CNT_HD_HANC_WORD           = 12'd272;
parameter [12:0] CNT_WORDS_PER_ACTIVE_LINE  = 13'd1920;
parameter [10:0] CNT_LINES_PER_FRAME        = 11'd1125;
parameter [0:0]  CFG_IS_PRO_OR_INTER        = 1'b1; 

parameter [10:0] CNT_FIRST_LINES_FIELD1        = 11'd1;
parameter [10:0] CNT_FIRST_LINES_FIELD2        = 11'd584;

parameter [10:0] CNT_ACT_START_LINES_FIELD1         = 11'd21;
parameter [10:0] CNT_UNACT_START_LINES_FIELD1       = 11'd561;
parameter [10:0] CNT_ACT_START_LINES_FIELD2         = 11'd584;
parameter [10:0] CNT_UNACT_START_LINES_FIELD2       = 11'd1124;

parameter [10:0] CNT_ACT_START_LINES_PRO_FRAME          = 11'd42;
parameter [10:0] CNT_UNACT_START_LINES_PRO_FRAME        = 11'd1122;



//---------def localparams------------------
localparam[4:0] FSM_GEN_IDLE   = 5'b00000;
localparam[4:0] FSM_GEN_EAV_1  = 5'b00001;
localparam[4:0] FSM_GEN_EAV_2  = 5'b00010;
localparam[4:0] FSM_GEN_EAV_3  = 5'b00011;
localparam[4:0] FSM_GEN_EAV_4  = 5'b00100;
localparam[4:0] FSM_GEN_HANC   = 5'b00101;
localparam[4:0] FSM_GEN_HANC_Y = 5'b00110;
localparam[4:0] FSM_GEN_SAV_1  = 5'b00111;
localparam[4:0] FSM_GEN_SAV_2  = 5'b01000;
localparam[4:0] FSM_GEN_SAV_3  = 5'b01001;
localparam[4:0] FSM_GEN_SAV_4  = 5'b01010;
localparam[4:0] FSM_GEN_AP     = 5'b01011;
localparam[4:0] FSM_GEN_AP_Y   = 5'b01100;
localparam[4:0] FSM_GEN_ADF0   = 5'b01101;
localparam[4:0] FSM_GEN_ADF1   = 5'b01110;
localparam[4:0] FSM_GEN_ADF2   = 5'b01111;
localparam[4:0] FSM_GEN_DID    = 5'b10000;
localparam[4:0] FSM_GEN_SDID   = 5'b10001;
localparam[4:0] FSM_GEN_DC     = 5'b10010;
localparam[4:0] FSM_GEN_UDW1   = 5'b10011;
localparam[4:0] FSM_GEN_UDW2   = 5'b10100;
localparam[4:0] FSM_GEN_UDW3   = 5'b10101;
localparam[4:0] FSM_GEN_UDW4   = 5'b10110;
localparam[4:0] FSM_GEN_CS     = 5'b10111;
localparam[4:0] FSM_GEN_LN_CRC = 5'b11000;

localparam[9:0] Y_BLANKING_DATA = 10'h040;
localparam[9:0] C_BLANKING_DATA = 10'h200;
localparam[9:0] Y_VANC_DATA = 10'h268;
localparam[9:0] C_VANC_DATA = 10'h092;



    //----------def vars-----------------------
    wire hvalid;
    wire vvalid;
    reg vvalid_d1;
    reg vvalid_d2;
    reg vert_start;
    reg hori_first_line_start;
    reg [7:0] shiftreg8_hfls;
    wire hori_first_line_start_vld;
    
    
    
    reg [7:0] data_y_r;
    reg [7:0] data_c_r;
    
    reg fifo_wr;
    wire [15:0] fifo_din;
    wire fifo_rst;
    wire [15:0] fifo_dout;
    wire fifo_rd;
    
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
    wire [9:0] fifo_dout_to_y;
    wire [9:0] fifo_dout_to_c;
    reg fifo_rd_req;
    
    wire fifo_full;    
    wire [12:0] rd_data_count;
generate
    if (STM == "FRAME") begin

        //-----------------------------start here-----------------------------------
        assign clk_sdi = clk_vid;

        assign hvalid = vid_active_vid_en;
        assign vvalid = ~vid_vblank;


        //------------- value clamp-------------------

        always @(posedge clk_vid)
        begin
            if(vid_data_y < 8'd16)
                data_y_r <= 8'd16;
            else if(vid_data_y > 8'd235)
                data_y_r <= 8'd235;
            else if(vid_data_y == 8'h44)
                data_y_r <= 8'h45;
            else
                data_y_r <= vid_data_y;       
        end


        always @(posedge clk_vid)
        begin
            if(vid_data_c < 8'd16)
                data_c_r <= 8'd16;
            else if(vid_data_c > 8'd240)
                data_c_r <= 8'd240;
            else
                data_c_r <= vid_data_c;       
        end

        //------------fifo isolate--------------------

        fifo_hd_sdi 
        fifo_u (
            .rst(fifo_rst),
            
            .wr_clk(clk_vid),   
            .wr_en(fifo_wr),
            .din(fifo_din),
            
            .rd_clk(clk_sdi),
            .rd_en(fifo_rd),    
            .dout(fifo_dout),
            
            .full(),                // output wire full
            .empty(),              // output wire empty
            
            .overflow(),
            .underflow(),
            .wr_rst_busy(),  // output wire wr_rst_busy
            .rd_rst_busy()  // output wire rd_rst_busy
        );

        always @(posedge clk_vid)
        begin
            fifo_wr <= hvalid & vvalid;
        end

        assign fifo_din = {data_c_r, data_y_r};
        assign fifo_rst = rst;

        assign fifo_rd = fifo_rd_req;


        //---------------------------------------
        always @(posedge clk_vid)
        begin
            vvalid_d1 <= vvalid;
            vvalid_d2 <= vvalid_d1;
        end

        always @(posedge clk_vid or posedge rst)
        begin
            if(rst)
                vert_start <= 1'b0;
            else
            begin
                if((~vvalid_d2) & vvalid_d1)
                    vert_start <= 1'b1;
            end
        end

        always @(posedge clk_vid or posedge rst)
        begin
            if(rst)
                hori_first_line_start <= 1'b0;
            else
            begin
                if(vert_start & hvalid)
                    hori_first_line_start <= 1'b1;
            end
        end
    end
    else if (STM == "STM") begin


        //-----------------------------start here-----------------------------------
        assign clk_sdi = clk_vid;

        assign hvalid = o_str_rdy & i_str_vld;
        assign vvalid = i_str_user & o_str_rdy & i_str_vld;
        assign o_str_rdy = ~fifo_full;

        //------------- value clamp-------------------

        always @(posedge i_stm_clk)
        begin
            if(i_str_data[7:0] < 8'd16)
                data_y_r <= 8'd16;
            else if(i_str_data[7:0] > 8'd235)
                data_y_r <= 8'd235;
            else if(i_str_data[7:0] == 8'h44)
                data_y_r <= 8'h45;
            else
                data_y_r <= i_str_data[7:0];       
        end


        always @(posedge i_stm_clk)
        begin
            if(i_str_data[15:8] < 8'd16)
                data_c_r <= 8'd16;
            else if(i_str_data[15:8] > 8'd240)
                data_c_r <= 8'd240;
            else
                data_c_r <= i_str_data[15:8];       
        end

        //------------fifo isolate--------------------

        fifo_hd_sdi 
        fifo_u (
            .rst(fifo_rst),
            
            .wr_clk(i_stm_clk),   
            .wr_en(fifo_wr),
            .din(fifo_din),
            
            .rd_clk(clk_vid),
            .rd_en(fifo_rd),    
            .dout(fifo_dout),
            
            .full(),                // output wire full
            .empty(),              // output wire empty
            
            .prog_full(fifo_full),
            .rd_data_count(rd_data_count),
            .overflow(),
            .underflow(),
            .wr_rst_busy(),  // output wire wr_rst_busy
            .rd_rst_busy()  // output wire rd_rst_busy
        );

        always @(posedge i_stm_clk)
        begin
            fifo_wr <= hvalid;
        end

        assign fifo_din = {data_c_r, data_y_r};
        assign fifo_rst = rst;

        assign fifo_rd = fifo_rd_req;


        //---------------------------------------
        always @(posedge i_stm_clk)
        begin
            vvalid_d1 <= vvalid;
            vvalid_d2 <= vvalid_d1;
        end

        always @(posedge i_stm_clk or posedge rst)
        begin
            if(rst)
                vert_start <= 1'b0;
            else
            begin
                if((~vvalid_d2) & vvalid_d1)
                    vert_start <= 1'b1;
            end
        end

        always @(posedge i_stm_clk or posedge rst)
        begin
            if(rst)
                hori_first_line_start <= 1'b0;
            else
            begin
                if(vert_start == 1 && rd_data_count > 13'd4000)
                    hori_first_line_start <= 1'b1;
            end
        end

    end
endgenerate


always @(posedge clk_vid)
begin
    shiftreg8_hfls <= {shiftreg8_hfls[6:0],hori_first_line_start};
end

assign hori_first_line_start_vld = shiftreg8_hfls[7];




//---------------------FSM for smpte---------------------------

always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        fsm_gen_smpte <= FSM_GEN_IDLE;
    end
    else
    begin
        case(fsm_gen_smpte)
        FSM_GEN_IDLE:
        begin
            if(hori_first_line_start_vld)
                fsm_gen_smpte <= FSM_GEN_EAV_1;
        end
        
        FSM_GEN_EAV_1:  fsm_gen_smpte <= FSM_GEN_EAV_2;
        FSM_GEN_EAV_2:  fsm_gen_smpte <= FSM_GEN_EAV_3;
        FSM_GEN_EAV_3:  fsm_gen_smpte <= FSM_GEN_EAV_4;
        FSM_GEN_EAV_4:  fsm_gen_smpte <= FSM_GEN_HANC;
        
        FSM_GEN_HANC:   
        begin
            if(word_count >= CNT_HD_HANC_WORD)
                fsm_gen_smpte <= FSM_GEN_SAV_1;   
            else
                fsm_gen_smpte <= FSM_GEN_HANC;   
        end
        
        FSM_GEN_SAV_1:  fsm_gen_smpte <= FSM_GEN_SAV_2;
        FSM_GEN_SAV_2:  fsm_gen_smpte <= FSM_GEN_SAV_3;
        FSM_GEN_SAV_3:  fsm_gen_smpte <= FSM_GEN_SAV_4;
        FSM_GEN_SAV_4:  fsm_gen_smpte <= FSM_GEN_AP;
        
        FSM_GEN_AP:
        begin
            if(word_count >= CNT_WORDS_PER_ACTIVE_LINE)
                fsm_gen_smpte <= FSM_GEN_EAV_1;   
            else
                fsm_gen_smpte <= FSM_GEN_AP; 
        end
        
        default:    fsm_gen_smpte <= FSM_GEN_IDLE;
        
        endcase
    end        
end

//------------------------------------------
always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        word_count     <= 13'd0;  
    end
    else
    begin
        case(fsm_gen_smpte)
        FSM_GEN_EAV_4:  word_count <= 13'd1;         
        FSM_GEN_HANC: 
        begin
            if(word_count >= CNT_HD_HANC_WORD)
                word_count <= 13'd1; 
            else
                word_count <= word_count + 13'd1; 
        end
        
        FSM_GEN_SAV_4:  word_count <= 13'd1;      
        FSM_GEN_AP:
        begin
            if(word_count >= CNT_WORDS_PER_ACTIVE_LINE)
                word_count <= 13'd1; 
            else
                word_count <= word_count + 13'd1;         
        end
        
        default: word_count <= word_count; 
              
        endcase
    end        
end


always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        line_count <= 11'd0;
    end
    else
    begin
        case(fsm_gen_smpte)
        FSM_GEN_IDLE: line_count <= CNT_ACT_START_LINES_PRO_FRAME;
        FSM_GEN_AP:
        begin
            if(word_count >= CNT_WORDS_PER_ACTIVE_LINE)
            begin
                if(line_count == CNT_LINES_PER_FRAME)
                    line_count <= 11'd1;
                else
                    line_count <= line_count + 11'd1;
            end               
        end
        
        default: line_count <= line_count;
        
        endcase       
    end        
end

//-------------------------------------------
assign FVH = {F,V,H};

always @(*)
begin
    case (FVH)
    3'b000 : calc_xyz = 10'h200;
    3'b001 : calc_xyz = 10'h274;
    3'b010 : calc_xyz = 10'h2ac;
    3'b011 : calc_xyz = 10'h2d8;
    3'b100 : calc_xyz = 10'h31c;
    3'b101 : calc_xyz = 10'h368;
    3'b110 : calc_xyz = 10'h3b0;
    3'b111 : calc_xyz = 10'h3c4;
    endcase
end

always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        F <= 1'b0;   
    end
    else
    begin
        case(fsm_gen_smpte)
        FSM_GEN_IDLE: F <= 1'b0;   
        FSM_GEN_EAV_1:
        begin
            if(CFG_IS_PRO_OR_INTER)
                F <= 1'b0;
            else 
            begin
                if(line_count == CNT_FIRST_LINES_FIELD1)
                    F <= 1'b0;
                else if(line_count == CNT_FIRST_LINES_FIELD2)
                    F <= 1'b1;
            end
        end
        
        default: F <= F;
        
        endcase       
    end        
end


always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        V <= 1'b1;
    end
    else
    begin
        case(fsm_gen_smpte)
        FSM_GEN_IDLE: V <= 1'b1;   
        FSM_GEN_EAV_1:
        begin
            if(CFG_IS_PRO_OR_INTER)
            begin
                if(line_count == CNT_ACT_START_LINES_PRO_FRAME)
                    V <= 1'b0;
                else if(line_count == CNT_UNACT_START_LINES_PRO_FRAME)
                    V <= 1'b1;
            end                
            else 
            begin
                if(line_count == CNT_ACT_START_LINES_FIELD1)
                    V <= 1'b0;
                else if(line_count == CNT_UNACT_START_LINES_FIELD1)
                    V <= 1'b1;
                else if(line_count == CNT_ACT_START_LINES_FIELD2)
                    V <= 1'b0;
                else if(line_count == CNT_UNACT_START_LINES_FIELD2)
                    V <= 1'b1;
            end
        end
        
        default: V <= V;
        
        endcase       
    end        
end


always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        H <= 1'b1;
    end
    else
    begin
        case(fsm_gen_smpte)
        FSM_GEN_IDLE: H <= 1'b1;   
        FSM_GEN_EAV_1: H <= 1'b1;
        FSM_GEN_SAV_1: H <= 1'b0;
        
        default: H <= H;
        
        endcase       
    end        
end

//----------------------------------------------



assign fifo_dout_to_y = {fifo_dout[7:0], 2'b00};
assign fifo_dout_to_c = {fifo_dout[15:8], 2'b00};

always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        data_stream1 <= 10'h000;
        data_stream2 <= 10'h000;
    end
    else
    begin
        case(fsm_gen_smpte)
        FSM_GEN_IDLE: 
        begin
            data_stream1 <= 10'h000;
            data_stream2 <= 10'h000;
        end
        FSM_GEN_EAV_1:
        begin
            data_stream1 <= 10'h3ff;
            data_stream2 <= 10'h3ff;
        end
        FSM_GEN_EAV_2:
        begin
            data_stream1 <= 10'h000;
            data_stream2 <= 10'h000;
        end
        FSM_GEN_EAV_3:
        begin
            data_stream1 <= 10'h000;
            data_stream2 <= 10'h000;
        end
        FSM_GEN_EAV_4:
        begin
            data_stream1 <= calc_xyz;
            data_stream2 <= calc_xyz;
        end
        FSM_GEN_HANC: 
        begin           
            data_stream1 <= Y_BLANKING_DATA;    
            data_stream2 <= C_BLANKING_DATA;            
        end
        FSM_GEN_SAV_1:
        begin
            data_stream1 <= 10'h3ff;
            data_stream2 <= 10'h3ff;
        end
        FSM_GEN_SAV_2:
        begin
            data_stream1 <= 10'h000;
            data_stream2 <= 10'h000;
        end
        FSM_GEN_SAV_3:
        begin
            data_stream1 <= 10'h000;
            data_stream2 <= 10'h000;
        end
        FSM_GEN_SAV_4:
        begin
            data_stream1 <= calc_xyz;
            data_stream2 <= calc_xyz;
        end
        FSM_GEN_AP:
        begin
            if(V)
            begin
                data_stream1 <= Y_VANC_DATA;
                data_stream2 <= C_VANC_DATA;
            end
            else
            begin
                data_stream1 <= fifo_dout_to_y;
                data_stream2 <= fifo_dout_to_c;
            end
        end
        
        default: 
        begin
            data_stream1 <= 10'h000;
            data_stream2 <= 10'h000;
        end
        
        endcase
    end        
end


always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        fifo_rd_req <= 1'b0;
    end
    else
    begin
        case(fsm_gen_smpte)
        FSM_GEN_IDLE:   fifo_rd_req <= 1'b0;  
        
        FSM_GEN_EAV_1:  fifo_rd_req <= 1'b0;  
        
        FSM_GEN_SAV_4: 
        begin
            if(~V)
                fifo_rd_req <= 1'b1;  
        end        
        FSM_GEN_AP:
        begin
            if(~V)
            begin                   
                if(word_count >= CNT_WORDS_PER_ACTIVE_LINE)
                    fifo_rd_req <= 1'b0; 
                else
                    fifo_rd_req <= 1'b1;                     
            end
        end
               
        default: fifo_rd_req <= 1'b0;
        
        endcase       
    end        
end

//-------------------------------------------

assign tx_sdi_data = {data_stream2,data_stream1};
assign tx_sdi_line_number = line_count;







always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        
    end
    else
    begin
    
    end        
end

always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        
    end
    else
    begin
    
    end        
end






always @(posedge clk_vid or posedge rst)
begin
    if(rst)
    begin
        
    end
    else
    begin
    
    end        
end

always @(posedge clk_vid or posedge rst)
begin
    if(rst)
    begin
        
    end
    else
    begin
    
    end        
end

endmodule
