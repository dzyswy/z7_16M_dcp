`timescale 1ns/1ps



//简单双口MEM
module sensor_sdpram # (
    parameter DATA_WIDTH            = 8,
    parameter MEM_DEEP              = 256,
    parameter MEM_TYPE              = "auto" //"auto", "block", "distributed", "registers", "ultra" 
) (
    input                                   rst_n,
    input                                   clk, 
    input   [DATA_WIDTH - 1 : 0]            din,
    input   [$clog2(MEM_DEEP) - 1 : 0]      waddr, 
    input                                   we, 
    input   [$clog2(MEM_DEEP) - 1 : 0]      raddr, 
    input                                   ren,
    output  [DATA_WIDTH - 1 : 0]            dout

);



(*ram_style = MEM_TYPE*) reg [DATA_WIDTH - 1 : 0] mem[MEM_DEEP - 1 : 0];
reg [DATA_WIDTH - 1 : 0] rdata;

always @(posedge clk)  
begin 
    if (!rst_n) begin
        rdata <= 0;
    end
    else begin
        if (we) begin 
            mem[waddr] <= din; 
        end 

        if (ren) begin
            // if (waddr == raddr) begin
            //     rdata <= din;
            // end 
            // else begin
            //     rdata <= mem[raddr];
            // end
            rdata <= mem[raddr];
        end
    end
 
    
    
 
end
assign dout = rdata;

endmodule






