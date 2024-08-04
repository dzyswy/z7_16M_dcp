// (c) Copyright 2011 - 2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
//------------------------------------------------------------------------------
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: $Revision: #2 $
//  \   \         
//  /   /         Filename: $File: //Groups/video_ip/demos/K7/xapp592_k7_sdi_demos/verilog/SDI_wrapper/x7gtx_reset_control.v $
// /___/   /\     Timestamp: $DateTime: 2012/08/16 15:23:21 $
// \   \  /  \
//  \___\/\___\
//
// Description:
//  This module implements the finite state machine that controls the GTXRESET of
//  7-series GTX transceiver.
//------------------------------------------------------------------------------
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.

`timescale 1 ns / 1 ns

module x7gtx_reset_control #( 
    parameter PLLLOCKDLY            = 4)            // Width, in bits, of the PLL lock delay counter
(
    input   wire        clk,                        // Fixed clock
    input   wire        pll_reset,                  // PLL reset input
    input   wire        pll_lock,                   // PLL lock input
    output  reg         gtxreset = 1'b0             // GTX reset output
);

//
// These parameters define the encoding of the RX & TX reset state machines.
//
localparam STATE_WIDTH = 3;

localparam [STATE_WIDTH-1:0]
    IDLE_STATE      = 3'b000,
    DELAY_STATE     = 3'b001,
    LOCK_STATE      = 3'b011,
    DONE_STATE      = 3'b010,
    RUN_STATE       = 3'b110;

reg     [PLLLOCKDLY-1:0]    dly_cntr = 0;
reg                         dly_cntr_rst;
wire                        dly_cntr_tc;
reg                         set_reset;
reg                         clr_reset;
reg     [STATE_WIDTH-1:0]   current_state = IDLE_STATE;
reg     [STATE_WIDTH-1:0]   next_state;
reg     [2:0]               pll_lock_sync_reg;
wire                        pll_lock_sync;
reg     [2:0]               pll_reset_sync_reg;
wire                        pll_reset_sync;

//
// Synchronize the pll_reset and pll_lock inputs
//
always @ (posedge clk)
    pll_lock_sync_reg <= {pll_lock_sync_reg[1:0], pll_lock};

assign pll_lock_sync = pll_lock_sync_reg[2];

always @ (posedge clk)
    pll_reset_sync_reg <= {pll_reset_sync_reg[1:0], pll_reset};

assign pll_reset_sync = pll_reset_sync_reg[2];

//
// Reset delay counter
//
always @ (posedge clk)
    if (dly_cntr_rst)
        dly_cntr <= 0;
    else
        dly_cntr <= dly_cntr + 1;

assign dly_cntr_tc = &dly_cntr;


//
// GTX reset flip-flop
//
always @ (posedge clk)
    if (set_reset)
        gtxreset <= 1'b1;
    else if (clr_reset)
        gtxreset <= 1'b0;

//
// FSM current state register
// 
always @ (posedge clk)
    current_state <= next_state;

//
// FSM next state logic
//
always @ (*)
begin
    case(current_state)
        IDLE_STATE:
            if (pll_reset_sync)
                next_state = DELAY_STATE;
            else
                next_state = IDLE_STATE;

        DELAY_STATE:
            if (dly_cntr_tc)
                next_state = LOCK_STATE;
            else
                next_state = DELAY_STATE;

        LOCK_STATE:
            if (pll_lock_sync)
                next_state = DONE_STATE;
            else
                next_state = LOCK_STATE;

        DONE_STATE:
            next_state = RUN_STATE;

        RUN_STATE:
            if (~pll_lock_sync | pll_reset_sync)
                next_state = DELAY_STATE;
            else
                next_state = RUN_STATE;

        default:
            next_state = IDLE_STATE;
    endcase
end

//
// FSM output logic
//
always @ (*)
begin
    set_reset               = 1'b0;
    clr_reset               = 1'b0;
    dly_cntr_rst            = 1'b0;

    case(current_state)
        IDLE_STATE:
            begin
                dly_cntr_rst = 1'b1;
                clr_reset = 1'b1;
            end

        DELAY_STATE:
            set_reset = 1'b1;

        LOCK_STATE:
            set_reset = 1'b1;

        DONE_STATE:
            clr_reset = 1'b1;

        RUN_STATE:
            begin
                clr_reset = 1'b1;
                dly_cntr_rst = 1'b1;
            end
    endcase
end

endmodule