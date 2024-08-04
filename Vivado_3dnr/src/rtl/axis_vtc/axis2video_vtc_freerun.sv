`timescale 1ns/1ps


module axis2video_vtc_freerun # (
    parameter DATA_WIDTH    = 16,
    parameter FIFO_DEEP     = 2048,
    parameter DEBUG         = "FALSE"
) (

    input                           rst_n,
    input                           clk,
    
    input   [15 : 0]                FIFO_FILL_LEN,
    input   [15 : 0]                ACTIVE_WIDTH,
    input   [15 : 0]                ACTIVE_HEIGHT,
    input   [15 : 0]                FRAME_WIDTH,
    input   [15 : 0]                FRAME_HEIGHT,  
    input   [15 : 0]                HBLK_HSTART,
    input   [15 : 0]                VBLK_VSTART,
    input   [15 : 0]                HSYNC_HSTART,
    input   [15 : 0]                HSYNC_HEND,
    input   [15 : 0]                VSYNC_HSTART,
    input   [15 : 0]                VSYNC_HEND,
    input   [15 : 0]                VSYNC_VSTART,
    input   [15 : 0]                VSYNC_VEND,

    
    input                           s_axis_aclk,
    input   [DATA_WIDTH - 1 : 0]    s_axis_tdata,
    input                           s_axis_tlast,
    input                           s_axis_tuser,
    input                           s_axis_tvalid,
    output                          s_axis_tready,

    output  [DATA_WIDTH - 1 : 0]    dout,
    output                          en_out,
    output                          hs_out,
    output                          vs_out,
    output                          overflow,
    output                          underflow,
    output                          axis_lock_out,
    output                          lost_lock_out
);



localparam FIFO_DW = DATA_WIDTH + 2;
localparam FIFO_AW = $clog2(FIFO_DEEP);


//----------------------------------------------------------------------------------------------
// Fsm define
//----------------------------------------------------------------------------------------------
typedef enum logic[2:0] {
    ST_IDLE         =	3'd0, 
    ST_FILL         =   3'd1,   
    ST_AP           =	3'd2 
}Fsm_e;


//----------------------------------------------------------------------------------------------
// struct define
//----------------------------------------------------------------------------------------------

typedef struct {
    Fsm_e                           state;
 
    logic [15 : 0]                  hcnt;
    logic [15 : 0]                  vcnt; 

    logic                           hen;
    logic                           ven;
 
    logic [DATA_WIDTH - 1 : 0]      frame_data; 
    logic                           frame_en;
    logic                           frame_hs;
    logic                           frame_vs;

    logic                           axis_lock;
    logic                           lost_lock;


}frame_s;

 

//----------------------------------------------------------------------------------------------
// Register define
//----------------------------------------------------------------------------------------------
frame_s r, rn; 


//----------------------------------------------------------------------------------------------
// Wire define
//----------------------------------------------------------------------------------------------
logic                            fifo_rst;
logic                            fifo_wr;
logic    [FIFO_DW - 1 : 0]       fifo_din;
logic                            fifo_rd;
logic    [FIFO_DW - 1 : 0]       fifo_dout; 
logic                            fifo_empty;
logic                            fifo_full; 
logic    [FIFO_AW : 0]           fifo_wr_data_count;
logic    [FIFO_AW : 0]           fifo_rd_data_count;
logic                            fifo_rd_rst_busy;
logic                            fifo_wr_rst_busy; 

logic    [DATA_WIDTH - 1 : 0]    fifo_tdata;
logic                            fifo_tuser;
logic                            fifo_tlast;                   

 


//----------------------------------------------------------------------------------------------
// Module define
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
    .wr_data_count          (   fifo_wr_data_count      ),
    .rd_data_count          (   fifo_rd_data_count      ),
    .rd_rst_busy            (   fifo_rd_rst_busy        ),
    .wr_rst_busy            (   fifo_wr_rst_busy        )
);
 
assign fifo_din = {s_axis_tlast, s_axis_tuser, s_axis_tdata};
assign fifo_wr = s_axis_tvalid & (!fifo_full) & (!fifo_wr_rst_busy);


assign fifo_tdata = fifo_dout[DATA_WIDTH - 1 : 0];
assign fifo_tuser = fifo_dout[DATA_WIDTH];
assign fifo_tlast = fifo_dout[DATA_WIDTH + 1];

assign s_axis_tready = (!fifo_full) & (!fifo_wr_rst_busy);

//----------------------------------------------------------------------------------------------
// axis domain
//----------------------------------------------------------------------------------------------
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

        r.hcnt          <= #1 'd0;
        r.vcnt          <= #1 'd0;

        r.hen           <= #1 'd0;
        r.ven           <= #1 'd0;
  
        r.frame_data    <= #1 'd0;
        r.frame_en      <= #1 'd0;
        r.frame_hs      <= #1 'd0;
        r.frame_vs      <= #1 'd0;
        
        r.axis_lock     <= #1 1'b0;
        r.lost_lock     <= #1 1'b0; 

    end
 

end

always_comb begin

    rn = r;

 
    case (r.state)
        ST_IDLE: begin
            if (fifo_tuser) begin 
                rn.axis_lock = 1'b1;
                rn.state = ST_FILL;
            end
            else begin
                rn.axis_lock = 1'b0;
            end
            rn.lost_lock = 1'b1;
            
            rn.hcnt = 0;
            rn.vcnt = 0;
            rn.hen = 1'b0;
            rn.ven = 1'b0;
            rn.frame_data = 0;
            rn.frame_en = 1'b0;
            rn.frame_hs = 1'b0;
            rn.frame_vs = 1'b0;
        end

        ST_FILL: begin
            if (fifo_rd_data_count >= FIFO_FILL_LEN) begin
                rn.lost_lock = 1'b0;
                rn.state = ST_AP; 
            end
        end

        ST_AP: begin
            if (r.hcnt == (FRAME_WIDTH - 1)) begin
                rn.hcnt = 0;
                if (r.vcnt == (FRAME_HEIGHT - 1)) begin
                    rn.vcnt = 0;
                end
                else begin
                    rn.vcnt = r.vcnt + 1;
                end
            end
            else begin
                rn.hcnt = r.hcnt + 1;
            end

            if (r.hcnt == HBLK_HSTART) begin
                rn.hen = 1'b1;
            end
            else if (r.hcnt == (HBLK_HSTART + ACTIVE_WIDTH)) begin
                rn.hen = 1'b0;
            end

            if (r.vcnt == VBLK_VSTART) begin
                rn.ven = 1'b1;
            end
            else if (r.vcnt == (VBLK_VSTART + ACTIVE_HEIGHT)) begin
                rn.ven = 1'b0;
            end

            rn.frame_data = fifo_tdata;
            rn.frame_en = r.hen & r.ven;

            if (r.hcnt == HSYNC_HSTART) begin
                rn.frame_hs = 1'b1;
            end
            else if (r.hcnt == HSYNC_HEND) begin
                rn.frame_hs = 1'b0;
            end

            if ((r.hcnt == VSYNC_HSTART) && (r.vcnt == VSYNC_VSTART)) begin
                rn.frame_vs = 1'b1;
            end
            else if ((r.hcnt == VSYNC_HEND) && (r.vcnt == VSYNC_VEND)) begin
                rn.frame_vs = 1'b0;
            end

            if (underflow) begin
                rn.lost_lock = 1'b1;
                rn.state = ST_IDLE;
            end
        end


        default: begin
            rn.state = ST_IDLE;
        end

    endcase


    if (r.state == ST_IDLE) begin
        fifo_rd = (!fifo_empty) && (!fifo_tuser);
    end
    else begin
        fifo_rd = r.hen & r.ven;
    end

    
end






//----------------------------------------------------------------------------------------------
// output assignment
//----------------------------------------------------------------------------------------------
assign dout             = r.frame_data;
assign en_out           = r.frame_en;
assign hs_out           = r.frame_hs; 
assign vs_out           = r.frame_vs; 
assign axis_lock_out    = r.axis_lock;
assign lost_lock_out    = r.lost_lock;










//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
if(DEBUG == "TRUE") begin

    (* mark_debug = "true" *)logic                          mark_fifo_rst;
    (* mark_debug = "true" *)logic                          mark_fifo_wr;
    (* mark_debug = "true" *)logic  [FIFO_DW - 1 : 0]       mark_fifo_din;
    (* mark_debug = "true" *)logic                          mark_fifo_rd;
    (* mark_debug = "true" *)logic  [FIFO_DW - 1 : 0]       mark_fifo_dout; 
    (* mark_debug = "true" *)logic                          mark_fifo_empty;
    (* mark_debug = "true" *)logic                          mark_fifo_full; 

    (* mark_debug = "true" *)Fsm_e                          mark_state; 
    (* mark_debug = "true" *)logic [15 : 0]                 mark_hcnt;
    (* mark_debug = "true" *)logic [15 : 0]                 mark_vcnt; 
    (* mark_debug = "true" *)logic [DATA_WIDTH - 1 : 0]     mark_frame_data; 
    (* mark_debug = "true" *)logic                          mark_frame_en;
    (* mark_debug = "true" *)logic                          mark_frame_hs; 
    (* mark_debug = "true" *)logic                          mark_frame_vs; 
    (* mark_debug = "true" *)logic                          mark_axis_lock;
    (* mark_debug = "true" *)logic                          mark_lost_lock;


    assign mark_fifo_rst                                    = fifo_rst;
    assign mark_fifo_wr                                     = fifo_wr;
    assign mark_fifo_din                                    = fifo_din;
    assign mark_fifo_rd                                     = fifo_rd;
    assign mark_fifo_dout                                   = fifo_dout;
    assign mark_fifo_empty                                  = fifo_empty;
    assign mark_fifo_full                                   = fifo_full; 

    assign mark_state                                       = r.state     ; 
    assign mark_hcnt                                        = r.hcnt      ;
    assign mark_vcnt                                        = r.vcnt      ; 
    assign mark_frame_data                                  = r.frame_data; 
    assign mark_frame_en                                    = r.frame_en  ;
    assign mark_frame_hs                                    = r.frame_hs  ; 
    assign mark_frame_vs                                    = r.frame_vs  ;
    assign mark_axis_lock                                   = r.axis_lock ;
    assign mark_lost_lock                                   = r.lost_lock ;
    
end
endgenerate



endmodule

