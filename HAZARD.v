module HAZARD (
    input [4:0] rd_addr1,
    input [4:0] rd_addr2,

    input [4:0] IDtoEX_destinationWire,
    input [2:0] IDtoEX_WBwire,

    input [4:0] EXtoMEM_destinationWire,
    input [2:0] EXtoMEM_WBwire,

    input [4:0] MEMtoWB_destinationWire,
    input [2:0] MEMtoWB_WBwire,

    output reg stallTime
);

wire IDtoEX_RegWrite;
wire EXtoMEM_RegWrite;
wire MEMtoWB_RegWrite;

assign IDtoEX_RegWrite  = IDtoEX_WBwire[1];
assign EXtoMEM_RegWrite = EXtoMEM_WBwire[1];
assign MEMtoWB_RegWrite = MEMtoWB_WBwire[1];

always @(*) begin

    if (
        IDtoEX_RegWrite &&
        (IDtoEX_destinationWire != 0) &&
        (
            (IDtoEX_destinationWire == rd_addr1) ||
            (IDtoEX_destinationWire == rd_addr2)
        )
    )
        stallTime = 1;

    else if (
        EXtoMEM_RegWrite &&
        (EXtoMEM_destinationWire != 0) &&
        (
            (EXtoMEM_destinationWire == rd_addr1) ||
            (EXtoMEM_destinationWire == rd_addr2)
        )
    )
        stallTime = 1;

    else if (
        MEMtoWB_RegWrite &&
        (MEMtoWB_destinationWire != 0) &&
        (
            (MEMtoWB_destinationWire == rd_addr1) ||
            (MEMtoWB_destinationWire == rd_addr2)
        )
    )
        stallTime = 1;

    else
        stallTime = 0;

end

endmodule