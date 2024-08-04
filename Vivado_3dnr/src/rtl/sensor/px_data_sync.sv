`timescale 1ps/1ps


module px_data_sync # (
    parameter DEBUG         = "FALSE"
) (
    input               px_clk,
    input               px_reset,
    

    input   [47:0]      SOF_PATTERN,
    input   [47:0]      SOL_PATTERN,
    input   [47:0]      EOL_PATTERN,
    input   [47:0]      EOF_PATTERN,


    input   [11:0]      px_data, 
    
    output  [11:0]      px_dout,
    output              px_en_out,
    output              px_vs_out,
    output              pattern_locked_out
);

reg         hsync_1;
reg         hsync_2;

reg [11:0]  px_data_1;
reg [11:0]  px_data_2;
reg [11:0]  px_data_3;
reg [11:0]  px_data_4;
wire    [47:0]  px_data_comb;


reg         sof;
reg         sol;
reg         eol;
reg         eof;
reg         pattern_locked;

reg         px_en;
reg         px_vs;


always @ (posedge px_clk) 
begin
    if (px_reset) begin
        px_data_1 <= 12'b0;
        px_data_2 <= 12'b0;
        px_data_3 <= 12'b0;
        px_data_4 <= 12'b0;
    end else begin
        px_data_1 <= px_data;
        px_data_2 <= px_data_1;
        px_data_3 <= px_data_2;
        px_data_4 <= px_data_3;
    end
end
assign px_data_comb = {px_data_4, px_data_3, px_data_2, px_data_1};


always @ (posedge px_clk) 
begin
    if (px_reset) begin
        sof <= 1'b0;
        sol <= 1'b0;
        eol <= 1'b0;
        eof <= 1'b0;
    end else begin
        if (px_data_comb == SOF_PATTERN) begin
            sof <= 1'b1;
        end else begin
            sof <= 1'b0;
        end

        if (px_data_comb == SOL_PATTERN) begin
            sol <= 1'b1;
        end else begin
            sol <= 1'b0;
        end

        if (px_data_comb == EOL_PATTERN) begin
            eol <= 1'b1;
        end else begin
            eol <= 1'b0;
        end

        if (px_data_comb == EOF_PATTERN) begin
            eof <= 1'b1;
        end else begin
            eof <= 1'b0;
        end

    end
end

always @ (posedge px_clk) 
begin
    if (px_reset) begin
        pattern_locked <= 1'b0; 
    end else begin
        pattern_locked <= sof | sol | eol | eof;
    end
end


always @ (posedge px_clk) 
begin
    if (px_reset) begin
        px_en <= 1'b0;
        px_vs <= 1'b0;  
    end else begin
        if (px_data_comb == SOF_PATTERN) begin
            px_vs <= 1'b1;
        end else if (px_data_comb == EOF_PATTERN) begin
            px_vs <= 1'b0;
        end

        if ((px_data_comb == SOL_PATTERN) || (px_data_comb == SOF_PATTERN)) begin
            px_en <= 1'b1;
        end else if ((px_data_comb == EOL_PATTERN) || (px_data_comb == EOF_PATTERN)) begin
            px_en <= 1'b0;
        end

    end
end

assign px_dout              = px_data_4;
assign px_en_out            = px_en & px_vs;
assign px_vs_out            = px_vs;
assign pattern_locked_out   = pattern_locked;

//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
if(DEBUG == "TRUE") begin

    (* mark_debug = "true" *)wire               mark_px_reset;
    (* mark_debug = "true" *)wire    [11:0]     mark_px_data;
    (* mark_debug = "true" *)wire    [47:0]     mark_px_data_comb;
    (* mark_debug = "true" *)wire               mark_sof;
    (* mark_debug = "true" *)wire               mark_sol;
    (* mark_debug = "true" *)wire               mark_eol;
    (* mark_debug = "true" *)wire               mark_eof;


    (* mark_debug = "true" *)wire    [11:0]     mark_px_dout  ;
    (* mark_debug = "true" *)wire               mark_px_en_out;
    (* mark_debug = "true" *)wire               mark_px_vs_out;
    (* mark_debug = "true" *)wire               mark_pattern_locked_out;


    assign mark_px_reset                        = px_reset    ;
    assign mark_px_data                         = px_data     ;
    assign mark_px_data_comb                    = px_data_comb;
    assign mark_sof                             = sof         ;
    assign mark_sol                             = sol         ;
    assign mark_eol                             = eol         ;
    assign mark_eof                             = eof         ;

    assign mark_px_dout                         = px_dout     ;
    assign mark_px_en_out                       = px_en_out   ;
    assign mark_px_vs_out                       = px_vs_out   ;
    assign mark_pattern_locked_out              = pattern_locked_out;


                 
    
end
endgenerate



endmodule

