`timescale 1ns/1ps


module video2axis # (
    parameter DATA_WIDTH    = 16,
    parameter FIFO_DEEP     = 2048,
    parameter DEBUG         = "FALSE"
) (
    input                           rst_n,
    input                           clk,
    input   [DATA_WIDTH - 1 : 0]    din,
    input                           en_in,
    input                           vs_in,


    output                          overflow,
    output                          underflow,

    input                           m_axis_aclk,
    output  [DATA_WIDTH - 1 : 0]    m_axis_tdata,
    output                          m_axis_tlast,
    output                          m_axis_tuser,
    output                          m_axis_tvalid,
    input                           m_axis_tready
);


localparam FIFO_DW = DATA_WIDTH + 2;
localparam FIFO_AW = $clog2(FIFO_DEEP);
localparam FIFO_RST_VS_NEGEDGE_NUM = FIFO_DEEP + FIFO_DEEP;

//----------------------------------------------------------------------------------------------
// struct define
//----------------------------------------------------------------------------------------------
typedef struct {


    logic   [DATA_WIDTH - 1 : 0]    frame_data[2 : 0];
    logic   [2 : 0]                 frame_en;
    logic   [2 : 0]                 frame_vs;


    logic                           first_line;
    logic                           sof;
    logic                           sol;
    logic                           eol;

    logic   [15 : 0]                vs_negedge_cnt;

    logic                           fifo_rst;
    logic   [FIFO_DW - 1 : 0]       fifo_din;
    logic                           fifo_wr;

}frame_s;



//----------------------------------------------------------------------------------------------
// Register define
//----------------------------------------------------------------------------------------------
frame_s r, rn;
 

wire                        fifo_rst;
wire                        fifo_wr;
wire    [FIFO_DW - 1 : 0]   fifo_din;
wire                        fifo_rd;
wire    [FIFO_DW - 1 : 0]   fifo_dout;
wire                        fifo_dvalid;
wire                        fifo_empty;
wire                        fifo_full;
wire                        fifo_overflow;
wire                        fifo_underflow;
wire    [FIFO_AW : 0]       fifo_wr_data_count;
wire    [FIFO_AW : 0]       fifo_rd_data_count;
wire                        fifo_rd_rst_busy;
wire                        fifo_wr_rst_busy;



//----------------------------------------------------------------------------------------------
// frame domain
//----------------------------------------------------------------------------------------------



always_ff @ (posedge clk) begin
    r <= #1 rn;
    if (rst_n == 1'b0) begin

        for (int i = 0; i < 3; i++) begin
            r.frame_data[i] <= #1 'd0;
            r.frame_en[i] <= #1 'd0;
            r.frame_vs[i] <= #1 'd0;
        end

        r.first_line <= #1 'd0;
        r.sof <= #1 'd0;
        r.sol <= #1 'd0;
        r.eol <= #1 'd0;

        r.vs_negedge_cnt <= #1 'd0;
  
        r.fifo_rst <= #1 'd1;
        r.fifo_din <= #1 'd0;
        r.fifo_wr <= #1 'd0;
 
    end
 
end

always_comb begin

    rn = r;

    //frame_data frame_en frame_vs
    rn.frame_data[0] = din;
    rn.frame_data[1] = r.frame_data[0];
    rn.frame_data[2] = r.frame_data[1];


    rn.frame_en[0] = en_in;
    rn.frame_en[1] = r.frame_en[0];
    rn.frame_en[2] = r.frame_en[1];

    rn.frame_vs[0] = vs_in;
    rn.frame_vs[1] = r.frame_vs[0];
    rn.frame_vs[2] = r.frame_vs[1];

    //sol
    if (r.frame_en[2:1] == 2'h1) begin //en rising
        rn.sol = 1'b1;
    end
    else begin
        rn.sol = 1'b0;
    end

    //eol
    if (r.frame_en[1:0] == 2'h2) begin //en falling
        rn.eol = 1'b1;
    end
    else begin
        rn.eol = 1'b0;
    end 
    
    //first line
    if (r.frame_vs[2:1] == 2'h1) begin // vs rising
        rn.first_line = 1'b1;
    end
    else if (rn.eol == 1'b1) begin //en falling
        rn.first_line = 1'b0;
    end

    //vs_negedge_cnt
    if (r.frame_vs[2:1] == 2'h2) begin // vs falling
        rn.vs_negedge_cnt = 'd0;
    end
    else begin
        if (r.vs_negedge_cnt == 16'hFFFF) begin
            rn.vs_negedge_cnt = 16'hFFFF;
        end
        else begin
            rn.vs_negedge_cnt = r.vs_negedge_cnt + 1;
        end
    end

    //fifo_rst
    if (rn.vs_negedge_cnt == FIFO_RST_VS_NEGEDGE_NUM) begin
        rn.fifo_rst = 'd1;

    end
    else if (rn.vs_negedge_cnt == (FIFO_RST_VS_NEGEDGE_NUM + 16)) begin
        rn.fifo_rst = 'd0;
    end


    //sof
    rn.sof = rn.first_line & rn.sol;


    //fifo_data fifo_wr
    rn.fifo_din = {r.eol, r.sof, r.frame_data[2]};
    rn.fifo_wr = r.frame_en[2];

end


//----------------------------------------------------------------------------------------------
// xpm_fifo_async
//----------------------------------------------------------------------------------------------


xpm_fifo_async #(
    .CDC_SYNC_STAGES        (   2                       ), 
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
    .USE_ADV_FEATURES       (   "1707"                  ), 
    .WAKEUP_TIME            (   0                       ), 
    .WRITE_DATA_WIDTH       (   FIFO_DW                 ), 
    .WR_DATA_COUNT_WIDTH    (   FIFO_AW + 1             )  
)
xpm_fifo_async_inst (
    .rst                    (   fifo_rst                ),
    .wr_clk                 (   clk                     ),                
    .din                    (   fifo_din                ),  
    .wr_en                  (   fifo_wr                 ),
    .rd_clk                 (   m_axis_aclk             ),              
    .dout                   (   fifo_dout               ), 
    .rd_en                  (   fifo_rd                 ), 
    .data_valid             (   fifo_dvalid             ),  
    .empty                  (   fifo_empty              ),                
    .full                   (   fifo_full               ),                
    .overflow               (   fifo_overflow           ),   
    .underflow              (   fifo_underflow          ), 
    .wr_data_count          (   fifo_wr_data_count      ),  
    .rd_data_count          (   fifo_rd_data_count      ),   
    .rd_rst_busy            (   fifo_rd_rst_busy        ),   
    .wr_rst_busy            (   fifo_wr_rst_busy        )
);
assign fifo_rst = r.fifo_rst;
assign fifo_din = r.fifo_din;
assign fifo_wr = r.fifo_wr;

//----------------------------------------------------------------------------------------------
// axis domain
//----------------------------------------------------------------------------------------------

assign fifo_rd = m_axis_tready & (!fifo_empty) & (!fifo_rd_rst_busy);

assign m_axis_tdata = fifo_dout[DATA_WIDTH - 1 : 0];	
assign m_axis_tuser = fifo_dout[DATA_WIDTH];
assign m_axis_tlast = fifo_dout[DATA_WIDTH + 1];
assign m_axis_tvalid = fifo_dvalid;


//----------------------------------------------------------------------------------------------
// output assignment
//----------------------------------------------------------------------------------------------
assign overflow = fifo_overflow;
assign underflow = fifo_underflow;


//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
    if(DEBUG == "TRUE") begin


        (* mark_debug = "true" *)logic                        mark_fifo_rst;
        (* mark_debug = "true" *)logic                        mark_fifo_wr;
        (* mark_debug = "true" *)logic    [FIFO_DW - 1 : 0]   mark_fifo_din;
        (* mark_debug = "true" *)logic                        mark_fifo_rd;
        (* mark_debug = "true" *)logic    [FIFO_DW - 1 : 0]   mark_fifo_dout;
        (* mark_debug = "true" *)logic                        mark_fifo_dvalid;
        (* mark_debug = "true" *)logic                        mark_fifo_empty;
        (* mark_debug = "true" *)logic                        mark_fifo_full;
        (* mark_debug = "true" *)logic                        mark_fifo_overflow;
        (* mark_debug = "true" *)logic                        mark_fifo_underflow;
        (* mark_debug = "true" *)logic    [FIFO_AW : 0]       mark_fifo_wr_data_count;
        (* mark_debug = "true" *)logic    [FIFO_AW : 0]       mark_fifo_rd_data_count;
        (* mark_debug = "true" *)logic                        mark_fifo_rd_rst_busy;
        (* mark_debug = "true" *)logic                        mark_fifo_wr_rst_busy;

        assign mark_fifo_rst                                  = fifo_rst;
        assign mark_fifo_wr                                   = fifo_wr;
        assign mark_fifo_din                                  = fifo_din;
        assign mark_fifo_rd                                   = fifo_rd;
        assign mark_fifo_dout                                 = fifo_dout;
        assign mark_fifo_dvalid                               = fifo_dvalid;
        assign mark_fifo_empty                                = fifo_empty;
        assign mark_fifo_full                                 = fifo_full;
        assign mark_fifo_overflow                             = fifo_overflow;
        assign mark_fifo_underflow                            = fifo_underflow;
        assign mark_fifo_wr_data_count                        = fifo_wr_data_count;
        assign mark_fifo_rd_data_count                        = fifo_rd_data_count;
        assign mark_fifo_rd_rst_busy                          = fifo_rd_rst_busy;
        assign mark_fifo_wr_rst_busy                          = fifo_wr_rst_busy;                                                   

        
    end
endgenerate



endmodule
