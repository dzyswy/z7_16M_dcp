`timescale 1ps/1ps


module gearbox_6to12 # (
    parameter DEBUG = "FALSE"
)(
    input               rx_reset,
    input               rx_clkdiv6,
    input   [5 : 0]     din,
 
    input   [3 : 0]     slip_num, 

    input               px_reset,
    input               px_clk,
    output  [11 : 0]    dout

);


reg     [5:0]   din_1;
reg     [5:0]   din_2; 
reg     [5:0]   din_3;  
reg     [5:0]   din_4; 
wire    [23:0]  data_comb;
reg     [11:0]  tx_data;

always @ (posedge rx_clkdiv6)
begin
   if (rx_reset) begin
       din_1 <= 6'b0;
       din_2 <= 6'b0; 
       din_3 <= 6'b0; 
       din_4 <= 6'b0;
   end else begin
       din_1 <= din;
       din_2 <= din_1; 
       din_3 <= din_2; 
       din_4 <= din_3; 
   end
end
assign data_comb = {din_4, din_3, din_2, din_1};

always @ (posedge px_clk)
begin
   if (px_reset) begin
        tx_data <= 12'b0;
   end else begin
        case (slip_num)
            4'h0 : begin
                tx_data <= data_comb[11:0];
            end

            4'h1 : begin
                tx_data <= data_comb[12:1];
            end

            4'h2 : begin
                tx_data <= data_comb[13:2];
            end

            4'h3 : begin
                tx_data <= data_comb[14:3];
            end

            4'h4 : begin
                tx_data <= data_comb[15:4];
            end

            4'h5 : begin
                tx_data <= data_comb[16:5];
            end

            4'h6 : begin
                tx_data <= data_comb[17:6];
            end

            4'h7 : begin
                tx_data <= data_comb[18:7];
            end

            4'h8 : begin
                tx_data <= data_comb[19:8];
            end

            4'h9 : begin
                tx_data <= data_comb[20:9];
            end

            4'h10 : begin
                tx_data <= data_comb[21:10];
            end

            4'h11 : begin
                tx_data <= data_comb[22:11];
            end

            default: begin
                tx_data <= data_comb[11:0];
            end

        endcase
   end
end

assign dout = tx_data;


//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
if(DEBUG == "TRUE") begin

 
    (* mark_debug = "true" *)wire    [5 : 0]            mark_din; 
    (* mark_debug = "true" *)wire    [17 : 0]           mark_data_comb;  
    (* mark_debug = "true" *)wire    [11 : 0]           mark_dout; 
 
    assign mark_din                                     = din;  
    assign mark_data_comb                               = data_comb; 
    assign mark_dout                                    = dout; 

                 
    
end
endgenerate



endmodule

