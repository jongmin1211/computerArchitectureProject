`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
	// input opcode and funct
	input rst,
	input clk,
	input [5:0] opcode,
	input [5:0] funct,

	// output various ports
	output reg [1:0]	PCSource,
	output reg [3:0] 	ALUOp,
	output reg [2:0] 	ALUSrcB,
	output reg 			ALUSrcA,
	output reg 			RegWrite,
	output reg [1:0]	RegDst,


	output reg PCWriteCond,
	output reg PCWrite,
	output reg IorD,
	output reg MemRead,
	output reg MemWrite,
	output reg MemtoReg,
	output reg IRWrite,

	output reg SignExtend,

	//for multicycle
	output reg 			InstDone
    );


	reg [2:0] state;
	reg [2:0] state_next;

	//clk마다 state 바꾸기
	always @(posedge clk) begin
		if (rst) state <= `IF;
		else state <= state_next;
	end

	always @(*) begin
		//ininitailize to 0
		PCSource = 2'b00; ALUOp = 4'b0000; ALUSrcB = 2'b00;
		ALUSrcA = 0; RegWrite = 0; RegDst = 0;
		PCWriteCond = 0; PCWrite = 0; IorD = 0;
		MemRead = 0; MemWrite = 0; MemtoReg = 0;
		IRWrite = 0; SignExtend = 1; InstDone = 0;
		state_next = state;

		case (state)
		//Instruction Fetch
			`IF: begin
				state_next = `ID;
				IorD = 0; MemRead = 1; IRWrite = 1;
				ALUSrcA = 0; ALUSrcB = 2'b01; ALUOp = `ALU_ADDU;
        		PCSource = 2'b00; PCWrite = 1;    
			end
		
		//Instruction Decode
			`ID: begin
			//R-Type instruction
				case (opcode)
					`OP_RTYPE: begin
						//JR
						if (funct == `FUNCT_JR) begin
							state_next = `EX;
						end
						//else Rtype
						else begin
							RegDst = 1;
							state_next = `EX;
						end
						end
						
			//I-Type instruction		
					`OP_ADDIU: begin
						state_next = `EX;
					end
					`OP_ANDI: begin
						state_next = `EX;
					end
					`OP_ORI: begin
						state_next = `EX;
					end
					`OP_XORI: begin
						state_next = `EX;
					end
					`OP_LUI: begin
						state_next = `EX;
					end
					
					`OP_SLTI: begin
						state_next = `EX;
					end
					`OP_SLTIU: begin
						state_next = `EX;
					end
					`OP_LW: begin
						state_next = `EX;
					end
					`OP_SW: begin
						state_next = `EX;
					end
					`OP_BEQ: begin
						state_next = `EX;
						ALUSrcA = 0; ALUSrcB = 2'b11; ALUOp = `ALU_ADDU;
					end
					`OP_BNE: begin
						state_next = `EX;
						ALUSrcA = 0; ALUSrcB = 2'b11; ALUOp = `ALU_ADDU;
					end

			//J-Type instruction
					`OP_J: begin
						state_next = `IF;
						PCWrite = 1; PCSource = 2'b10;
					end
					`OP_JAL: begin
						state_next = `WB;
						PCWrite = 1; PCSource = 2'b10; 
						ALUSrcA = 0; ALUSrcB = 3'b100; ALUOp = `ALU_ADDU;
					end
					default: begin
						
					end
				endcase
			end

		//Execution
			`EX: begin
				//R-Type instruction
				case (opcode)
					`OP_RTYPE: begin
						//JR
						if (funct == `FUNCT_JR) begin
							state_next = `IF;
							PCSource = 2'b11; PCWrite = 1; 
						end
						else begin 
							state_next = `WB;
							ALUSrcA = 1; ALUSrcB = 2'b00;
						end
						case (funct)
							`FUNCT_ADDU: 		ALUOp = `ALU_ADDU;
							`FUNCT_AND: 		ALUOp = `ALU_AND;
							`FUNCT_NOR: 		ALUOp = `ALU_NOR;
							`FUNCT_OR: 			ALUOp = `ALU_OR;
							`FUNCT_SLT: 		ALUOp = `ALU_SLT;
							`FUNCT_SLTU: 		ALUOp = `ALU_SLTU;
							`FUNCT_SUBU: 		ALUOp = `ALU_SUBU;
							`FUNCT_XOR: 		ALUOp = `ALU_XOR;
							`FUNCT_SLL: 		ALUOp = `ALU_SLL;
							`FUNCT_SRA: 		ALUOp = `ALU_SRA;
							`FUNCT_SRL: 		ALUOp = `ALU_SRL;
						endcase
						end
						
			//I-Type instruction		
					`OP_ADDIU: begin
						state_next = `WB;
						ALUSrcA = 1; ALUSrcB = 2'b10; ALUOp = `ALU_ADDU;
					end
					`OP_ANDI: begin
						state_next = `WB;
						SignExtend = 0; ALUSrcA = 1; ALUSrcB = 2'b10;  ALUOp = `ALU_AND;
					end
					`OP_ORI: begin
						state_next = `WB;
						SignExtend = 0; ALUSrcA = 1; ALUSrcB = 2'b10; ALUOp = `ALU_OR;
					end
					`OP_XORI: begin
						state_next = `WB;
						SignExtend = 0; ALUSrcA = 1; ALUSrcB = 2'b10; ALUOp = `ALU_XOR;
					end
					`OP_LUI: begin
						state_next = `WB;
						SignExtend = 0; ALUSrcA = 1; ALUSrcB = 2'b10; ALUOp = `ALU_LUI;
					end
					
					`OP_SLTI: begin
						state_next = `WB;
						ALUSrcA = 1; ALUSrcB = 2'b10; ALUOp = `ALU_SLT;
					end
					`OP_SLTIU: begin
						state_next = `WB;
						ALUSrcA = 1; ALUSrcB = 2'b10; ALUOp = `ALU_SLTU;
					end
					`OP_LW: begin
						state_next = `MEM;
						SignExtend = 1; ALUSrcA = 1; ALUSrcB = 2'b10; ALUOp = `ALU_ADDU;
					end
					`OP_SW: begin
						state_next = `MEM;
						SignExtend = 1; ALUSrcA = 1; ALUSrcB = 2'b10; ALUOp = `ALU_ADDU;
					end
					`OP_BEQ: begin
						state_next = `IF;
						ALUSrcA = 1; ALUSrcB = 2'b00; ALUOp = `ALU_EQ;
						PCWriteCond = 1; PCSource = 2'b01;
					end
					`OP_BNE: begin
						state_next = `IF;
						ALUSrcA = 1; ALUSrcB = 2'b00; ALUOp = `ALU_NEQ;
						PCWriteCond = 1; PCSource = 2'b01;
					end
				endcase
			end

		//Memory
			`MEM: begin
				case (opcode)	
			//I-Type instruction		
					`OP_LW: begin
						state_next = `WB;
						IorD = 1; MemRead = 1;
					end
					`OP_SW: begin
						state_next = `IF;
						IorD = 1; MemWrite = 1;
					end
				endcase
			end

		//Write Back
			`WB: begin
				//R-Type instruction except JR
				case (opcode)
					`OP_RTYPE: begin
						state_next = `IF;
						RegDst = 2'b01;
						MemtoReg = 0;
						RegWrite = 1;
						end
						
			//I-Type instruction		
					`OP_ADDIU: begin
						state_next = `IF;
						RegWrite = 1; MemtoReg = 0;
					end
					`OP_ANDI: begin
						state_next = `IF;
						RegWrite = 1; MemtoReg = 0;
					end
					`OP_ORI: begin
						state_next = `IF;
						RegWrite = 1; MemtoReg = 0;
					end
					`OP_XORI: begin
						state_next = `IF;
						RegWrite = 1; MemtoReg = 0;
					end
					`OP_LUI: begin
						state_next = `IF;
						RegWrite = 1; MemtoReg = 0;
					end
					
					`OP_SLTI: begin
						state_next = `IF;
						RegWrite = 1; MemtoReg = 0;
					end
					`OP_SLTIU: begin
						state_next = `IF;
						RegWrite = 1; MemtoReg = 0;
					end
					`OP_LW: begin
						state_next = `IF;
						RegWrite = 1; MemtoReg = 1; RegDst = 2'b00;
					end
			//J-Type instruction
					`OP_JAL: begin
						state_next = `IF;
						RegWrite = 1; RegDst = 2'b10; MemtoReg = 0;
					end
					default: begin
						
					end
				endcase
			end
		endcase


		
	end
endmodule
