module alu(
	output[31:0] aluout,
	input[31:0] in1,
	input[31:0] in2,
	input[2:0] mode
);

reg[31:0]out;

assign aluout = out;

always @(*) begin
	case (mode)
		3'b001: out <= in1 + in2;
		3'b010: out <= in1 ^ in2;
		3'b011: out <= in1 | in2;
		3'b100: out <= in1 & in2;
		3'b101: out <= in1 - in2;


		default: out <= 32'b0;
	endcase
end

endmodule