`timescale 1ps/1ps



module line_data_align # (
    parameter       D               = 4,               // Parameter to set the number of data lines
    parameter       DEBUG           = "FALSE"
) (
    input                   px_reset,
    input                   px_clk, 

    input   [15:0]          ACTIVE_WIDTH,
    input                   stream_on_in,

    input   [12*D-1 : 0]    px_data,
    input   [D-1 : 0]       px_en_in,
    input   [D-1 : 0]       px_vs_in, 

    
  
    output  [12*D-1 : 0]    sen_dout,
    output                  sen_en_out,
    output                  sen_vs_out 
);

genvar               i;
genvar               j;
 
reg     stream_on;

reg     [3:0]    waddr[D-1:0];
reg     [15:0]   raddr; 

wire    [12*D-1 : 0]   rdata;

reg     sen_en_1;
reg     sen_en_2;
reg     sen_en_3;
reg     sen_en_4;
reg     sen_en_5;

reg     sen_vs_1;
reg     sen_vs_2;
reg     sen_vs_3;
reg     sen_vs_4;
reg     sen_vs_5;


reg     [12*D-1 : 0]    pxl_data;
reg                     pxl_en;
reg                     pxl_vs; 

reg     [12*D-1 : 0]    dst_data;
reg                     dst_en;
reg                     dst_vs; 

always @ (posedge px_clk)
begin
    if (px_reset) begin
        stream_on <= 1'b0;
    end else begin
 
        if (!px_vs_in[0]) begin
            stream_on <= stream_on_in;
        end

    end
end

always @ (posedge px_clk)
begin
    if (px_reset) begin
        sen_en_1 <= 1'b0;
        sen_en_2 <= 1'b0;
        sen_en_3 <= 1'b0;
        sen_en_4 <= 1'b0;
        sen_en_5 <= 1'b0;
        sen_vs_1 <= 1'b0;
        sen_vs_2 <= 1'b0;
        sen_vs_3 <= 1'b0;
        sen_vs_4 <= 1'b0;
        sen_vs_5 <= 1'b0;
    end else begin
        sen_en_1 <= px_en_in[0];
        sen_en_2 <= sen_en_1;
        sen_en_3 <= sen_en_2;
        sen_en_4 <= sen_en_3;
        sen_en_5 <= sen_en_4;

        sen_vs_1 <= px_vs_in[0];
        sen_vs_2 <= sen_vs_1;
        sen_vs_3 <= sen_vs_2;
        sen_vs_4 <= sen_vs_3;
        sen_vs_5 <= sen_vs_4;

    end
end



generate
for (i = 0 ; i < D ; i = i+1) begin : loop_ram

    always @ (posedge px_clk)
    begin

        if (px_en_in[i] == 1'b0) begin
            waddr[i] <= 4'h0;
        end else begin
            waddr[i] <= waddr[i] + 1;
        end
    end


    xpm_memory_sdpram #(
        .ADDR_WIDTH_A               (   4                           ),               
        .ADDR_WIDTH_B               (   4                           ),               
        .AUTO_SLEEP_TIME            (   0                           ),            
        .BYTE_WRITE_WIDTH_A         (   12                          ),        
        .CLOCKING_MODE              (   "common_clock"              ), //independent_clock common_clock
        .ECC_MODE                   (   "no_ecc"                    ),            
        .MEMORY_INIT_FILE           (   "none"                      ),      
        .MEMORY_INIT_PARAM          (   "0"                         ),        
        .MEMORY_OPTIMIZATION        (   "true"                      ),   
        .MEMORY_PRIMITIVE           (   "distributed"               ),      
        .MEMORY_SIZE                (   16*12                       ),             
        .MESSAGE_CONTROL            (   0                           ),            
        .READ_DATA_WIDTH_B          (   12                          ),         
        .READ_LATENCY_B             (   1                           ),             
        .READ_RESET_VALUE_B         (   "0"                         ),       
        .RST_MODE_A                 (   "SYNC"                      ),            
        .RST_MODE_B                 (   "SYNC"                      ),            
        .USE_EMBEDDED_CONSTRAINT    (   0                           ),    
        .USE_MEM_INIT               (   1                           ),               
        .WAKEUP_TIME                (   "disable_sleep"             ),  
        .WRITE_DATA_WIDTH_A         (   12                          ),        
        .WRITE_MODE_B               (   "read_first"                )      
    ) u_ram (
        .clka                       (   px_clk                          ),                      
        .addra                      (   waddr[i]                        ),                   
        .dina                       (   px_data[12*(i+1)-1 : 12 * i]    ),                     
        .ena                        (   px_en_in[i]                     ),                        
        .wea                        (   px_en_in[i]                     ),                          
        .clkb                       (   px_clk                        ),                      
        .addrb                      (   raddr[3:0]                      ),                   
        .doutb                      (   rdata[12*(i+1)-1 : 12 * i]      ),                   
        .enb                        (   sen_en_4                        ),                         
        .rstb                       (   px_reset                       ),                      
        .regceb                     (   1'b1                            ),                  
        .sleep                      (   1'b0                            ),                   
        .injectdbiterra             (   1'b0                            ),  
        .injectsbiterra             (   1'b0                            ), 
        .sbiterrb                   (                                   ),              
        .dbiterrb                   (                                   )               
    );
end
endgenerate

 

always @ (posedge px_clk)
begin

    if (px_reset) begin
        raddr <= 16'hFFFF;
    end else begin

        if ((sen_en_3) && (!sen_en_4)) begin
            raddr <= 16'h0;

        end else begin
            if (raddr == 16'hFFFF) begin
                raddr <= 16'hFFFF;
            end else begin
                raddr <= raddr + 1;
            end
        end
        
    end
end

always @ (posedge px_clk)
begin
    if (px_reset) begin 

        pxl_data <= 0;
        pxl_en <= 1'b0;
        pxl_vs <= 1'b0;

    end else begin
 
        pxl_data <= rdata;

        if (raddr == 4) begin
            pxl_en <= 1'b1;
        end else if (raddr == (4 + ACTIVE_WIDTH)) begin
            pxl_en <= 1'b0;
        end
        pxl_vs <= sen_vs_5;
    end
end


always @ (posedge px_clk)
begin
    if (px_reset) begin 

        dst_data    <= 0;
        dst_en      <= 1'b0;
        dst_vs      <= 1'b0;

    end else begin

        if (stream_on) begin
            dst_data    <= pxl_data;
            dst_en      <= pxl_en;
            dst_vs      <= pxl_vs;
        end
        else begin
            dst_data    <= 0;
            dst_en      <= 1'b0;
            dst_vs      <= 1'b0;
        end
    end
end

assign sen_dout     = dst_data;
assign sen_en_out   = dst_en;
assign sen_vs_out   = dst_vs; 


//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
if(DEBUG == "TRUE") begin


    (* mark_debug = "true" *)wire   [12*D-1 : 0]        mark_px_data        ;
    (* mark_debug = "true" *)wire   [D-1 : 0]           mark_px_en_in       ;
    (* mark_debug = "true" *)wire   [D-1 : 0]           mark_px_vs_in       ; 
    (* mark_debug = "true" *)wire   [12*D-1 : 0]        mark_sen_dout       ;

    (* mark_debug = "true" *)wire   [3 : 0]             mark_waddr          ;
    (* mark_debug = "true" *)wire   [15 : 0]            mark_raddr          ;


    (* mark_debug = "true" *)wire                       mark_sen_en_out     ;
    (* mark_debug = "true" *)wire                       mark_sen_vs_out     ; 

 
    assign mark_px_data                                 = px_data     ;
    assign mark_px_en_in                                = px_en_in    ;
    assign mark_px_vs_in                                = px_vs_in    ; 

    assign mark_waddr                                   = waddr[0];
    assign mark_raddr                                   = raddr;

    assign mark_sen_dout                                = sen_dout    ;
    assign mark_sen_en_out                              = sen_en_out  ;
    assign mark_sen_vs_out                              = sen_vs_out  ; 
    
end
endgenerate



endmodule








