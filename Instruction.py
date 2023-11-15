# define the class of instruction encoding 
# pls add the remaining encoding of instructions for the testing purpose

class Instruction:
  def __init__(self):
    print("Instructions  Generating...")
    # store the instructions to be tested
    self.myinst = []
    return
  
  def reg2binary(self, decimal):
    binary = format(decimal, '05b')
    return binary
  
  # generate R-type instruction
  def Rtype_Gen(self, funct7, src2, src1, funct3, dst, opcode):
    src1_binary = self.reg2binary(src1)
    src2_binary = self.reg2binary(src2)
    dst_binary = self.reg2binary(dst)
    inst = str(funct7) + src2_binary + src1_binary + str(funct3) + dst_binary + str(opcode)  
    return int(inst, 2)

  def Itype_Gen(self, imm, src1, funct3, dst, opcode):
    src1_binary = self.reg2binary(src1)
    dst_binary = self.reg2binary(dst)
    if (imm < 0):
      imm = 2**12 + imm 
    imm_binary = format(imm, '012b')
    inst = imm_binary + src1_binary + str(funct3) + dst_binary + str(opcode)
    return int(inst, 2)

  def IShift_Gen(self, shamt, src1, funct3, dst, opcode, funct7):
    src1_binary = self.reg2binary(src1)
    dst_binary = self.reg2binary(dst)
    shamt_binary = format(shamt, '05b')
    inst = str(funct7) + shamt_binary + src1_binary + str(funct3) + dst_binary + str(opcode)
    return int(inst, 2)

  
  def Store_Gen(self, src2, src1, imm, funct3, opcode):
    src1_binary = self.reg2binary(src1)
    src2_binary = self.reg2binary(src2)
    if (imm < 0):
      imm = 2**12 + imm 
    imm_binary = format(imm, '012b')
    inst = imm_binary[0:7]+ src2_binary + src1_binary + str(funct3) + imm_binary[7:12] + str(opcode)
    return int(inst, 2)

  def Load_Gen(self, src1, imm, funct3, dst, opcode):
    src1_binary = self.reg2binary(src1)
    dst_binary = self.reg2binary(dst)
    if (imm < 0):
      imm = 2**12 + imm 
    imm_binary = format(imm, '012b')
    inst = imm_binary + src1_binary + str(funct3) + dst_binary + str(opcode)
    return int(inst, 2)

  def Branch_Gen(self, src1, src2, imm, funct3, opcode):
    src1_binary = self.reg2binary(src1)
    src2_binary = self.reg2binary(src2)
    if (imm < 0):
      imm = 2**12 + imm 
    imm_binary = format(imm, '012b')
    print("the branch gen offset if not sure!! pls figure out the encoding")
    exit(1)
    # inst = '0' + imm_binary[1:7] + src2_binary + src1_binary + str(funct3) + imm_binary[7:11] + imm_binary[0] + str(opcode)
    return int(inst, 2)

  def LUI_Gen(self, imm, dst, opcode):
    dst_binary = self.reg2binary(dst)
    imm_binary = format(imm, '020b')
    inst = imm_binary + dst_binary + str(opcode)
    return int(inst, 2)

  def Halt():
    self.myinst.append(0xffffffff)
    return 0xffffffff

  # return a 32 bit binary instruction
  # input is a decimal integer of index of register 
  def Add(self, dst, src1, src2):
    opcode = '0110011'
    funct7 = '0000000'
    funct3 = '000'
    inst = self.Rtype_Gen(funct7, src2, src1, funct3, dst, opcode)
    self.myinst.append(inst)
    return  inst

  def Sub(self, dst, src1, src2):
    opcode = '0110011'
    funct7 = '0100000'
    funct3 = '000'
    inst = self.Rtype_Gen(funct7, src2, src1, funct3, dst, opcode)
    self.myinst.append(inst)
    return  inst

  def SRA (self, dst, src1, src2):
    opcode = '0110011'
    funct7 = '0100000'
    funct3 = '101'
    inst = self.Rtype_Gen(funct7, src2, src1, funct3, dst, opcode)
    self.myinst.append(inst)
    return  inst

  def Sll(self, dst, src1, src2):
    opcode = '0110011'
    funct7 = '0000000'
    funct3 = '001'
    inst = self.Rtype_Gen(funct7, src2, src1, funct3, dst, opcode)
    self.myinst.append(inst)
    return  inst

  def Slt(self, dst, src1, src2):
    opcode = '0110011'
    funct7 = '0000000'
    funct3 = '010'
    inst = self.Rtype_Gen(funct7, src2, src1, funct3, dst, opcode)
    self.myinst.append(inst)
    return  inst

  def Sltu(self, dst, src1, src2):
    opcode = '0110011'
    funct7 = '0000000'
    funct3 = '011'
    inst = self.Rtype_Gen(funct7, src2, src1, funct3, dst, opcode)
    self.myinst.append(inst)
    return  inst

  def Addi(self, dst, src1, imm):
    opcode = '0010011'
    funct3 = '000'
    inst = self.Itype_Gen(imm, src1, funct3, dst, opcode)
    self.myinst.append(inst)
    return inst

  def Srli(self, dst, src1, shamt):
    opcode = '0010011'
    funct3 = '101'
    funct7 = '0000000'
    inst = self.IShift_Gen(shamt, src1, funct3, dst, opcode, funct7)
    self.myinst.append(inst)
    return inst

  def Slli(self, dst, src1, shamt):
    opcode = '0010011'
    funct3 = '001'
    funct7 = '0000000'
    inst = self.IShift_Gen(shamt, src1, funct3, dst, opcode, funct7)
    self.myinst.append(inst)
    return inst

  def StoreW(self, src2, src1, offset):
    opcode = '0100011'
    funct3 = '010'
    inst = self.Store_Gen(src2, src1, offset, funct3, opcode)
    self.myinst.append(inst)
    return inst

  def StoreB(self, src2, src1, offset):
    opcode = '0100011'
    funct3 = '000'
    inst = self.Store_Gen(src2, src1, offset, funct3, opcode)
    self.myinst.append(inst)
    return inst

  def StoreH(self, src2, src1, offset):
    opcode = '0100011'
    funct3 = '001'
    inst = self.Store_Gen(src2, src1, offset, funct3, opcode)
    self.myinst.append(inst)
    return inst

  def LoadB(self, dst, src1, offset):
    opcode = '0000011'
    funct3 = '000'
    inst = self.Load_Gen(src1, offset, funct3, dst, opcode)
    self.myinst.append(inst)
    return inst

  def LoadBU(self, dst, src1, offset):
    opcode = '0000011'
    funct3 = '100'
    inst = self.Load_Gen(src1, offset, funct3, dst, opcode)
    self.myinst.append(inst)
    return inst

  def LoadHU(self, dst, src1, offset):
    opcode = '0000011'
    funct3 = '101'
    inst = self.Load_Gen(src1, offset, funct3, dst, opcode)
    self.myinst.append(inst)
    return inst

  def LoadH(self, dst, src1, offset):
    opcode = '0000011'
    funct3 = '001'
    inst = self.Load_Gen(src1, offset, funct3, dst, opcode)
    self.myinst.append(inst)
    return inst

  def LoadW(self, dst, src1, offset):
    opcode = '0000011'
    funct3 = '010'
    inst = self.Load_Gen(src1, offset, funct3, dst, opcode)
    self.myinst.append(inst)
    return inst

  def BEQ(self, src1, src2, offset):
    opcode = '1100011'
    funct3 = '000'
    inst = self.Branch_Gen(src1, src2, offset, funct3, opcode)
    self.myinst.append(inst)
    return inst

  def BNE(self, src1, src2, offset):
    opcode = '1100011'
    funct3 = '001'
    inst = self.Branch_Gen(src1, src2, offset, funct3, opcode)
    self.myinst.append(inst)
    return inst

  def LUI(self, dst, imm):
    opcode = '0110111'
    inst = self.LUI_Gen(imm, dst, opcode)
    self.myinst.append(inst)
    return inst

  def AUIPC(self, dst, imm): 
    opcode = '0010111'
    inst = self.LUI_Gen(imm, dst, opcode)
    self.myinst.append(inst)
    return inst

  def JAL(self, rd, offset):
    opcode = '1101111'
    rd_binary = reg2binary(rd)
    if (offset < 0):
      offset = 2**20 + offset 
    offset_binary = format(offset, '020b')
    inst = offset_binary[0] + offset_binary[10:20] + offset_binary[9] + offset_binary[1:9] + rd_binary + str(opcode)
    self.myinst.append(inst)
    return int(inst, 2)