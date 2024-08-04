`timescale 1ps/1ps


module decode_lock_mask # ( 
    parameter DEBUG                 = "FALSE"
) (
    input               px_clk,
    input               px_reset,


    input               start,
    
    input   [31:0]      lock_mask_din, 

    
    output  [7:0]       delay_min_dout,
    output  [7:0]       delay_max_dout,
    output  [7:0]       delay_range_dout,
 
    output              done_out
);





//----------------------------------------------------------------------------------------------
// Fsm define
//----------------------------------------------------------------------------------------------
typedef enum logic[2:0] {
    ST_IDLE             = 3'd0, 
    ST_MASK_SHIFT       = 3'd1,
    ST_DELAY_MINMAX     = 3'd2,       
    ST_LOOP             = 3'd3,
    ST_LOOP_OUT        = 3'd4,
    ST_DELAY_RANGE      = 3'd5,
    ST_OUTPUT           = 3'd6,
    ST_DONE             = 3'd7
}Fsm_e;


//----------------------------------------------------------------------------------------------
// struct define
//----------------------------------------------------------------------------------------------


typedef struct {

    Fsm_e           state;

    logic [31:0]    lock_mask_a; 
    logic [31:0]    lock_mask_rs_a; 
    logic [31:0]    lock_mask_ls_a; 

    logic [31:0]    lock_mask_b; 
    logic [31:0]    lock_mask_rs_b; 
    logic [31:0]    lock_mask_ls_b; 

 
    logic [7:0]     dcnt; 

    logic [7:0]     delay_min_a; 
    logic [7:0]     delay_max_a; 
    logic [7:0]     delay_range_a; 
    logic [7:0]     delay_min_b; 
    logic [7:0]     delay_max_b; 
    logic [7:0]     delay_range_b; 
    logic [7:0]     delay_min; 
    logic [7:0]     delay_max; 
    logic [7:0]     delay_range; 

 
    logic           done; 

}logic_s;


//----------------------------------------------------------------------------------------------
// Register define
//----------------------------------------------------------------------------------------------
logic_s r, rn;  

logic           lock_bit_a   ;
logic           lock_bit_rs_a;
logic           lock_bit_ls_a;
logic           lock_bit_b   ;
logic           lock_bit_rs_b;
logic           lock_bit_ls_b;

//----------------------------------------------------------------------------------------------
// sequential always
//----------------------------------------------------------------------------------------------    

always_ff @ (posedge px_clk) begin
    r <= #1 rn;
    if (px_reset) begin

        r.state             <= #1 ST_IDLE;

        

        r.lock_mask_a       <= #1 'd0; 
        r.lock_mask_rs_a    <= #1 'd0; 
        r.lock_mask_ls_a    <= #1 'd0; 
        r.lock_mask_b       <= #1 'd0; 
        r.lock_mask_rs_b    <= #1 'd0; 
        r.lock_mask_ls_b    <= #1 'd0; 
 
        r.dcnt              <= #1 'd0; 

        r.delay_min_a       <= #1 'd0; 
        r.delay_max_a       <= #1 'd0; 
        r.delay_range_a     <= #1 'd0; 
        r.delay_min_b       <= #1 'd0; 
        r.delay_max_b       <= #1 'd0; 
        r.delay_range_b     <= #1 'd0; 
        r.delay_min         <= #1 'd0; 
        r.delay_max         <= #1 'd0; 
        r.delay_range       <= #1 'd0; 
        

 
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
                
                rn.lock_mask_a = lock_mask_din;
                rn.lock_mask_b = lock_mask_din;
                rn.delay_min_a = 33;
                rn.delay_max_a = 33;
                rn.delay_min_b = 33;
                rn.delay_max_b = 33;
                rn.dcnt = 0;
                rn.done = 1'b0;
                rn.state = ST_MASK_SHIFT;
            end
            
        end

        ST_MASK_SHIFT: begin
            rn.lock_mask_rs_a = r.lock_mask_a >> 1;
            rn.lock_mask_ls_a = r.lock_mask_a << 1;

            rn.lock_mask_rs_b = r.lock_mask_b >> 1;
            rn.lock_mask_ls_b = r.lock_mask_b << 1;

            rn.state = ST_DELAY_MINMAX;
        end

 
        ST_DELAY_MINMAX: begin
            if ((lock_bit_a) && (lock_bit_ls_a) && (!lock_bit_rs_a)) begin
                rn.delay_max_a = r.dcnt;
            end

            if ((lock_bit_a) && (!lock_bit_ls_a) && (lock_bit_rs_a)) begin
                rn.delay_min_a = r.dcnt;
            end

            if ((lock_bit_b) && (lock_bit_ls_b) && (!lock_bit_rs_b)) begin
                rn.delay_max_b = 31 - r.dcnt;
            end

            if ((lock_bit_b) && (!lock_bit_ls_b) && (lock_bit_rs_b)) begin
                rn.delay_min_b = 31 - r.dcnt;
            end

            

            rn.state = ST_LOOP;
        end

        

        ST_LOOP: begin
            rn.dcnt = r.dcnt + 1;
            rn.state = ST_LOOP_OUT;
        end

        ST_LOOP_OUT: begin 
            if (r.dcnt >= 32) begin  
                rn.state = ST_DELAY_RANGE;
            end
            else begin
                rn.state = ST_DELAY_MINMAX;
            end

            rn.lock_mask_a      = r.lock_mask_a    >> 1;
            rn.lock_mask_rs_a   = r.lock_mask_rs_a >> 1;
            rn.lock_mask_ls_a   = r.lock_mask_ls_a >> 1;

            rn.lock_mask_b      = r.lock_mask_b    << 1;
            rn.lock_mask_rs_b   = r.lock_mask_rs_b << 1;
            rn.lock_mask_ls_b   = r.lock_mask_ls_b << 1;
        end

        ST_DELAY_RANGE: begin

            if ((r.delay_min_a != 33) && (r.delay_max_a != 33)) begin
                rn.delay_range_a = r.delay_max_a - r.delay_min_a + 1;
            end

            if ((r.delay_min_b != 33) && (r.delay_max_b != 33)) begin
                rn.delay_range_b = r.delay_max_b - r.delay_min_b + 1;
            end

            rn.state = ST_OUTPUT;
        end

        ST_OUTPUT: begin
            if ((r.delay_range_a >= r.delay_range_b) && (r.delay_range_a != 0)) begin
                rn.delay_min = r.delay_min_a;
                rn.delay_max = r.delay_max_a;
                rn.delay_range = r.delay_range_a;
            end
            else if ((r.delay_range_b >= r.delay_range_a) && (r.delay_range_b != 0)) begin
                rn.delay_min = r.delay_min_b;
                rn.delay_max = r.delay_max_b;
                rn.delay_range = r.delay_range_b;
            end
            rn.done = 1'b1;
            rn.state = ST_DONE;
        end

  

        ST_DONE: begin 
            rn.state = ST_IDLE;
        end

        default: begin
            rn.state = ST_IDLE;
        end

    endcase

end


assign lock_bit_a     = r.lock_mask_a[0];
assign lock_bit_rs_a  = r.lock_mask_rs_a[0];
assign lock_bit_ls_a  = r.lock_mask_ls_a[0];
assign lock_bit_b     = r.lock_mask_b[31];
assign lock_bit_rs_b  = r.lock_mask_rs_b[31];
assign lock_bit_ls_b  = r.lock_mask_ls_b[31];


//----------------------------------------------------------------------------------------------
// output assignment
//----------------------------------------------------------------------------------------------
assign delay_min_dout           = r.delay_min;
assign delay_max_dout           = r.delay_max;
assign delay_range_dout         = r.delay_range; 
assign done_out                 = r.done; 



//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
if(DEBUG == "TRUE") begin


end
endgenerate













endmodule





