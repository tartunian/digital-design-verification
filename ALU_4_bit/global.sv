`ifndef GLOBAL_SV_
`define GLOBAL_SV_

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

`endif