`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:19:52 02/24/2014 
// Design Name: 
// Module Name:    rx_hd_proc 
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
module rx_hd1080_proc(
	input  wire           i_clk,
	input	 wire				rst_n,
	input  wire           i_h,
	input  wire           i_v,
	input  wire           i_f,
	input  wire [9:0]     i_y,
	input  wire [9:0]     i_c,

(* KEEP = "TRUE" *)	output reg [10:0] rx_hd_ln=1,
(* KEEP = "TRUE" *)	output reg [19:0] rx_hd_vid = 0 	
    );
reg [10:0] rx_hd_ln_r=0;
reg h_r0 = 0;
reg h_r1;
reg h_r2;
(* KEEP = "TRUE" *)reg h_r3;

reg v_r0 = 0;
reg v_r1;
reg v_r2;
(* KEEP = "TRUE" *)reg v_r3;

reg [9:0] y_r0 = 0;
reg [9:0] y_r1;
reg [9:0] y_r2;
(* KEEP = "TRUE" *)reg [9:0] y_r3;

reg [9:0] c_r0 = 0;
reg [9:0] c_r1;
reg [9:0] c_r2;
(* KEEP = "TRUE" *)reg [9:0] c_r3;

reg [9:0] vid_y = 0;
reg [9:0] vid_c = 0;
reg f_int = 0;
reg v_int = 0;
reg h_int = 0;
wire p3_int;
wire p2_int;
wire p1_int;
wire p0_int;

reg [9:0] xyz_int = 0;
(* KEEP = "TRUE" *)reg [11:0] pixel_cnt = 0;
(* KEEP = "TRUE" *)reg [10:0] ln_max = 0;
(* KEEP = "TRUE" *)reg [11:0] pixel_max = 0;



always @(posedge i_clk )
begin
	h_r0 <= i_h;
	h_r1 <= h_r0;
	h_r2 <= h_r1;
	h_r3 <= h_r2;

	v_r0 <= i_v;
	v_r1 <= v_r0;
	v_r2 <= v_r1;
	v_r3 <= v_r2;
	
	y_r0 <= i_y;
	y_r1 <= y_r0;
	y_r2 <= y_r1;
	y_r3 <= y_r2;

	c_r0 <= i_c;
	c_r1 <= c_r0;
	c_r2 <= c_r1;
	c_r3 <= c_r2;

end

assign	p3_int = v_int^h_int;
assign	p2_int = f_int^h_int;
assign	p1_int = f_int^v_int;
assign	p0_int = f_int^v_int^h_int;

reg [10:0] ln_dly1 = 0;
reg lock_flag =0;
	

always @(posedge i_clk)
begin	
		
	if(((h_r3==1'b0)&&(h_r2==1'b1))&&((v_r3==1'b0)&&(v_r2==1'b1)))
		rx_hd_ln_r <= 11'd1122;
	else if((rx_hd_ln_r==1125)&&(h_r3==1'b0)&&(h_r2==1'b1))
		rx_hd_ln_r <= 11'd1;
	else if((h_r3==1'b0)&&(h_r2==1'b1))
		rx_hd_ln_r <= rx_hd_ln_r + 1;
	
	if((h_r3==1'b0)&&(h_r2==1'b1))
		pixel_cnt <= 0;
	else if(pixel_cnt < 2300)
		pixel_cnt <= pixel_cnt + 1;
	else
		pixel_cnt <= pixel_cnt;
	
	if(((h_r3==1'b0)&&(h_r2==1'b1))&&((v_r3==1'b0)&&(v_r2==1'b1)))
		ln_max <= rx_hd_ln_r;
		
	if((h_r3==1'b0)&&(h_r2==1'b1))
		pixel_max <= pixel_cnt;
end

reg [12:0] sav1 = 0 ;
reg [12:0] sav2 = 0 ;
reg [12:0] sav3 = 0 ;
reg [12:0] sav4 = 0 ;
reg [12:0] eav1 = 0 ;
reg [12:0] eav2 = 0 ;
reg [12:0] eav3 = 0 ;
reg [12:0] eav4 = 0 ;	
reg [12:0] eav5 = 0 ;
reg [12:0] eav6 = 0 ;

reg [9:0] eav_int = 0 ;
reg [9:0] sav_int = 0 ;

always @(posedge i_clk or negedge rst_n)
if(!rst_n) begin
rx_hd_vid <= {10'h40,10'h200};
end
else begin
			sav1 <= 188;
			sav2 <= 189;
			sav3 <= 190;
			sav4 <= 191;

			eav1 <= 2112;
			eav2 <= 2113;
			eav3 <= 2114;
			eav4 <= 2115;
			eav5 <= 2116;
			eav6 <= 2117;						

			if(rx_hd_ln < 42)
			begin
				eav_int <= 10'h2D8;
				sav_int <= 10'h2AC;
			end
			else if((rx_hd_ln > 41)&&(rx_hd_ln < 1122))
			begin
				eav_int <= 10'h274;
				sav_int <= 10'h200;
			end
			else if(rx_hd_ln > 1121)
			begin
				eav_int <= 10'h2D8;
				sav_int <= 10'h2AC;
			end

	
	if((pixel_cnt==sav1)||(pixel_cnt==eav1))
		vid_y <= 10'h3ff;
	else 	if((pixel_cnt==sav2)||(pixel_cnt==eav2))
		vid_y <= 10'h000;
	else 	if((pixel_cnt==sav3)||(pixel_cnt==eav3))
		vid_y <= 10'h000;		
//	else 	if((pixel_cnt==sav4)||(pixel_cnt==eav4))
//		vid_y <= xyz_int;
	else 	if((pixel_cnt==eav4))
		vid_y <= eav_int;
	else 	if((pixel_cnt==sav4))
		vid_y <= sav_int;
	else 	if(pixel_cnt==eav5)
		vid_y <= {~rx_hd_ln[6],rx_hd_ln[6:0],2'b0};
	else 	if(pixel_cnt==eav6)
		vid_y <= {4'b1000,rx_hd_ln[10:7],2'b0};
	else
		vid_y <= y_r3;		

	if((pixel_cnt==sav1)||(pixel_cnt==eav1))
		vid_c <= 10'h3ff;
	else 	if((pixel_cnt==sav2)||(pixel_cnt==eav2))
		vid_c <= 10'h000;
	else 	if((pixel_cnt==sav3)||(pixel_cnt==eav3))
		vid_c <= 10'h000;		
	else 	if((pixel_cnt==eav4))
		vid_c <= eav_int;
	else 	if((pixel_cnt==sav4))
		vid_c <= sav_int;
	else 	if(pixel_cnt==eav5)
		vid_c <= {~rx_hd_ln[6],rx_hd_ln[6:0],2'b0};
	else 	if(pixel_cnt==eav6)
		vid_c <= {4'b1000,rx_hd_ln[10:7],2'b0};	
	else
	begin
			vid_c <= c_r3;	
	end
	rx_hd_vid <= {vid_y,vid_c};
	
	if(pixel_cnt==eav1)
		rx_hd_ln <= rx_hd_ln_r;
end



endmodule
