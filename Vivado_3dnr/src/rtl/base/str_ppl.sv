`timescale   1ns/1ps
//--------------------------------------------------------------------------------------------------
// module declaration
//--------------------------------------------------------------------------------------------------

module str_ppl
#(
	parameter WIDTH	= 32,
	parameter SIM 	= "FALSE",
	parameter DEBUG	= "FALSE"
)
(
	//------------------------------------------------
	// Port define
	//------------------------------------------------
	input						i_clk,
	input						i_rst,
	
	input 	[WIDTH - 1 : 0] 	i_str_data,
	input 						i_str_vld,
	input 						i_str_user,	
	input 						i_str_last,
	output						o_str_rdy,
	
	output 	[WIDTH - 1 : 0] 	o_str_data,
	output 						o_str_vld,
	output 						o_str_user,	
	output 						o_str_last,
	input						i_str_rdy

);

    logic                       input_accept_int;
    logic   [WIDTH - 1 : 0]     output_reg;
    logic                       output_last_reg;
    logic                       output_valid_reg;
    logic                       buffer_full;
    logic   [WIDTH - 1 : 0]     buffer_data;
    logic                       buffer_last;
    logic                       buffer_user;
    logic                       output_user_reg;


    always@(posedge i_clk) begin
        if(i_rst == 1'b1) begin
			output_reg          <= 'd0;
			output_last_reg     <= 'd0;
			output_valid_reg    <= 'd0;

			input_accept_int    <= 1'd1;

			buffer_full         <= 'd0;
			buffer_data         <= 'd0;
			buffer_last         <= 'd0;
			buffer_user         <= 'd0;
			output_user_reg		<= 'd0;
        end
        else begin
			//
			// Data is coming, buf output data can't be sent => Store input data in buffer
			// and remove input_accept signal!
			//
			if (i_str_vld == 1'b1 && input_accept_int == 1'b1 && output_valid_reg == 1'b1 && i_str_rdy == 1'b0 )begin
				buffer_data      <= i_str_data;
				buffer_last      <= i_str_last;
				buffer_user	     <= i_str_user;
				buffer_full      <= 1'b1;
				input_accept_int <= 1'b0;
            end

			//
			// Output data is being read but there is data in the buffer waiting for being sent
			// => Use the buffer data!
			//
			if (i_str_rdy == 1'b1 && output_valid_reg == 1'b1 && buffer_full == 1'b1)begin
				output_reg       <= buffer_data;
				output_last_reg  <= buffer_last;
				output_user_reg  <= buffer_user;
				output_valid_reg <= 1'b1;
				buffer_full      <= 1'b0;
				input_accept_int <= 1'b1;
            end
			//
			// Data is being read and buffer is empty => Use input data directly!
			// Output register is empty => Use input data directly!
			//
			else if ((i_str_rdy == 1'b1 && output_valid_reg == 1'b1) || output_valid_reg == 1'b0)begin
				output_reg       <= i_str_data;
				output_last_reg  <= i_str_last;
				output_user_reg  <= i_str_user;
				output_valid_reg <= i_str_vld;
            end
        end
    end

    assign o_str_rdy = input_accept_int;
    assign o_str_data = output_reg;
    assign o_str_last = output_last_reg;
    assign o_str_vld = output_valid_reg;
	assign o_str_user = output_user_reg;

endmodule

//--------------------------------------------------------------------------------------------------
// eof
//--------------------------------------------------------------------------------------------------

