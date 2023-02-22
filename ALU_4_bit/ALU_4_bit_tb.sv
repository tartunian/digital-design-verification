`define DEBUG_FMT	"%-16s%16s=%6d"

`define OPCODE_WIDTH	2
`define ALU_INPUT_NUM_WIDTH 4
`define ALU_OUTPUT_NUM_WIDTH 5

// `define ALU_INPUT_NUM_MAX 2**ALU_INPUT_NUM_WIDTH-1

typedef bit	[`OPCODE_WIDTH-1:0] opcode_t;
typedef bit signed [`ALU_INPUT_NUM_WIDTH-1:0] alu_input_number_t;
typedef bit signed [`ALU_OUTPUT_NUM_WIDTH-1:0] alu_output_number_t;

typedef logic [`OPCODE_WIDTH-1:0] opcode_bus_t;
typedef logic signed [`ALU_INPUT_NUM_WIDTH-1:0] alu_input_number_bus_t;
typedef logic signed [`ALU_OUTPUT_NUM_WIDTH-1:0] alu_output_number_bus_t;

opcode_t opcode_add = 2'b00;
opcode_t opcode_sub = 2'b01;
opcode_t opcode_not_a = 2'b10;
opcode_t opcode_reduc_or_b = 2'b11;


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



module Monitor(
	ref alu_output_number_t results[$],
	input alu_output_number_bus_t dut_result_bus,
	input logic capture_enable);

	always @(posedge capture_enable) begin
		results.push_back(dut_result_bus);
		$display(`DEBUG_FMT, "\tmonitor::", "dut_result", dut_result_bus);
	end

endmodule




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




module ALU_4_bit_tb
	();

	// Inputs
	logic					clk;
	logic					reset;
	opcode_bus_t			Opcode;
	alu_input_number_bus_t	A, B;					// 4-bit signed inputs to the ALU

	// Outputs
  	alu_output_number_bus_t	C;						// 5-bit signed output from the ALU

  	// Control signals
  	logic					capture_enable;			// On posedge, monitor and scoreboard will record
  													// the current result(s).

	// Random stimuli
	int 					a, b;					
	bit [1:0]				random_opcode;
	bit [1:0]				random_reset;

	// Counter for # of failures
	int						failures = 0;			// Counter for number of failures in checker output


	/*
	 *
	 * Clock
	 *
	 */
	always #5 clk = ~clk;

	/*
	 *
	 * Tasks
	 *
	 */

	// Tells the monitor and scoreboard to record the current result(s)
	task capture_result();
		begin
			capture_enable = 1'b1;
			#5;
			capture_enable = 1'b0;
			#5;
		end
	endtask : capture_result





	/* 
	 *
	 * Shared memory
	 *
	 */

	alu_output_number_t 	dut_results[$];			// Queue from monitor->checker
	alu_output_number_t 	true_results[$];		// Queue from scoreboard->checker
	string 					pass_fail_results[$];	// Queue with checker results


	/* 
	 *
	 * Module instantiation
	 * 
	 */

	// Instantiate the ALU driver
	Driver driver(
		.reset(reset),
		.opcode_bus(Opcode),
		.A(A),
		.B(B)
	);

	ALU_4_bit alu(
		.clk(clk),
		.reset(reset),
		.Opcode(Opcode),
		.A(A),
		.B(B),
		.C(C)
	);

	Monitor monitor(
		.results(dut_results),
		.dut_result_bus(C),
		.capture_enable(capture_enable)
	);

	Scoreboard scoreboard(
		.results(true_results),
		.A(A),
		.B(B),
		.opcode(Opcode),
		.reset(reset),
		.capture_enable(capture_enable)
	);

	Checker checker(
		.pass_fail_results(pass_fail_results),
		.true_results(true_results),
		.dut_results(dut_results),
		.clk(clk)
	);


	/*
	 *
	 * Procedure
	 *
	 */
	initial begin
		$vcdpluson;
		$dumpfile("ALU_4_bit_tb_dump.vcd");
		$dumpvars;

		capture_enable = 1'b0;
		clk = 1'b0;		

		// Run X random trials
		for(int i=0; i<10; i++) begin

			// Generate random stimuli
			a					= $urandom_range(15)-8;			// Random integer in range -8 to 7
			b					= $urandom_range(15)-8;			// Random integer in range -8 to 7
			random_opcode		= $urandom_range(3);			// Random integer in range 0 to 3
			random_reset		= $urandom_range(3);			// Random integer in range 0 to 3

			$display("Trial %4d", i);

			// Trigger reset approx. 25% of time
			case(random_reset)
				2'b00	: ;
				2'b01	: ;
				2'b10	: ;
				2'b11	: begin driver.EnableReset(); #10;	end
			endcase

			case(random_opcode)
				opcode_add			: driver.Add(a, b);
				opcode_sub			: driver.Sub(a, b);
				opcode_not_a		: driver.NotA(a);
				opcode_reduc_or_b	: driver.ReductionOrB(b);
			endcase

			// Wait for result to propogate and record it
			#10;
			capture_result();

			driver.DisableReset();
			#10;

			$display();

		end

		$display("DUT Results Size: ", dut_results.size());
		$display("True Results Size: ", true_results.size());
		$display("Pass/Fail Results: ", pass_fail_results);

		// Count the failures
		foreach(pass_fail_results[i]) begin
			if(pass_fail_results[i] == "Fail") begin
				failures++;
			end
		end

		$display("Total Failures: %d", failures);

		$finish;

	end

endmodule : ALU_4_bit_tb