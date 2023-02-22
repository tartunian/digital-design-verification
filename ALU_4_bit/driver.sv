module Driver
	(
	output opcode_bus_t opcode_bus,
	output logic reset,
	output alu_input_number_bus_t A, B);

	function Add(integer a, integer b);
		A <= a;
		B <= b;
		opcode_bus <= opcode_add;
		$display("driver::Add(%4d,%4d)", a, b);
	endfunction

	function Sub(int a, int b);
		A <= a;
		B <= b;
		opcode_bus <= opcode_sub;
		$display("driver::Sub(%4d,%4d)", a, b);
	endfunction

	function NotA(int a);
		A <= a;
		opcode_bus <= opcode_not_a;
		$display("driver::NotA(%4d)", a);
	endfunction

	function ReductionOrB(int b);
		B <= b;
		opcode_bus <= opcode_reduc_or_b;
		$display("driver::ReductionOrB(%4d)", b);
	endfunction

	function EnableReset();
		reset <= 1'b1;
		$display("driver::EnableReset");
	endfunction

	function DisableReset();
		reset <= 1'b0;
		$display("driver::DisableReset");
	endfunction

endmodule