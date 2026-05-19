`timescale 1ns / 1ps


module CPU(
	input		clk,
	input		rst,
	output 		halt
	);
	
	//define latchs for control
	reg 			IDtoEX_WBreg;
	reg 			IDtoEX_MEMreg;
	reg 			IDtoEX_EXreg;
	reg 			EXtoMEM_WBreg;
	reg 			EXtoMEM_MEMreg;
	reg 			MEMtoWB_WBreg;
	wire 			IDtoEX_WBwire;
	wire 			IDtoEX_MEMwire;
	wire 			IDtoEX_EXwire;
	wire 			EXtoMEM_WBwire;
	wire 			EXtoMEM_MEMwire;
	wire 			MEMtoWB_WBwire;

	//for IR
	reg [31:0]		IR;
	wire [31:0]		IRwire;
	//for save reg destination
	reg [4:0] 		IDtoEX_rt;
	reg [4:0] 		IDtoEX_rd;
	reg [4:0] 		EXtoMEM_destination;
	reg [4:0] 		MEMtoWB_destination;
	wire [4:0] 		IDtoEX_rtWire;
	wire [4:0] 		IDtoEX_rdWire;
	wire [4:0] 		EXtoMEM_destinationWire;
	wire [4:0] 		MEMtoWB_destinationWire;

	//for save signExtend
	reg [31:0] 		IDtoEX_ext;
	wire [31:0] 	IDtoEX_extWire;

	//for save ALU result
	reg 			EXtoMEM_zero;
	reg [31:0] 		EXtoMEM_ALUresult;
	reg [31:0] 		EXtoMEM_ADDresult;
	reg [31:0] 		MEMtoWB_ALUresult;
	
	wire 			EXtoMEM_zeroWire;
	wire [31:0] 	EXtoMEM_ALUresultWire;
	wire [31:0] 	EXtoMEM_ADDresultWire;
	wire [31:0] 	MEMtoWB_ALUresultWire;


	//for rd data
	reg [31:0] 		IDtoEX_rd_data1;
	reg [31:0] 		IDtoEX_rd_data2;
	wire [31:0] 	IDtoEX_rd_data1Wire;
	wire [31:0] 	IDtoEX_rd_data2Wire;
	
	//for memory data
	reg [31:0]		EXtoMEM_wrdata;
	wire [31:0]		EXtoMEM_wrdataWire;
	reg  [31:0]		MEMtoWB_memorydata;
	wire [31:0]		MEMtoWB_memorydataWire;

	//for pc + 4
	reg [31:0] 		IFtoID_nextPC;
	reg [31:0] 		IDtoEX_nextPC;
	reg [31:0] 		EXtoMEM_nextPC;
	wire [31:0] 	IFtoID_nextPCwire;
	wire [31:0] 	IDtoEX_nextPCwire;
	wire [31:0] 	EXtoMEM_nextPCwire;

	//PC alu
	reg [31:0]		addResult;
	wire [31:0]		addResultWire;

	// Split the IRwireructions
	// IRwireruction-related
	wire [5:0]		opcode;
	wire [4:0]		rs;
	wire [4:0]		rt;
	wire [4:0]		rd;
	wire [4:0]		shamt;
	wire [5:0]		funct;
	wire [15:0]		immi;
	wire [25:0]		immj;

	// Control-related wires
	wire [1:0]		PCSrc;
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
	wire 			IRwireDone;
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

	// MEM-related wires
	wire [31:0]		mem_addr;
	wire [31:0]		mem_write_data;
	wire [31:0]		mem_read_data;
	wire [31:0] 	inst_addr;
	wire [31:0]		inst;


	// ALU-related wires
	wire [31:0]		operand1;
	wire [31:0]		operand2;
	wire [31:0]		alu_result;
	wire 			zero;
	
	// Define PC
	reg [31:0]		PC;
	wire [31:0]  	PC_plus4 = PC + 32'd4;


	// Define the wires
	assign halt				= (IRwire == 32'b0);
	assign ext_imm 			= (SignExtend) ? {{16{immi[15]}}, immi} : {16'b0, immi};
	assign opcode			= IRwire[31:26];
	assign rs				= IRwire[25:21];
	assign rt				= IRwire[20:16];
	assign rd				= IRwire[15:11];
	assign shamt			= IRwire[10:6];
	assign funct			= IRwire[5:0];
	assign immi				= IRwire[15:0];
	assign immj				= IRwire[25:0];



	//RF wire 연결
	assign rd_addr1 = rs;
	assign rd_addr2 = rt;
	assign wr_addr = MEMtoWB_destinationWire;

	assign wr_data = MemtoReg ? MEMtoWB_ALUresultWire : MEMtoWB_memorydataWire;
	
	//ALU wire 연결
	always @(*) begin	
		addResult = IDtoEX_nextPCwire + (IDtoEX_extWire << 2);
	end
	assign operand1 = IDtoEX_rd_data1Wire;
	assign operand2 = ALUSrc ? IDtoEX_extWire : IDtoEX_rd_data2Wire;


	always @(*) begin
		if (PCSrc) PC = EXtoMEM_ADDresultWire;
		else 	   PC = PC_plus4;
	end

	// Update the Clock
	always @(posedge clk) begin
		if (rst)	PC <= 0;
		else begin
			if (RegDst) EXtoMEM_destination <= IDtoEX_rdWire;
			else 		EXtoMEM_destination <= IDtoEX_rtWire;

			IR <= inst;
			IFtoID_nextPC <= PC_plus4;


			IDtoEX_WBreg <= 
			IDtoEX_MEMreg <=
			IDtoEX_EXreg <= 
			IDtoEX_ext <= ext_imm;
			IDtoEX_nextPC <= IFtoID_nextPCwire;
			IDtoEX_rd_data1 <= rd_data1;
			IDtoEX_rd_data2 <= rd_data2;
			IDtoEX_ext <= ext_imm;
			IDtoEX_rt <= rt;
			IDtoEX_rd <= rd;

			EXtoMEM_WBreg <= IDtoEX_WBwire;
			EXtoMEM_MEMreg <= IDtoEX_MEMwire;
			EXtoMEM_ADDresult <= addResultWire;
			EXtoMEM_zero <= zero;
			EXtoMEM_ALUresult <= alu_result;
			EXtoMEM_wrdata <= IDtoEX_rd_data2Wire;

			MEMtoWB_WBreg <= EXtoMEM_WBwire;
			MEMtoWB_memorydata <= mem_read_data;
			MEMtoWB_ALUresult <= EXtoMEM_ALUresultWire;
			MEMtoWB_destination <= EXtoMEM_destinationWire;
			


		end
	end

	CTRL ctrl (
		//input
		.rst(rst),
		.clk(clk),
		.opcode(opcode),
		.funct(funct),
		//output
		.PCSrc(PCSrc),
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
		.SignExtend(SignExtend)
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

		.inst_addr(inst_addr),
		.inst(inst),
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
