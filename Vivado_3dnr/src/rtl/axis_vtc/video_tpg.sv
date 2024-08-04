`timescale 1ns/1ps




module video_tpg # (
    parameter DATA_WIDTH        = 16,
    parameter CHESS_WPOW        = 4,
    parameter CHESS_HPOW        = 4,
    parameter DEBUG             = "FALSE"

) (
    input                           rst_n,
    input                           clk,
    input   [3 : 0]                 tpg_mode,

 
    input   [15 : 0]                ACTIVE_WIDTH ,
    input   [15 : 0]                ACTIVE_HEIGHT,
    input   [15 : 0]                FRAME_WIDTH  ,
    input   [15 : 0]                FRAME_HEIGHT ,
    input   [15 : 0]                HBLK_HSTART  ,
    input   [15 : 0]                VBLK_VSTART  ,
    input   [15 : 0]                HSYNC_HSTART ,
    input   [15 : 0]                HSYNC_HEND   ,
    input   [15 : 0]                VSYNC_HSTART ,
    input   [15 : 0]                VSYNC_HEND   ,
    input   [15 : 0]                VSYNC_VSTART ,
    input   [15 : 0]                VSYNC_VEND   , 

    output  [DATA_WIDTH - 1 : 0]    dout,
    output                          en_out,
    output                          hs_out,
    output                          vs_out

);


//----------------------------------------------------------------------------------------------
// struct define
//----------------------------------------------------------------------------------------------


typedef struct {

    logic [15 : 0]              hcnt;
    logic [15 : 0]              vcnt;
    logic [15 : 0]              fcnt; 


    logic [1 : 0]               hvld; 
    logic [1 : 0]               vvld;
    logic [1 : 0]               hsync;
    logic [1 : 0]               vsync;

    logic [15 : 0]              xcnt;
    logic [15 : 0]              ycnt; 

    logic [DATA_WIDTH - 1 : 0]  chess;
    logic [DATA_WIDTH - 1 : 0]  gray_x;
    logic [DATA_WIDTH - 1 : 0]  gray_y;
    logic [DATA_WIDTH - 1 : 0]  gray_x_run;
    logic [DATA_WIDTH - 1 : 0]  gray_y_run;

    logic [DATA_WIDTH - 1 : 0]  pattern;
    logic                       pattern_en;
    logic                       pattern_hs;
    logic                       pattern_vs;

}logic_s;


//----------------------------------------------------------------------------------------------
// Register define
//----------------------------------------------------------------------------------------------


logic_s r, rn;


//----------------------------------------------------------------------------------------------
// sequential always
//----------------------------------------------------------------------------------------------	

always_ff @ (posedge clk) begin
    r <= #1 rn;
    if (rst_n == 1'b0) begin

        r.hcnt <= #1 'd0;
        r.vcnt <= #1 'd0;
        r.fcnt <= #1 'd0;

        for (int i = 0; i < 2; i++) begin
            r.hvld[i] <= #1 'd0;
            r.vvld[i] <= #1 'd0;
            r.hsync[i] <= #1 'd0;
            r.vsync[i] <= #1 'd0;
        end

        r.xcnt <= #1 'd0;
        r.ycnt <= #1 'd0; 

        r.chess <= #1 'd0;
        r.gray_x <= #1 'd0;
        r.gray_y <= #1 'd0;
        r.gray_x_run <= #1 'd0;
        r.gray_y_run <= #1 'd0; 

        r.pattern <= #1 'd0;
        r.pattern_en <= #1 'd0;
        r.pattern_hs <= #1 'd0;
        r.pattern_vs <= #1 'd0;
    end


end

//----------------------------------------------------------------------------------------------
// combinatorial always
//----------------------------------------------------------------------------------------------

always_comb begin

    rn = r;

    //hcnt vcnt fcnt
    if (r.hcnt == (FRAME_WIDTH - 1)) begin
        rn.hcnt = 'd0;

        if (r.vcnt == (FRAME_HEIGHT - 1)) begin
            rn.vcnt = 'd0;
            rn.fcnt = r.fcnt + 1;
        end
        else begin
            rn.vcnt <= r.vcnt + 1;
        end

    end
    else begin
        rn.hcnt = r.hcnt + 1;
    end

    //hvld 
    if (r.hcnt == HBLK_HSTART) begin
        rn.hvld[0] = 1'b1;
    end
    else if (r.hcnt == (HBLK_HSTART + ACTIVE_WIDTH)) begin
        rn.hvld[0] = 1'b0;
    end

    //vvld
    if (r.vcnt == VBLK_VSTART) begin
        rn.vvld[0] = 1'b1;
    end
    else if (r.vcnt == (VBLK_VSTART + ACTIVE_HEIGHT)) begin
        rn.vvld[0] = 1'b0;
    end

    //hsync
    if (r.hcnt == HSYNC_HSTART) begin
        rn.hsync[0] = 1'b1;
    end
    else if (r.hcnt == (HSYNC_HEND)) begin
        rn.hsync[0] = 1'b0;
    end

    //vsync
    if ((r.hcnt == VSYNC_HSTART) && (r.vcnt == VSYNC_VSTART)) begin
        rn.vsync[0] = 1'b1;
    end
    else if ((r.hcnt == VSYNC_HEND) && (r.vcnt == VSYNC_VEND)) begin
        rn.vsync[0] = 1'b0;
    end

    rn.hvld[1] = r.hvld[0];
    rn.vvld[1] = r.vvld[0];
    rn.hsync[1] = r.hsync[0];
    rn.vsync[1] = r.vsync[0];


    //xcnt ycnt
    if (r.hvld[0] == 1'b0) begin
        rn.xcnt = 'd0;
    end
    else begin
        rn.xcnt = r.xcnt + 1;
    end

    if (r.vvld[0] == 1'b0) begin
        rn.ycnt = 'd0;
    end
    else if (r.hcnt == (FRAME_WIDTH - 1)) begin
        rn.ycnt = r.ycnt + 1;
    end

    //chess
    if (r.xcnt[CHESS_WPOW] == r.ycnt[CHESS_HPOW]) begin
        rn.chess = ~0;
    end
    else begin
        rn.chess = 0;
    end

    //gray_x
    rn.gray_x = r.xcnt[DATA_WIDTH - 1 : 0];

    //gray_y
    rn.gray_y = r.ycnt[DATA_WIDTH - 1 : 0];

    //gray_x_run
    rn.gray_x_run = r.xcnt + r.fcnt;

    //gray_y_run
    rn.gray_y_run = r.ycnt + r.fcnt;

    //pattern
    case (tpg_mode)
        4'h0: begin
            rn.pattern = r.chess;
        end

        4'h1: begin
            rn.pattern = r.gray_x;
        end

        4'h2: begin
            rn.pattern = r.gray_y;
        end

        4'h3: begin
            rn.pattern = r.gray_x_run;
        end

        4'h4: begin
            rn.pattern = r.gray_y_run;
        end

        4'h5: begin
            rn.pattern = ~0;
        end

        default: begin
            rn.pattern = 0;
        end

    endcase

    rn.pattern_en = r.hvld[1] & r.vvld[1];
    rn.pattern_hs = r.hsync[1];
    rn.pattern_vs = r.vsync[1];

end



//----------------------------------------------------------------------------------------------
// output assignment
//----------------------------------------------------------------------------------------------

assign dout = r.pattern;
assign en_out = r.pattern_en;
assign hs_out = r.pattern_hs;
assign vs_out = r.pattern_vs;

//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
if(DEBUG == "TRUE") begin

        

    (* mark_debug = "true" *)logic [15 : 0]              mark_ACTIVE_WIDTH  ;
    (* mark_debug = "true" *)logic [15 : 0]              mark_ACTIVE_HEIGHT ;
    (* mark_debug = "true" *)logic [15 : 0]              mark_FRAME_WIDTH   ;
    (* mark_debug = "true" *)logic [15 : 0]              mark_FRAME_HEIGHT  ; 
    (* mark_debug = "true" *)logic [15 : 0]              mark_HBLK_HSTART   ;
    (* mark_debug = "true" *)logic [15 : 0]              mark_VBLK_VSTART   ;
    (* mark_debug = "true" *)logic [15 : 0]              mark_HSYNC_HSTART  ;
    (* mark_debug = "true" *)logic [15 : 0]              mark_HSYNC_HEND    ;
    (* mark_debug = "true" *)logic [15 : 0]              mark_VSYNC_HSTART  ;
    (* mark_debug = "true" *)logic [15 : 0]              mark_VSYNC_HEND    ;
    (* mark_debug = "true" *)logic [15 : 0]              mark_VSYNC_VSTART  ;
    (* mark_debug = "true" *)logic [15 : 0]              mark_VSYNC_VEND    ;

    (* mark_debug = "true" *)logic [15 : 0]              mark_hcnt;
    (* mark_debug = "true" *)logic [15 : 0]              mark_vcnt;
    (* mark_debug = "true" *)logic [15 : 0]              mark_fcnt;  
    (* mark_debug = "true" *)logic [1 : 0]               mark_hvld; 
    (* mark_debug = "true" *)logic [1 : 0]               mark_vvld;
    (* mark_debug = "true" *)logic [1 : 0]               mark_hsync;
    (* mark_debug = "true" *)logic [1 : 0]               mark_vsync; 
    (* mark_debug = "true" *)logic [15 : 0]              mark_xcnt;
    (* mark_debug = "true" *)logic [15 : 0]              mark_ycnt;  
    (* mark_debug = "true" *)logic [DATA_WIDTH - 1 : 0]  mark_chess;
    (* mark_debug = "true" *)logic [DATA_WIDTH - 1 : 0]  mark_gray_x;
    (* mark_debug = "true" *)logic [DATA_WIDTH - 1 : 0]  mark_gray_y;
    (* mark_debug = "true" *)logic [DATA_WIDTH - 1 : 0]  mark_gray_x_run;
    (* mark_debug = "true" *)logic [DATA_WIDTH - 1 : 0]  mark_gray_y_run; 
    (* mark_debug = "true" *)logic [DATA_WIDTH - 1 : 0]  mark_pattern;
    (* mark_debug = "true" *)logic                       mark_pattern_en;
    (* mark_debug = "true" *)logic                       mark_pattern_hs;
    (* mark_debug = "true" *)logic                       mark_pattern_vs;


    assign mark_ACTIVE_WIDTH                            = ACTIVE_WIDTH  ;
    assign mark_ACTIVE_HEIGHT                           = ACTIVE_HEIGHT ;
    assign mark_FRAME_WIDTH                             = FRAME_WIDTH   ;
    assign mark_FRAME_HEIGHT                            = FRAME_HEIGHT  ;
    assign mark_HBLK_HSTART                             = HBLK_HSTART   ;
    assign mark_VBLK_VSTART                             = VBLK_VSTART   ;
    assign mark_HSYNC_HSTART                            = HSYNC_HSTART  ;
    assign mark_HSYNC_HEND                              = HSYNC_HEND    ;
    assign mark_VSYNC_HSTART                            = VSYNC_HSTART  ;
    assign mark_VSYNC_HEND                              = VSYNC_HEND    ;
    assign mark_VSYNC_VSTART                            = VSYNC_VSTART  ;
    assign mark_VSYNC_VEND                              = VSYNC_VEND    ;



    assign mark_hcnt                                    = r.hcnt;
    assign mark_vcnt                                    = r.vcnt;
    assign mark_fcnt                                    = r.fcnt;    
    assign mark_hvld                                    = r.hvld;  
    assign mark_vvld                                    = r.vvld;
    assign mark_hsync                                   = r.hsync;
    assign mark_vsync                                   = r.vsync;  
    assign mark_xcnt                                    = r.xcnt;
    assign mark_ycnt                                    = r.ycnt;    
    assign mark_chess                                   = r.chess;
    assign mark_gray_x                                  = r.gray_x;
    assign mark_gray_y                                  = r.gray_y;
    assign mark_gray_x_run                              = r.gray_x_run;
    assign mark_gray_y_run                              = r.gray_y_run; 
    assign mark_pattern                                 = r.pattern;
    assign mark_pattern_en                              = r.pattern_en;
    assign mark_pattern_hs                              = r.pattern_hs;
    assign mark_pattern_vs                              = r.pattern_vs;


         
end
endgenerate




endmodule
