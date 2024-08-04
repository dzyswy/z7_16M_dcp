`timescale 1ps/1ps



module rx_channel_1to12_ddr # (
    parameter       D               = 4,               // Parameter to set the number of data lines
    parameter real  REF_FREQ        = 200.0, 
    parameter       DIFF_TERM       = "FALSE",      // Enable internal LVDS termination  
    parameter       DEBUG           = "FALSE"
) (
    input                       clkin_p,
    input                       clkin_n,
    input   [D-1:0]             datain_p,
    input   [D-1:0]             datain_n,

    input                       reset,
    input                       idelay_rdy,
 
    input   [47:0]              SOF_PATTERN,
    input   [47:0]              SOL_PATTERN,
    input   [47:0]              EOL_PATTERN,
    input   [47:0]              EOF_PATTERN, 

    input   [15:0]              ACTIVE_WIDTH,
    input   [15:0]              FRAME_WIDTH,
    input   [15:0]              CHECK_SEARCH_LINE,
    input   [15:0]              CHECK_PATTERN_NUM,
    input   [7:0]               EYE_RANGE,

    input                       SERDES_BIT_REVERSE,
    input   [7:0]               SERDES_SLIP_NUM,
    input   [7:0]               SERDES_DELAY_NUM,
    input                       SERDES_MANUL_MODE,
    

    input                       start,
    input                       stream_on_in,
    
    output                      px_reset,
    output                      px_clk,
    output  [D * 12 - 1 : 0]    sen_dout,
    output                      sen_en_out,
    output                      sen_vs_out,
    output                      sen_lock_out,
    output                      sen_done_out 
);


wire rx_clkdiv2;
wire rx_clkdiv6;
wire rx_reset;
 

wire [D-1:0]    rx_bit_reverse;
wire [8*D-1:0]  rx_delay_num;
wire [8*D-1:0]  rx_slip_num; 


wire [D-1:0]    train_lock;
wire [D-1:0]    train_done;
reg             sen_lock;
reg             sen_done;  


wire [11:0]     px_data[D-1:0];



wire [12*D-1:0] line_data;
wire [D-1:0]    line_en;
wire [D-1:0]    line_vs;
wire [D-1:0]    pattern_locked;



genvar               i;
genvar               j;

rx_clk_gen_1to12_ddr # (
    .DIFF_TERM      (   DIFF_TERM       ),
    .DEBUG          (   DEBUG           )
) rxc (
    .reset          (   reset           ),
    .idelay_rdy     (   idelay_rdy      ),
    .clkin_p        (   clkin_p         ),
    .clkin_n        (   clkin_n         ),
    .rx_clkdiv2     (   rx_clkdiv2      ),
    .rx_clkdiv6     (   rx_clkdiv6      ),
    .rx_reset       (   rx_reset        ),
    .px_clk         (   px_clk          ),
    .px_reset       (   px_reset        )
);



generate
for (i = 0 ; i < D ; i = i+1) begin : rxd
   
    rx_serdes_1to12_ddr #   (
        .DIFF_TERM          (   DIFF_TERM                       ),
        .REF_FREQ           (   REF_FREQ                        ), 
        .DEBUG              (   DEBUG                           )//"TRUE"
    ) rxd (
        .datain_p           (   datain_p[i]                     ),    
        .datain_n           (   datain_n[i]                     ),     
        .rx_clkdiv2         (   rx_clkdiv2                      ),  
        .rx_clkdiv6         (   rx_clkdiv6                      ),  
        .rx_reset           (   rx_reset                        ), 
        .rx_bit_reverse     (   rx_bit_reverse[i]               ),   
        .rx_delay_num       (   rx_delay_num[8*(i+1)-1 : 8 * i] ),
        .rx_slip_num        (   rx_slip_num[8*(i+1)-1 : 8 * i]  ),  
        .px_clk             (   px_clk                          ),      
        .px_reset           (   px_reset                        ),
        .px_data            (   px_data[i]                      )      
    );

    px_data_sync # (
        .DEBUG              (   DEBUG                           )//"TRUE"
    ) u_sync (
        .px_clk             (   px_clk                          ),
        .px_reset           (   px_reset                        ),
        .px_data            (   px_data[i]                      ),  
        .SOF_PATTERN        (   SOF_PATTERN                     ),
        .SOL_PATTERN        (   SOL_PATTERN                     ),
        .EOL_PATTERN        (   EOL_PATTERN                     ),
        .EOF_PATTERN        (   EOF_PATTERN                     ),
        .px_dout            (   line_data[12*(i+1)-1 : 12 * i]  ),
        .px_en_out          (   line_en[i]                      ),
        .px_vs_out          (   line_vs[i]                      ),
        .pattern_locked_out (   pattern_locked[i]               )
    );
 
    px_data_train # (
        .DEBUG              (   DEBUG                           )//"TRUE"
    ) u_train (
        .px_clk             (   px_clk                          ),
        .px_reset           (   px_reset                        ),
        .FRAME_WIDTH        (   FRAME_WIDTH                     ),
        .CHECK_SEARCH_LINE  (   CHECK_SEARCH_LINE               ),
        .CHECK_PATTERN_NUM  (   CHECK_PATTERN_NUM               ),
        .EYE_RANGE          (   EYE_RANGE                       ),
        .SERDES_BIT_REVERSE (   SERDES_BIT_REVERSE              ),
        .SERDES_SLIP_NUM    (   SERDES_SLIP_NUM                 ),
        .SERDES_DELAY_NUM   (   SERDES_DELAY_NUM                ),
        .SERDES_MANUL_MODE  (   SERDES_MANUL_MODE               ),
        .start              (   start                           ),
        .pattern_locked     (   pattern_locked[i]               ),
        .bit_reverse_out    (   rx_bit_reverse[i]               ),
        .slip_num_out       (   rx_slip_num[8*(i+1)-1 : 8 * i]  ),  
        .delay_num_out      (   rx_delay_num[8*(i+1)-1 : 8 * i] ), 
        .best_range_out     (                                   ),
        .lock_out           (   train_lock[i]                   ),
        .done_out           (   train_done[i]                   )    

    );

end
endgenerate


always @(posedge px_clk)  
begin 
    if (px_reset) begin
        sen_lock <= 1'b0;
        sen_done <= 1'b0; 
    end
    else begin
        sen_lock <= &train_lock;
        sen_done <= &train_done;
    end
end
assign sen_lock_out = sen_lock;
assign sen_done_out = sen_done;



line_data_align # (
    .D              (   D                   ),
    .DEBUG          (   DEBUG               )//"TRUE"
) u_line (  
    .px_reset       (   px_reset            ),
    .px_clk         (   px_clk              ), 

    .ACTIVE_WIDTH   (   ACTIVE_WIDTH[15:0]  ),
    .stream_on_in   (   stream_on_in        ),

    .px_data        (   line_data           ),
    .px_en_in       (   line_en             ),
    .px_vs_in       (   line_vs             ), 

    

    .sen_dout       (   sen_dout            ),
    .sen_en_out     (   sen_en_out          ),
    .sen_vs_out     (   sen_vs_out          ) 
);
 





endmodule





