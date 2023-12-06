// Northwestern - CompEng 361 - Lab2
// Groupname: SmartArch
// NetIDs: tht5102, dsn9734 


/***
README:
Implement a pipelined CPU with the following features:
1. 5-stage pipeline
2. Full data forwarding to resolve data hazard
3. Branch prediction and pipeline flush if misprediction
4. Stall for load-use hazard

Note:
1. Since the library modules are required to use, and can only instance once,
but ID and WB both require register file instance,
so WB stage will not update register file immediately, instead forwarding the 
data to ID stage, and ID stage will update the register file in the next cycle. 
Which create one more cycle delay for register file update.

2. Branch prediction is decided in EX stage, always predict not taken. 
If branch Taken, then flush the EX and ID stage for next cycle, and fetch 
the correct instruction in IF stage in the next cycle.

3. Jump is decided in the ID stage, and flush the ID stage in the next cycle, 
also fetch the correct instruction in IF stage in the next cycle.

4. Data forwarding are fully implemented. The forwarding can resolve the RAW hazard except
for the load-use case. The load-use case will stall the pipeline for one cycle.

5. Load-use is detected at the ID stage, then insert a nop to the next cycle and 
hold the pipeline for one cycle in IF stage stoping fetching the next instruction.
***/

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

  ////// pipeline registers ////////
  reg[31:0] IF_ID_InstWord;
  reg[31:0] IF_ID_PC;  // current PC in IF stage 

  ///// define module instances /////
  wire [31:0] PC , NPC, PC_Plus_4 ; 
  wire [31:0] Fetch_PC; // PC addr to fetch instruction
  wire [31:0] InstWord ; 
  wire IF_BranchTaken, IF_Jump_Taken ; // resolved branch taken signal from ID/EXE
  wire [31:0] IF_Jump_Addr, IF_Branch_Addr ;

  ////// updating the module intsances //////
  assign IF_BranchTaken = EX_IF_BranchTaken;
  assign IF_Jump_Taken = ID_IF_Jump_Taken ;
  assign IF_Branch_Addr = EX_IF_PC + EX_IF_branch_offset;
  assign IF_Jump_Addr = ID_IF_Jump_Addr ; 
  assign PC_Plus_4 = PC + 4; // PC + 4
  /* 
  * If branch taken, update NPC = branch_addr + 4, else NPC = PC + 4
  */
  assign NPC = (IF_BranchTaken === 1) ? (IF_Branch_Addr + 4) 
              : (IF_Jump_Taken === 1) ? (IF_Jump_Addr + 4)
              : (Load_Use_Need_Stall_ID === 1) ? (PC) // stall if load use hazard
              : PC_Plus_4; 
  /* 
  * If branch taken, then fetch the instruction from the branch address other than PC
  */
  assign Fetch_PC = (IF_BranchTaken === 1) ? (IF_Branch_Addr) 
                    : (IF_Jump_Taken === 1) ? (IF_Jump_Addr)
                    : PC ; 
  /*
  * Updating PC and NPC, should monitor Fetch_PC other than PC!
  */
  Reg PC_REG(.Din(NPC), .Qout(PC), .WEN(1'b0), .CLK(clk), .RST(rst));
  InstMem IMEM(.Addr(Fetch_PC), .Size(`SIZE_WORD), .DataOut(InstWord), .CLK(clk));

  /////// updating pipeline registers ///////
  always @(negedge clk) begin
    if (Load_Use_Need_Stall_ID) begin
      // stall 
    end
    else begin
      IF_ID_InstWord <= InstWord;
      IF_ID_PC <= Fetch_PC;
    end 
  end

  /**************************IF Stage End *************************************/




  /**************************ID Stage Begin*************************************/
  
  /////// pipeline registers ////////
  reg [31:0] ID_EX_OpA, ID_EX_OpB; 
  reg [31:0] Old_PC_ID; // passing the PC from IF 
  reg signed [31:0] ID_EX_branch_offset, ID_EX_store_offset;
  reg [2:0]  ID_EX_Func3;
  reg [6:0]  ID_EX_Func7;
  reg [4:0]  ID_EX_Rdst, ID_EX_Rsrc1, ID_EX_Rsrc2; 
  reg [1:0]  ID_EX_MemSize;
  reg ID_EX_IsRtype, ID_EX_IsItype, ID_EX_IsIshift, 
      ID_EX_IsStore, ID_EX_IsLoad, ID_EX_IsBranch, 
      ID_EX_IsLui, ID_EX_IsAuiPC, ID_EX_IsJump; // signals pass to next stage 
  reg ID_EX_halt_signal ;
  reg Jump_Taken_Flush ;
  reg ID_IF_Jump_Taken ;
  reg [31:0] ID_IF_Jump_Addr ; 

  /////// define module instances //////
  /*
  * Decode signals/offset for current instructions
  */
  wire [6:0]  opcode;
  wire [6:0]  funct7;
  wire [2:0]  funct3;
  wire known_type ;
  wire IsRtype , IsItype , IsIshift, IsStore, IsLoad, 
      IsBranch, IsLui, IsAuiPC, IsJump, IsJALR, IsJAL;
  wire [31:0] shamt;
  wire signed [31:0] imm_ext, store_offset, imm_branch;
  wire [31:0] Rdata1_ID, Rdata2_ID, RWrdata_ID;
  wire        RWrEn_ID;
  wire [4:0]  Rsrc1_ID, Rsrc2_ID, Rdst_ID, Rdst_actual;
  wire [1:0]  MemSize;
  wire [31:0] LargeImm, jal_imm;
  wire [31:0] Rdata1_fresh, Rdata2_fresh; // to resolve data hazard
  /*
  * Stall signal for load-use hazard
  */
  wire Load_Use_Need_Stall_ID ; 

  /////// updating the module intsances ////////
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
  /*
  * Write Data is from WB stage instead of current stage
  */
  assign RWrdata_ID = WB_ForwardedData; 
  /*
  * Calculate the offset 
  */
  assign store_offset = { {20{IF_ID_InstWord[31]}}, IF_ID_InstWord[31:25], IF_ID_InstWord[11:7] };
  assign imm_branch = { {19{IF_ID_InstWord[31]}} ,IF_ID_InstWord[31], IF_ID_InstWord[7], IF_ID_InstWord[30:25], IF_ID_InstWord[11:8], {1'b0} } ;
  assign LargeImm = ( { {12{IF_ID_InstWord[31]}}, IF_ID_InstWord[31:12] });
  assign jal_imm =  { {12{IF_ID_InstWord[31]}}, IF_ID_InstWord[31],  IF_ID_InstWord[19:12], IF_ID_InstWord[20], IF_ID_InstWord[30:21]  } << 1 ;
  assign MemSize = ( (funct3 == `FUNC_SB ) || (funct3 == `FUNC_LB)  || (funct3==`FUNC_LBU) ) ? `SIZE_BYTE 
                  : ( (funct3 == `FUNC_SH) || (funct3 == `FUNC_LH) || (funct3 ==`FUNC_LHU) ) ? `SIZE_HWORD 
                  : `SIZE_WORD;
  /*
  * Determine the instruction type
  */
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
  assign IsAuiPC = (opcode == `OPCODE_AUIPC);
  assign IsJump = (opcode == `OPCODE_JUMP || opcode == `OPCODE_JUMPR );
  assign IsJALR = (opcode == `OPCODE_JUMPR) && (funct3 == `FUNC_JALR);
  assign IsJAL = (opcode == `OPCODE_JUMP) ;
  /*
  * Only Known type of instruction can be executed
  */
  assign known_type = (IsRtype || IsItype || IsIshift || IsStore || IsLoad || IsBranch || IsJump || IsLui || IsAuiPC) ;
  /* 
  * halt after 4 cycles after ID to ensure instructions before are finished
  */
  assign halt = WB_ID_haltsignal ;
  /*
  * Resolve the data hazard by forwarding the data from WB stage
  */
  assign Rdata1_fresh = (Rdst_actual === Rsrc1_ID) ? RWrdata_ID : Rdata1_ID; 
  assign Rdata2_fresh = (Rdst_actual === Rsrc2_ID) ? RWrdata_ID : Rdata2_ID; 
  /*
  * If Last cycle is a load 
  * and current cycle is a use (R and I type)
  * and they have RAW hazard, then stall 
  */ 
  assign Load_Use_Need_Stall_ID =( (IsRtype || IsIshift || IsItype)
                                   && (ID_EX_IsLoad) 
                                   && ( (Rsrc1_ID === ID_EX_Rdst) || (Rsrc2_ID === ID_EX_Rdst) ) ) ;
  /*
  * Updating the register file instance
  */
  RegFile RF(.AddrA(Rsrc1_ID), .DataOutA(Rdata1_ID), 
      .AddrB(Rsrc2_ID), .DataOutB(Rdata2_ID), 
      .AddrW(Rdst_actual), .DataInW(RWrdata_ID), .WenW(RWrEn_ID), .CLK(clk));

  
  ///////  updating pipeline registers ///////
  always @(negedge clk) begin
    /*
    * Flush the pipeline if branch/jump is taken 
    * or load use hazard (inserting a nop)
    */
    if (EX_ID_Need_Flush || Jump_Taken_Flush || Load_Use_Need_Stall_ID) begin
      ID_EX_OpA <= 0;
      ID_EX_OpB <= 0;
      ID_EX_Func3 <= 0;
      ID_EX_Func7 <= 0;
      ID_EX_Rdst <= 0;
      ID_EX_Rsrc1 <= 0;
      ID_EX_Rsrc2 <= 0;
      ID_EX_IsRtype <= 0;
      ID_EX_IsItype <= 0;
      ID_EX_IsIshift <= 0;
      ID_EX_IsStore <= 0;
      ID_EX_IsLoad <= 0;
      ID_EX_IsBranch <= 0;
      ID_EX_IsAuiPC <= 0;
      ID_EX_IsLui <= 0;
      ID_EX_store_offset <= 0;
      ID_EX_branch_offset <= 0;
      ID_EX_MemSize <= 0;
      Old_PC_ID <= 0;
      ID_EX_halt_signal <= 0 ;
      ID_IF_Jump_Addr <= 0 ;
      ID_IF_Jump_Taken <= 0 ;
      Jump_Taken_Flush <= 0 ; // reset the flush signal
      EX_ID_Need_Flush <= 0; // reset the need flush signal
    end
    else begin
      ID_EX_OpA <= (IsLui || IsAuiPC) ? LargeImm
                  : (IsJump) ? IF_ID_PC
                  : Rdata1_fresh ; // enable data forwarding to resolve data hazard
      ID_EX_OpB <= (IsRtype || IsBranch) ? Rdata2_fresh
                  : (IsItype) ? imm_ext 
                  : (IsIshift) ? shamt 
                  : (IsStore) ? Rdata2_fresh
                  : (IsLoad) ? imm_ext 
                  : (IsAuiPC) ? IF_ID_PC 
                  : (IsJump) ? 4
                  : 32'hffffffff; // for testing purpose
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
      ID_EX_IsAuiPC <= IsAuiPC;
      ID_EX_IsJump <= IsJump;
      ID_EX_IsLui <= IsLui;
      ID_EX_store_offset <= store_offset;
      ID_EX_branch_offset <= imm_branch;
      ID_EX_MemSize <= MemSize;
      Old_PC_ID <= IF_ID_PC;
      ID_EX_halt_signal <=  !(known_type) ;
      ID_IF_Jump_Addr <= (IsJAL) ? (IF_ID_PC + jal_imm) 
                        : (IsJALR) ? (Rdata1_fresh + imm_ext)
                        : 32'h00000000 ;
      ID_IF_Jump_Taken <= (IsJump) ;
      Jump_Taken_Flush <= (IsJump) ; // flush the ID for next cycle if jump taken
    end
  end

  /**************************ID Stage End *************************************/


  /**************************EX Stage Begin*************************************/

  ////////  pipeline registers /////////
  reg [31:0] EX_MEM_ALUresult;
  reg [31:0] EX_MEM_Store_Data;
  reg [4:0]  EX_MEM_Rdst, EX_MEM_RStore_Src;
  reg signed [31:0] EX_MEM_DataAddr;
  reg [1:0] EX_MEM_MemSize;
  reg EX_MEM_IsStore, EX_MEM_IsLoad;
  reg [2:0] EX_MEM_Func3;
  reg EX_IF_BranchTaken ;
  reg signed [31:0] EX_IF_branch_offset;
  reg [31:0] EX_IF_PC ; 
  reg EX_MEM_halt_signal ;
  reg EX_Need_Flush, EX_ID_Need_Flush ;

  /////////  define module instances ///////////
  wire [31:0] ALUresult;
  wire [31:0] DataAddr_EX, store_offset_EX; // calcualte the data address for load and store
  wire [31:0] OpA, OpB;
  wire [2:0]  func_EX;
  wire [6:0]  auxFunc_EX;
  wire IsRtype_EX, IsItype_EX, IsIshift_EX, IsStore_EX, IsLoad_EX, IsLui_EX, IsAuiPC_EX, IsBranch_EX, IsJump_EX;
  wire branchTaken ; 
  wire beqtaken, bnetaken, blttaken, bgetaken, bltutaken, bgeutaken;

  /////// updating the module intsances //////// 
  /*
  * Forward the data from EX MEM WB stage if there is RAW hazard
  * Do Not forwarding for specific kind types of instructions
  */
  assign OpA = (IsLui_EX || IsLui_EX || IsJump_EX) ? ID_EX_OpA // U J type does not forward opA
              : (EX_MEM_Rdst === ID_EX_Rsrc1) ? EX_MEM_ALUresult 
              : (MEM_WB_Rdst === ID_EX_Rsrc1) ? MEM_EX_ForwardedData 
              : (WB_Rdst === ID_EX_Rsrc1) ? WB_ForwardedData
              : ID_EX_OpA; // enable data forwarding to resolve data hazard
  assign OpB =  (IsItype_EX || IsIshift_EX || IsLoad_EX || IsAuiPC_EX || IsLui_EX || IsJump_EX) ? ID_EX_OpB // I type, U, J type does not forward opB 
              :(EX_MEM_Rdst === ID_EX_Rsrc2) ? EX_MEM_ALUresult 
              : (MEM_WB_Rdst === ID_EX_Rsrc2) ? MEM_EX_ForwardedData
              : (WB_Rdst === ID_EX_Rsrc2) ? WB_ForwardedData
              : ID_EX_OpB; // enable data forwarding to resolve data hazard
  /*
  * Instruction signals from ID 
  */
  assign func_EX = ID_EX_Func3;
  assign auxFunc_EX = ID_EX_Func7;
  assign IsRtype_EX = ID_EX_IsRtype;
  assign IsItype_EX = ID_EX_IsItype;
  assign IsIshift_EX = ID_EX_IsIshift;
  assign IsStore_EX = ID_EX_IsStore;
  assign IsLoad_EX = ID_EX_IsLoad;
  assign IsLui_EX = ID_EX_IsLui;
  assign IsAuiPC_EX = ID_EX_IsAuiPC;
  assign IsJump_EX = ID_EX_IsJump;
  assign IsBranch_EX = ID_EX_IsBranch;
  /*
  * Calculate the data address for load and store separately
  * Not go through the ALU 
  */
  assign store_offset_EX = ID_EX_store_offset;
  assign DataAddr_EX = (IsStore_EX) ? (OpA + store_offset_EX) 
                      : (IsLoad_EX) ? (OpA + OpB) 
                      : 32'b0; // calculate the data address for load and store
  /* 
  * Resolve branch taken condition in EX 
  * Any of branch taken is true then taken 
  */
  assign beqtaken = ((IsBranch_EX) && (ID_EX_Func3 == `FUNC_BEQ))? (OpA == OpB) : 1'b0;
  assign bnetaken = ((IsBranch_EX) && (ID_EX_Func3 == `FUNC_BNE))? (OpA != OpB) : 1'b0;
  assign blttaken = ((IsBranch_EX) && (ID_EX_Func3 == `FUNC_BLT))? ($signed(OpA) < $signed(OpB)) : 1'b0;
  assign bgetaken = ((IsBranch_EX) && (ID_EX_Func3 == `FUNC_BGE))? ($signed(OpA) >= $signed(OpB)) : 1'b0;
  assign bltutaken = ((IsBranch_EX) && (ID_EX_Func3 == `FUNC_BLTU))? ($unsigned(OpA) < $unsigned(OpB)) : 1'b0;
  assign bgeutaken = ((IsBranch_EX) && (ID_EX_Func3 == `FUNC_BGEU) )? ($unsigned(OpA) >= $unsigned(OpB)) : 1'b0;
  assign branchTaken = ( (beqtaken) || (bnetaken) || (blttaken) || (bgetaken) || (bltutaken) || (bgeutaken) );
  /*
  * Execution Unit 
  */
  ExecutionUnit EU(.out(ALUresult), .opA(OpA), .opB(OpB), .func(ID_EX_Func3), .auxFunc(ID_EX_Func7), 
  .IsRtype(IsRtype_EX), .IsItype(IsItype_EX), .IsIshift(IsIshift_EX), .IsLui(IsLui_EX), .IsAuiPC(IsAuiPC_EX), .IsJump(IsJump_EX));

  ////// updating pipeline registers /////// 
  always @(negedge clk) begin
    /*
    * Flush the pipeline if branch is taken 
    */
    if( EX_Need_Flush ) begin
      EX_MEM_ALUresult <= 0;
      EX_MEM_Rdst <= 0;
      EX_MEM_DataAddr <= 0;
      EX_MEM_MemSize <= 0;
      EX_MEM_Store_Data <= 0;
      EX_MEM_IsStore <= 0;
      EX_MEM_IsLoad <= 0;
      EX_IF_BranchTaken <= 0;
      EX_IF_branch_offset <= 32'hdeadbeef;
      EX_MEM_Func3 <= 0;
      EX_IF_PC <= 0;
      EX_MEM_halt_signal <= 0 ;
      EX_MEM_RStore_Src <= 0;
      EX_Need_Flush <= 0; // reset the need flush signal
    end
    else begin
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
      EX_MEM_RStore_Src <= ID_EX_Rsrc2;
      EX_Need_Flush <= branchTaken ; // need to flush the pipeline next cycle if branch taken
      EX_ID_Need_Flush <= branchTaken ; // need to flush the pipeline next cycle if branch taken
    end
  end
  /**************************EX Stage End**************************************/


  /*************************MEM Stage Begin*************************************/

  ////////  pipeline registers //////// 
  reg [31:0] MEM_WB_ALUresult;
  reg [31:0] MEM_WB_LoadData;
  reg [31:0] MEM_EX_ForwardedData; // for load and store 
  reg [4:0]  MEM_WB_Rdst;
  reg MEM_WB_IsLoad, MEM_WB_IsStore;
  reg MEM_WB_halt_signal ;

  /////// define module instances ////////
  wire [31:0] DataAddr_MEM;
  wire [31:0] StoreData_MEM;
  wire [31:0] DataWord  , LoadData_MEM; // data word read from memory
  wire [1:0] MemSize_MEM;
  wire [2:0] func3_MEM;
  wire [4:0] RStore_src ; 
  wire IsLoad_MEM, IsStore_MEM ; 
  wire MemWrEn;

  //////  updating the module intsances ///////
  assign DataAddr_MEM = EX_MEM_DataAddr;
  assign MemSize_MEM = EX_MEM_MemSize;
  assign MemWrEn = !EX_MEM_IsStore; // only enable store in MEM stage
  assign func3_MEM = EX_MEM_Func3;
  assign IsLoad_MEM = EX_MEM_IsLoad;
  assign IsStore_MEM = EX_MEM_IsStore;
  assign RStore_src = EX_MEM_RStore_Src; // the src for store instruction
  /*
  * Loaded memory data word, aligning according to the size
  */
  assign LoadData_MEM = (
                  ( func3_MEM == `FUNC_LBU ) ? (DataWord & 32'h000000ff) :
                  ( func3_MEM == `FUNC_LHU ) ? (DataWord & 32'h0000ffff) :
                  ( func3_MEM == `FUNC_LB ) ? ( { {24{DataWord[7]}}, DataWord[7:0] }) :
                  ( func3_MEM == `FUNC_LH ) ? ( { {16{DataWord[15]}}, DataWord[15:0] }) :
                  DataWord ) ;
  /* 
  * Resolve the memory RAW (lw/sw)
  * Forward the fresh data if this cycle is a store and 
  * the last cycle is a load from memory and they have RAW 
  */
  assign StoreData_MEM = ( (IsStore_MEM) && (MEM_WB_IsLoad) && (RStore_src === MEM_WB_Rdst) )? MEM_WB_LoadData
                        : (EX_MEM_Store_Data);
  /*
  * Updating the memory instance
  */
  DataMem DMEM(.Addr(DataAddr_MEM), .Size(MemSize_MEM), .DataIn(StoreData_MEM), .DataOut(DataWord), .WEN(MemWrEn), .CLK(clk));


  /////// updating pipeline registers //////
  always @(negedge clk) begin
    MEM_WB_ALUresult <= EX_MEM_ALUresult;
    MEM_WB_Rdst <= EX_MEM_Rdst;
    MEM_WB_LoadData <= LoadData_MEM;
    MEM_WB_IsLoad <= EX_MEM_IsLoad;
    MEM_WB_IsStore <= EX_MEM_IsStore;
    MEM_WB_halt_signal <= EX_MEM_halt_signal ;
    /*
    * Determine which data to forward 
    */
    MEM_EX_ForwardedData <= (IsLoad_MEM) ? LoadData_MEM 
                          : EX_MEM_ALUresult; 
  end

  /*************************MEM Stage End***************************************/


  /*************************WB Stage Begin**************************************/

  ///////  pipeline registers //////// 
  reg [31:0] WB_ForwardedData;
  reg [4:0]  WB_Rdst;
  reg WB_ID_IsStore ; 
  reg WB_ID_haltsignal ;

  ////////  define module instances //////// 
  wire [31:0] ALUresult_WB;
  wire [4:0]  Rdst_WB;
  wire IsLoad_WB ;

  //////// updating the module intsances ///////
  assign ALUresult_WB = MEM_WB_ALUresult;
  assign Rdst_WB = MEM_WB_Rdst;
  assign IsLoad_WB = MEM_WB_IsLoad;

  //////// forward the data to the ID state in order to write back //////// 
  always @(negedge clk) begin
    WB_ForwardedData <= (IsLoad_WB) ? MEM_WB_LoadData
                        : ALUresult_WB; // decide the wb data is from memory or ALU
    WB_Rdst <= Rdst_WB;
    WB_ID_IsStore <= MEM_WB_IsStore;
    WB_ID_haltsignal <= MEM_WB_halt_signal ;
  end

  /*************************WB Stage End****************************************/
endmodule // PipelinedCPU


// EU provide ALU result for R and I type instructions
module ExecutionUnit(out, opA, opB, func, auxFunc, IsRtype, IsItype, IsIshift, IsLui, IsAuiPC, IsJump);
   output [31:0] out;
   input [31:0]  opA, opB;
   input [2:0] 	 func;
   input [6:0] 	 auxFunc;
   input IsRtype;
   input IsItype;
   input IsIshift;
   input IsLui;
   input IsAuiPC;
   input IsJump;

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
    else if (IsLui) begin
      result <= (opA << 12) ; // imm << 12 
    end
    else if (IsAuiPC) begin
      result <= opA + opB; // pc + imm
    end
    else if (IsJump) begin
      result <= opA + opB; // pc + 4
    end
    else begin
      result <= 32'b0;
    end
  end

  assign out = result;

   
endmodule // ExecutionUnit