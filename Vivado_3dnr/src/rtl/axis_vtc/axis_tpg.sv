`timescale 1ns/1ps


module axis_tpg # (
    parameter DATA_WIDTH        = 16, 
    parameter CHESS_WPOW        = 4,
    parameter CHESS_HPOW        = 4,
    parameter DEBUG             = "FALSE"
) (
    input                           rst_n,

    
    input   [15 : 0]                ACTIVE_WIDTH,
    input   [15 : 0]                ACTIVE_HEIGHT,
    input   [3 : 0]                 tpg_mode,


    input                           m_axis_aclk,
    output  [DATA_WIDTH - 1 : 0]    m_axis_tdata,
    output                          m_axis_tlast,
    output                          m_axis_tuser,
    output                          m_axis_tvalid,
    input                           m_axis_tready
);


 

//----------------------------------------------------------------------------------------------
// struct define
//----------------------------------------------------------------------------------------------
typedef struct { 
    logic [15 : 0]                  xcnt;
    logic [15 : 0]                  ycnt;
    logic [15 : 0]                  zcnt;

    logic [DATA_WIDTH - 1 : 0]      tdata; 
    logic                           tvalid;

}logic_s;

logic [DATA_WIDTH - 1 : 0]      chess;
logic [DATA_WIDTH - 1 : 0]      gray_x;
logic [DATA_WIDTH - 1 : 0]      gray_y;
logic [DATA_WIDTH - 1 : 0]      gray_x_run;
logic [DATA_WIDTH - 1 : 0]      gray_y_run;

logic is_tlast;
logic is_tuser;


//----------------------------------------------------------------------------------------------
// Register define
//----------------------------------------------------------------------------------------------
logic_s r, rn;




//----------------------------------------------------------------------------------------------
// sequential always
//----------------------------------------------------------------------------------------------	

always_ff @ (posedge m_axis_aclk) begin

    r <= #1 rn;
    if (rst_n == 1'b0) begin
 
        r.xcnt <= #1 'd0;
        r.ycnt <= #1 'd0;
        r.zcnt <= #1 'd0;
 
        r.tdata <= #1 'd0; 
        r.tvalid <= #1 'd0;
        
    end
end

//----------------------------------------------------------------------------------------------
// combinatorial always
//----------------------------------------------------------------------------------------------

always_comb begin

    rn = r;

    if (m_axis_tready) begin

        if (r.xcnt >= (ACTIVE_WIDTH - 1)) begin
            rn.xcnt = 0;
            if (r.ycnt >= (ACTIVE_HEIGHT - 1)) begin
                rn.ycnt = 0;
                rn.zcnt = r.zcnt + 1;
            end
            else begin
                rn.ycnt = r.ycnt + 1;
            end 
        end
        else begin
            rn.xcnt = r.xcnt + 1;
        end

    end

    

    if (r.xcnt == (ACTIVE_WIDTH - 1)) begin
        is_tlast = 1'b1;
    end
    else begin
        is_tlast = 1'b0;
    end

    if ((r.xcnt == 0) && (r.ycnt == 0)) begin
        is_tuser = 1'b1;
    end
    else begin
        is_tuser = 1'b0;
    end

    rn.tvalid = 1'b1;

    //chess
    if (rn.xcnt[CHESS_WPOW] == rn.ycnt[CHESS_HPOW]) begin
        chess = ~0;
    end
    else begin
        chess = 0;
    end

    //gray_x
    gray_x = rn.xcnt[DATA_WIDTH - 1 : 0];

    //gray_y
    gray_y = rn.ycnt[DATA_WIDTH - 1 : 0];

    //gray_x_run
    gray_x_run = rn.xcnt + rn.zcnt;

    //gray_y_run
    gray_y_run = rn.ycnt + rn.zcnt;

    case (tpg_mode)
        4'h0: begin
            rn.tdata = chess;
        end

        4'h1: begin
            rn.tdata = gray_x;
        end

        4'h2: begin
            rn.tdata = gray_y;
        end

        4'h3: begin
            rn.tdata = gray_x_run;
        end

        4'h4: begin
            rn.tdata = gray_y_run;
        end

        4'h5: begin
            rn.tdata = ~0;
        end

        default: begin
            rn.tdata = 0;
        end

    endcase

 
end



//----------------------------------------------------------------------------------------------
// output assignment
//----------------------------------------------------------------------------------------------
assign m_axis_tdata             = r.tdata;
assign m_axis_tlast             = is_tlast;
assign m_axis_tuser             = is_tuser;
assign m_axis_tvalid            = r.tvalid;

//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
if(DEBUG == "TRUE") begin

 
        
end
endgenerate



endmodule
