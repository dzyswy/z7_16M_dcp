`timescale 1ps/1ps


module serdes_gen_lock_mask # ( 
    parameter DEBUG                 = "FALSE"
) (
    input               px_clk,
    input               px_reset,

    input   [15:0]      FRAME_WIDTH,
    input   [15:0]      CHECK_SEARCH_LINE,
    input   [15:0]      CHECK_PATTERN_NUM, 


    input               start,
    input               pattern_locked,

    output  [7:0]       delay_num_out,
    output  [7:0]       slip_num_out,

    output  [31:0]      lock_mask_dout,
    output  [3:0]       lock_mask_waddr_out,
    output              lock_mask_we_out,
    output              done_out
);





//----------------------------------------------------------------------------------------------
// Fsm define
//----------------------------------------------------------------------------------------------
typedef enum logic[3:0] {
    ST_IDLE            = 4'd0, 
    ST_SET_PARAM       = 4'd1,
    ST_CHECK_PATTERN   = 4'd2,       
    ST_CHECK_LOCK      = 4'd3,
    ST_SHIFT_MASK      = 4'd4,
    ST_LOCK_MASK       = 4'd5,
    ST_LOOP            = 4'd6,
    ST_LOOP_OUT        = 4'd7,
    ST_DONE            = 4'd8
}Fsm_e;


//----------------------------------------------------------------------------------------------
// struct define
//----------------------------------------------------------------------------------------------


typedef struct {

    Fsm_e           state;

    logic [15:0]    hcnt; 
    logic [15:0]    vcnt;

    logic [7:0]     dcnt;
    logic [7:0]     scnt; 

    logic [7:0]     dnum;
    logic [7:0]     snum;  

    logic [15:0]    lock_cnt; 
    logic           lock_bit;
    logic [31:0]    lock_mask; 

    logic [31:0]    lock_data; 
    logic [3:0]     lock_data_waddr;
    logic           lock_data_we;

    logic           done; 

}logic_s;


//----------------------------------------------------------------------------------------------
// Register define
//----------------------------------------------------------------------------------------------
logic_s r, rn;  



//----------------------------------------------------------------------------------------------
// sequential always
//----------------------------------------------------------------------------------------------    

always_ff @ (posedge px_clk) begin
    r <= #1 rn;
    if (px_reset) begin

        r.state             <= #1 ST_IDLE;

        r.hcnt              <= #1 'd0; 
        r.vcnt              <= #1 'd0; 

        r.dcnt              <= #1 'd0;
        r.scnt              <= #1 'd0; 

        r.dnum              <= #1 'd0;
        r.snum              <= #1 'd0; 

        r.lock_cnt          <= #1 'd0;
        r.lock_bit          <= #1 'd0;
        r.lock_mask         <= #1 'd0; 

        r.lock_data         <= #1 'd0;
        r.lock_data_waddr   <= #1 'd0; 
        r.lock_data_we      <= #1 'd0; 

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
                
                rn.done = 1'b0;
                rn.state = ST_SET_PARAM;
            end
            rn.hcnt = 0;
            rn.vcnt = 0;
            rn.scnt = 0;
            rn.dcnt = 0;
        end

        ST_SET_PARAM: begin
            rn.dnum = r.dcnt;
            rn.snum = r.scnt; 
            rn.lock_cnt = 0;
            rn.lock_bit = 1'b0;
            

            if (r.hcnt >= 8) begin
                rn.hcnt = 0;
                rn.vcnt = 0;
                rn.state = ST_CHECK_PATTERN;
            end else begin
                rn.hcnt = r.hcnt + 1;
            end


        end

        ST_CHECK_PATTERN: begin

            if (r.hcnt == (FRAME_WIDTH - 1)) begin
                rn.hcnt = 0;
                if (r.vcnt == (CHECK_SEARCH_LINE - 1)) begin
                    rn.vcnt = 0;
                    rn.state = ST_CHECK_LOCK;
                end
                else begin
                    rn.vcnt = r.vcnt + 1;
                end
            end
            else begin
                rn.hcnt = r.hcnt + 1;
            end

            if (pattern_locked) begin
                if (r.lock_cnt == 16'hffff) begin
                    rn.lock_cnt = 16'hffff;
                end
                else begin
                    rn.lock_cnt = r.lock_cnt + 1;
                end
            end 
            
        end

        ST_CHECK_LOCK: begin

            if (r.lock_cnt >= CHECK_PATTERN_NUM) begin
                rn.lock_bit = 1'b1;
            end
            else begin
                rn.lock_bit = 1'b0;
            end

            rn.state = ST_SHIFT_MASK;

        end

        ST_SHIFT_MASK: begin
            rn.lock_mask = r.lock_mask >> 1;
            rn.state = ST_LOCK_MASK;
        end

        ST_LOCK_MASK: begin

            rn.lock_mask = r.lock_mask | (r.lock_bit << 31);
            rn.state = ST_LOOP;
        end

        ST_LOOP: begin
            if (r.dcnt >= 31) begin
                rn.dcnt = 0;
                rn.lock_mask = 0;
                rn.lock_data = r.lock_mask;
                rn.lock_data_waddr = r.scnt;
                rn.lock_data_we = 1'b1;
                
                rn.scnt = r.scnt + 1;
            end
            else begin
                rn.dcnt = r.dcnt + 1;
            end
            rn.state = ST_LOOP_OUT;
        end

        ST_LOOP_OUT: begin
            rn.lock_data_we = 1'b0;
            if (r.scnt >= 12) begin
                rn.scnt = 0;
                rn.done = 1'b1;
                rn.state = ST_DONE;
            end
            else begin
                rn.state = ST_SET_PARAM;
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


assign delay_num_out            = r.dnum;
assign slip_num_out             = r.snum;
assign lock_mask_dout           = r.lock_data;
assign lock_mask_waddr_out      = r.lock_data_waddr;
assign lock_mask_we_out         = r.lock_data_we;
assign done_out                 = r.done; 


//----------------------------------------------------------------------------------------------
// Debug Signal
//----------------------------------------------------------------------------------------------
generate
if(DEBUG == "TRUE") begin


end
endgenerate













endmodule





