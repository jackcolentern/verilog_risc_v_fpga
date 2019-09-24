
module clock_gen(
	input clk,
	input button,
	output clk_out
);
reg[24:0]cnt;

reg button_prev;
	
reg button_debounced; 

assign clk_out = button_debounced;

always @(posedge clk) begin

	if(button_prev != button) begin
		cnt <= cnt + 1'b1;
		if (cnt == 24'h0ffff) begin
			button_debounced <= ~button_debounced;
			button_prev <= button;
		end
		else;
	end
	else cnt <= 24'h000000;
end

endmodule