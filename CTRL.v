`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
	// input opcode and funct
	input [5:0] opcode,
	input [5:0] funct,

	//
	// output various ports
	output reg RegDst,
	output reg Jump,
	output reg Branch,
	output reg JR,
	output reg MemRead,
	output reg MemtoReg,
	output reg MemWrite,
	output reg ALUSrc,
	output reg SignExtend,
	output reg RegWrite,
	output reg [3:0] ALUOp,
	output reg SavePC
    );

	always @(*) begin
		//ininitailize to 0
		RegDst = 0; Jump = 0; Branch = 0; MemRead = 0; MemtoReg = 0;
		MemWrite = 0; ALUSrc = 0; SignExtend = 0; RegWrite = 0;
		ALUOp = 4'b0000; SavePC = 0;
	//R-Type instruction
		case (opcode)
			6'b000000: begin
				//JR
				if (funct == FUNCT_JR) begin
					JR = 1;
				end
				else begin
					RegDst = 1;
					RegWrite = 1;
				end
				case (funct)
					FUNCT_ADDU: begin
						ALUOp = ALU_ADDU;
					end
					FUNCT_AND: begin
						ALUOp = ALU_AND;
					end
					FUNCT_NOR: begin
						ALUOp = ALU_NOR;
					end
					FUNCT_OR: begin
						ALUOp = ALU_OR;
					end
					FUNCT_SLT: begin
						ALUOp =  ALU_SLT;
					end
					FUNCT_SLTU: begin
						ALUOp = ALU_SLTU;
					end
					FUNCT_SUBU: begin
						ALUOp = ALU_SUBU;
					end
					FUNCT_XOR: begin
						ALUOp = ALU_XOR;
					end
					FUNCT_SLL: begin
						ALUOp = ALU_SLL;
					end
					FUNCT_SRA: begin
						ALUOp = ALU_SRA;
					end
					FUNCT_SRL: begin
						ALUOp = ALU_SRL;
					end
				endcase
				end
				endcase
		

		
	//I-Type instruction		
			OP_ADDIU: begin
				ALUSrc = 1; SignExtend = 1; RegWrite = 1; ALUOp = ALU_ADDU;
			end
			OP_ANDI: begin
				ALUSrc = 1; RegWrite = 1;  ALUOp = ALU_AND;
			end
			OP_ORI: begin
				ALUSrc = 1; RegWrite = 1; ALUOp = ALU_OR;
			end
			OP_XORI: begin
				ALUSrc = 1; RegWrite = 1; ALUOp = ALU_XOR;
			end
			OP_LUI: begin
				ALUSrc = 1; ALUOp = ALU_LUI;
			end
			
			OP_SLTI: begin
				ALUSrc = 1; ALUOp = ALU_SLT;
			end
			OP_SLTIU: begin
				ALUSrc = 1; ALUOp = ALU_SLTU;
			end
			OP_LW: begin
				MemtoReg = 1; ALUSrc = 1; ALUOp = ALU_ADD;
			end
			OP_SW: begin
				MemWrite = 1; ALUSrc = 1; ALUOp = ALU_ADD;
			end
			OP_BEQ: begin
				Branch = 1; ALUOp = ALU_SUBU;
			end
			OP_BNE: begin
				Branch = 1; ALUOp = ALU_SUBU;
			end

		//J-Type instruction
			OP_J: begin
				Jump = 1;
			end
			OP_JAL: begin
				Jump = 1; RegWrite = 1; SavePC = 1;
			end
			default: begin
				
			end

	end
endmodule
