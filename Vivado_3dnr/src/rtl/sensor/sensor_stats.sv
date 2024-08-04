`timescale 1ps/1ps



module sensor_stats # (
    parameter       D               = 4,               // Parameter to set the number of data lines
    parameter       DEBUG           = "FALSE"
) (
    input                   px_clk,
    input                   px_reset,

    input                   exp_in,
    input   [12*D-1 : 0]    din,
    input                   en_in,
    input                   vs_in,

    output  [31 : 0]        exp_time_out,
    output  [31 : 0]        gray_sum_L_out,
    output  [31 : 0]        gray_sum_H_out 
);

reg  exp_r;
reg  vs_r;
reg     [31 : 0]    exp_time;
reg     [31 : 0]    exp_time_r;
reg     [39 : 0]    gray_sum; 
reg     [39 : 0]    gray_sum_r; 

always @ (posedge px_clk)
begin
    if (px_reset) begin
        exp_r <= 1'b0;
        vs_r  <= 1'b0;
    end else begin
        exp_r <= exp_in;
        vs_r  <= vs_in;
    end
end

always @ (posedge px_clk)
begin
    if (px_reset) begin
        exp_time    <= 0;
        exp_time_r  <= 0;
    end else begin
        if (!exp_in) begin
            exp_time    <= 0;
        end
        else begin
            if (exp_time == 32'hFFFFFFFF) begin
                exp_time <= 32'hFFFFFFFF;
            end
            else begin
                exp_time <= exp_time + 1;
            end
        end

        if ((!exp_in) && (exp_r)) begin
            exp_time_r <= exp_time;
        end
    end
end
assign exp_time_out = exp_time_r;


always @ (posedge px_clk)
begin
    if (px_reset) begin
        gray_sum <= 0;
        gray_sum_r <= 0;
    end else begin
        
        if (!vs_in) begin
            gray_sum <= 0;
        end
        else begin
            if (en_in) begin
                gray_sum = gray_sum + din[11:0];
            end
        end

        if ((!vs_in) && (vs_r)) begin
            gray_sum_r <= gray_sum;

        end
    end
end
assign gray_sum_L_out = gray_sum_r[31:0];
assign gray_sum_H_out = {24'b0, gray_sum_r[39:32]};




endmodule




