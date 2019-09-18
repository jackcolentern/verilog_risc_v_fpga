module memory(
	input clk,
	output reg [31:0] data_out,         
	input [31:0] address,
	input [31:0] data_in,
	input write_enable
);

reg [31:0] memory [0:15];

integer i;
initial begin
//	memory[0] = 32'h202A23;
//	memory[1] = 32'h00508093;
//	memory[1] =  32'h1402083; //4
//	memory[3] =  32'habcd; //12
//	memory[4] =  32'habcd; //16
//	memory[5] =  32'h4321; //20

/*	memory[0] = 'h00000317;
	memory[1] = 'h00830067;
	memory[2] = 'h02000193;
	memory[3] = 'h00508093;
	memory[4] = 'h00000113;
	memory[5] = 'h00110113;
	memory[6] = 'hfe310ae3;
	memory[7] = 'hff9ff06f;*/

/*	memory[0] = 'h00000317;
	memory[1] = 'h00830067;
	memory[2] = 'h0c800193;
	memory[3] = 'h00000213;
	memory[4] = 'h003080b3;
	memory[5] = 'hfff18193;
	memory[6] = 'hfe419ce3;
	memory[7] = 'h0000006f;*/
	
	memory[0] = 'h00000317;
	memory[1] = 'h00830067;
	memory[2] = 'h0c800193;
	memory[3] = 'h01500213;
	memory[4] = 'h00018293;
	memory[5] = 'h00108093;
	memory[6] = 'h404282b3;
	memory[7] = 'hfe42dce3;
	memory[8] = 'h0000006f;



end

always @(negedge clk) begin
	if (write_enable == 1'b1) begin
		memory[address] <= data_in;
	end
	data_out <= memory[address];
end

endmodule