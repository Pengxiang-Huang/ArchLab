// Northwestern - CompEng 361 - Lab2
// Groupname:
// NetIDs:

// Some useful defines...please add your own
`define OPCODE_COMPUTE    7'b0110011
`define OPCODE_BRANCH     7'b1100011
`define OPCODE_LOAD       7'b0000011
`define OPCODE_STORE      7'b0100011 

`define FUNC_ADD      3'b000
`define FUNC_SUB      3'b000
`define FUNC_SLL      3'b001
`define FUNC_SLT      3'b010
`define FUNC_SLTU     3'b011
`define FUNC_XOR      3'b100
`define FUNC_SRL      3'b101
`define FUNC_SRA      3'b101
`define FUNC_OR       3'b110
`define FUNC_AND      3'b111


`define AUX_FUNC_ADD  7'b0000000
`define AUX_FUNC_SUB  7'b0100000
`define AUX_FUNC_SLL  7'b0000000
`define AUX_FUNC_SLT  7'b0000000
`define AUX_FUNC_SLTU 7'b0000000
`define AUX_FUNC_XOR  7'b0000000
`define AUX_FUNC_SRL  7'b0000000
`define AUX_FUNC_SRA  7'b0100000
`define AUX_FUNC_OR   7'b0000000
`define AUX_FUNC_AND  7'b0000000


`define SIZE_BYTE  2'b00
`define SIZE_HWORD 2'b01
`define SIZE_WORD  2'b10

module SingleCycleCPU(halt, clk, rst);
   output halt;
   input clk, rst;

   wire [31:0] PC, InstWord;
   wire [31:0] DataAddr, StoreData, DataWord;
   wire [1:0]  MemSize;
   wire        MemWrEn;
   
   wire [4:0]  Rsrc1, Rsrc2, Rdst;
   wire [31:0] Rdata1, Rdata2, RWrdata;
   wire        RWrEn;

   wire [31:0] NPC, PC_Plus_4;
   wire [6:0]  opcode;

   wire [6:0]  funct7;
   wire [2:0]  funct3;
   

   // Only support R-TYPE ADD and SUB
   assign IsRtype = (opcode == `OPCODE_COMPUTE) && 
   (funct3 == `FUNC_ADD || funct3 == `FUNC_SUB || funct3 == `FUNC_SLL || funct3 == `FUNC_SLT || funct3 == `FUNC_SLTU || funct3 == `FUNC_XOR || funct3 == `FUNC_SRL || funct3 == `FUNC_SRA || funct3 == `FUNC_OR || funct3 == `FUNC_AND)
   && ((funct7 == `AUX_FUNC_ADD) || (funct7 == `AUX_FUNC_SUB) || (funct7 == `AUX_FUNC_SLL) || (funct7 == `AUX_FUNC_SLT) || (funct7 == `AUX_FUNC_SLTU) || (funct7 == `AUX_FUNC_XOR) || (funct7 == `AUX_FUNC_SRL) || (funct7 == `AUX_FUNC_SRA) || (funct7 == `AUX_FUNC_OR) || (funct7 == `AUX_FUNC_AND));
   
   assign halt = !(IsRtype);
     
   // System State (everything is neg assert)
   InstMem IMEM(.Addr(PC), .Size(`SIZE_WORD), .DataOut(InstWord), .CLK(clk));
   DataMem DMEM(.Addr(DataAddr), .Size(MemSize), .DataIn(StoreData), .DataOut(DataWord), .WEN(MemWrEn), .CLK(clk));

   RegFile RF(.AddrA(Rsrc1), .DataOutA(Rdata1), 
	      .AddrB(Rsrc2), .DataOutB(Rdata2), 
	      .AddrW(Rdst), .DataInW(RWrdata), .WenW(RWrEn), .CLK(clk));

   Reg PC_REG(.Din(NPC), .Qout(PC), .WEN(1'b0), .CLK(clk), .RST(rst));

   // Instruction Decode
   assign opcode = InstWord[6:0];   
   assign Rdst = InstWord[11:7]; 
   assign Rsrc1 = InstWord[19:15]; 
   assign Rsrc2 = InstWord[24:20];
   assign funct3 = InstWord[14:12];  // R-Type, I-Type, S-Type
   assign funct7 = InstWord[31:25];  // R-Type

   assign MemWrEn = 1'b1; // Change this to allow stores
   assign RWrEn = 1'b0;  // Every instruction will write to the register file

   // Hardwired to support R-Type instructions -- please add muxes and other control signals
   ExecutionUnit EU(.out(RWrdata), .opA(Rdata1), .opB(Rdata2), .func(funct3), .auxFunc(funct7));

   // Fetch Address Datapath
   assign PC_Plus_4 = PC + 4;
   assign NPC = PC_Plus_4;
   
endmodule // SingleCycleCPU


// Incomplete version of Lab1 execution unit
module ExecutionUnit(out, opA, opB, func, auxFunc);
   output [31:0] out;
   input [31:0]  opA, opB;
   input [2:0] 	 func;
   input [6:0] 	 auxFunc;

  reg [31:0] result;
  
  always @(*) begin
    case({func, auxFunc})
      // artithmetic operations
      10'b000_0000000: result <= opA + opB; // ADD, assume no overflow bit
      10'b000_0100000: result <= opA - opB; // SUB
      // logic operations
      10'b111_0000000: result <= opA & opB; // AND
      10'b110_0000000: result <= opA | opB; // OR
      10'b100_0000000: result <= opA ^ opB; // XOR
      // shift operations
      10'b001_0000000: result <= $unsigned(opA) << opB; // SLL
      10'b101_0000000: result <= $unsigned(opA) >> opB; // SRL
      10'b010_0000000: result <= ($signed(opA) < $signed(opB)) ? 32'b1 : 32'b0; // SLT
      10'b011_0000000: result <= ($unsigned(opA) < $unsigned(opB))? 32'b1 : 32'b0; // SLTU
      10'b101_0100000: result <= ($signed(opA) >>> $unsigned(opB)); // SRA
  endcase
  end

  assign out = result;

   
endmodule // ExecutionUnit
