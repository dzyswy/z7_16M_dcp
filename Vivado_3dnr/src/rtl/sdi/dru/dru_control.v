//-----------------------------------------------------------------------------
//  (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//------------------------------------------------------------------------------
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: $Revision: #3 $
//  \   \         
//  /   /         Filename: $File: //Groups/video_ip/demos/K7/xapp592_k7_sdi_demos/verilog/dru/dru_control.v $
// /___/   /\     Timestamp: $DateTime: 2012/08/16 15:03:57 $
// \   \  /  \
//  \___\/\___\
//
// Description:
//  Control logic for NI-DRU barrel shifter.
//------------------------------------------------------------------------------
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES. 
//
//----------------------------------------------------------
`timescale 1ns / 1ps

module dru_control (
    input  wire         CLK,        // clock      
    input  wire         RST,        // reset  
    input  wire [3:0]   DV,         // data valid 
    output wire [4:0]   SHIFT,      // shift
    output wire         WRFLAG,     // write flags  
    output wire         VALID);     // valid 

    reg  [4:0] pointer = 5'b0;
    reg  flag_d = 1'b0;
    reg  wrflags = 1'b0;
    reg  valids = 1'b0;
    wire flag;
    wire [4:0] temp;

    // pointer
    assign temp = pointer + {1'b0, DV};
    
    always @(posedge CLK)
        if (RST == 1'b0)
            pointer <= 5'b00000;
        else
            begin
               if (temp <= 5'b10011)
                   pointer <= temp;
               else
                   pointer <= temp - 5'b10100; 
            end


    assign SHIFT = pointer;                
    assign flag =  (pointer < 5'b01010) ?  1'b0 : 1'b1;       

    always @(posedge CLK)
        if (RST == 1'b0)
            flag_d <= 1'b0;
        else
            flag_d <= flag;

    always @(posedge CLK)
        if (RST == 1'b0)
            wrflags <= 1'b0;
        else
            begin
                wrflags <= flag_d;
                valids <= flag ^ flag_d;
            end
    
    assign WRFLAG = wrflags;
    assign VALID  = valids;

endmodule                
