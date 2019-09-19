module cpu(
	input clk,
	output[7:0] segments,
	output[3:0] digits,
	output[3:0]	 LED,
	input switch_3,
	input switch_4,
	input button
);

wire[15:0] to_seven_segment;
assign to_seven_segment = real_reg_x[1];
//assign inst_debug = inst;
//assign load_debug = load;
//assign pc_debug = reg_pc;

memory mem(
	.clk(clk_main),
	.data_out(data_out),         
	.address(to_memaddress),
	.data_in(data_in),
	.write_enable(store)
);

seven_segment ss(
	.clk(clk),
	.data(to_seven_segment),
	.segments(segments),
	.digits(digits)
);	

alu a(
	.aluout(aluout),
	.in1(aluin1),
	.in2(aluin2),
	.mode(alumode)
);

clock_gen cg(
	.clk(clk),
	.button(button),
	.clk_out(clk_step)
);

wire clk_step;

wire clk_main;

assign clk_main = (~switch_4)?cnt[0]:(~switch_3)?cnt[20]:clk_step;

wire [31:0] aluout;
reg [31:0] aluin1;
reg [31:0] aluin2;
reg [2:0] alumode;

reg[31:0] address;
wire[31:0] data_out;
reg[31:0] data_in;

reg[31:0] real_reg_x[0:31];
reg[31:0] reg_x[0:31];

reg[31:0] reg_pc;

wire[31:0] inst;
reg[31:0] inst_old;

assign inst = (load||store)?inst_old:data_out;

integer j;
always @(reg_x)begin
	for(j=1;j<32;j=j+1) real_reg_x[j] <= reg_x[j];

end

wire[6:0] opcode;
wire[2:0] funct3;
wire[6:0] funct7;
wire[4:0] rd;
wire[4:0] rs1;
wire[4:0] rs2;

wire[11:0] imm_i;
wire[11:0] imm_s;
wire[11:0] imm_b;
wire[19:0] imm_u;
wire[19:0] imm_j;

wire[31:0] simm_i;
wire[31:0] simm_s;
wire[31:0] simm_b;
wire[31:0] simm_u;
wire[31:0] simm_j;

wire[31:0] to_memaddress;

reg load;

reg store;

reg alu;

assign to_memaddress = (load || store)?address:(reg_pc>>2);

parameter lui = 7'b0110111;
parameter auipc = 7'b0010111;
parameter jal = 7'b1101111;
parameter jalr = 7'b1100111;
parameter b = 7'b1100011;
parameter l = 7'b0000011;
parameter s = 7'b0100011;
parameter i_type = 7'b0010011;
parameter r_type = 7'b0110011;

assign opcode = inst[6:0];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];
assign rd = inst[11:7];
assign rs1 = inst[19:15];
assign rs2 = inst[24:20];

assign imm_i = inst[31:20];
assign imm_s = {inst[31:25],inst[11:7]};
assign imm_b = {inst[31],inst[7],inst[30:25],inst[11:8]};
assign imm_u = inst[31:12];
assign imm_j = {inst[31],inst[19:12],inst[20],inst[30:21]};

assign simm_i = {{20{imm_i[11]}},imm_i};
assign simm_s = {{20{imm_s[11]}},imm_s};
assign simm_b = {{19{imm_b[11]}},imm_b,1'b0};
assign simm_j = {{11{imm_j[19]}},imm_j,1'b0};

wire[7:0] load_ff = data_out & 8'hff;
wire[15:0] load_ffff = data_out& 16'hffff;

reg[31:0] cnt;

always @(posedge clk)begin
	cnt<= cnt+1;
end

reg test;

integer i;
initial begin
	for(i=0;i<32;i=i+1)reg_x[i]=0;	
	test <= 1'b0;
end


always @(posedge clk_main)begin
	if(load == 1'b1)begin
		load <= 1'b0;
		reg_pc <= reg_pc + 4;
		case(funct3)
			3'b000:begin //lb
				reg_x[rd] <= {{24{load_ff[7]}},load_ff}; 
			end
			
			3'b001:begin //lh
				reg_x[rd] <= {{16{load_ffff[15] }},load_ffff}; 
			end
			
			3'b010:begin //lw
				reg_x[rd] <= data_out; 
			end
			
			3'b100:begin //lbu
				reg_x[rd] <= data_out & 16'hff; 
			end
			default:;
		endcase
	end
	else if(store == 1'b1)begin
		store <= 1'b0;
		reg_pc <= reg_pc + 4;
	end
	else if(alu == 1'b1)begin
		alu <= 1'b0;
		reg_x[rd] <= aluout;
		reg_pc <= reg_pc + 4;		
	end
	else begin
		case(opcode)
		
			lui: begin
				reg_x[rd] <= {imm_u<<12,12'b0};
				reg_pc <= reg_pc + 4;
			end
			
			auipc: begin
				reg_x[rd] <= reg_pc + {imm_u<<12,12'b0};
				reg_pc <= reg_pc + 4;
			end
			
			jal: begin
				reg_x[rd] <= reg_pc + 4;
				reg_pc <= reg_pc + simm_j;
			end
		
			jalr: begin
				reg_x[rd] <= reg_pc + 4;
				reg_pc <= (reg_x[rs1] + simm_i) & 32'hfffffffe;
			end
			
			b: begin
				case(funct3)
					3'b000:begin //beq
						if(real_reg_x[rs1] == real_reg_x[rs2])reg_pc <= reg_pc + simm_b;
						else reg_pc <= reg_pc + 4;
					end
					
					3'b001:begin //bne
						if(real_reg_x[rs1] != real_reg_x[rs2]) reg_pc <= reg_pc + simm_b;
						else reg_pc <= reg_pc + 4;
					end	

					3'b100:begin //blt
						if($signed(real_reg_x[rs1]) < $signed(real_reg_x[rs2])) reg_pc <= reg_pc + simm_b;
						else reg_pc <= reg_pc + 4;
					end	

					3'b101:begin //bge
						if($signed(real_reg_x[rs1]) >= $signed(real_reg_x[rs2])) reg_pc <= reg_pc + simm_b;
						else reg_pc <= reg_pc + 4;
					end	
					
					3'b110:begin //bltu
						if(real_reg_x[rs1] < real_reg_x[rs2]) reg_pc <= reg_pc + simm_b;
						else reg_pc <= reg_pc + 4;
					end	

					3'b111:begin //bgeu
						if(real_reg_x[rs1] >= real_reg_x[rs2]) reg_pc <= reg_pc + simm_b;
						else reg_pc <= reg_pc + 4;
					end
					
					default:;
				endcase
			end 
			
			l: begin	
				load <= 1'b1;
				inst_old <= inst;
				address <= real_reg_x[rs1] + simm_i;
			end
			
			s: begin	
				store <= 1'b1;
				inst_old <= inst;
				address <= real_reg_x[rs1] + simm_s;
				case(funct3)
					3'b000:begin //sb
						data_in <= real_reg_x[rs2] & 'hff; 
					end
					
					3'b001:begin //sh
						data_in <= real_reg_x[rs2] & 'hffff; 
					end
					
					3'b010:begin //sw
						data_in <= real_reg_x[rs2]; 
					end
					default:;
				endcase
			end
			
			i_type: begin
				aluin1 <=  real_reg_x[rs1];
				aluin2 <= simm_i;
				case(funct3)
					3'b000:begin //addi
						alu <= 1'b1;
						alumode <= 3'b001;
					end
					3'b010:begin //slti
						reg_x[rd] <= ($signed(real_reg_x[rs1]) < $signed(simm_i))?32'b1:32'b0; 
						reg_pc <= reg_pc + 4;
					end
					3'b011:begin //sltiu
						reg_x[rd] <= (real_reg_x[rs1] < simm_i)?32'b1:32'b0; 
						reg_pc <= reg_pc + 4;
					end
					3'b100:begin //xori
						alu <= 1'b1;
						alumode <= 3'b010;
					end
					3'b110:begin //ori
						alu <= 1'b1;
						alumode <= 3'b011;
					end		
					3'b111:begin //andi
						alu <= 1'b1;
						alumode <= 3'b100;
					end
					3'b001:begin //slli
						if(funct7 == 7'b0000000) reg_x[rd] <= real_reg_x[rs1] << imm_i[4:0] ;
						else;
						reg_pc <= reg_pc + 4;
					end
					3'b101:begin //srli / srai
						if(funct7 == 7'b0000000) reg_x[rd] <= real_reg_x[rs1] >> imm_i[4:0] ; //srli
						else if(funct7 == 7'b0100000) reg_x[rd] <= real_reg_x[rs1] >>> imm_i[4:0] ; //srai
						else;
						reg_pc <= reg_pc + 4;
					end
	
					default:;
				endcase			
			end
			
			r_type: begin
				aluin1 <= real_reg_x[rs1];
				aluin2 <= real_reg_x[rs2];
				case(funct3)
					3'b000:begin //add / sub
						if(funct7 == 7'b0000000) alumode <= 3'b001;//add
						else if(funct7 == 7'b0100000) alumode <= 3'b101;//sub
						else;
						alu <= 1'b1;
					end
					3'b001:begin //sll
						if(funct7 == 7'b0000000) reg_x[rd]<=real_reg_x[rs1] << real_reg_x[rs2];
						else;
						reg_pc <= reg_pc + 4;
					end
					3'b010:begin //slt
						if(funct7 == 7'b0000000) reg_x[rd]<=($signed(real_reg_x[rs1]) < $signed(real_reg_x[rs2]))?32'b1:32'b0;
						else;
						reg_pc <= reg_pc + 4;
					end
					3'b011:begin //sltu
						if(funct7 == 7'b0000000) reg_x[rd]<=(real_reg_x[rs1] < real_reg_x[rs2])?32'b1:32'b0;
						else;
						reg_pc <= reg_pc + 4;

					end
					3'b100:begin //xor
						if(funct7 == 7'b0000000) alumode <= 3'b001;
						else;
						alu <= 1'b1;
					end
					3'b101:begin //srl / sra
						if(funct7 == 7'b0000000) reg_x[rd]<=real_reg_x[rs1] >> real_reg_x[rs2]; //srl
						else if(funct7 == 7'b0100000) reg_x[rd]<=real_reg_x[rs1] >>> real_reg_x[rs2]; //sra
						else;
						reg_pc <= reg_pc + 4;
					end
					3'b110:begin //or
						if(funct7 == 7'b0000000) alumode <= 3'b011;
						else;
						alu <= 1'b1;
					end
					3'b111:begin //and
						if(funct7 == 7'b0000000) alumode <= 3'b100;
						else;
						alu <= 1'b1;
					end
				
					default:;
				endcase
			end
			default: ;//reg_pc <= reg_pc + 4;
		endcase
	end
end


assign LED = ~(reg_pc >> 2);
endmodule