// Northwestern - CompEng 361 - Lab2
// Groupname:
// NetIDs:

// Definition of ISA Encoding
`define OPCODE_COMPUTE    7'b0110011
`define OPCODE_BRANCH     7'b1100011
`define OPCODE_LOAD       7'b0000011
`define OPCODE_STORE      7'b0100011 
`define OPCODE_COMPUTE_I  7'b0010011
`define OPCODE_LUI        7'b0110111
`define OPCODE_AUIPC      7'b0010111
`define OPCODE_JUMP       7'b1101111

// R-type FUNCT3
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

// R-type FUNCT7
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

// I-type FUNCT3
`define FUNC_ADDI     3'b000
`define FUNC_SLLI     3'b001
`define FUNC_SLTI     3'b010
`define FUNC_SLTIU    3'b011
`define FUNC_XORI     3'b100
`define FUNC_SRLI     3'b101
`define FUNC_SRAI     3'b101
`define FUNC_ORI      3'b110
`define FUNC_ANDI     3'b111

// I-type FUNCT7
`define AUX_FUNC_SLLI 7'b0000000
`define AUX_FUNC_SRLI 7'b0000000
`define AUX_FUNC_SRAI 7'b0100000

// S-type FUNCT3
`define FUNC_SB       3'b000
`define FUNC_SH       3'b001
`define FUNC_SW       3'b010

// L-type FUNCT3
`define FUNC_LB       3'b000
`define FUNC_LH       3'b001
`define FUNC_LW       3'b010
`define FUNC_LBU      3'b100
`define FUNC_LHU      3'b101

// B-type FUNCT3
`define FUNC_BEQ      3'b000
`define FUNC_BNE      3'b001
`define FUNC_BLT      3'b100
`define FUNC_BGE      3'b101
`define FUNC_BLTU     3'b110
`define FUNC_BGEU     3'b111

// J-type FUNCT3
`define FUNC_JALR      3'b000



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
  wire [31:0] ALU_Result, LoadData;
  wire        RWrEn;

  wire [31:0] NPC, PC_Plus_4, PC_branch;
  wire [6:0]  opcode;

  wire [6:0]  funct7;
  wire [2:0]  funct3;
  wire signed [31:0] imm_ext;
  wire signed [31:0] imm_branch;
  wire unsigned [31:0] imm_ext_unsigned;
  wire signed [31:0] offset ;
  wire [4:0] shamt;
  wire [31:0] Large_imm, Aui_PC;
  wire [31:0] j_imm, link_rd ; 

  wire [31:0] opB;
  wire branchTaken ; 
  wire beqtaken, bnetaken, blttaken, bgetaken, bltutaken, bgeutaken;

  wire IsRtype, IsItype, IsIshift, IsStore, IsLoad, IsBranch, IsLui, IsAuiPC, IsJump;

  // Only support R-TYPE ADD and SUB
  assign IsRtype = (opcode == `OPCODE_COMPUTE) && 
  ( (funct3 == `FUNC_ADD) || (funct3 == `FUNC_SUB) || (funct3 == `FUNC_SLL) || (funct3 == `FUNC_SLT) || (funct3 == `FUNC_SLTU) || (funct3 == `FUNC_XOR) || (funct3 == `FUNC_SRL) || (funct3 == `FUNC_SRA) || (funct3 == `FUNC_OR) || (funct3 == `FUNC_AND) )
  && ((funct7 == `AUX_FUNC_ADD) || (funct7 == `AUX_FUNC_SUB) || (funct7 == `AUX_FUNC_SLL) || (funct7 == `AUX_FUNC_SLT) || (funct7 == `AUX_FUNC_SLTU) || (funct7 == `AUX_FUNC_XOR) || (funct7 == `AUX_FUNC_SRL) || (funct7 == `AUX_FUNC_SRA) || (funct7 == `AUX_FUNC_OR) || (funct7 == `AUX_FUNC_AND));
  
  assign IsItype = (opcode == `OPCODE_COMPUTE_I) &&
  ( (funct3 == `FUNC_ADDI) || (funct3 == `FUNC_SLTI) || (funct3 == `FUNC_SLTIU) || (funct3 == `FUNC_XORI) || (funct3 == `FUNC_ORI) || (funct3 == `FUNC_ANDI) );

  assign IsIshift = (opcode == `OPCODE_COMPUTE_I) && ((funct3 == `FUNC_SLLI) || (funct3 == `FUNC_SRLI) || (funct3 == `FUNC_SRAI) ) && ((funct7 == `AUX_FUNC_SLLI) || (funct7 == `AUX_FUNC_SRLI) || (funct7 == `AUX_FUNC_SRAI));

  assign IsStore = (opcode == `OPCODE_STORE) && ( (funct3 == `FUNC_SB) || (funct3 == `FUNC_SH) || (funct3 == `FUNC_SW) );

  assign IsLoad = (opcode == `OPCODE_LOAD) && ( (funct3 == `FUNC_LB) || (funct3 == `FUNC_LH) || (funct3 == `FUNC_LW) || (funct3 == `FUNC_LBU) || (funct3 == `FUNC_LHU) );

  assign IsBranch = (opcode == `OPCODE_BRANCH) && (funct3 == `FUNC_BEQ || funct3 == `FUNC_BNE || funct3 == `FUNC_BLT || funct3 == `FUNC_BGE || funct3 == `FUNC_BLTU || funct3 == `FUNC_BGEU);

  assign IsLui = (opcode == `OPCODE_LUI);

  assign IsAuiPC = (opcode == `OPCODE_AUIPC);

  assign IsJump = (opcode == `OPCODE_JUMP);

  assign halt = (!( (IsLoad)|| (IsStore) || (IsBranch)|| (IsJump) || (IsAuiPC) || (IsRtype) || (IsItype)  || (IsIshift) || (IsLui)) ) || (BadAddr); 
    
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
  assign shamt = InstWord[24:20];   // I-Type (for SLLI, SRLI, SRAI)
  // extend the immediate value to 32 bits for I type 
  assign imm_ext = { {20{InstWord[31]}}, InstWord[31:20] };
  assign imm_ext_unsigned = { {20{1'b0}}, InstWord[31:20] };
  // branch offset, original offset is 12 bits, we need to shift it to the left by 1 and add 0 to the LSB
  // then shift again ensuring PC is always divisible by 4
  assign imm_branch = { {19{InstWord[31]}} ,InstWord[31], InstWord[7], InstWord[30:25], InstWord[11:8], {1'b0} } << 1 ;
  // store offset 
  assign offset = { {20{InstWord[31]}}, InstWord[31:25], InstWord[11:7] };
  // lui immediate value
  assign Large_imm = { {12{InstWord[31]}}, InstWord[31:12] } << 12;
  // auipc
  assign Aui_PC = PC + Large_imm;
  // jump immediate value
  assign j_imm = (funct3 == `FUNC_ADDI) ? imm_ext : { 12{InstWord[31]}, InstWord[31],  InstWord[19:12], InstWord[20], InstWord[30:21]  };

  // if it is shift then use the shamt if it is isItype then use the immediate value else use rdata2
  assign opB = (IsItype) ? imm_ext : (IsIshift) ? shamt : Rdata2;

  // used for store & load
  assign DataAddr = IsStore ? (Rdata1 + offset) : ( (funct3 == `FUNC_LBU) || (funct3 == `FUNC_LHU) ) ? (Rdata1 + imm_ext_unsigned) : (Rdata1 + imm_ext);
  assign MemSize = ( (funct3 == `FUNC_SB ) || (funct3 == `FUNC_LB)  || (funct3==`FUNC_LBU) ) ? `SIZE_BYTE : ( (funct3 == `FUNC_SH) || (funct3 == `FUNC_LH) || (funct3 ==`FUNC_LHU) ) ? `SIZE_HWORD : `SIZE_WORD;
  assign StoreData = Rdata2;

  // used for load
  // if it is a load then use dataword, if it is rtype or itype then use the alu result
  assign LoadData = ( (funct3 == `FUNC_LB) || (funct3 == `FUNC_LBU) ) ? (DataWord & 8'hff) : ( (funct3 == `FUNC_LH) || (funct3 == `FUNC_LHU) ) ? (DataWord & 16'hffff) : DataWord;
  
  // linked rd
  assign link_rd = PC + 4;

  // check if it is load or lui or auipc or j type 
  assign RWrdata = (IsLoad) ? LoadData : (IsLui) ? Large_imm : (IsAuiPC) ? Aui_PC : (IsJump) ? link_rd : ALU_Result;
  
  // any load addr should div by 4
  assign BadAddr = (IsLoad) ? (DataAddr[1:0] != 2'b00) : 1'b0;

  // only store should write to the memory
  assign MemWrEn = !IsStore ; 

  // if not branch and not store then write to the register file
  assign RWrEn = (IsBranch || IsStore);

  assign beqtaken = ((IsBranch) && (funct3 == `FUNC_BEQ))? (Rdata1 == Rdata2) : 1'b0;
  assign bnetaken = ((IsBranch) && (funct3 == `FUNC_BNE))? (Rdata1 != Rdata2) : 1'b0;
  assign blttaken = ((IsBranch) && (funct3 == `FUNC_BLT))? (Rdata1 < Rdata2) : 1'b0;
  assign bgetaken = ((IsBranch) && (funct3 == `FUNC_BGE))? (Rdata1 >= Rdata2) : 1'b0;
  assign bltutaken = ((IsBranch) && (funct3 == `FUNC_BLTU))? ($unsigned(Rdata1) < $unsigned(Rdata2)) : 1'b0;
  assign bgeutaken = ((IsBranch) && (funct3 == `FUNC_BGEU) )? ($unsigned(Rdata1) >= $unsigned(Rdata2)) : 1'b0;

  // check the func3 code and assign the branch taken
  assign branchTaken = ( (beqtaken) || (bnetaken) || (blttaken) || (bgetaken) || (bltutaken) || (bgeutaken) );

  // Hardwired to support R-Type instructions -- please add muxes and other control signals
  ExecutionUnit EU(.out(ALU_Result), .opA(Rdata1), .opB(opB), .func(funct3), .auxFunc(funct7), 
                  .IsRtype(IsRtype), .IsItype(IsItype), .IsIshift(IsIshift));

  // Fetch Address Datapath
  assign PC_Plus_4 = PC + 4;
  assign PC_branch = PC + imm_branch ;
  assign NPC = (branchTaken) ? PC_branch : (IsJump) ? (PC + j_imm) : PC_Plus_4;
   
endmodule // SingleCycleCPU


// Incomplete version of Lab1 execution unit
module ExecutionUnit(out, opA, opB, func, auxFunc, IsRtype, IsItype, IsIshift);
   output [31:0] out;
   input [31:0]  opA, opB;
   input [2:0] 	 func;
   input [6:0] 	 auxFunc;
   input IsRtype;
   input IsItype;
   input IsIshift;

  reg [31:0] result;
  
  always @(*) begin
    if (IsRtype) begin
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
    else if (IsItype) begin
      case (func)
      // addi
      3'b000: result <= opA + opB;
      // slti
      3'b010: result <= ($signed(opA) < $signed(opB)) ? 32'b1 : 32'b0;
      // sltiu
      3'b011: result <= ($unsigned(opA) < $unsigned(opB)) ? 32'b1 : 32'b0;
      // xori
      3'b100: result <= opA ^ opB;
      // ori
      3'b110: result <= opA | opB;
      // andi
      3'b111: result <= opA & opB;
      endcase
    end 
    else if (IsIshift) begin
      case({func, auxFunc})
      // slli 
      10'b001_0000000: result <= $unsigned(opA) << opB;
      // srli
      10'b101_0000000: result <= $unsigned(opA) >> opB;
      // srai
      10'b101_0100000: result <= ($signed(opA) >>> $unsigned(opB));
      endcase
    end
    else begin
      result <= 32'b0;
    end
  end

  assign out = result;

   
endmodule // ExecutionUnit
