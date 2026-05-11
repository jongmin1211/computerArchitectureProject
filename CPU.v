`timescale 1ns / 1ps


module CPU(
	input		clk,
	input		rst,
	output 		halt
	);
	
	// Split the instructions
	// Instruction-related
	reg [31:0]		IR;

	wire [5:0]		opcode;
	wire [4:0]		rs;
	wire [4:0]		rt;
	wire [4:0]		rd;
	wire [4:0]		shamt;
	wire [5:0]		funct;
	wire [15:0]		immi;
	wire [25:0]		immj;

	// Control-related wires
	wire [1:0]		PCSource;
	wire [3:0]		ALUOp;
	wire [2:0]		ALUSrcB;
	wire 			ALUSrcA;
	wire      		RegWrite;
	wire [1:0]		RegDst;
	wire			PCWriteCond;
	wire 			PCWrite;
	wire            IorD;
	wire 			MemRead;
	wire 			MemWrite;
	wire 			MemtoReg;
	wire 			IRWrite;
	wire 			InstDone;
	wire 			SignExtend;

	// Sign extend the immediate
	wire [31:0]		ext_imm;

	// RF-related wires
	wire [4:0]		rd_addr1;
	wire [4:0]		rd_addr2;
	wire [31:0]		rd_data1;
	wire [31:0]		rd_data2;
	wire [31:0]		AWire;
	wire [31:0]		BWire;
	wire [4:0]		wr_addr;
	wire [31:0]		wr_data;

	//A,B reg
	reg [31:0] 		A;
	reg [31:0] 		B;

	// MEM-related wires
	wire [31:0]		mem_addr;
	wire [31:0]		mem_write_data;
	wire [31:0]		mem_read_data;

	//memory data register
	reg  [31:0]		MDR;
	wire [31:0]		MDRWire;

	// ALU-related wires
	wire [31:0]		operand1;
	wire [31:0]		operand2;
	wire [31:0]		alu_result;
	wire 			zero;
	reg [31:0]		ALUOut;
	wire [31:0]		ALUOutWire;
	
	// Define PC
	reg [31:0]	PC;
	reg [31:0]	PC_next;
	wire [31:0]  PC_plus4 = PC + 32'd4;


	// Define the wires
	assign halt				= (IR == 32'b0);
	assign ext_imm 			= (SignExtend) ? {{16{immi[15]}}, immi} : {16'b0, immi};
	assign opcode			= IR[31:26];
	assign rs				= IR[25:21];
	assign rt				= IR[20:16];
	assign rd				= IR[15:11];
	assign shamt			= IR[10:6];
	assign funct			= IR[5:0];
	assign immi				= IR[15:0];
	assign immj				= IR[25:0];


	//새로 선언한 레지스터 와이어 연결
	assign MDRWire = MDR;
	assign AWire = A;
	assign BWire = B;
	assign ALUOutWire = ALUOut;

	//MEM wire 연결
	assign mem_addr = IorD ? ALUOut : PC;
	assign mem_write_data = BWire;

	//RF wire 연결
	assign rd_addr1 = rs;
	assign rd_addr2 = rt;
	assign wr_addr = (RegDst == 2'b01) ? rd : 
					 (RegDst == 2'b00) ? rt :
					 5'd31;
	assign wr_data = MemtoReg ? MDRWire : ALUOutWire;
	
	//ALU wire 연결
	assign operand1 = ALUSrcA ? AWire : PC;
	assign operand2 = (ALUSrcB == 2'b00) ? B :
					  (ALUSrcB == 2'b01) ? 4 :
					  (ALUSrcB == 2'b10) ? ext_imm:
					  (ALUSrcB == 2'b11) ? (ext_imm << 2) :
					  0;


	always @(*) begin
		// wr_addr = SavePC ? 5'd31 : (RegDst ? rd : rt);
		// wr_data = SavePC ? PC_plus4 : (MemtoReg ? mem_read_data : alu_result);

		// PC_next = JR ? A : Jump ?  {PC_plus4[31:28], immj, 2'b00} : 
        //          (Branch && alu_result) ?  (PC_plus4 + (ext_imm << 2)) : PC_plus4;
		if (PCSource == 2'b00)
			PC_next = alu_result;
		else if (PCSource == 2'b01)
			PC_next = ALUOutWire;
		else if (PCSource == 2'b10)
			PC_next = {PC[31:28], immj, 2'b00};
		else if (PCSource == 2'b11)
			PC_next = AWire;

	end

	// Update the Clock
	always @(posedge clk) begin
    $display("PC=%h IR=%h", PC, IR);
		if (rst)	PC <= 0;
		else begin
			if(PCWrite || (PCWriteCond && zero)) 
				PC <= PC_next;
			if (IRWrite)
				IR <= mem_read_data;
			if (MemRead)
				MDR <= mem_read_data;
			ALUOut <= alu_result;
			A <= rd_data1;
			B <= rd_data2;
		end
	end
	always @(posedge clk) begin
end

	CTRL ctrl (
		//input
		.rst(rst),
		.clk(clk),
		.opcode(opcode),
		.funct(funct),
		//output
		.PCSource(PCSource),
		.ALUOp(ALUOp),
		.ALUSrcB(ALUSrcB),
		.ALUSrcA(ALUSrcA),
		.RegWrite(RegWrite),
		.RegDst(RegDst),
		.PCWriteCond(PCWriteCond),
		.PCWrite(PCWrite),
		.IorD(IorD),
		.MemRead(MemRead),
		.MemWrite(MemWrite),
		.MemtoReg(MemtoReg),
		.IRWrite(IRWrite),
		.SignExtend(SignExtend),
		.InstDone(InstDone)
	);

	RF rf (
		//input
		.clk(clk),
		.rst(rst),
		//read related
		.rd_addr1(rd_addr1),
		.rd_addr2(rd_addr2),
		//write related
		.RegWrite(RegWrite),
		.wr_addr(wr_addr),
		.wr_data(wr_data),
		//output
		.rd_data1(rd_data1),
		.rd_data2(rd_data2)
	);

	MEM mem (
		.clk(clk),
		.rst(rst),

		//input reg
		.mem_addr(mem_addr),
		.MemWrite(MemWrite),
		.mem_write_data(mem_write_data),
		//output reg
		.mem_read_data(mem_read_data)
	);
	
	ALU alu (
		//input
		.operand1(operand1),
		.operand2(operand2),
		.shamt(shamt),
		.funct(ALUOp),
		//output
		.alu_result(alu_result),
		.zero(zero)
	);
endmodule
