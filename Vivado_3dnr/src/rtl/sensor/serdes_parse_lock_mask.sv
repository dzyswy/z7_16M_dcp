`timescale 1ps/1ps


module serdes_parse_lock_mask # ( 
    parameter DEBUG                 = "FALSE"
) (
    input               px_clk,
    input               px_reset,

    input   [7:0]       EYE_RANGE,


    input               start,
    
    input   [31:0]      lock_mask_din,
    output  [3:0]       lock_mask_raddr_out,
    output              lock_mask_ren_out,

    
    output  [7:0]       delay_min_dout,
    output  [7:0]       delay_max_dout,
    output  [7:0]       delay_range_dout,
    output  [3:0]       delay_data_waddr_out,
    output              delay_data_we_out,

    output  [7:0]       best_delay_out,
    output  [7:0]       best_slip_out,
    output  [7:0]       best_range_out,
    output              lock_out,
    output              done_out
);





//----------------------------------------------------------------------------------------------
// Fsm define
//----------------------------------------------------------------------------------------------
typedef enum logic[3:0] {
    ST_IDLE             = 4'd0, 
    ST_MASK_ADDR        = 4'd1,
    ST_MASK_READ        = 4'd2,
    ST_LOAD_MASK        = 4'd3,       
    ST_DECODE_START     = 4'd4,
    ST_DECODE_DONE      = 4'd5,
    ST_MAX_RANGE        = 4'd6,
    ST_LOOP             = 4'd7,
    ST_LOOP_OUT         = 4'd8,
    ST_DONE             = 4'd9
}Fsm_e;


//----------------------------------------------------------------------------------------------
// struct define
//----------------------------------------------------------------------------------------------


typedef struct {

    Fsm_e           state;

    logic [31:0]    lock_mask; 
    logic [3:0]     lock_mask_raddr;
    logic           lock_mask_ren;

    logic           decode_start;
    logic [7:0]     delay_min; 
    logic [7:0]     delay_max; 
    logic [7:0]     delay_range; 
    logic [3:0]     delay_data_waddr;
    logic           delay_data_we;
 
 
    logic [7:0]     scnt; 
  
 
    logic [7:0]     best_range;
    logic [7:0]     best_slip;
    logic [7:0]     best_delay;
    


    logic           lock;
    logic           done; 

}logic_s;


//----------------------------------------------------------------------------------------------
// Register define
//----------------------------------------------------------------------------------------------
logic_s r, rn;  

//----------------------------------------------------------------------------------------------
// Wire define
//----------------------------------------------------------------------------------------------
logic [7:0] decode_delay_min_dout  ; 
logic [7:0] decode_delay_max_dout  ; 
logic [7:0] decode_delay_range_dout; 
logic decode_done_out        ; 


//----------------------------------------------------------------------------------------------
// other module
//----------------------------------------------------------------------------------------------

decode_lock_mask # (
    .DEBUG          (   DEBUG               )
) u_decode (
    .px_clk             (   px_clk                      ),
    .px_reset           (   px_reset                    ),
    .start              (   r.decode_start              ),
    .lock_mask_din      (   r.lock_mask                 ), 
    .delay_min_dout     (   decode_delay_min_dout       ),
    .delay_max_dout     (   decode_delay_max_dout       ),
    .delay_range_dout   (   decode_delay_range_dout     ),
    .done_out           (   decode_done_out             )
);


//----------------------------------------------------------------------------------------------
// sequential always
//----------------------------------------------------------------------------------------------    

always_ff @ (posedge px_clk) begin
    r <= #1 rn;
    if (px_reset) begin

        r.state             <= #1 ST_IDLE;

        r.lock_mask         <= #1 'd0;  
        r.lock_mask_raddr   <= #1 'd0;  
        r.lock_mask_ren     <= #1 'd0;
 
        r.decode_start      <= #1 'd0;
        r.delay_min         <= #1 'd0; 
        r.delay_max         <= #1 'd0; 
        r.delay_range       <= #1 'd0; 
        r.delay_data_waddr  <= #1 'd0;
        r.delay_data_we     <= #1 'd0;

        r.scnt              <= #1 'd0; 

        r.best_range         <= #1 'd0;
        r.best_slip         <= #1 'd0;
        r.best_delay        <= #1 'd0;

        r.lock              <= #1 'd0; 
        r.done              <= #1 'd0; 

 
    end


end


//----------------------------------------------------------------------------------------------
// combinatorial always
//----------------------------------------------------------------------------------------------

always_comb begin

    rn = r; 

    case (r.state)
        ST_IDLE: begin

            if (start) begin 
                rn.lock = 1'b0;
                rn.done = 1'b0;
                rn.state = ST_MASK_ADDR;
            end

            rn.scnt = 0; 
            
        end

        ST_MASK_ADDR: begin


            rn.lock_mask_raddr = r.scnt; 
            rn.lock_mask_ren = 1'b1;
            rn.state = ST_MASK_READ;

        end

        ST_MASK_READ: begin
            rn.lock_mask_ren = 1'b0;
            rn.state = ST_LOAD_MASK;
        end

        ST_LOAD_MASK: begin
            rn.lock_mask = lock_mask_din;
            rn.decode_start = 1'b1;
            rn.state = ST_DECODE_START;
        end

        ST_DECODE_START: begin
            
            rn.state = ST_DECODE_DONE;
        end

        ST_DECODE_DONE: begin
            if (decode_done_out) begin
                rn.decode_start = 1'b0;
                rn.delay_min = decode_delay_min_dout;
                rn.delay_max = decode_delay_max_dout;
                rn.delay_range = decode_delay_range_dout;
                rn.delay_data_waddr = r.scnt;
                rn.delay_data_we = 1'b1;
                rn.state = ST_MAX_RANGE;
            end
        end

        ST_MAX_RANGE: begin
            rn.delay_data_we = 1'b0;
            if (r.delay_range > r.best_range) begin
                rn.best_range = r.delay_range;
                rn.best_slip = r.scnt;
                rn.best_delay = r.delay_min + r.delay_range / 2;
            end
            rn.state = ST_LOOP;
        end

        ST_LOOP: begin
  
            rn.scnt = r.scnt + 1;
            rn.state = ST_LOOP_OUT;
        end

        ST_LOOP_OUT: begin 
            if (r.scnt >= 12) begin
                rn.scnt = 0;

                if (r.best_range >= EYE_RANGE) begin
                    rn.lock = 1'b1;
                end

                rn.done = 1'b1;
                rn.state = ST_DONE;
            end
            else begin
                rn.state = ST_MASK_ADDR;
            end
        end


        ST_DONE: begin 
            rn.state = ST_IDLE;
        end

        default: begin
            rn.state = ST_IDLE;
        end

    endcase

end



//----------------------------------------------------------------------------------------------
// output assignment
//----------------------------------------------------------------------------------------------

assign lock_mask_raddr_out      = r.lock_mask_raddr;
assign lock_mask_ren_out        = r.lock_mask_ren;

assign delay_min_dout           = r.delay_min;
assign delay_max_dout           = r.delay_max;
assign delay_range_dout         = r.delay_range;
assign delay_data_waddr_out     = r.delay_data_waddr;
assign delay_data_we_out        = r.delay_data_we;
assign best_delay_out           = r.best_delay;
assign best_slip_out            = r.best_slip;
assign best_range_out            = r.best_range;
assign lock_out                 = r.lock;
assign done_out                 = r.done; 


//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
if(DEBUG == "TRUE") begin

    (* mark_debug = "true" *)Fsm_e           mark_state;
    (* mark_debug = "true" *)logic [31:0]    mark_lock_mask; 
    (* mark_debug = "true" *)logic [3:0]     mark_lock_mask_raddr;
    (* mark_debug = "true" *)logic           mark_lock_mask_ren;
    (* mark_debug = "true" *)logic           mark_decode_start;
    (* mark_debug = "true" *)logic [7:0]     mark_delay_min; 
    (* mark_debug = "true" *)logic [7:0]     mark_delay_max; 
    (* mark_debug = "true" *)logic [7:0]     mark_delay_range; 
    (* mark_debug = "true" *)logic [3:0]     mark_delay_data_waddr;
    (* mark_debug = "true" *)logic           mark_delay_data_we;
    (* mark_debug = "true" *)logic [7:0]     mark_scnt; 
    (* mark_debug = "true" *)logic [7:0]     mark_best_range;
    (* mark_debug = "true" *)logic [7:0]     mark_best_slip;
    (* mark_debug = "true" *)logic [7:0]     mark_best_delay;
    (* mark_debug = "true" *)logic           mark_lock;
    (* mark_debug = "true" *)logic           mark_done; 

    assign mark_state                       = r.state            ;
    assign mark_lock_mask                   = r.lock_mask        ; 
    assign mark_lock_mask_raddr             = r.lock_mask_raddr  ;
    assign mark_lock_mask_ren               = r.lock_mask_ren    ;
    assign mark_decode_start                = r.decode_start     ;
    assign mark_delay_min                   = r.delay_min        ; 
    assign mark_delay_max                   = r.delay_max        ; 
    assign mark_delay_range                 = r.delay_range      ; 
    assign mark_delay_data_waddr            = r.delay_data_waddr ;
    assign mark_delay_data_we               = r.delay_data_we    ;
    assign mark_scnt                        = r.scnt             ; 
    assign mark_best_range                  = r.best_range       ;
    assign mark_best_slip                   = r.best_slip        ;
    assign mark_best_delay                  = r.best_delay       ;
    assign mark_lock                        = r.lock             ;
    assign mark_done                        = r.done             ; 

end
endgenerate













endmodule





