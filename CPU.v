`timescale 1ns / 1ps

module CPU (
	input  wire        clk,
	input  wire        rst,
	output wire        halt
);
	
	// =========================================================================
	// 1. Pipeline Registers & Wires Declaration
	// =========================================================================
	
	// Hazard Control Wires
	wire               stallTime;

	// ---- IF/ID Stage ----
	reg  [31:0]        IR;
	wire [31:0]        IRwire;
	reg  [31:0]        IFtoID_nextPC;
	wire [31:0]        IFtoID_nextPCwire;

	// ---- ID/EX Stage ----
	reg  [2:0]         IDtoEX_WBreg;
	reg  [2:0]         IDtoEX_MEMreg;
	reg  [5:0]         IDtoEX_EXreg;
	reg  [4:0]         IDtoEX_shamt;
	reg  [4:0]         IDtoEX_rt;
	reg  [4:0]         IDtoEX_rd;
	reg  [31:0]        IDtoEX_ext;
	reg  [31:0]        IDtoEX_rd_data1;
	reg  [31:0]        IDtoEX_rd_data2;
	reg  [31:0]        IDtoEX_nextPC;
	reg                IDtoEX_halt;

	wire [2:0]         IDtoEX_WBwire;
	wire [2:0]         IDtoEX_MEMwire;
	wire [5:0]         IDtoEX_EXwire;
	wire [4:0]         IDtoEX_shamtWire;
	wire [4:0]         IDtoEX_rtWire;
	wire [4:0]         IDtoEX_rdWire;
	wire [4:0]         IDtoEX_destinationWire;
	wire [31:0]        IDtoEX_extWire;
	wire [31:0]        IDtoEX_rd_data1Wire;
	wire [31:0]        IDtoEX_rd_data2Wire;
	wire [31:0]        IDtoEX_nextPCwire;
	wire               IDtoEX_haltWire;

	// ---- EX/MEM Stage ----
	reg  [2:0]         EXtoMEM_WBreg;
	reg  [2:0]         EXtoMEM_MEMreg;
	reg                EXtoMEM_zero;
	reg  [31:0]        EXtoMEM_ALUresult;
	reg  [31:0]        EXtoMEM_ADDresult;
	reg  [31:0]        EXtoMEM_wrdata;
	reg  [4:0]         EXtoMEM_destination;
	reg  [31:0]        EXtoMEM_PCplus4;
	reg                EXtoMEM_halt;

	wire [2:0]         EXtoMEM_WBwire;
	wire [2:0]         EXtoMEM_MEMwire;
	wire               EXtoMEM_zeroWire;
	wire [31:0]        EXtoMEM_ALUresultWire;
	wire [31:0]        EXtoMEM_ADDresultWire;
	wire [31:0]        EXtoMEM_wrdataWire;
	wire [4:0]         EXtoMEM_destinationWire;
	wire [31:0]        EXtoMEM_PCplus4wire;
	wire               EXtoMEM_haltWire;

	// ---- MEM/WB Stage ----
	reg  [2:0]         MEMtoWB_WBreg;
	reg  [31:0]        MEMtoWB_ALUresult;
	reg  [31:0]        MEMtoWB_memorydata;
	reg  [4:0]         MEMtoWB_destination;
	reg  [31:0]        MEMtoWB_PCplus4;
	reg                MEMtoWB_halt;
	reg                is_halt;

	wire [2:0]         MEMtoWB_WBwire;
	wire [31:0]        MEMtoWB_ALUresultWire;
	wire [31:0]        MEMtoWB_memorydataWire;
	wire [4:0]         MEMtoWB_destinationWire;
	wire [31:0]        MEMtoWB_PCplus4wire;
	wire               MEMtoWB_haltWire;

	// =========================================================================
	// 2. Internal Datapath Wires (Instruction Split & Control)
	// =========================================================================
	
	// Instruction fields
	wire [5:0]         opcode;
	wire [4:0]         rs;
	wire [4:0]         rt;
	wire [4:0]         rd;
	wire [4:0]         shamt;
	wire [5:0]         funct;
	wire [15:0]        immi;
	wire [25:0]        immj;

	// Control Signals
	wire               PCSrc;
	wire [3:0]         ALUOp;
	wire               ALUSrc;
	wire               RegWrite;
	wire               RegDst;
	wire               MemRead;
	wire               MemWrite;
	wire               MemtoReg;
	wire               Branch;
	wire               Jump;
	wire               JR;
	wire               SignExtend;
	wire               SavePC;
	
	wire [2:0]         WB;
	wire [2:0]         MEM;
	wire [5:0]         EX;

	// Component-specific Wires
	wire [31:0]        ext_imm;
	wire [4:0]         rd_addr1;
	wire [4:0]         rd_addr2;
	wire [31:0]        rd_data1;
	wire [31:0]        rd_data2;
	wire [4:0]         wr_addr;
	wire [31:0]        wr_data;

	wire [31:0]        mem_addr;
	wire [31:0]        mem_write_data;
	wire [31:0]        mem_read_data;
	wire [31:0]        inst_addr;
	wire [31:0]        inst;

	wire [31:0]        operand1;
	wire [31:0]        operand2;
	wire [31:0]        alu_result;
	wire               zero;
	
	// Program Counter
	reg  [31:0]        PC;
	wire [31:0]        PC_plus4 = PC + 32'd4;

	// PC ALU Addition
	reg  [31:0]        addResult;
	wire [31:0]        addResultWire;

	// =========================================================================
	// 3. Continuous Assignments (Wiring)
	// =========================================================================
	
	// Instruction Decoding & Extension
	assign ext_imm    = (SignExtend) ? {{16{immi[15]}}, immi} : {16'b0, immi};
	assign opcode     = IRwire[31:26];
	assign rs         = IRwire[25:21];
	assign rt         = IRwire[20:16];
	assign rd         = IRwire[15:11];
	assign shamt      = IRwire[10:6];
	assign funct      = IRwire[5:0];
	assign immi       = IRwire[15:0];
	assign immj       = IRwire[25:0];

	// Memory Address Mapping
	assign inst_addr      = PC;
	assign mem_addr       = EXtoMEM_ALUresultWire;
	assign mem_write_data = EXtoMEM_wrdataWire;

	// Register to Wire Connections
	assign IRwire                 = IR;
	assign IFtoID_nextPCwire      = IFtoID_nextPC;
	assign IDtoEX_nextPCwire      = IDtoEX_nextPC;
	
	assign IDtoEX_WBwire          = IDtoEX_WBreg;
	assign IDtoEX_MEMwire         = IDtoEX_MEMreg;
	assign IDtoEX_EXwire          = IDtoEX_EXreg;
	assign IDtoEX_shamtWire       = IDtoEX_shamt;	
	assign IDtoEX_extWire         = IDtoEX_ext;
	assign IDtoEX_rd_data1Wire    = IDtoEX_rd_data1;
	assign IDtoEX_rd_data2Wire    = IDtoEX_rd_data2;
	assign IDtoEX_rtWire          = IDtoEX_rt;
	assign IDtoEX_rdWire          = IDtoEX_rd;
	assign IDtoEX_haltWire        = IDtoEX_halt;

	assign EXtoMEM_WBwire         = EXtoMEM_WBreg;
	assign EXtoMEM_MEMwire        = EXtoMEM_MEMreg;
	assign EXtoMEM_zeroWire       = EXtoMEM_zero;
	assign EXtoMEM_ALUresultWire  = EXtoMEM_ALUresult;
	assign EXtoMEM_ADDresultWire  = EXtoMEM_ADDresult;
	assign EXtoMEM_wrdataWire     = EXtoMEM_wrdata;
	assign EXtoMEM_destinationWire= EXtoMEM_destination;
	assign EXtoMEM_PCplus4wire    = EXtoMEM_PCplus4;
	assign EXtoMEM_haltWire       = EXtoMEM_halt;

	assign MEMtoWB_WBwire         = MEMtoWB_WBreg;
	assign MEMtoWB_ALUresultWire  = MEMtoWB_ALUresult;
	assign MEMtoWB_memorydataWire = MEMtoWB_memorydata;
	assign MEMtoWB_destinationWire= MEMtoWB_destination;
	assign MEMtoWB_PCplus4wire    = MEMtoWB_PCplus4;
	assign MEMtoWB_haltWire       = MEMtoWB_halt;
	
	assign addResultWire          = addResult;

	// Register File Connections
	assign rd_addr1   = rs;
	assign rd_addr2   = rt;
	assign wr_addr    = SavePC ? 5'd31 : MEMtoWB_destinationWire;
	assign wr_data    = SavePC ? MEMtoWB_PCplus4wire : 
	                    MemtoReg ? MEMtoWB_ALUresultWire : MEMtoWB_memorydataWire;

	// ALU Connections
	always @(*) begin	
		addResult = IDtoEX_nextPCwire + (IDtoEX_extWire << 2);
	end
	assign operand1   = IDtoEX_rd_data1Wire;
	assign operand2   = ALUSrc ? IDtoEX_extWire : IDtoEX_rd_data2Wire;

	// Control Signal Demux from Pipeline Wires
	assign PCSrc                       = Branch & EXtoMEM_zeroWire;
	assign {ALUOp, ALUSrc, RegDst}     = IDtoEX_EXwire;
	assign {Branch, MemRead, MemWrite} = EXtoMEM_MEMwire;
	assign {SavePC, RegWrite, MemtoReg} = MEMtoWB_WBwire;

	assign IDtoEX_destinationWire = IDtoEX_WBwire[2] ? 5'd31 : RegDst ? IDtoEX_rdWire : IDtoEX_rtWire;
	assign halt = is_halt;

	// =========================================================================
	// 4. Sequential Logic (Clock & Reset Control)
	// =========================================================================
	always @(posedge clk) begin
		if (rst) begin
			PC <= 0;
		end

		// ---- Case 1: Flush Younger Instructions (Branch Taken) ----
		else if (PCSrc) begin
			PC                  <= EXtoMEM_ADDresultWire;
			IR                  <= 32'hFC00_0000;

			IDtoEX_EXreg        <= 6'b000000;
			IDtoEX_MEMreg       <= 3'b000;
			IDtoEX_WBreg        <= 3'b000;
			IDtoEX_halt         <= 0;

			EXtoMEM_WBreg       <= 3'b000;
			EXtoMEM_MEMreg      <= 3'b000;
			EXtoMEM_ADDresult   <= 0;
			EXtoMEM_zero        <= 0;
			EXtoMEM_ALUresult   <= 0;
			EXtoMEM_wrdata      <= 0;
			EXtoMEM_destination <= 0;
			EXtoMEM_PCplus4     <= 0;
			EXtoMEM_halt        <= 0;

			MEMtoWB_WBreg       <= EXtoMEM_WBwire;
			MEMtoWB_memorydata  <= mem_read_data;
			MEMtoWB_ALUresult   <= EXtoMEM_ALUresultWire;
			MEMtoWB_destination <= EXtoMEM_destinationWire;
			MEMtoWB_PCplus4     <= EXtoMEM_PCplus4wire;
			MEMtoWB_halt        <= 0;

			is_halt             = 0; 
		end

		// ---- Case 2: Hazard Detected (Stall) ----
		else if (stallTime) begin
			// Freeze IF stage
			PC                  <= PC;

			// Freeze IF/ID pipeline reg
			IR                  <= IR;
			IFtoID_nextPC       <= IFtoID_nextPC;

			// Insert bubble into ID/EX
			IDtoEX_WBreg        <= 3'b00;
			IDtoEX_MEMreg       <= 3'b000;
			IDtoEX_EXreg        <= 6'b000000;
			IDtoEX_ext          <= 32'b0;
			IDtoEX_nextPC       <= 32'b0;
			IDtoEX_rd_data1     <= 32'b0;
			IDtoEX_rd_data2     <= 32'b0;
			IDtoEX_rt           <= 5'b0;
			IDtoEX_rd           <= 5'b0;
			IDtoEX_shamt        <= 0;

			// EX stage continues
			EXtoMEM_WBreg       <= IDtoEX_WBwire;
			EXtoMEM_MEMreg      <= IDtoEX_MEMwire;
			EXtoMEM_ADDresult   <= addResultWire;
			EXtoMEM_zero        <= zero;
			EXtoMEM_ALUresult   <= alu_result;
			EXtoMEM_wrdata      <= IDtoEX_rd_data2Wire;
			EXtoMEM_destination <= IDtoEX_destinationWire;
			EXtoMEM_PCplus4     <= IDtoEX_nextPCwire;
			EXtoMEM_halt        <= IDtoEX_haltWire;

			// MEM stage continues
			MEMtoWB_WBreg       <= EXtoMEM_WBwire;
			MEMtoWB_memorydata  <= mem_read_data;
			MEMtoWB_ALUresult   <= EXtoMEM_ALUresultWire;
			MEMtoWB_destination <= EXtoMEM_destinationWire;
			MEMtoWB_PCplus4     <= EXtoMEM_PCplus4wire;
			MEMtoWB_halt        <= EXtoMEM_haltWire;

			is_halt             <= MEMtoWB_haltWire;
		end

		// ---- Case 3: Jump Instruction ----
		else if (Jump) begin 
			PC                  <= {IFtoID_nextPCwire[31:28], immj, 2'b00};
			IR                  <= 32'hFC00_0000;
			IFtoID_nextPC       <= PC_plus4;

			IDtoEX_WBreg        <= WB;
			IDtoEX_MEMreg       <= MEM;
			IDtoEX_EXreg        <= EX;
			IDtoEX_ext          <= ext_imm;
			IDtoEX_nextPC       <= IFtoID_nextPCwire;
			IDtoEX_rd_data1     <= rd_data1;
			IDtoEX_rd_data2     <= rd_data2;
			IDtoEX_rt           <= rt;
			IDtoEX_rd           <= rd;
			IDtoEX_shamt        <= shamt;
			IDtoEX_halt         <= (IRwire == 0);

			EXtoMEM_WBreg       <= IDtoEX_WBwire;
			EXtoMEM_MEMreg      <= IDtoEX_MEMwire;
			EXtoMEM_ADDresult   <= addResultWire;
			EXtoMEM_zero        <= zero;
			EXtoMEM_ALUresult   <= alu_result;
			EXtoMEM_wrdata      <= IDtoEX_rd_data2Wire;
			EXtoMEM_PCplus4     <= IDtoEX_nextPCwire;
			EXtoMEM_destination <= IDtoEX_destinationWire;
			EXtoMEM_halt        <= IDtoEX_haltWire;

			MEMtoWB_WBreg       <= EXtoMEM_WBwire;
			MEMtoWB_memorydata  <= mem_read_data;
			MEMtoWB_ALUresult   <= EXtoMEM_ALUresultWire;
			MEMtoWB_destination <= EXtoMEM_destinationWire;
			MEMtoWB_PCplus4     <= EXtoMEM_PCplus4wire;
			MEMtoWB_halt        <= EXtoMEM_haltWire;

			is_halt             <= MEMtoWB_haltWire;
		end

		// ---- Case 4: Jump Register (JR) ----
		else if (JR) begin 
			PC                  <= rd_data1;
			IR                  <= 32'hFC00_0000;
			IFtoID_nextPC       <= PC_plus4;
		
			IDtoEX_WBreg        <= WB;
			IDtoEX_MEMreg       <= MEM;
			IDtoEX_EXreg        <= EX;
			IDtoEX_ext          <= ext_imm;
			IDtoEX_nextPC       <= IFtoID_nextPCwire;
			IDtoEX_rd_data1     <= rd_data1;
			IDtoEX_rd_data2     <= rd_data2;
			IDtoEX_rt           <= rt;
			IDtoEX_rd           <= rd;
			IDtoEX_shamt        <= shamt;
			IDtoEX_halt         <= (IRwire == 0);

			EXtoMEM_WBreg       <= IDtoEX_WBwire;
			EXtoMEM_MEMreg      <= IDtoEX_MEMwire;
			EXtoMEM_ADDresult   <= addResultWire;
			EXtoMEM_zero        <= zero;
			EXtoMEM_ALUresult   <= alu_result;
			EXtoMEM_wrdata      <= IDtoEX_rd_data2Wire;
			EXtoMEM_PCplus4     <= IDtoEX_nextPCwire;
			EXtoMEM_destination <= IDtoEX_destinationWire;
			EXtoMEM_halt        <= IDtoEX_haltWire;

			MEMtoWB_WBreg       <= EXtoMEM_WBwire;
			MEMtoWB_memorydata  <= mem_read_data;
			MEMtoWB_ALUresult   <= EXtoMEM_ALUresultWire;
			MEMtoWB_destination <= EXtoMEM_destinationWire;
			MEMtoWB_PCplus4     <= EXtoMEM_PCplus4wire;
			MEMtoWB_halt        <= EXtoMEM_haltWire;

			is_halt             <= MEMtoWB_haltWire;
		end

		// ---- Case 5: Normal Execution ----
		else begin
			PC                  <= PC_plus4;
			IR                  <= inst;
			IFtoID_nextPC       <= PC_plus4;
	
			IDtoEX_WBreg        <= WB;
			IDtoEX_MEMreg       <= MEM;
			IDtoEX_EXreg        <= EX;
			IDtoEX_ext          <= ext_imm;
			IDtoEX_nextPC       <= IFtoID_nextPCwire;
			IDtoEX_rd_data1     <= rd_data1;
			IDtoEX_rd_data2     <= rd_data2;
			IDtoEX_rt           <= rt;
			IDtoEX_rd           <= rd;
			IDtoEX_shamt        <= shamt;
			IDtoEX_halt         <= (IRwire == 0);

			EXtoMEM_WBreg       <= IDtoEX_WBwire;
			EXtoMEM_MEMreg      <= IDtoEX_MEMwire;
			EXtoMEM_ADDresult   <= addResultWire;
			EXtoMEM_zero        <= zero;
			EXtoMEM_ALUresult   <= alu_result;
			EXtoMEM_wrdata      <= IDtoEX_rd_data2Wire;
			EXtoMEM_PCplus4     <= IDtoEX_nextPCwire;
			EXtoMEM_destination <= IDtoEX_destinationWire;
			EXtoMEM_halt        <= IDtoEX_haltWire;

			MEMtoWB_WBreg       <= EXtoMEM_WBwire;
			MEMtoWB_memorydata  <= mem_read_data;
			MEMtoWB_ALUresult   <= EXtoMEM_ALUresultWire;
			MEMtoWB_destination <= EXtoMEM_destinationWire;
			MEMtoWB_PCplus4     <= EXtoMEM_PCplus4wire;
			MEMtoWB_halt        <= EXtoMEM_haltWire;

			is_halt             <= MEMtoWB_haltWire;
		end
	end

	// =========================================================================
	// 5. Submodule Instantiations
	// =========================================================================
	
	CTRL ctrl (
		.opcode     (opcode),
		.funct      (funct),
		.PCSrc      (PCSrc),
		.WB         (WB),
		.MEM        (MEM),
		.EX         (EX),
		.Jump       (Jump),
		.JR         (JR),
		.SignExtend (SignExtend)
	);

	RF rf (
		.clk        (clk),
		.rst        (rst),
		.rd_addr1   (rd_addr1),
		.rd_addr2   (rd_addr2),
		.RegWrite   (RegWrite),
		.wr_addr    (wr_addr),
		.wr_data    (wr_data),
		.rd_data1   (rd_data1),
		.rd_data2   (rd_data2)
	);

	MEM mem (
		.clk            (clk),
		.rst            (rst),
		.inst_addr      (inst_addr),
		.inst           (inst),
		.mem_addr       (mem_addr),
		.MemWrite       (MemWrite),
		.mem_write_data (mem_write_data),
		.mem_read_data  (mem_read_data)
	);
	
	ALU alu (
		.operand1   (operand1),
		.operand2   (operand2),
		.shamt      (IDtoEX_shamtWire),
		.funct      (ALUOp),
		.alu_result (alu_result),
		.zero       (zero)
	);

	HAZARD hazard (
		.rd_addr1               (rd_addr1),
		.rd_addr2               (rd_addr2),
		.IDtoEX_destinationWire (IDtoEX_destinationWire),
		.IDtoEX_WBwire          (IDtoEX_WBwire),
		.EXtoMEM_destinationWire(EXtoMEM_destinationWire),
		.EXtoMEM_WBwire         (EXtoMEM_WBwire),
		.MEMtoWB_destinationWire(MEMtoWB_destinationWire),
		.MEMtoWB_WBwire         (MEMtoWB_WBwire),
		.stallTime              (stallTime)
	);
	
endmodule