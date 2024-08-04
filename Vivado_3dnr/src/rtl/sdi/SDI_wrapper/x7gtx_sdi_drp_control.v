// (c) Copyright 2006 - 2012 Xilinx, Inc. All rights reserved.
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
//  /   /         Filename: $File: //Groups/video_ip/demos/K7/xapp592_k7_sdi_demos/verilog/SDI_wrapper/x7gtx_sdi_drp_control.v $
// /___/   /\     Timestamp: $DateTime: 2012/08/16 15:23:21 $
// \   \  /  \
//  \___\/\___\
//
// Description:
//  This module connects to the DRP of the 7series GTX and modifies attributes in 
//  the GTX transceiver in response to changes on its input control signals. This 
//  module is specifically designed to support triple-rate SDI interfaces 
//  implemented in the 7series GTX. It changes the RXCDR_CFG attribute when the 
//  rx_mode input changes.
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

module x7gtx_sdi_drp_control 
#(
    parameter RXCDR_CFG_HD      = 72'h03800023ff20100020,   // HD-SDI CDR setting
    parameter RXCDR_CFG_3G      = 72'h03800023ff20200020,   // 3G-SDI CDR setting
    parameter DRP_TIMEOUT_MSB   = 9)                        // MSB of DRP timeout counter
(
    input   wire        clk,                                // DRP DCLK
    input   wire        rst,                                // sync reset
    input   wire [1:0]  rx_mode,                            // RX mode select
    input   wire        drprdy,
    output  reg  [8:0]  drpaddr   = 9'b0,
    output  reg  [15:0] drpdi     = 16'b0,
    output  reg         drpen     = 1'b0,
    output  reg         drpwe     = 1'b0,
    output  reg         rxcdrhold = 1'b0,
    output  reg         gtrxreset = 1'b0
);
             
localparam RXCDR_CFG_DRPADDR = 9'h0A8;

//
// This group of constants defines the states of the master state machine.
// 
localparam MSTR_STATE_WIDTH = 3;
localparam MSTR_STATE_MSB   = MSTR_STATE_WIDTH - 1;

localparam [MSTR_STATE_MSB:0]
    MSTR_START      = 3'b000,
    MSTR_WRITE      = 3'b001,
    MSTR_WAIT       = 3'b011,
    MSTR_NEXT       = 3'b010,
    MSTR_DONE       = 3'b100,
    MSTR_STARTUP    = 3'b101,
    MSTR_SD         = 3'b110;

//
// This group of parameters defines the states of the DRP state machine.
//
localparam DRP_STATE_WIDTH = 3;
localparam DRP_STATE_MSB = DRP_STATE_WIDTH - 1;

localparam [DRP_STATE_MSB:0]
    DRP_START       = 3'b000,
    DRP_WRITE       = 3'b001,
    DRP_WAIT        = 3'b010,
    DRP_DONE        = 3'b101,
    DRP_TO          = 3'b100;

//
// Local signal declarations
//
reg  [1:0]              rx_mode_in_reg = 2'b00;
reg  [1:0]              rx_mode_sync1_reg = 2'b00;
reg  [1:0]              rx_mode_sync2_reg = 2'b00;
reg  [1:0]              rx_mode_last_reg = 2'b00;
reg                     rx_change_req = 1'b1;
reg                     clr_rx_change_req;

reg [MSTR_STATE_MSB:0]  mstr_current_state = MSTR_START;    // master FSM current state
reg [MSTR_STATE_MSB:0]  mstr_next_state;                    // master FSM next state
reg [DRP_STATE_MSB:0]   drp_current_state = DRP_START;      // DRP FSM current state
reg [DRP_STATE_MSB:0]   drp_next_state;                     // DRP FSM next state

reg                     drp_go;                             // Go signal from master FSM to DRP FSM
reg                     drp_done;                           // Done signal from DRP FSM to master FSM
reg                     drp_err;

reg  [2:0]              cycle = 3'b000;                     // cycle counter
reg                     clr_cycle;
reg                     inc_cycle;
wire                    complete;

reg  [8:0]              drp_addr;
reg  [15:0]             drp_data;
reg  [71:0]             rxcdr_cfg = RXCDR_CFG_HD;

reg [DRP_TIMEOUT_MSB:0] to_counter;
reg                     clr_to;
wire                    timeout;
reg                     do_gtx_reset;

//------------------------------------------------------------------------------
// rx_mode change detectors
//
// Synchronize the rx_mode signal to the clock
always @ (posedge clk)
begin
    rx_mode_in_reg <= rx_mode;
    rx_mode_sync1_reg <= rx_mode_in_reg;
    rx_mode_sync2_reg <= rx_mode_sync1_reg;
    rx_mode_last_reg <= rx_mode_sync2_reg;
end

always @ (posedge clk)
    if (rst)
        rx_change_req <= 1'b1;
    else if (clr_rx_change_req)
        rx_change_req <= 1'b0;
    else if (rx_mode_sync2_reg != rx_mode_last_reg)
        rx_change_req <= 1'b1;

//
// Assert rxcdrhold if mode changes to SD-SDI mode
//
always @ (posedge clk)
    if (rx_change_req)
        rxcdrhold <= (rx_mode_sync1_reg == 2'b01);
        
//
// Create values used for the new data word
//
always @ *
    case(rx_mode_sync1_reg)
        2'b10:   rxcdr_cfg = RXCDR_CFG_3G;
        default: rxcdr_cfg = RXCDR_CFG_HD;
    endcase

//------------------------------------------------------------------------------        
// Master state machine
//
// The master FSM examines the rx_change_req register and then initiates multiple
// DRP write cycles to modify the RXCDR_CFG attribute.
//
// The actual DRP write cycles are handled by a separate FSM, the DRP FSM. The
// master FSM provides a DRP address and new data word to the DRP FSM and 
// asserts a drp_go signal. The DRP FSM does the actual write cycle and responds
// with a drp_done signal when the cycle is complete.
//

//
// Current state register
// 
always @ (posedge clk)
    if (rst)
        mstr_current_state <= MSTR_STARTUP;
    else
        mstr_current_state <= mstr_next_state;

//
// Next state logic
//
always @ (*)
begin
    case(mstr_current_state)
        MSTR_STARTUP:
            if (drprdy)
                mstr_next_state <= MSTR_WRITE;
            else
                mstr_next_state <= MSTR_STARTUP;

        MSTR_START:
            if (rx_change_req & drprdy)
            begin
                if (rx_mode_sync1_reg == 2'b01)
                    mstr_next_state <= MSTR_SD;
                else
                    mstr_next_state <= MSTR_WRITE;
            end
            else
                mstr_next_state <= MSTR_START;

        MSTR_WRITE:
            mstr_next_state <= MSTR_WAIT;

        MSTR_WAIT:
            if (drp_done)
                mstr_next_state <= MSTR_NEXT;
            else if (drp_err)
                mstr_next_state <= MSTR_WRITE;
            else
                mstr_next_state <= MSTR_WAIT;

        MSTR_NEXT:
            if (complete)
                mstr_next_state <= MSTR_DONE;
            else
                mstr_next_state <= MSTR_WRITE;

        MSTR_DONE:
            mstr_next_state <= MSTR_START;

        MSTR_SD:
            mstr_next_state <= MSTR_START;

        default:
            mstr_next_state <= MSTR_START;
    endcase
end

//
// Output logic
//
always @ (*)
begin
    clr_cycle = 1'b0;
    inc_cycle = 1'b0;
    clr_rx_change_req = 1'b0;
    drp_go = 1'b0;
    do_gtx_reset = 1'b0;

    case(mstr_current_state)
        MSTR_START:
            clr_cycle = 1'b1;

        MSTR_WRITE:
            begin
                drp_go = 1'b1;
                if (cycle == 3'b000)
                    clr_rx_change_req = 1'b1;
                else
                    clr_rx_change_req = 1'b0;
            end

        MSTR_NEXT:
            inc_cycle = 1'b1;

        MSTR_DONE:
            do_gtx_reset = 1'b1;

        MSTR_SD:
            begin
                do_gtx_reset = 1'b1;
                clr_rx_change_req = 1'b1;
            end

    endcase
end

always @ (posedge clk)
    if (rst)
        gtrxreset <= 1'b0;
    else if (do_gtx_reset)
        gtrxreset <= 1'b1;
    else
        gtrxreset <= 1'b0;
        
//
// This logic creates the correct DRP address and data values.
//
always @ (*)
    case(cycle)
        3'b000:  
            begin
                drp_data = rxcdr_cfg[15:0];
                drp_addr = RXCDR_CFG_DRPADDR;
            end
        3'b001:
            begin  
                drp_data = rxcdr_cfg[31:16];
                drp_addr = RXCDR_CFG_DRPADDR + 1;
            end
        3'b010:  
            begin
                drp_data = rxcdr_cfg[47:32];
                drp_addr = RXCDR_CFG_DRPADDR + 2;
            end
        3'b011:
            begin  
                drp_data = rxcdr_cfg[63:48];
                drp_addr = RXCDR_CFG_DRPADDR + 3;
            end
        default: 
            begin
                drp_data = {8'b0, rxcdr_cfg[71:64]};
                drp_addr = RXCDR_CFG_DRPADDR + 4;
            end
    endcase

//
// cycle counter
//
always @ (posedge clk)
    if (clr_cycle)
        cycle <= 0;
    else if (inc_cycle)
        cycle <= cycle + 1;

assign complete = cycle == 3'b100;

//------------------------------------------------------------------------------
// DRP state machine
//
// The DRP state machine performs the write cycle to the DRP at the request of
// the master FSM.
//
// A timeout timer is used to timeout a DRP access should the DRP fail to
// respond with a DRDY signal within a given amount of time controlled by the
// DRP_TIMEOUT_MSB parameter.
//

//
// Current state register
//
always @ (posedge clk)
    if (rst)
        drp_current_state <= DRP_START;
    else
        drp_current_state <= drp_next_state;

//
// Next state logic
//
always @ *
    case(drp_current_state)
        DRP_START:
            if (drp_go)
                drp_next_state <= DRP_WRITE;
            else
                drp_next_state <= DRP_START;

        DRP_WRITE:
            drp_next_state <= DRP_WAIT;

        DRP_WAIT:
            if (drprdy)
                drp_next_state <= DRP_DONE;
            else if (timeout)
                drp_next_state <= DRP_TO;
            else
                drp_next_state <= DRP_WAIT;

        DRP_DONE:
            drp_next_state <= DRP_START;

        DRP_TO:
            drp_next_state <= DRP_START;

        default: 
            drp_next_state <= DRP_START;
    endcase

always @ (posedge clk)
    begin
        drpdi <= drp_data;
        drpaddr <= drp_addr;
    end

//
// Output logic
//
always @ *
begin
    drpen = 1'b0;
    drpwe = 1'b0;
    drp_done = 1'b0;
    drp_err = 1'b0;
    clr_to = 1'b0;
    
    case(drp_current_state)
        DRP_WRITE:
            begin
                drpen = 1'b1;
                drpwe = 1'b1;
                clr_to = 1'b1;
            end

        DRP_DONE:
            drp_done = 1'b1;

        DRP_TO:
            drp_err = 1'b1;
    endcase
end

//
// A timeout counter for DRP accesses. If the timeout counter reaches its
// terminal count, the DRP state machine aborts the transfer.
//
always @ (posedge clk)
    if (clr_to)
        to_counter <= 0;
    else
        to_counter <= to_counter + 1;

assign timeout = to_counter[DRP_TIMEOUT_MSB];


endmodule