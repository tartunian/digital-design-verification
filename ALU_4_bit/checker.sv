module Checker(
	ref string pass_fail_results[$],
	ref alu_output_number_t true_results[$],
	ref alu_output_number_t dut_results[$],
	input clk);

	// Whenever the monitor pushes a new result
	always @(dut_results.size()) begin

		// Wait for the true result from the Scoreboard
		// just in case
		wait(true_results.size() == dut_results.size());

		// Compare the two results and record pass or fail
		pass_fail_results.push_back(
			dut_results.pop_front()==true_results.pop_front() ? 
				"Pass" : "Fail");

	end

endmodule