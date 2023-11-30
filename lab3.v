// Northwestern - CompEng 361 - Lab2
// Groupname: SmartArch
// NetIDs: tht5102, dsn9734 

// Definition of ISA Encoding
`define OPCODE_COMPUTE    7'b0110011
`define OPCODE_BRANCH     7'b1100011
`define OPCODE_LOAD       7'b0000011
`define OPCODE_STORE      7'b0100011 
`define OPCODE_COMPUTE_I  7'b0010011
`define OPCODE_LUI        7'b0110111
`define OPCODE_AUIPC      7'b0010111
`define OPCODE_JUMP       7'b1101111
`define OPCODE_JUMPR      7'b1100111

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

// Memory Size
`define SIZE_BYTE  2'b00
`define SIZE_HWORD 2'b01
`define SIZE_WORD  2'b10

module PipelinedCPU(halt, clk, rst);
  output halt;
  input clk, rst;


  /**************************IF Stage Begin*************************************/
  // pipeline registers
  reg[31:0] IF_ID_InstWord;
  reg[31:0] Old_PC_IF; // used for branch instructions

  // define module instances
  wire [31:0] PC , NPC, PC_Plus_4; // PC and NPC
  wire [31:0] InstWord ; 
  wire IF_BranchTaken ; 
  wire [31:0] IF_branch_offset ;

  // updating the module intsances
  assign IF_BranchTaken = EX_IF_BranchTaken;

  // assign halt = IF_BranchTaken; 
  assign IF_branch_offset = EX_IF_branch_offset;
  assign PC_Plus_4 = PC + 4; // PC + 4


  ////// has bug for branch offset !!!! currently using +8 
  assign NPC = (IF_BranchTaken === 1) ? (EX_IF_PC + 8) : PC_Plus_4; // calculate the next PC
  ////// has bug for NPC!!!!



  Reg PC_REG(.Din(NPC), .Qout(PC), .WEN(1'b0), .CLK(clk), .RST(rst));
  InstMem IMEM(.Addr(PC), .Size(`SIZE_WORD), .DataOut(InstWord), .CLK(clk));

  // updating pipeline registers
  always @(negedge clk) begin
    IF_ID_InstWord <= InstWord;
    Old_PC_IF <= PC_Plus_4;
  end
  /**************************IF Stage End *************************************/




  /**************************ID Stage Begin*************************************/
  // pipeline registers
  reg [31:0] ID_EX_OpA, ID_EX_OpB; 
  reg [31:0] Old_PC_ID; // used for branch instructions
  reg signed [31:0] ID_EX_branch_offset;
  reg signed [31:0] ID_EX_store_offset;
  reg [2:0]  ID_EX_Func3;
  reg [6:0]  ID_EX_Func7;
  reg [4:0]  ID_EX_Rdst, ID_EX_Rsrc1, ID_EX_Rsrc2; 
  reg [1:0]  ID_EX_MemSize;
  reg ID_EX_IsRtype, ID_EX_IsItype, ID_EX_IsIshift , ID_EX_IsStore, ID_EX_IsLoad, ID_EX_IsBranch, ID_EX_IsLui;
  reg ID_EX_halt_signal ;
  reg [31:0] ID_EX_LargeImm;

  // define module instances
  wire [6:0]  opcode;
  wire [6:0]  funct7;
  wire [2:0]  funct3;
  wire known_type ;
  wire IsRtype , IsItype , IsIshift, IsStore, IsLoad, IsBranch, IsLui ;
  wire [31:0] shamt;
  wire signed [31:0] imm_ext;
  wire signed [31:0] store_offset ;
  wire signed [31:0] imm_branch;
  wire [4:0]  Rsrc1_ID, Rsrc2_ID, Rdst_ID, Rdst_actual;
  wire [31:0] Rdata1_ID, Rdata2_ID, RWrdata_ID;
  wire [31:0] Rdata1_fresh, Rdata2_fresh; // to resolve data hazard
  wire [31:0] LargeImm;
  wire        RWrEn_ID;
  wire [1:0]  MemSize;

  // updating the module intsances
  assign opcode = IF_ID_InstWord[6:0];
  assign funct7 = IF_ID_InstWord[31:25];
  assign funct3 = IF_ID_InstWord[14:12];
  assign shamt = { {27{1'b0}} , IF_ID_InstWord[24:20] };   // shift amount for I type
  assign imm_ext = { {20{IF_ID_InstWord[31]}}, IF_ID_InstWord[31:20] }; // sign extension for I type
  assign Rsrc1_ID = IF_ID_InstWord[19:15];
  assign Rsrc2_ID = IF_ID_InstWord[24:20];
  assign Rdst_ID = IF_ID_InstWord[11:7];
  assign RWrEn_ID = (WB_ID_IsStore) ;// only store is not enable for register update 
  assign Rdst_actual = WB_Rdst; // get the actual Rdst from WB stage

  assign RWrdata_ID = WB_ForwardedData; // get the forwarded data from WB stage

  assign store_offset = { {20{IF_ID_InstWord[31]}}, IF_ID_InstWord[31:25], IF_ID_InstWord[11:7] };
  assign imm_branch = { {19{IF_ID_InstWord[31]}} ,IF_ID_InstWord[31], IF_ID_InstWord[7], IF_ID_InstWord[30:25], IF_ID_InstWord[11:8], {1'b0} } ;
  
  // lui immediate value
  assign LargeImm= ( { {12{IF_ID_InstWord[31]}}, IF_ID_InstWord[31:12] }  << 12);

  assign IsRtype = (opcode == `OPCODE_COMPUTE) && 
  ( (funct3 == `FUNC_ADD) || (funct3 == `FUNC_SUB) || (funct3 == `FUNC_SLL) || (funct3 == `FUNC_SLT) || (funct3 == `FUNC_SLTU) || (funct3 == `FUNC_XOR) || (funct3 == `FUNC_SRL) || (funct3 == `FUNC_SRA) || (funct3 == `FUNC_OR) || (funct3 == `FUNC_AND) )&& 
  ( (funct7 == `AUX_FUNC_ADD) || (funct7 == `AUX_FUNC_SUB) || (funct7 == `AUX_FUNC_SLL) || (funct7 == `AUX_FUNC_SLT) || (funct7 == `AUX_FUNC_SLTU) || (funct7 == `AUX_FUNC_XOR) || (funct7 == `AUX_FUNC_SRL) || (funct7 == `AUX_FUNC_SRA) || (funct7 == `AUX_FUNC_OR) || (funct7 == `AUX_FUNC_AND));

  assign IsItype = (opcode == `OPCODE_COMPUTE_I) &&
  ( (funct3 == `FUNC_ADDI) || (funct3 == `FUNC_SLTI) || (funct3 == `FUNC_SLTIU) || (funct3 == `FUNC_XORI) || (funct3 == `FUNC_ORI) || (funct3 == `FUNC_ANDI) );
  
  assign IsIshift = (opcode == `OPCODE_COMPUTE_I) && 
  ((funct3 == `FUNC_SLLI) || (funct3 == `FUNC_SRLI) || (funct3 == `FUNC_SRAI) ) && ((funct7 == `AUX_FUNC_SLLI) || (funct7 == `AUX_FUNC_SRLI) || (funct7 == `AUX_FUNC_SRAI));

  assign IsStore = (opcode == `OPCODE_STORE) &&
  ( (funct3 == `FUNC_SB) || (funct3 == `FUNC_SH) || (funct3 == `FUNC_SW) );

  assign IsLoad = (opcode == `OPCODE_LOAD) && 
  ( (funct3 == `FUNC_LB) || (funct3 == `FUNC_LH) || (funct3 == `FUNC_LW) || (funct3 == `FUNC_LBU) || (funct3 == `FUNC_LHU) );

  assign IsBranch = (opcode == `OPCODE_BRANCH) && 
  (funct3 == `FUNC_BEQ || funct3 == `FUNC_BNE || funct3 == `FUNC_BLT || funct3 == `FUNC_BGE || funct3 == `FUNC_BLTU || funct3 == `FUNC_BGEU);

  assign IsLui = (opcode == `OPCODE_LUI);

  assign known_type = (IsRtype || IsItype || IsIshift || IsStore || IsLoad || IsBranch || IsLui ) ;

  // halt after 4 cycles after ID to ensure instruction before is finished
  assign halt = WB_ID_haltsignal ;

  assign MemSize = ( (funct3 == `FUNC_SB ) || (funct3 == `FUNC_LB)  || (funct3==`FUNC_LBU) ) ? `SIZE_BYTE 
                  : ( (funct3 == `FUNC_SH) || (funct3 == `FUNC_LH) || (funct3 ==`FUNC_LHU) ) ? `SIZE_HWORD 
                  : `SIZE_WORD;


  RegFile RF(.AddrA(Rsrc1_ID), .DataOutA(Rdata1_ID), 
      .AddrB(Rsrc2_ID), .DataOutB(Rdata2_ID), 
      .AddrW(Rdst_actual), .DataInW(RWrdata_ID), .WenW(RWrEn_ID), .CLK(clk));

  assign Rdata1_fresh = (Rdst_actual === Rsrc1_ID) ? RWrdata_ID : Rdata1_ID; // enable data forwarding to resolve data hazard
  assign Rdata2_fresh = (Rdst_actual === Rsrc2_ID) ? RWrdata_ID : Rdata2_ID; 
  
  // updating pipeline registers
  always @(negedge clk) begin
    if (EX_IF_BranchTaken) begin
      // flush the pipeline
      ID_EX_OpA <= 32'b0;
      ID_EX_OpB <= 32'b0;
      ID_EX_Func3 <= 3'b0;
      ID_EX_Func7 <= 7'b0;
      ID_EX_Rdst <= 5'b0;
      ID_EX_Rsrc1 <= 5'b0;
      ID_EX_Rsrc2 <= 5'b0;
      ID_EX_IsRtype <= 1'b0;
      ID_EX_IsItype <= 1'b0;
      ID_EX_IsIshift <= 1'b0;
      ID_EX_IsStore <= 1'b0;
      ID_EX_IsLoad <= 1'b0;
      ID_EX_IsBranch <= 1'b0;
      ID_EX_store_offset <= 32'b0;
      ID_EX_branch_offset <= 32'b0;
      ID_EX_MemSize <= 2'b0;
      Old_PC_ID <= 32'b0;
    end 
    else begin
      ID_EX_OpA <=  Rdata1_fresh ; // enable data forwarding to resolve data hazard
      ID_EX_OpB <= (IsRtype) ? Rdata2_fresh
                  : (IsItype) ? imm_ext 
                  : (IsIshift) ? shamt 
                  : (IsStore) ? Rdata2_fresh
                  : (IsLoad) ? imm_ext 
                  : 32'b0; // get the operand B
      ID_EX_Func3 <= funct3;
      ID_EX_Func7 <= funct7;
      ID_EX_Rdst <= Rdst_ID;
      ID_EX_Rsrc1 <= Rsrc1_ID;
      ID_EX_Rsrc2 <= Rsrc2_ID;
      ID_EX_IsRtype <= IsRtype;
      ID_EX_IsItype <= IsItype;
      ID_EX_IsIshift <= IsIshift;
      ID_EX_IsStore <= IsStore;
      ID_EX_IsLoad <= IsLoad;
      ID_EX_IsBranch <= IsBranch;
      ID_EX_IsLui <= IsLui;
      ID_EX_store_offset <= store_offset;
      ID_EX_branch_offset <= imm_branch;
      ID_EX_MemSize <= MemSize;
      Old_PC_ID <= Old_PC_IF;
      ID_EX_halt_signal <=  !(known_type) ;
      ID_EX_LargeImm <= LargeImm;
    end
  end
  /**************************ID Stage End *************************************/




  /**************************EX Stage Begin*************************************/
  // pipeline registers
  reg [31:0] EX_MEM_ALUresult;
  reg [31:0] EX_MEM_Store_Data;
  reg [4:0]  EX_MEM_Rdst;
  reg signed [31:0] EX_MEM_DataAddr;
  reg [1:0] EX_MEM_MemSize;
  reg EX_MEM_IsStore, EX_MEM_IsLoad;
  reg [2:0] EX_MEM_Func3;
  reg EX_IF_BranchTaken ;
  reg signed [31:0] EX_IF_branch_offset;
  reg [31:0] EX_IF_PC ; 
  reg EX_MEM_halt_signal ;
  reg EX_MEM_IsLui ; 
  reg [31:0]  EX_MEM_LargeImm ;

  // define module instances
  wire [31:0] ALUresult;
  wire [31:0] DataAddr_EX, store_offset_EX; // calcualte the data address for load and store
  wire [31:0] OpA, OpB;
  wire [2:0]  func_EX;
  wire [6:0]  auxFunc_EX;
  wire IsRtype_EX, IsItype_EX, IsIshift_EX, IsStore_EX, IsLoad_EX;
  wire branchTaken ; 
  wire beqtaken, bnetaken, blttaken, bgetaken, bltutaken, bgeutaken;
  wire BadAddr_EX;

  // updating the module intsances
  assign OpA = (EX_MEM_Rdst === ID_EX_Rsrc1) ? EX_MEM_ALUresult 
              : (MEM_WB_Rdst === ID_EX_Rsrc1) ? MEM_WB_ALUresult 
              : (WB_Rdst === ID_EX_Rsrc1) ? WB_ForwardedData
              : ID_EX_OpA; // enable data forwarding to resolve data hazard
  assign OpB =  (EX_MEM_Rdst === ID_EX_Rsrc2) ? EX_MEM_ALUresult 
              : (MEM_WB_Rdst === ID_EX_Rsrc2) ? MEM_WB_ALUresult
              : (WB_Rdst === ID_EX_Rsrc2) ? WB_ForwardedData
              : ID_EX_OpB; // enable data forwarding to resolve data hazard
  assign func_EX = ID_EX_Func3;
  assign auxFunc_EX = ID_EX_Func7;
  assign IsRtype_EX = ID_EX_IsRtype;
  assign IsItype_EX = ID_EX_IsItype;
  assign IsIshift_EX = ID_EX_IsIshift;
  assign IsStore_EX = ID_EX_IsStore;
  assign IsLoad_EX = ID_EX_IsLoad;
  assign store_offset_EX = ID_EX_store_offset;
  assign DataAddr_EX = (IsStore_EX) ? (OpA + store_offset_EX) : (IsLoad_EX) ? (OpA + OpB) : 32'b0; // calculate the data address for load and store
  
  
  ExecutionUnit EU(.out(ALUresult), .opA(OpA), .opB(OpB), .func(ID_EX_Func3), .auxFunc(ID_EX_Func7), .IsRtype(IsRtype_EX), .IsItype(IsItype_EX), .IsIshift(IsIshift_EX));


  // resolve branch taken condition 
  assign beqtaken = ((IsBranch) && (funct3 == `FUNC_BEQ))? (OpA == OpB) : 1'b0;
  assign bnetaken = ((IsBranch) && (funct3 == `FUNC_BNE))? (OpA != OpB) : 1'b0;
  assign blttaken = ((IsBranch) && (funct3 == `FUNC_BLT))? ($signed(OpA) < $signed(OpB)) : 1'b0;
  assign bgetaken = ((IsBranch) && (funct3 == `FUNC_BGE))? ($signed(OpA) >= $signed(OpB)) : 1'b0;
  assign bltutaken = ((IsBranch) && (funct3 == `FUNC_BLTU))? ($unsigned(OpA) < $unsigned(OpB)) : 1'b0;
  assign bgeutaken = ((IsBranch) && (funct3 == `FUNC_BGEU) )? ($unsigned(OpA) >= $unsigned(OpB)) : 1'b0;

  // any of branch taken is true then taken 
  assign branchTaken = ( (beqtaken) || (bnetaken) || (blttaken) || (bgetaken) || (bltutaken) || (bgeutaken) );


  // updating pipeline registers
  always @(negedge clk) begin
    EX_MEM_ALUresult <= ALUresult;
    EX_MEM_Rdst <= ID_EX_Rdst;
    EX_MEM_DataAddr <= DataAddr_EX;
    EX_MEM_MemSize <= ID_EX_MemSize;
    EX_MEM_Store_Data <= OpB;
    EX_MEM_IsStore <= IsStore_EX;
    EX_MEM_IsLoad <= IsLoad_EX;
    EX_IF_BranchTaken <= branchTaken;
    EX_IF_branch_offset <= ID_EX_branch_offset;
    EX_MEM_Func3 <= ID_EX_Func3;
    EX_IF_PC <= Old_PC_ID;
    EX_MEM_halt_signal <= ID_EX_halt_signal ;
    EX_MEM_IsLui <= ID_EX_IsLui ;
    EX_MEM_LargeImm <= ID_EX_LargeImm ;
  end
  /**************************EX Stage End**************************************/


  /*************************MEM Stage Begin*************************************/
  // pipeline registers
  reg [31:0] MEM_WB_ALUresult;
  reg [31:0] MEM_WB_LoadData;
  reg [4:0]  MEM_WB_Rdst;
  reg MEM_WB_IsLoad, MEM_WB_IsStore;
  reg MEM_WB_halt_signal ;
  reg [31:0] MEM_WB_LargeImm ;
  reg MEM_WB_IsLui ;

  // define module instances
  wire [31:0] DataAddr_MEM;
  wire [31:0] StoreData_MEM;
  wire [31:0] DataWord; // data word read from memory
  wire [1:0] MemSize_MEM;
  wire [2:0] func3_MEM;
  wire MemWrEn;

  // updating the module intsances
  assign DataAddr_MEM = EX_MEM_DataAddr;
  assign MemSize_MEM = EX_MEM_MemSize;
  assign MemWrEn = !EX_MEM_IsStore; // only enable store in MEM stage
  assign StoreData_MEM = EX_MEM_Store_Data;
  assign func3_MEM = EX_MEM_Func3;

  DataMem DMEM(.Addr(DataAddr_MEM), .Size(MemSize_MEM), .DataIn(StoreData_MEM), .DataOut(DataWord), .WEN(MemWrEn), .CLK(clk));


  // updating pipeline registers
  always @(negedge clk) begin
    MEM_WB_ALUresult <= EX_MEM_ALUresult;
    MEM_WB_Rdst <= EX_MEM_Rdst;
    MEM_WB_LoadData <=(
                  ( func3_MEM == `FUNC_LBU ) ? (DataWord & 32'h000000ff) :
                  ( func3_MEM == `FUNC_LHU ) ? (DataWord & 32'h0000ffff) :
                  ( func3_MEM == `FUNC_LB ) ? ( { {24{DataWord[7]}}, DataWord[7:0] }) :
                  ( func3_MEM == `FUNC_LH ) ? ( { {16{DataWord[15]}}, DataWord[15:0] }) :
                  DataWord
    ) ;
    MEM_WB_IsLoad <= EX_MEM_IsLoad;
    MEM_WB_IsStore <= EX_MEM_IsStore;
    MEM_WB_halt_signal <= EX_MEM_halt_signal ;
    MEM_WB_LargeImm <= EX_MEM_LargeImm ;
    MEM_WB_IsLui <= EX_MEM_IsLui ;
  end
  /*************************MEM Stage End***************************************/


  /*************************WB Stage Begin**************************************/
  // pipeline registers
  reg [31:0] WB_ForwardedData;
  reg [4:0]  WB_Rdst;
  reg WB_ID_IsStore ; 
  reg WB_ID_haltsignal ;

  // define module instances
  wire [31:0] ALUresult_WB;
  wire [4:0]  Rdst_WB;
  wire IsLoad_WB, IsLui_WB;
  wire [31:0] LargeImm_WB ;

  // updating the module intsances
  assign ALUresult_WB = MEM_WB_ALUresult;
  assign Rdst_WB = MEM_WB_Rdst;
  assign IsLoad_WB = MEM_WB_IsLoad;
  assign IsLui_WB = MEM_WB_IsLui ;
  assign LargeImm_WB = MEM_WB_LargeImm ;


  // forward the data to the ID state in order to write back 
  always @(negedge clk) begin
    WB_ForwardedData <= (IsLoad_WB) ? MEM_WB_LoadData
                        : (IsLui_WB) ? LargeImm_WB
                        : ALUresult_WB;
    WB_Rdst <= Rdst_WB;
    WB_ID_IsStore <= MEM_WB_IsStore;
    WB_ID_haltsignal <= MEM_WB_halt_signal ;
  end
  /*************************WB Stage End****************************************/
endmodule // PipelinedCPU


// EU provide ALU result for R and I type instructions
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
      10'b001_0000000: result <= $unsigned(opA) << $unsigned(opB);
      // srli
      10'b101_0000000: result <= $unsigned(opA) >> $unsigned(opB);
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