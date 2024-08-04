`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:  luster
// Engineer: lz
// 
// Create Date:     20/08/2021 
// Design Name: 
// Module Name:    sdi2video_converter
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

module sdi2video_converter(
    //----global signals
    rst,
    clk_sdi,
    clk_vid,
    
    //---- input sdi smpte frame
    rx_ds1a,
    rx_ds2a,    
    rx_trs,
    rx_sav,
    rx_eav,
    rx_line_number,

    //---- output video frame
    vid_hblank,
    vid_vblank,
    vid_active_vid_en,
    vid_data
    
);
//----global signals
input rst;
input clk_sdi;
output wire clk_vid;

//---- input sdi smpte frame
input [9:0] rx_ds1a;
input [9:0] rx_ds2a;    
input rx_trs;
input rx_sav;
input rx_eav;
input [10:0] rx_line_number;

//---- output video frame
output wire vid_hblank;
output wire vid_vblank;
output wire vid_active_vid_en;
output wire [15:0] vid_data;




//--------def params-----------------



//-----------def local params--------------
localparam [10:0] VVALID_START_LINE_NUMBER   = 11'd42;
localparam [10:0] VVALID_END_LINE_NUMBER   = 11'd1122;

    //----------def vars----------------
    reg hvalid;
    reg vvalid;
    reg rx_sav_d1;
    reg [15:0] vid_data_i;
    
//--------------------start here---------------------------------------
assign clk_vid = clk_sdi;

always @(posedge clk_sdi)
begin
    rx_sav_d1 <= rx_sav;
end

always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        hvalid <= 0;
    end
    else
    begin
        if((~hvalid) & rx_sav_d1)
            hvalid <= 1'b1;
        else if(hvalid & rx_trs)
            hvalid <= 1'b0;
    end        
end

assign vid_hblank = ~(hvalid & vvalid);
assign vid_active_vid_en = hvalid & vvalid;

always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        vvalid <= 0;
    end
    else
    begin
        if(rx_sav && (rx_line_number == VVALID_START_LINE_NUMBER))
            vvalid <= 1'b1;
        else if(rx_sav && (rx_line_number == VVALID_END_LINE_NUMBER))
            vvalid <= 1'b0;
    end        
end

assign vid_vblank = ~vvalid;


always @(posedge clk_sdi or posedge rst)
begin
    if(rst)
    begin
        vid_data_i <= 16'd0;
    end
    else
    begin
        vid_data_i <= {rx_ds2a[9:2], rx_ds1a[9:2]};
    end        
end

assign vid_data = vid_data_i;



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




endmodule





