`timescale 1ns/1ps


module video_crop # (
    parameter DATA_WIDTH = 16,
    parameter DEBUG = "FALSE"
) (
    input                           rst_n,
    input                           clk,


    input   [15 : 0]                CROP_X,
    input   [15 : 0]                CROP_Y,
    input   [15 : 0]                CROP_W,
    input   [15 : 0]                CROP_H,


    input   [DATA_WIDTH - 1 : 0]    din,
    input                           en_in,
    input                           vs_in,




 
    output  [DATA_WIDTH - 1 : 0]    dout,
    output                          en_out,
    output                          vs_out
);

 


//----------------------------------------------------------------------------------------------
// struct define
//----------------------------------------------------------------------------------------------
typedef struct {

    logic   [DATA_WIDTH - 1 : 0]        frame_data[2 : 0];
    logic   [2 : 0]                     frame_en;
    logic   [2 : 0]                     frame_vs;
 
    logic   [15 : 0]                    xcnt;
    logic   [15 : 0]                    ycnt;

    logic                               hvld;
    logic                               vvld;

    logic   [DATA_WIDTH - 1 : 0]        video_data;
    logic                               video_en;
    logic                               video_vs;
 

}logic_s;



//----------------------------------------------------------------------------------------------
// Register define
//----------------------------------------------------------------------------------------------
logic_s r, rn;
 



//----------------------------------------------------------------------------------------------
// frame domain
//----------------------------------------------------------------------------------------------



always_ff @ (posedge clk) begin
    r <= #1 rn;
    if (rst_n == 1'b0) begin

        for (int i = 0; i < 3; i++) begin
            r.frame_data[i] <= #1 'd0;
            r.frame_en[i] <= #1 'd0;
            r.frame_vs[i] <= #1 'd0;
        end
 
        r.xcnt <= #1 'd0;
        r.ycnt <= #1 'd0; 

        r.hvld <= #1 'd0;
        r.vvld <= #1 'd0; 

        r.video_data <= #1 'd0; 
        r.video_en <= #1 'd0; 
        r.video_vs <= #1 'd0; 
 
    end
 
end

always_comb begin

    rn = r;

    //frame_data frame_en frame_vs
    rn.frame_data[0] = din;
    rn.frame_data[1] = r.frame_data[0];
    rn.frame_data[2] = r.frame_data[1];


    rn.frame_en[0] = en_in;
    rn.frame_en[1] = r.frame_en[0];
    rn.frame_en[2] = r.frame_en[1];

    rn.frame_vs[0] = vs_in;
    rn.frame_vs[1] = r.frame_vs[0];
    rn.frame_vs[2] = r.frame_vs[1];

    //ycnt
    if (vs_in == 0) begin
        rn.ycnt = 'd0;
    end
    else begin
        if ((en_in == 1'b0) && (r.frame_en[0] == 1'b1)) begin
            if (r.ycnt == 16'hffff) begin
                rn.ycnt = 16'hffff;
            end
            else begin
                rn.ycnt = r.ycnt + 1;
            end
        end
    end

    //xcnt
    // if (en_in == 1'b0) begin
    //     rn.xcnt = 'd0;
    // end
    // else begin
    //     if (r.xcnt == 16'hffff) begin
    //         rn.xcnt = 16'hffff;
    //     end
    //     else begin
    //         rn.xcnt = r.xcnt + 1;
    //     end
    // end

    if ((en_in == 1'b1) && (r.frame_en[0] == 1'b0)) begin
        rn.xcnt = 'd0;
    end
    else begin
        if (r.xcnt == 16'hffff) begin
            rn.xcnt = 16'hffff;
        end
        else begin
            rn.xcnt = r.xcnt + 1;
        end
    end

    //hvld
    if (r.xcnt == CROP_X) begin
        rn.hvld = 1'b1;
    end
    else if (r.xcnt == (CROP_X + CROP_W)) begin
        rn.hvld = 1'b0;
    end

    //vvld
    if (r.ycnt == CROP_Y) begin
        rn.vvld = 1'b1;
    end
    else if (r.ycnt == (CROP_Y + CROP_H)) begin
        rn.vvld = 1'b0;
    end


    //dout
    rn.video_data = r.frame_data[1];
    rn.video_en = r.frame_en[1] & r.hvld & r.vvld;
    rn.video_vs = r.frame_vs[1];

end




//----------------------------------------------------------------------------------------------
// output assignment
//----------------------------------------------------------------------------------------------
assign dout = r.video_data;
assign en_out = r.video_en;
assign vs_out = r.video_vs;

//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
    if(DEBUG == "TRUE") begin


        (* mark_debug = "true" *)logic    [15 : 0]                  mark_CROP_X;
        (* mark_debug = "true" *)logic    [15 : 0]                  mark_CROP_Y;
        (* mark_debug = "true" *)logic    [15 : 0]                  mark_CROP_W;
        (* mark_debug = "true" *)logic    [15 : 0]                  mark_CROP_H;

        (* mark_debug = "true" *)logic    [DATA_WIDTH - 1 : 0]      mark_din;
        (* mark_debug = "true" *)logic                              mark_en_in;
        (* mark_debug = "true" *)logic                              mark_vs_in;

        (* mark_debug = "true" *)logic    [15 : 0]                  mark_xcnt;
        (* mark_debug = "true" *)logic    [15 : 0]                  mark_ycnt;

        (* mark_debug = "true" *)logic                              mark_hvld;
        (* mark_debug = "true" *)logic                              mark_vvld;

        (* mark_debug = "true" *)logic    [DATA_WIDTH - 1 : 0]      mark_dout;
        (* mark_debug = "true" *)logic                              mark_en_out;
        (* mark_debug = "true" *)logic                              mark_vs_out;

 
        assign mark_CROP_X                                          = CROP_X;
        assign mark_CROP_Y                                          = CROP_Y;
        assign mark_CROP_W                                          = CROP_W;
        assign mark_CROP_H                                          = CROP_H;
        assign mark_din                                             = din;
        assign mark_en_in                                           = en_in;
        assign mark_vs_in                                           = vs_in;
        assign mark_xcnt                                            = r.xcnt;
        assign mark_ycnt                                            = r.ycnt;
        assign mark_hvld                                            = r.hvld;
        assign mark_vvld                                            = r.vvld;
        assign mark_dout                                            = r.video_data;
        assign mark_en_out                                          = r.video_en;
        assign mark_vs_out                                          = r.video_vs;
         

                                                  

        
    end
endgenerate



endmodule
