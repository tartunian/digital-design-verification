`default_nettype none

module my_mem(
  input var logic clk,
  input var logic write,
  input var logic read,
  input var logic [7:0] data_in,
  input var logic [15:0] address,
  output logic [8:0] data_out
);
  
  // Declare a 9-bit associative array using the logic data type
  logic [8:0] mem_array[logic [15:0]];
  
  always @(posedge clk) begin
    if (write)
      mem_array[address] = {^data_in, data_in};
    else if (read)
      data_out =  mem_array[address];
  end

endmodule