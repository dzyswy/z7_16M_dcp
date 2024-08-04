`timescale 1ps/1ps


module px_data_train # ( 
    parameter DEBUG                 = "FALSE"
) (
    input               px_clk,
    input               px_reset,
    
    input   [15:0]      FRAME_WIDTH,
    input   [15:0]      CHECK_SEARCH_LINE,
    input   [15:0]      CHECK_PATTERN_NUM,
    input   [7:0]       EYE_RANGE,

    input               SERDES_BIT_REVERSE,
    input   [7:0]       SERDES_SLIP_NUM,
    input   [7:0]       SERDES_DELAY_NUM,
    input               SERDES_MANUL_MODE,

    input               start,
    input               pattern_locked,
    
    output              bit_reverse_out,
    output  [7:0]       slip_num_out,  
    output  [7:0]       delay_num_out, 
    output  [7:0]       best_range_out,
    output              lock_out,
    output              done_out
);





//----------------------------------------------------------------------------------------------
// Fsm define
//----------------------------------------------------------------------------------------------
typedef enum logic[2:0] {
    ST_IDLE                 = 3'd0, 
    ST_GEN_START            = 3'd1,
    ST_GEN_DONE             = 3'd2,       
    ST_PARSE_START          = 3'd3,
    ST_PARSE_DONE           = 3'd4,
    ST_DONE                 = 3'd5 
}Fsm_e;


//----------------------------------------------------------------------------------------------
// struct define
//----------------------------------------------------------------------------------------------


typedef struct {

    Fsm_e           state;
 

    logic           gen_start;
    logic           parse_start;

    logic           bit_reverse;
    logic [7:0]     slip_num;
    logic [7:0]     delay_num; 

    logic           done;

}logic_s;


//----------------------------------------------------------------------------------------------
// Register define
//----------------------------------------------------------------------------------------------
logic_s r, rn; 
logic [31 : 0] lock_buff[11 : 0];

//----------------------------------------------------------------------------------------------
// Wire define
//----------------------------------------------------------------------------------------------
logic [7:0] gen_delay_num_out      ;
logic [7:0] gen_slip_num_out       ;
logic [31:0] gen_lock_mask_dout     ;
logic [3:0] gen_lock_mask_waddr_out;
logic gen_lock_mask_we_out   ;
logic gen_done_out           ;

logic [31:0] parse_lock_mask_din       ;
logic [3:0] parse_lock_mask_raddr_out ;
logic parse_lock_mask_ren_out   ;
logic [7:0] parse_delay_min_dout      ;
logic [7:0] parse_delay_max_dout      ;
logic [7:0] parse_delay_range_dout    ;
logic [3:0] parse_delay_data_waddr_out;
logic parse_delay_data_we_out   ;
logic [7:0] parse_best_delay_out      ;
logic [7:0] parse_best_slip_out       ;
logic [7:0] parse_best_range_out       ;
logic parse_lock_out            ;
logic parse_done_out            ;

//----------------------------------------------------------------------------------------------
// Module define
//----------------------------------------------------------------------------------------------
serdes_gen_lock_mask # (
    .DEBUG          (   DEBUG               )
) u_gen_lock_mask (
    .px_clk                 (   px_clk                      ),
    .px_reset               (   px_reset                    ),
    .FRAME_WIDTH            (   FRAME_WIDTH                 ),
    .CHECK_SEARCH_LINE      (   CHECK_SEARCH_LINE           ),
    .CHECK_PATTERN_NUM      (   CHECK_PATTERN_NUM           ), 
    .start                  (   r.gen_start                 ),
    .pattern_locked         (   pattern_locked              ),
    .delay_num_out          (   gen_delay_num_out           ),
    .slip_num_out           (   gen_slip_num_out            ),
    .lock_mask_dout         (   gen_lock_mask_dout          ),
    .lock_mask_waddr_out    (   gen_lock_mask_waddr_out     ),
    .lock_mask_we_out       (   gen_lock_mask_we_out        ),
    .done_out               (   gen_done_out                )
);

serdes_parse_lock_mask # (
    .DEBUG          (   "TRUE"               )//"TRUE"
) u_parse_lock_mask (
    .px_clk                 (   px_clk                      ),
    .px_reset               (   px_reset                    ),
    .EYE_RANGE              (   EYE_RANGE                   ),
    .start                  (   r.parse_start               ),
    .lock_mask_din          (   parse_lock_mask_din         ),
    .lock_mask_raddr_out    (   parse_lock_mask_raddr_out   ),
    .lock_mask_ren_out      (   parse_lock_mask_ren_out     ),
    .delay_min_dout         (   parse_delay_min_dout        ),
    .delay_max_dout         (   parse_delay_max_dout        ),
    .delay_range_dout       (   parse_delay_range_dout      ),
    .delay_data_waddr_out   (   parse_delay_data_waddr_out  ),
    .delay_data_we_out      (   parse_delay_data_we_out     ),
    .best_delay_out         (   parse_best_delay_out        ),
    .best_slip_out          (   parse_best_slip_out         ),
    .best_range_out         (   parse_best_range_out        ),
    .lock_out               (   parse_lock_out              ),
    .done_out               (   parse_done_out              )
);

sensor_sdpram # (
    .DATA_WIDTH     (   32              ),
    .MEM_DEEP       (   16              ),
    .MEM_TYPE       (   "auto"          )
) u_lock_mask_ram (
    .rst_n          (   !px_reset                   ),
    .clk            (   px_clk                      ), 
    .din            (   gen_lock_mask_dout          ),
    .waddr          (   gen_lock_mask_waddr_out     ), 
    .we             (   gen_lock_mask_we_out        ), 
    .raddr          (   parse_lock_mask_raddr_out   ), 
    .ren            (   parse_lock_mask_ren_out     ),
    .dout           (   parse_lock_mask_din         )
);



//----------------------------------------------------------------------------------------------
// sequential always
//----------------------------------------------------------------------------------------------    

always_ff @ (posedge px_clk) begin
    r <= #1 rn;
    if (px_reset) begin

        r.state         <= #1 ST_IDLE;
 
        r.gen_start     <= #1 'd0;
        r.parse_start   <= #1 'd0;
        r.bit_reverse   <= #1 'd0;
        r.slip_num      <= #1 'd0;
        r.delay_num     <= #1 'd0; 
        r.done          <= #1 'd0;
 
 
    end


end


//----------------------------------------------------------------------------------------------
// combinatorial always
//----------------------------------------------------------------------------------------------

always_comb begin

    rn = r; 

    rn.bit_reverse = SERDES_BIT_REVERSE;

    case (r.state)
        ST_IDLE: begin

            if (start) begin
                rn.gen_start = 1'b1;
                rn.done = 1'b0;
                rn.state = ST_GEN_START;
            end 
            
        end

        ST_GEN_START: begin
            rn.state = ST_GEN_DONE;
        end

        ST_GEN_DONE: begin
            if (gen_done_out) begin
                rn.gen_start = 1'b0;
                rn.parse_start = 1'b1;
                rn.state = ST_PARSE_START;
            end
        end

        ST_PARSE_START: begin
            rn.state = ST_PARSE_DONE;
        end

        ST_PARSE_DONE: begin
            if (parse_done_out) begin
                rn.parse_start = 1'b0;
                rn.done = 1'b1;
                rn.state = ST_DONE;
            end
        end

        ST_DONE: begin 
            rn.state = ST_IDLE;
        end

        default: begin
            rn.state = ST_IDLE;
        end

    endcase


    

    if (SERDES_MANUL_MODE) begin
        rn.slip_num = SERDES_SLIP_NUM;
        rn.delay_num = SERDES_DELAY_NUM;
    end
    else begin
        if ((r.state == ST_GEN_START) || (r.state == ST_GEN_DONE)) begin
            rn.slip_num = gen_slip_num_out;
            rn.delay_num = gen_delay_num_out;
        end
        else begin
            rn.slip_num = parse_best_slip_out;
            rn.delay_num = parse_best_delay_out;
        end
    end
end



//----------------------------------------------------------------------------------------------
// output assignment
//----------------------------------------------------------------------------------------------
assign bit_reverse_out      = r.bit_reverse;
assign slip_num_out         = r.slip_num;  
assign delay_num_out        = r.delay_num;  
assign best_range_out       = parse_best_range_out;
assign lock_out             = parse_lock_out;
assign done_out             = r.done;   


//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
if(DEBUG == "TRUE") begin


end
endgenerate













endmodule





