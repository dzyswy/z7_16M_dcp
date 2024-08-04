`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/26 17:53:15
// Design Name: 
// Module Name: video_loss_detector
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module video_loss_detector(
    clk_sdi,
    rst,
    
    vid_in_vblank,
    vid_in_hblank,
    
    vid_in_loss_n
        
);
input clk_sdi;
input rst;

input vid_in_vblank;
input vid_in_hblank;

output wire vid_in_loss_n;

//----------------def param---------------------
parameter CNT_TIMEOUT = 12'hfff;

//-------------def localparam-------------------


    //-----------def vars-----------------------
    reg [11:0] cnt_timeout;
    reg vblank_d1;
    reg vblank_d2;
    
    wire vblank_rising;
    wire vblank_falling;
    
    wire vid_in_lossed;
    reg vid_in_recovered;
//-----------------------start here-----------------------------------

always @(posedge clk_sdi)
begin
    vblank_d1 <= vid_in_vblank;
    vblank_d2 <= vblank_d1;
end

assign vblank_rising = (~vblank_d2) & vblank_d1;
assign vblank_falling = vblank_d2 & (~vblank_d1);

always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        cnt_timeout <= 12'd0;
    end
    else
    begin        
        if(~vid_in_vblank)
        begin
            if(vid_in_hblank)
                cnt_timeout <= 0;            
            else if(cnt_timeout == CNT_TIMEOUT)
                cnt_timeout <= cnt_timeout;  
            else
                cnt_timeout <= cnt_timeout + 12'd1;
        end                
    end        
end


assign vid_in_lossed = (cnt_timeout == CNT_TIMEOUT) ? 1 : 0 ;

always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        vid_in_recovered <= 1;
    end
    else
    begin
        if(vid_in_lossed)
            vid_in_recovered <= 0;
        else if((~vid_in_recovered) & vblank_rising)
            vid_in_recovered <= 1;
    end        
end

assign vid_in_loss_n = vid_in_recovered;




endmodule
