`timescale 1ps/1ps




module rx_serdes_1to12_ddr # ( 
    parameter real  REF_FREQ        = 200.0, 
    parameter       DIFF_TERM       = "FALSE",      // Enable internal LVDS termination 
    parameter       DEBUG           = "FALSE"
) (

    input               datain_p,
    input               datain_n,

    input               rx_clkdiv2,  
    input               rx_clkdiv6,  
    input               rx_reset,    
    input               rx_bit_reverse,
    input  [7:0]        rx_delay_num,
    input  [7:0]        rx_slip_num,  
    
    
    //      
    input               px_clk,      
    input               px_reset,
    output [11:0]       px_data      
);

wire            datain_i;
wire [5:0]      rx_wr_curr; 
reg  [5:0]      reverse_data;  
//
// Data Input LVDS Buffer
//

IBUFDS # (
    .DIFF_TERM     (    DIFF_TERM   ),
    .IBUF_LOW_PWR  (    "FALSE"     )
)
iob_clk_in (
    .I             (    datain_p    ),
    .IB            (    datain_n    ),
    .O             (    datain_i    )
); 
 

//
// Data Input IDELAY
//
IDELAYE2 #(
    .REFCLK_FREQUENCY   (   REF_FREQ            ), 
    .IDELAY_VALUE       (   1                   ),
    .DELAY_SRC          (   "IDATAIN"           ),
    .IDELAY_TYPE        (   "VAR_LOAD"          )
)
idelay_m(                   
    .DATAOUT            (   datain_d            ),
    .C                  (   rx_clkdiv6          ),
    .CE                 (   1'b0                ),
    .INC                (   1'b0                ),
    .DATAIN             (   1'b0                ),
    .IDATAIN            (   datain_i            ),
    .LD                 (   1'b1                ),
    .LDPIPEEN           (   1'b0                ),
    .REGRST             (   1'b0                ),
    .CINVCTRL           (   1'b0                ),
    .CNTVALUEIN         (   rx_delay_num[4:0]   ),
    .CNTVALUEOUT        (                       )
);
   
    
//
// Date ISERDES
//
ISERDESE2 #(
    .DATA_WIDTH         (   6               ),                 
    .DATA_RATE          (   "DDR"           ),             
    .SERDES_MODE        (   "MASTER"        ),             
    .IOBDELAY           (   "IFD"           ),             
    .INTERFACE_TYPE     (   "NETWORKING"    )
)         
iserdes_m (
    .D                  (    1'b0           ),
    .DDLY               (    datain_d       ),
    .CE1                (    1'b1           ),
    .CE2                (    1'b1           ),
    .CLK                (    rx_clkdiv2     ),
    .CLKB               (    ~rx_clkdiv2    ),
    .RST                (    rx_reset       ),
    .CLKDIV             (    rx_clkdiv6     ),
    .CLKDIVP            (    1'b0           ),
    .OCLK               (    1'b0           ),
    .OCLKB              (    1'b0           ),
    .DYNCLKSEL          (    1'b0           ),
    .DYNCLKDIVSEL       (    1'b0           ),
    .SHIFTIN1           (    1'b0           ),
    .SHIFTIN2           (    1'b0           ),
    .BITSLIP            (    1'b0           ),
    .O                  (                   ),
    .Q8                 (    rx_wr_curr[0]  ),
    .Q7                 (    rx_wr_curr[1]  ),
    .Q6                 (    rx_wr_curr[2]  ),
    .Q5                 (    rx_wr_curr[3]  ),
    .Q4                 (    rx_wr_curr[4]  ),
    .Q3                 (    rx_wr_curr[5]  ),
    .Q2                 (                   ),
    .Q1                 (                   ),
    .OFB                (                   ),
    .SHIFTOUT1          (                   ),
    .SHIFTOUT2          (                   )
);    

always @ (posedge rx_clkdiv6)
begin
    if (rx_bit_reverse) begin
        reverse_data[0] <= rx_wr_curr[5];
        reverse_data[1] <= rx_wr_curr[4];
        reverse_data[2] <= rx_wr_curr[3];
        reverse_data[3] <= rx_wr_curr[2];
        reverse_data[4] <= rx_wr_curr[1];
        reverse_data[5] <= rx_wr_curr[0];

    end else begin
        reverse_data <= rx_wr_curr;
    end
end
 


gearbox_6to12 # (
    .DEBUG          (   DEBUG           )
) u_gearbox ( 
    .rx_reset       (   rx_reset            ),
    .rx_clkdiv6     (   rx_clkdiv6          ),
    .din            (   reverse_data        ),
    .slip_num       (   rx_slip_num[3:0]    ),
    .px_reset       (   px_reset            ),
    .px_clk         (   px_clk              ),
    .dout           (   px_data             )
);



















endmodule






