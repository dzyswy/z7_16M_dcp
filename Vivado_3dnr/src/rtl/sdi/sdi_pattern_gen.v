module sdi_pattern_gen 
(
  input         i_clk,
  input         i_rst,

  input         i_sdi_enable,

  input  [2:0]  i_video_mode,

  input [19:0]  i_sdi_tx_data,
  output        o_sdi_data_req,

  output        o_sdi_fval,
  output [19:0] o_sdi_dout,
  output [10:0] o_sdi_ln,
  output [11:0] o_sdi_wn  
);

reg [2:0]  video_mode;

reg [10:0] int_lines_per_frame;
reg [12:0] int_words_per_active_line;
reg [12:0] int_words_per_total_line;
reg [10:0] int_f_rise_line;
reg [10:0] int_v_fall_line_1;
reg [10:0] int_v_rise_line_1;
reg [10:0] int_v_fall_line_2;
reg [10:0] int_v_rise_line_2;
reg [10:0] int_patho_change_line_1;
reg [10:0] int_patho_change_line_2;
wire        vout;

wire            req;// 数据请求信号
wire    [19:0]  dout;// SDI输出数据
wire            trs;
wire    [10:0]  ln;
wire    [11:0]  wn; 


wire [9:0] y_make = i_sdi_tx_data[19:10];//输入的像素数据 YUV422格式
wire [9:0] c_make = i_sdi_tx_data[9:0];  //输入的像素数据 YUV422格式


assign o_sdi_data_req = req;
assign o_sdi_dout = dout;
assign o_sdi_ln = ln;
assign o_sdi_wn = wn; 
assign o_sdi_fval = vout;
//--------------------------------------------------------------------------------------------------
//创建输出帧

sdi_makeframe u_makeframe (
  .hd_sdn                   (1'b1),

  .clk                      (i_clk),
  .rst                      (i_rst),
  .enable                   (i_sdi_enable),
  .din_req                  (req),
  .line_active              (),
  .ln                       (ln),
  .field_line               (),
  .word_count               (),
  .wn                       (wn),
  .V_out				    (vout),
  .din_y                    (y_make),
  .din_c                    (c_make),
  .dout                     (dout),
  .trs                      (trs),

  .lines_per_frame          (int_lines_per_frame),
  .words_per_active_line    (int_words_per_active_line),
  .words_per_total_line     (int_words_per_total_line),
  .f_rise_line              (int_f_rise_line),
  .v_fall_line_1            (int_v_fall_line_1),
  .v_rise_line_1            (int_v_rise_line_1),
  .v_fall_line_2            (int_v_fall_line_2),
  .v_rise_line_2            (int_v_rise_line_2)
  );

//--------------------------------------------------------------------------------------------------
//控制视频制式    此处与时钟配合，可添加更多的视频制式
//--------------------------------------------------------------------------------------------------
//{select_std,is_720p}=0000 1080P60
//{select_std,is_720p}=0001 1080P50 
//{select_std,is_720p}=0100 1080I60
//{select_std,is_720p}=0101 720P60
//{select_std,is_720p}=0110 1080P30
//{select_std,is_720p}=10XX NTSC
//{select_std,is_720p}=11XX PAL

always @ (posedge i_clk or posedge i_rst)begin
    if (i_rst) begin
        // 1080p 30
        int_lines_per_frame          <= 11'd1125;
        int_words_per_active_line    <= 13'd1920;
        int_words_per_total_line     <= 13'd2200;
        //int_f_rise_line              <= 11'd1;
        int_f_rise_line              <= 11'd1126;
        int_v_fall_line_1            <= 11'd42;
        int_v_rise_line_1            <= 11'd1122;
        int_v_fall_line_2            <= 11'd0;
        int_v_rise_line_2            <= 11'd0;
        // patho change lines unchanged from 1080i
        int_patho_change_line_1      <= 11'd290;
        int_patho_change_line_2      <= 11'd853;
        video_mode                   <= 3'd2;
    end
    else begin
        video_mode                   <= i_video_mode;
        case (video_mode)
            3'd0:begin
                // 1080p 24
                int_lines_per_frame          <= 11'd1125;
                int_words_per_active_line    <= 13'd1920;
                int_words_per_total_line     <= 13'd2750;
                //int_f_rise_line              <= 11'd1;
                int_f_rise_line              <= 11'd1126;
                int_v_fall_line_1            <= 11'd42;
                int_v_rise_line_1            <= 11'd1122;
                int_v_fall_line_2            <= 11'd0;
                int_v_rise_line_2            <= 11'd0;
                // patho change lines unchanged from 1080i
                int_patho_change_line_1      <= 11'd290;
                int_patho_change_line_2      <= 11'd853;                
            end 
            3'd1:begin
                // 1080p 25
                int_lines_per_frame          <= 11'd1125;
                int_words_per_active_line    <= 13'd1920;
                int_words_per_total_line     <= 13'd2640;
                //int_f_rise_line              <= 11'd1;
                int_f_rise_line              <= 11'd1126;
                int_v_fall_line_1            <= 11'd42;
                int_v_rise_line_1            <= 11'd1122;
                int_v_fall_line_2            <= 11'd0;
                int_v_rise_line_2            <= 11'd0;
                // patho change lines unchanged from 1080i
                int_patho_change_line_1      <= 11'd290;
                int_patho_change_line_2      <= 11'd853;            
            end 
            3'd2:begin
                // 1080p 30
                int_lines_per_frame          <= 11'd1125;
                int_words_per_active_line    <= 13'd1920;
                int_words_per_total_line     <= 13'd2200;
                //int_f_rise_line              <= 11'd1;
                int_f_rise_line              <= 11'd1126;
                int_v_fall_line_1            <= 11'd42;
                int_v_rise_line_1            <= 11'd1122;
                int_v_fall_line_2            <= 11'd0;
                int_v_rise_line_2            <= 11'd0;
                // patho change lines unchanged from 1080i
                int_patho_change_line_1      <= 11'd290;
                int_patho_change_line_2      <= 11'd853;           
            end 
            3'd3:begin 
                // 1080p 50
                int_lines_per_frame          <= 11'd1125;
                int_words_per_active_line    <= 13'd1920;
                int_words_per_total_line     <= 13'd2640;
                //int_f_rise_line              <= 11'd1;
                int_f_rise_line              <= 11'd1126;
                int_v_fall_line_1            <= 11'd42;
                int_v_rise_line_1            <= 11'd1122;
                int_v_fall_line_2            <= 11'd0;
                int_v_rise_line_2            <= 11'd0;
                // patho change lines unchanged from 1080i
                int_patho_change_line_1      <= 11'd290;
                int_patho_change_line_2      <= 11'd853;
            end
            3'd4:begin
                // 1080p 60
                int_lines_per_frame          <= 11'd1125;
                int_words_per_active_line    <= 13'd1920;
                int_words_per_total_line     <= 13'd2200;
                //int_f_rise_line              <= 11'd1;
                int_f_rise_line              <= 11'd1126;
                int_v_fall_line_1            <= 11'd42;
                int_v_rise_line_1            <= 11'd1122;
                int_v_fall_line_2            <= 11'd0;
                int_v_rise_line_2            <= 11'd0;
                // patho change lines unchanged from 1080i
                int_patho_change_line_1      <= 11'd290;
                int_patho_change_line_2      <= 11'd853;
            end
            default:; 
        endcase
    end
end
endmodule
