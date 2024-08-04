`timescale 1ns/1ps


module axis2video # (
    parameter DATA_WIDTH        = 16,
    parameter FIFO_DEEP         = 2048,
    parameter DEBUG             = "FALSE"
) (

    input                           rst_n,
    input                           clk,
    

    input   [15 : 0]                ACTIVE_WIDTH,
    input   [15 : 0]                ACTIVE_HEIGHT,

    input                           s_axis_aclk,
    input   [DATA_WIDTH - 1 : 0]    s_axis_tdata,
    input                           s_axis_tlast,
    input                           s_axis_tuser,
    input                           s_axis_tvalid,
    output                          s_axis_tready,

    output  [DATA_WIDTH - 1 : 0]    dout,
    output                          en_out,
    output                          vs_out,

    output                          overflow,
    output                          underflow
);



localparam FIFO_DW = DATA_WIDTH + 2;
localparam FIFO_AW = $clog2(FIFO_DEEP);


//----------------------------------------------------------------------------------------------
// Fsm define
//----------------------------------------------------------------------------------------------
typedef enum logic[2:0] {
    ST_IDLE         =	3'd0, 
    ST_FILL         =   3'd1,
    ST_FVBLK        =	3'd2,       
    ST_FHBLK        =	3'd3,
    ST_AP           =	3'd4,
    ST_BHBLK        =   3'd5,
    ST_BVBLK        =   3'd6
}Fsm_e;


//----------------------------------------------------------------------------------------------
// struct define
//----------------------------------------------------------------------------------------------

typedef struct {
    Fsm_e state;

    logic [DATA_WIDTH - 1 : 0]      frame_data; 
    logic                           frame_en;
    logic                           frame_vs;
 
    logic [15 : 0]                  xcnt;
    logic [15 : 0]                  ycnt;

}frame_s;

 

//----------------------------------------------------------------------------------------------
// Register define
//----------------------------------------------------------------------------------------------
frame_s r, rn; 


//----------------------------------------------------------------------------------------------
// wire define
//----------------------------------------------------------------------------------------------
logic                           fifo_rst;
logic                           fifo_wr;
logic    [FIFO_DW - 1 : 0]      fifo_din;
logic                           fifo_rd;
logic    [FIFO_DW - 1 : 0]      fifo_dout; 
logic                           fifo_empty;
logic                           fifo_full;  
logic    [FIFO_AW : 0]          fifo_rd_data_count; 
logic                           fifo_wr_rst_busy; 

logic    [DATA_WIDTH - 1 : 0]   fifo_tdata;
logic                           fifo_tuser;
logic                           fifo_tlast;


//----------------------------------------------------------------------------------------------
// xpm_fifo_async
//----------------------------------------------------------------------------------------------


xpm_fifo_async #(
    .CDC_SYNC_STAGES        (   4                       ), 
    .DOUT_RESET_VALUE       (   "0"                     ), 
    .ECC_MODE               (   "no_ecc"                ), 
    .FIFO_MEMORY_TYPE       (   "auto"                  ), 
    .FIFO_READ_LATENCY      (   0                       ), 
    .FIFO_WRITE_DEPTH       (   FIFO_DEEP               ), 
    .FULL_RESET_VALUE       (   1                       ), 
    .PROG_EMPTY_THRESH      (   10                      ), 
    .PROG_FULL_THRESH       (   10                      ), 
    .RD_DATA_COUNT_WIDTH    (   FIFO_AW + 1             ), 
    .READ_DATA_WIDTH        (   FIFO_DW                 ), 
    .READ_MODE              (   "fwft"                  ), 
    .RELATED_CLOCKS         (   0                       ), 
    .USE_ADV_FEATURES       (   "0707"                  ), 
    .WAKEUP_TIME            (   0                       ), 
    .WRITE_DATA_WIDTH       (   FIFO_DW                 ), 
    .WR_DATA_COUNT_WIDTH    (   FIFO_AW + 1             )  
)
xpm_fifo_async_inst (
    .rst                    (   fifo_rst                ),
    .wr_clk                 (   s_axis_aclk             ),
    .wr_en                  (   fifo_wr                 ),
    .din                    (   fifo_din                ),  
    .rd_clk                 (   clk                     ),
    .rd_en                  (   fifo_rd                 ),  
    .dout                   (   fifo_dout               ), 
    .empty                  (   fifo_empty              ),
    .full                   (   fifo_full               ), 
    .overflow               (   overflow                ),
    .underflow              (   underflow               ), 
    .rd_data_count          (   fifo_rd_data_count      ), 
    .wr_rst_busy            (   fifo_wr_rst_busy        )
);
 
assign fifo_din = {s_axis_tlast, s_axis_tuser, s_axis_tdata};
assign fifo_wr = s_axis_tvalid & (!fifo_full) & (!fifo_wr_rst_busy);



assign fifo_tdata = fifo_dout[DATA_WIDTH - 1 : 0];
assign fifo_tuser = fifo_dout[DATA_WIDTH];
assign fifo_tlast = fifo_dout[DATA_WIDTH + 1];

assign s_axis_tready = (!fifo_full) & (!fifo_wr_rst_busy);

always_ff @ (posedge s_axis_aclk) begin

    fifo_rst <= #1 !rst_n;

end




//----------------------------------------------------------------------------------------------
// frame domain
//----------------------------------------------------------------------------------------------


always_ff @ (posedge clk) begin
    r <= #1 rn;
    if (rst_n == 1'b0) begin

        r.state         <= #1 ST_IDLE;
 
        r.frame_data    <= #1 'd0;
        r.frame_en      <= #1 'd0;
        r.frame_vs      <= #1 'd0;
        
        r.xcnt          <= #1 'd0;
        r.ycnt          <= #1 'd0;
 
    end
end

always_comb begin

    rn = r;

    case (r.state) 

        ST_IDLE: begin
            if (fifo_tuser) begin 
                rn.state = ST_FILL;
            end
    
            rn.frame_vs = 1'b0;
        end

        ST_FILL: begin
            if (fifo_rd_data_count >= ACTIVE_WIDTH) begin
                rn.state = ST_FVBLK; 
            end 
        end

        ST_FVBLK: begin
            rn.frame_vs = 1'b1;
            rn.ycnt = 0;
            rn.state = ST_FHBLK;  
        end

        ST_FHBLK: begin
            
            if (fifo_rd_data_count >= ACTIVE_WIDTH) begin 
                rn.xcnt = 0;
                rn.state = ST_AP; 
            end 
        end

        ST_AP: begin

            if (r.xcnt >= (ACTIVE_WIDTH - 1)) begin
                rn.xcnt = 0; 
                rn.state = ST_BHBLK;
            end
            else begin
                rn.xcnt = r.xcnt + 1;
            end  
        end

        ST_BHBLK: begin
            if (r.ycnt >= (ACTIVE_HEIGHT - 1)) begin
                rn.ycnt = 0;
                rn.state = ST_BVBLK;
            end
            else begin
                rn.ycnt = r.ycnt + 1;
                rn.state = ST_FHBLK;
            end 
        end

        ST_BVBLK: begin
            rn.frame_vs = 1'b0;
            rn.state = ST_IDLE; 
        end

        default: begin
            rn.state = ST_IDLE; 
        end

    endcase


    if (rn.state == ST_IDLE) begin
        fifo_rd = !fifo_empty;
    end
    else if (rn.state == ST_AP) begin
        fifo_rd = 1'b1;
    end
    else begin
        fifo_rd = 1'b0;
    end


    rn.frame_data = fifo_tdata;
    rn.frame_en = fifo_rd;
 

end








//----------------------------------------------------------------------------------------------
// output assignment
//----------------------------------------------------------------------------------------------
assign dout     = r.frame_data;
assign en_out   = r.frame_en;
assign vs_out   = r.frame_vs; 







//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
    if(DEBUG == "TRUE") begin

        
    end
endgenerate



endmodule

