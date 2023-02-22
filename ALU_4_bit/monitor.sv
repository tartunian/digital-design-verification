module Monitor(
	ref alu_output_number_t results[$],
	input alu_output_number_bus_t dut_result_bus,
	input logic capture_enable);

	always @(posedge capture_enable) begin
		results.push_back(dut_result_bus);
		$display(`DEBUG_FMT, "\tmonitor::", "dut_result", dut_result_bus);
	end

endmodule