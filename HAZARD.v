module HAZARD (
    input clk,
    input rst,
    input rd_addr1,
	input rd_addr2,
	input IDtoEX_destinationWire,
    input IDtoEX_WBwire,
	input EXtoMEM_destinationWire,
    input EXtoMEM_WBwire,
	input MEMtoWB_destinationWire,
	input MEMtoWB_WBwire,

	output reg  stallTime
);

    wire IDtoEX_RegWrite;
    wire EXtoMEM_RegWrite;
    wire MEMtoWB_RegWrite;

    assign IDtoEX_RegWrite = IDtoEX_WBwire[0]
    assign EXtoMEM_RegWrite = EXtoMEM_WBwire[0]
    assign MEMtoWB_RegWrite = MEMtoWB_WBwire[0]


always @(posedge clk) begin
    if (rst) stallTime <= 0;
    else if (IDtoEX_destinationWire == rd_addr1
    || IDtoEX_destinationWire == rd_addr2 
    && IDtoEX_RegWrite)
        stallTime <= 3;
    else if (EXtoMEM_destinationWire == rd_addr1
    || EXtoMEM_destinationWire == rd_addr2
    && EXtoMEM_RegWrite)
        stallTime <= 2;
    else if (MEMtoWB_destinationWire == rd_addr1
    || MEMtoWB_destinationWire == rd_addr2
    && MEMtoWB_RegWrite)
        stallTime <= 1;
    else stallTime <= 0;
end

endmodule