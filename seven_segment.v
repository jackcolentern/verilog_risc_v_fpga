
module seven_segment(
	input  clk,
	input wire[15:0]data,
	output[7:0] segments,
	output[3:0] digits
);	

reg[7:0] reg_segments;
reg[3:0] reg_digits;
reg[3:0] num;
reg[31:0] cnt;

initial begin
	reg_segments <= 8'b00000000;
	reg_digits <= 4'b1110;
end


always @(posedge clk) begin

	cnt = cnt + 1'b1;
	
end

always @(posedge cnt[16]) begin//16

	reg_digits <= {reg_digits[0],reg_digits[3:1]};
	
	if(reg_digits == 4'b1110) num <= data[7:4];
	if(reg_digits == 4'b1101) num <= data[3:0];
	if(reg_digits == 4'b1011) num <= data[15:12];
	if(reg_digits == 4'b0111) num <= data[11:8];
	
	case(num)
		4'b0000: reg_segments <= 8'b00000011; // "0"  
		4'b0001: reg_segments <= 8'b10011111; // "1" 
		4'b0010: reg_segments <= 8'b00100101; // "2" 
		4'b0011: reg_segments <= 8'b00001101; // "3" 
		4'b0100: reg_segments <= 8'b10011001; // "4" 
		4'b0101: reg_segments <= 8'b01001001; // "5" 
		4'b0110: reg_segments <= 8'b01000001; // "6" 
		4'b0111: reg_segments <= 8'b00011111; // "7" 
		4'b1000: reg_segments <= 8'b00000001; // "8"  
		4'b1001: reg_segments <= 8'b00011001; // "9" 
		4'b1010: reg_segments <= 8'b00010001;
		4'b1011: reg_segments <= 8'b11000001;
		4'b1100: reg_segments <= 8'b01100011;
		4'b1101: reg_segments <= 8'b10000101;
		4'b1110: reg_segments <= 8'b01100001;
		4'b1111: reg_segments <= 8'b01110001;
		default: reg_segments <= 8'b11111111; // off

	endcase

end


assign segments = reg_segments;
assign digits = reg_digits;
endmodule