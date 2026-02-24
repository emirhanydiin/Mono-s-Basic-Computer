module memory_unit (
    input	clk,we,   
    input[11:0]	address,
    input[15:0]	write_data,
	output reg [15:0]	read_data 
);
	reg [15:0] memory [0:4095];
	//Read the instructions (and data) into memory
	initial begin
		$readmemh("memory_content.hex", memory);
	end
	//Write on positive edge
    always @(posedge clk) begin
        if (we) begin
			memory[address] <= write_data;
		end
	end
	//combinational read
	always @(*) begin
        read_data = memory[address];
	end
endmodule