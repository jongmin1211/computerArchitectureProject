`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
	input  [5:0] opcode,
	input  [5:0] funct,
	input        PCSrc,

	output reg [2:0] WB,
	output reg [2:0] MEM,
	output reg [5:0] EX,

	output reg Jump,
	output reg JR,
	output reg SignExtend
);

	reg       RegDst;
	reg       Branch;
	reg       SavePC;
	reg       MemRead;
	reg       MemtoReg;
	reg       MemWrite;
	reg       ALUSrc;
	reg       RegWrite;
	reg [3:0] ALUOp;

	always @(*) begin
		RegDst     = 0;
		Jump       = 0;
		Branch     = 0;
		MemRead    = 0;
		MemtoReg   = 1;
		MemWrite   = 0;
		ALUSrc     = 0;
		SignExtend = 0;
		RegWrite   = 0;
		ALUOp      = 4'b0000;
		SavePC     = 0;
		JR         = 0;

		case (opcode)
			// R-Type
			`OP_RTYPE: begin
				if (funct == `FUNCT_JR) begin
					JR = 1;
				end else begin
					RegDst   = 1;
					RegWrite = 1;
				end
				case (funct)
					`FUNCT_ADDU: ALUOp = `ALU_ADDU;
					`FUNCT_AND:  ALUOp = `ALU_AND;
					`FUNCT_NOR:  ALUOp = `ALU_NOR;
					`FUNCT_OR:   ALUOp = `ALU_OR;
					`FUNCT_SLT:  ALUOp = `ALU_SLT;
					`FUNCT_SLTU: ALUOp = `ALU_SLTU;
					`FUNCT_SUBU: ALUOp = `ALU_SUBU;
					`FUNCT_XOR:  ALUOp = `ALU_XOR;
					`FUNCT_SLL:  ALUOp = `ALU_SLL;
					`FUNCT_SRA:  ALUOp = `ALU_SRA;
					`FUNCT_SRL:  ALUOp = `ALU_SRL;
				endcase
			end

			// I-Type
			`OP_ADDIU: begin ALUSrc = 1; SignExtend = 1; RegWrite = 1;               ALUOp = `ALU_ADDU; end
			`OP_ANDI:  begin ALUSrc = 1;                 RegWrite = 1;               ALUOp = `ALU_AND;  end
			`OP_ORI:   begin ALUSrc = 1;                 RegWrite = 1;               ALUOp = `ALU_OR;   end
			`OP_XORI:  begin ALUSrc = 1;                 RegWrite = 1;               ALUOp = `ALU_XOR;  end
			`OP_LUI:   begin ALUSrc = 1;                 RegWrite = 1;               ALUOp = `ALU_LUI;  end
			`OP_SLTI:  begin ALUSrc = 1; SignExtend = 1; RegWrite = 1;               ALUOp = `ALU_SLT;  end
			`OP_SLTIU: begin ALUSrc = 1; SignExtend = 1; RegWrite = 1;               ALUOp = `ALU_SLTU; end
			`OP_LW:    begin ALUSrc = 1; SignExtend = 1; RegWrite = 1; MemRead = 1; MemtoReg = 0; ALUOp = `ALU_ADDU; end
			`OP_SW:    begin ALUSrc = 1; SignExtend = 1; MemWrite = 1;               ALUOp = `ALU_ADDU; end
			`OP_BEQ:   begin SignExtend = 1; Branch = 1; ALUOp = `ALU_EQ;  end
			`OP_BNE:   begin SignExtend = 1; Branch = 1; ALUOp = `ALU_NEQ; end

			// J-Type
			`OP_J:   begin Jump = 1;                            end
			`OP_JAL: begin Jump = 1; RegWrite = 1; SavePC = 1; end

			default: begin end
		endcase

		if (PCSrc) begin
			RegWrite = 0;
			MemWrite = 0;
		end

		EX  = {ALUOp, ALUSrc, RegDst};
		MEM = {Branch, MemRead, MemWrite};
		WB  = {SavePC, RegWrite, MemtoReg};
	end

endmodule
