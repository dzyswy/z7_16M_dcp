module sdi_makeframe (
  input            hd_sdn,             // 0 : SDI, 1 : HD-SDI
  input            clk,                // 数据时钟
  input            rst,                // 复位信号 高有效
  input            enable,             // 生成是能信号 高有效 
  output reg       din_req,            // 数据请求信号 
  output reg [10:0] line_active,       // 数据有效行计数 
  output reg [10:0] field_line,        // 当前场行计数
  output reg [12:0] word_count,        // 当前行时钟计数
  output reg [10:0] ln,                // 行计数
  output reg [11:0] wn,                // 当前行有效像素计数
  input  [9:0]  din_c,                 // 色度数据输入
  input  [9:0]  din_y,                 // 亮度数据输入
  output [19:0] dout,                  // SDI数据流输出
  output reg    trs,                   // 时序信号
  output       V_out,                  // 场同步信号
  input [10:0] lines_per_frame,        // 一帧总行数
  input [12:0] words_per_active_line,  // 一行像素有效时钟数
  input [12:0] words_per_total_line,   // 一行总时钟数
  input [10:0] f_rise_line,            // 场标志变高行数
  input [10:0] v_fall_line_1,          // 第一场场同步变低行数  在交错行模式下分奇偶场
  input [10:0] v_rise_line_1,          // 第一场场同步变高行数
  input [10:0] v_fall_line_2,          // 第二场场同步变低行数
  input [10:0] v_rise_line_2           // 第二场场同步变低行数

  );

parameter DATA_DELAY = 1;   
parameter SD_10BIT = 0;

parameter [9:0] Y_BLANKING_DATA = 10'h040;
parameter [9:0] C_BLANKING_DATA = 10'h200;

// State values
parameter [3:0] GEN_IDLE   = 4'b0000;
parameter [3:0] GEN_EAV_1  = 4'b0001;
parameter [3:0] GEN_EAV_2  = 4'b0010;
parameter [3:0] GEN_EAV_3  = 4'b0011;
parameter [3:0] GEN_EAV_4  = 4'b0100;
parameter [3:0] GEN_HANC   = 4'b0101;
parameter [3:0] GEN_HANC_Y = 4'b0110;
parameter [3:0] GEN_SAV_1  = 4'b0111;
parameter [3:0] GEN_SAV_2  = 4'b1000;
parameter [3:0] GEN_SAV_3  = 4'b1001;
parameter [3:0] GEN_SAV_4  = 4'b1010;
parameter [3:0] GEN_AP     = 4'b1011;
parameter [3:0] GEN_AP_Y   = 4'b1100;



reg [10:0] line_count;       // Variable
reg [12:0] field_word;       // Word number within field
reg  [3:0] state;
reg        F;
reg        V;






always @ (posedge clk or posedge rst)
begin
  if (rst) begin
    state      <= GEN_IDLE;
    F          <= 1'b0;
    V          <= 1'b1;
    ln         <= 0;
	  wn         <= 0;
    field_line <= 0;
    word_count <= 0;
    field_word <= 0;
    din_req    <= 1'b0;
  end
  // SAV of first active line of first field is the first word generated
  else if (~enable) begin
    ln         <= v_fall_line_1;
    field_line <= 1;
    field_word <= 0;
	  wn         <= 0;
    F          <= 1'b0;
    V          <= 1'b0;
    state      <= GEN_SAV_1;
  end
  else begin
   wn <= wn + 1;
    case (state)

      GEN_IDLE    : begin
                      state <= GEN_EAV_1;
                    end

      GEN_EAV_1   : begin
                      state <= GEN_EAV_2;
                      wn <= 1;
                      // Temp variable assignment
                      line_count = ln;

                      // Reset line count at end of frame
                      if (line_count==lines_per_frame) begin
                        line_count = 1;
								line_active <= 0;
                        F <= 1'b0;
                      end
                      // else just increment on every line
                      else begin
                        line_count = line_count + 1;
								if(~V)
								  line_active <= line_active +1;
							 end

                      // Line number within field may be useful to pattern generator
                      if (field_line>0)
                        field_line <= field_line + 1;

                      // Determine V and F from line number
                      if (line_count==v_fall_line_1 | line_count==v_fall_line_2) begin
                        V <= 1'b0;
                        field_line <= 1;
                      end

                      if (line_count==v_rise_line_1 | line_count==v_rise_line_2) begin
                        V <= 1'b1;
                        field_line <= 0;
                      end

                      if (line_count==f_rise_line)
                        F <= 1'b1;

                      // Assign temp variable back to register
                      ln <= line_count;

                    end

      GEN_EAV_2   : begin
                      state <= GEN_EAV_3;
                    end

      GEN_EAV_3   : begin
                      state <= GEN_EAV_4;
                    end

      GEN_EAV_4   : begin
                      state <= GEN_HANC;
                      word_count <= 1;
                    end

      GEN_HANC    : begin
                      if (hd_sdn) begin
                        if (word_count>=words_per_total_line-words_per_active_line-8) begin
                          state <= GEN_SAV_1;
                          word_count <= 0;
                        end
                        else begin
                          word_count <= word_count + 1;
                          state <= GEN_HANC;
                        end
                      end
                      else
                        state <= GEN_HANC_Y;
                    end

      GEN_HANC_Y  : begin
                      if (word_count>=words_per_total_line-words_per_active_line-4) begin
                        state <= GEN_SAV_1;
                        word_count <= 0;
                      end
                      else begin
                        word_count <= word_count + 1;
                        state <= GEN_HANC;
                      end
                    end

      GEN_SAV_1   : begin
                      state <= GEN_SAV_2;
                    end

      GEN_SAV_2   : begin
                      state <= GEN_SAV_3;
                    end

      GEN_SAV_3   : begin
                      state <= GEN_SAV_4;
                    end

      GEN_SAV_4   : begin
                      state <= GEN_AP;
                      word_count <= 1;
                      din_req <= ~V;
                    end

      GEN_AP      : begin
                      if (hd_sdn) begin
                        if (word_count>=words_per_active_line) begin
                          state <= GEN_EAV_1;
                          word_count <= 0;
                          din_req <= 1'b0;
                        end
                        else begin
                          state <= GEN_AP;
                          word_count <= word_count + 1;
                          din_req <= ~V;
                        end
                        field_word <= field_word + 1;
                      end

                      else begin

                        state <= GEN_AP_Y;
                        field_word <= field_word + 1;
                        din_req <= ~V & SD_10BIT;
                      end

                    end

      GEN_AP_Y    : begin
                      if (word_count>=words_per_active_line) begin
                        din_req <= 1'b0;
                        state <= GEN_EAV_1;
                        word_count <= 0;
                        field_word <= 0;
                      end
                      else begin
                        din_req <= ~V;           // Request data
                        state <= GEN_AP;
                        word_count <= word_count + 1;
                      end
                    end
     endcase
  end
end

//--------------------------------------------------------------------------------------------------
//延迟以同步数据
//--------------------------------------------------------------------------------------------------
reg [DATA_DELAY:1] state3_pipeline;
reg [DATA_DELAY:1] state2_pipeline;
reg [DATA_DELAY:1] state1_pipeline;
reg [DATA_DELAY:1] state0_pipeline;
reg [DATA_DELAY:1] F_pipeline;
reg [DATA_DELAY:1] V_pipeline;
always @ (posedge clk or posedge rst)
begin
  if (rst) begin
    state0_pipeline <= 0;
    state1_pipeline <= 0;
    state2_pipeline <= 0;
    state3_pipeline <= 0;
  end
  else begin
    // Shift values in to pipeline
    state0_pipeline <= {state0_pipeline, state[0]};
    state1_pipeline <= {state1_pipeline, state[1]};
    state2_pipeline <= {state2_pipeline, state[2]};
    state3_pipeline <= {state3_pipeline, state[3]};
    F_pipeline <= {F_pipeline, F};
    V_pipeline <= {V_pipeline, V};
  end
end
wire [3:0] state_matched = {state3_pipeline[DATA_DELAY], state2_pipeline[DATA_DELAY], state1_pipeline[DATA_DELAY], state0_pipeline[DATA_DELAY]};
wire F_matched = F_pipeline[DATA_DELAY];
wire V_matched = V_pipeline[DATA_DELAY];

//--------------------------------------------------------------------------------------------------
// 生成时序基准信号TRS
//--------------------------------------------------------------------------------------------------
function [9:0] calc_xyz;
  input [2:0] FVH;
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
endfunction

//--------------------------------------------------------------------------------------------------
// 依照时序，填入对应的数据
//--------------------------------------------------------------------------------------------------
reg [19:0] data;
//reg trs;
always @ (posedge clk or posedge rst)
begin
  if (rst) begin
    data <= 20'b0;
    trs <= 1'b0;
  end
  else begin
    // Default
    data <= 20'b0;
    trs <= 1'b0;

    case (state_matched)

        GEN_EAV_1   : begin
                        data <= {10'h3ff, 10'h3ff};
                        trs <= 1'b1;
                      end

        GEN_EAV_2   : begin
                        data <= {10'h000, 10'h000};
                      end

        GEN_EAV_3   : begin
                        data <= {10'h000, 10'h000};
                      end

        GEN_EAV_4   : begin
                        data[9:0]   <= calc_xyz({F_matched, V_matched, 1'b1});
                        data[19:10] <= calc_xyz({F_matched, V_matched, 1'b1});
                      end

        GEN_HANC    : begin
                        data[9:0]   <= C_BLANKING_DATA;
                        data[19:10] <= Y_BLANKING_DATA;
                      end

        GEN_HANC_Y  : begin
                        data[9:0] <= Y_BLANKING_DATA;
                      end

        GEN_SAV_1   : begin
                        data <= {10'h3ff, 10'h3ff};
                        trs <= 1'b1;
                      end

        GEN_SAV_2   : begin
                        data <= {10'h000, 10'h000};
                      end

        GEN_SAV_3   : begin
                        data <= {10'h000, 10'h000};
                      end

        GEN_SAV_4   : begin
                        data[9:0]   <= calc_xyz({F_matched, V_matched, 1'b0});
                        data[19:10] <= calc_xyz({F_matched, V_matched, 1'b0});
                      end

        GEN_AP      : begin
                        if (V_matched) begin
                          data[9:0]   <= C_BLANKING_DATA;
                          data[19:10] <= Y_BLANKING_DATA;
                        end
                        else begin
                          data[9:0]   <= din_c;
                          data[19:10] <= din_y;
                        end
                      end

        GEN_AP_Y    : begin
                        if (V_matched)
                          data[9:0] <= Y_BLANKING_DATA;
                        else
                          data[9:0] <= din_y;
                      end
    endcase

  end
end

assign dout = data;

reg genhd_v_blank_d;
always@(posedge clk)
begin
  genhd_v_blank_d <= V;
end
reg[11:0] vs_cnt=0;
wire vs_negedge = V && ~genhd_v_blank_d;
always@(posedge clk)
begin
  if(V && trs)
    vs_cnt <= vs_cnt + 1;
  else if(~V)
    vs_cnt <= 0;
  else vs_cnt <= vs_cnt;
end
 reg vs_d=0;
 always@(posedge clk)
 begin
   if(vs_negedge)
     vs_d <= 0;
   else if(vs_cnt == 0)
     vs_d <= 1;
  else if(vs_cnt == 1)
     vs_d <= 0;
  else vs_d <= vs_d;
 end
 assign  V_out = vs_d;

    // (* mark_debug = "true" *)wire   [10:0]  make_frame_line_count;       // Variable
    // (* mark_debug = "true" *)wire   [12:0]  make_frame_field_word;       // Word number within field
    // (* mark_debug = "true" *)wire   [3:0]   make_frame_state;
    // (* mark_debug = "true" *)wire           make_frame_F;
    // (* mark_debug = "true" *)wire           make_frame_V;
    // (* mark_debug = "true" *)wire   [19:0]  make_frame_data;

    // assign make_frame_line_count    = line_count;       // Variable
    // assign make_frame_field_word    = field_word;       // Word number within field
    // assign make_frame_state         = state;
    // assign make_frame_F             = F;
    // assign make_frame_V             = V;
    // assign make_frame_data          = data;













endmodule
