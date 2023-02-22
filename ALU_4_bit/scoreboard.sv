module Scoreboard(
	ref alu_output_number_t results[$],
	input alu_input_number_bus_t A, B,
	input opcode_bus_t opcode,
	input logic reset,
	input logic capture_enable);

	alu_output_number_t res;

	always @(posedge capture_enable) begin
		if(reset) begin
			res = 0;
		end else if(opcode == opcode_add) begin
			res = A + B;
		end else if(opcode == opcode_sub) begin
			res = A - B;
		end else if(opcode == opcode_not_a) begin
			res = ~A;
		end else if(opcode == opcode_reduc_or_b) begin
			res = |B;
		end
		results.push_back(res);
		$display(`DEBUG_FMT, "\tscoreboard::", "true_result", res);
		
	end

endmodule