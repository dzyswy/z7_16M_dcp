`timescale 1ps/1ps


module rx_clk_gen_1to12_ddr # (
    parameter DIFF_TERM     = "FALSE",      // Enable internal LVDS termination 
    parameter DEBUG         = "FALSE"
) (
    input       reset,
    input       idelay_rdy,
    input       clkin_p,
    input       clkin_n,

    output      rx_reset,
    output      rx_clkdiv2,
    output      rx_clkdiv6,
    
    output      px_reset,
    output      px_clk
    
);

wire clkin_i;
reg  [7:0] rx_reset_sync;
reg  [7:0] px_reset_sync;


// Clock input 
IBUFDS # (
    .DIFF_TERM      (   DIFF_TERM       ),
    .IBUF_LOW_PWR   (   "FALSE"         )
)
iob_clk_in (
    .I              (   clkin_p         ),
    .IB             (   clkin_n         ),
    .O              (   clkin_i         )
); 


BUFIO  bufio_div2 (.I (clkin_i), .O(rx_clkdiv2)) ;
BUFR #(.BUFR_DIVIDE("3"),.SIM_DEVICE("7SERIES"))bufr_div6 (.I(clkin_i),.CE(1'b1),.O(rx_clkdiv6),.CLR(1'b0)) ;
BUFR #(.BUFR_DIVIDE("6"),.SIM_DEVICE("7SERIES"))bufr_div12 (.I(clkin_i),.CE(1'b1),.O(px_clk),.CLR(1'b0)) ;


//
// Synchronize reset to rx_clkdiv6
// 
always @ (posedge rx_clkdiv6)
begin
    if (reset | (!idelay_rdy))
        rx_reset_sync <= 8'b11111111;
    else
        rx_reset_sync <= {1'b0, rx_reset_sync[7:1]};
end
assign rx_reset = rx_reset_sync[0];

//
// Synchronize rx_reset to px_clk
//
always @ (posedge px_clk or posedge rx_reset)
begin
    if (rx_reset)
        px_reset_sync <= 8'b11111111;
    else
        px_reset_sync <= {1'b0, px_reset_sync[7:1]};
end
assign px_reset = px_reset_sync[0];


//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
if(DEBUG == "TRUE") begin


    (* mark_debug = "true" *)wire                       mark_reset; 
    (* mark_debug = "true" *)wire                       mark_idelay_rdy;
    (* mark_debug = "true" *)wire                       mark_rx_reset;
    (* mark_debug = "true" *)wire                       mark_px_reset;

    assign mark_reset                                   = reset;            
    assign mark_idelay_rdy                              = idelay_rdy; 
    assign mark_rx_reset                                = rx_reset; 
    assign mark_px_reset                                = px_reset; 
    
end
endgenerate

endmodule

