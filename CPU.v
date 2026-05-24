`timescale 1ns / 1ps


module CPU(
	input		clk,
	input		rst,
	output 		halt
	);
	
	//hazard
	wire  				stallTime;
	//define latchs for control
	reg [1:0]			IDtoEX_WBreg;
	reg [2:0]			IDtoEX_MEMreg;
	reg [5:0]			IDtoEX_EXreg;
	reg [1:0]			EXtoMEM_WBreg;
	reg [2:0]			EXtoMEM_MEMreg;
	reg [1:0]			MEMtoWB_WBreg;
	wire [1:0]			IDtoEX_WBwire;
	wire [2:0]			IDtoEX_MEMwire;
	wire [5:0]			IDtoEX_EXwire;
	wire [1:0]			EXtoMEM_WBwire;
	wire [2:0]			EXtoMEM_MEMwire;
	wire [1:0]			MEMtoWB_WBwire;


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
	wire [4:0]		IDtoEX_destinationWire;

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
	wire 			PCSrc;
	wire [3:0]		ALUOp;
	wire 			ALUSrc;
	wire      		RegWrite;
	wire  			RegDst;
	wire 			MemRead;
	wire 			MemWrite;
	wire 			MemtoReg;
	wire 			Branch;
	wire 			Jump;
	wire 			JR;
	wire 			SignExtend;

	wire [1:0]			WB;
	wire [2:0]			MEM;
	wire  [5:0]			EX;

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


	//IR wire 연결
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

	assign inst_addr = PC;
	assign mem_addr = EXtoMEM_ALUresultWire;
	assign mem_write_data = EXtoMEM_wrdataWire;

	//ctrl, latch wire 연결
	assign IDtoEX_WBwire      = IDtoEX_WBreg;
	assign IDtoEX_MEMwire     = IDtoEX_MEMreg;
	assign IDtoEX_EXwire      = IDtoEX_EXreg;
	assign EXtoMEM_WBwire     = EXtoMEM_WBreg;
	assign EXtoMEM_MEMwire    = EXtoMEM_MEMreg;
	assign MEMtoWB_WBwire     = MEMtoWB_WBreg;
	assign IRwire             = IR;
	assign IFtoID_nextPCwire  = IFtoID_nextPC;
	assign IDtoEX_nextPCwire  = IDtoEX_nextPC;
	assign EXtoMEM_nextPCwire = EXtoMEM_nextPC;
	assign IDtoEX_extWire     = IDtoEX_ext;
	assign IDtoEX_rd_data1Wire= IDtoEX_rd_data1;
	assign IDtoEX_rd_data2Wire= IDtoEX_rd_data2;
	assign EXtoMEM_zeroWire   = EXtoMEM_zero;
	assign EXtoMEM_ALUresultWire = EXtoMEM_ALUresult;
	assign EXtoMEM_ADDresultWire = EXtoMEM_ADDresult;
	assign MEMtoWB_ALUresultWire = MEMtoWB_ALUresult;
	assign MEMtoWB_memorydataWire= MEMtoWB_memorydata;
	assign IDtoEX_rtWire      = IDtoEX_rt;
	assign IDtoEX_rdWire      = IDtoEX_rd;
	assign EXtoMEM_destinationWire = EXtoMEM_destination;
	assign MEMtoWB_destinationWire = MEMtoWB_destination;
	assign addResultWire      = addResult;

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


	assign 	PCSrc 	= Branch & EXtoMEM_zeroWire;
	assign	{ALUOp, ALUSrc, RegDst} 	= IDtoEX_EXwire;
	assign	{Branch, MemRead, MemWrite} = EXtoMEM_MEMwire;
	assign	{RegWrite, MemtoReg} 		= MEMtoWB_WBwire;

	assign IDtoEX_destinationWire = RegDst ? IDtoEX_rdWire : IDtoEX_rtWire;

	// Update the Clock, PC
	always @(posedge clk) begin
		if (rst)	PC <= 0;

		//flush younger instructions
		else if (PCSrc) begin
			PC <= EXtoMEM_ADDresultWire;
			IR <= 0;
			IDtoEX_EXreg <= 6'b000000;
			IDtoEX_MEMreg <= 3'b000;
			IDtoEX_WBreg <= 2'b00;

			// EX/MEM 레지스터도 Flush (EX에 있던 잘못된 명령어가 MEM으로 못 넘어가게 막음)
			EXtoMEM_WBreg       <= 2'b00;
			EXtoMEM_MEMreg      <= 3'b000;
			EXtoMEM_ADDresult   <= 0;
			EXtoMEM_zero        <= 0;
			EXtoMEM_ALUresult   <= 0;
			EXtoMEM_wrdata      <= 0;
			EXtoMEM_destination <= 0;

			// MEM/WB는 정상 진행 (현재 MEM에 있는 분기 명령어가 무사히 빠져나가야 하므로)
			MEMtoWB_WBreg       <= EXtoMEM_WBwire;
			MEMtoWB_memorydata  <= mem_read_data;
			MEMtoWB_ALUresult   <= EXtoMEM_ALUresultWire;
			MEMtoWB_destination <= EXtoMEM_destinationWire;
		end

		else if (stallTime) begin
    // =========================
    // Freeze IF stage
    // =========================
    PC <= PC;

    // =========================
    // Freeze IF/ID pipeline reg
    // =========================
    IR <= IR;
    IFtoID_nextPC <= IFtoID_nextPC;

    // =========================
    // Insert bubble into ID/EX
    // =========================
    IDtoEX_WBreg <= 2'b00;
    IDtoEX_MEMreg <= 3'b000;
    IDtoEX_EXreg <= 6'b000000;

    IDtoEX_ext <= 32'b0;
    IDtoEX_nextPC <= 32'b0;
    IDtoEX_rd_data1 <= 32'b0;
    IDtoEX_rd_data2 <= 32'b0;

    IDtoEX_rt <= 5'b0;
    IDtoEX_rd <= 5'b0;

    // =========================
    // EX stage continues
    // =========================
    EXtoMEM_WBreg <= IDtoEX_WBwire;
    EXtoMEM_MEMreg <= IDtoEX_MEMwire;

    EXtoMEM_ADDresult <= addResultWire;
    EXtoMEM_zero <= zero;
    EXtoMEM_ALUresult <= alu_result;

    EXtoMEM_wrdata <= IDtoEX_rd_data2Wire;

    EXtoMEM_destination <= IDtoEX_destinationWire;

    // =========================
    // MEM stage continues
    // =========================
    MEMtoWB_WBreg <= EXtoMEM_WBwire;

    MEMtoWB_memorydata <= mem_read_data;
    MEMtoWB_ALUresult <= EXtoMEM_ALUresultWire;

    MEMtoWB_destination <= EXtoMEM_destinationWire;
end

		else if (Jump)	begin 
			PC <= {IFtoID_nextPCwire[31:28], immj, 2'b00};
			IR <= 0;
		end;	
		else if (JR)	begin 
			PC <= IDtoEX_rd_data1Wire;
			IR <= 0;
		end
		else begin
			PC <= PC_plus4;

			if (RegDst) EXtoMEM_destination <= IDtoEX_rdWire;
			else 		EXtoMEM_destination <= IDtoEX_rtWire;

			IR <= inst;
			IFtoID_nextPC <= PC_plus4;


			IDtoEX_WBreg <= WB;
			IDtoEX_MEMreg <= MEM;
			IDtoEX_EXreg <= EX;
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
		.PCSrc(PCSrc),
		//output
		.WB(WB),
		.MEM(MEM),
		.EX(EX),
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

	HAZARD hazard (
		//input
		.rd_addr1(rd_addr1),
		.rd_addr2(rd_addr2),
		.IDtoEX_destinationWire(IDtoEX_destinationWire),
		.IDtoEX_WBwire(IDtoEX_WBwire),
		.EXtoMEM_destinationWire(EXtoMEM_destinationWire),
		.EXtoMEM_WBwire(EXtoMEM_WBwire),
		.MEMtoWB_destinationWire(MEMtoWB_destinationWire),
		.MEMtoWB_WBwire(MEMtoWB_WBwire),
		//output
		.stallTime(stallTime)
	);
endmodule
