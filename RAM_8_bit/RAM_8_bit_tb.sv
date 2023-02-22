
package ram_types;
	typedef logic [7:0] ram_data_in_t;
	typedef logic [15:0] ram_address_t;
	typedef logic [8:0] ram_data_out_t;

	const ram_data_in_t RAM_DATAIN_ALLBITS = 8'hff;
	const ram_address_t RAM_ADDRESS_ALLBITS = 16'hffff;

endpackage


module RAM_8_bit_tb
	import ram_types::*;
	();


	logic clk, write, read;
	ram_data_in_t	data_in;
	ram_address_t	address;
	ram_data_out_t	data_out;


	my_mem mem (
		.clk     	(clk),
		.write   	(write),
		.read    	(read),
		.data_in 	(data_in),
		.address 	(address),
		.data_out 	(data_out)
	);

	const int N_TRIALS = 6;
	
	/*
	 * Create a dynamic array of 6 random addresses to write called address_array.
	 */
	ram_address_t address_array[] = { 
		$urandom() & RAM_ADDRESS_ALLBITS,
		$urandom() & RAM_ADDRESS_ALLBITS,
		$urandom() & RAM_ADDRESS_ALLBITS,
		$urandom() & RAM_ADDRESS_ALLBITS,
		$urandom() & RAM_ADDRESS_ALLBITS,
		$urandom() & RAM_ADDRESS_ALLBITS
	};

	/*
	 * Create a dynamic array of 6 random bytes to write called data_to_write_array.
	 */
	ram_data_in_t data_to_write_array[] = {
		$urandom() & RAM_DATAIN_ALLBITS,
		$urandom() & RAM_DATAIN_ALLBITS,
		$urandom() & RAM_DATAIN_ALLBITS,
		$urandom() & RAM_DATAIN_ALLBITS,
		$urandom() & RAM_DATAIN_ALLBITS,
		$urandom() & RAM_DATAIN_ALLBITS
	};


	/* 
	 * Create an associative array of data expected to be read, indexed by the address 
	 * read from address_array and called data_read_expect_assoc.
	 */
	ram_data_in_t data_read_expect_assoc [ram_address_t];

	/*
	 * Create a queue of data read called data_read_queue.
	 */
	ram_data_out_t data_read_queue[$];


	/*
	 * Driver Task
	 * This task reads a from a single address in the RAM
	 */ 
	task ramRead(input ram_address_t raddress);
		read <= 1'b1;
		write <= 1'b0;
		address <= raddress;
		#10;
		read <= 1'b0;
		$display("driver::ramRead\t\taddress=0x%04h data=0x%04h", raddress, data_out);
	endtask : ramRead



	/*
	 * Driver Task
	 * This task writes to a single address in the RAM
	 */ 
	task ramWrite(input ram_address_t waddress, input ram_data_in_t data);
		read <= 1'b0;
		write <= 1'b1;
		address <= waddress;
		data_in <= data;
		#10;
		write <= 1'b0;
		$display("driver::ramWrite\taddress=0x%04h data=0x%04h", waddress, data);
	endtask : ramWrite

	/* 
	 *
	 * This task reads the RAM and then pushes the output value into the data_read_queue queue.
	 *
	 */
	task ramReadToQueue(input ram_address_t raddress);
		ramRead( .raddress(raddress) );
		data_read_queue.push_front( data_out );
	endtask : ramReadToQueue

	/* 
	 *
	 * This task writes a value to the RAM and records the address/value pair into the data_read_expect_assoc associate array.
	 *
	 */
	task ramWriteAndRecord(input ram_address_t waddress, input ram_data_in_t data);
		ramWrite( .waddress(waddress), .data(data) );
		data_read_expect_assoc[waddress] = data;
	endtask : ramWriteAndRecord


	/*
	 *
	 * This task verifies that the written values match the ones read out.
	 *
	 */
	task ramCheckData(input int trialnum, output error);	 	
		automatic ram_data_in_t read_data = data_read_queue[trialnum] & 8'hff;								// Get the 9-bit value read from the RAM and mask to 8-bit
		var automatic read_cks = (data_read_queue[trialnum] & 9'h100) >> 8;									// Get the checksum bit (9th bit)
		automatic ram_data_in_t expected_data = data_read_expect_assoc[address_array[trialnum]];			// Get the 8-bit value that was written
		var automatic expected_cks = ^expected_data;														// Compute the checksum of the written value
		var automatic data_ok = read_data == expected_data;													// Compare the written and read data
		var automatic cks_ok = read_cks == expected_cks;													// Compare the two checksums
		error = ~(data_ok & cks_ok);																		// Record an error if data or checksums do not match
		$display("%2d) Data Read: 0x%h, Data Expected: 0x%h, CKS Read: %1d, CKS Expected: %1d, Error: %s",
			trialnum, read_data, expected_data, read_cks, expected_cks, error ? "Yes" : "No");
	endtask : ramCheckData



	initial begin
		write <= 1'b0;
		read <= 1'b0;
		clk = 1'b0;
	end

	always #5 clk = ~clk;

	var error;
	int error_count;

	initial begin

		$vcdpluson;
		$dumpfile("RAM_8_bit_tb_dump.vcd");
		$dumpvars;

		/*
		 * Perform 6 writes of random data to random addresses...
		 */
		for(int i=0; i<N_TRIALS; i++) begin
			ramWriteAndRecord( .waddress(address_array[i]), .data(data_to_write_array[i]) );
		end

		/*
		 * ...followed by 6 reads to the same 
		 * addresses in reverse order.
		 */
		 
		for(int i=N_TRIALS-1; i>=0; i--) begin
			ramReadToQueue( .raddress(address_array[i]) );
		end


		/* 
		 * At the end, traverse the data_read_queue, print out the data read, 
		 * and print out the error counter.
		 */

		for(int i=0; i<data_read_queue.size(); i++) begin
			ramCheckData( .trialnum(i), .error(error) );
			error_count += error;
		end

		$display("Total Errors: %d/%-d (%3d%%)", error_count, N_TRIALS, error_count/N_TRIALS*100);

		$finish;

	end


endmodule : RAM_8_bit_tb