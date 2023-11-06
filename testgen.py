# generate mem_in.hex  regs_in.hex

# transfer the int register index to 5 bit binary string 
def reg2binary(decimal):
  binary = format(decimal, '05b')
  return binary

# generate R-type instruction
# output of 32 bit binary instruction
def Rtype_Gen(funct7, src2, src1, funct3, dst, opcode):
  src1_binary = reg2binary(src1)
  src2_binary = reg2binary(src2)
  dst_binary = reg2binary(dst)
  inst = str(funct7) + src2_binary + src1_binary + str(funct3) + dst_binary + str(opcode)  
  return int(inst, 2)

def Itype_Gen(imm, src1, funct3, dst, opcode):
  src1_binary = reg2binary(src1)
  dst_binary = reg2binary(dst)
  if (imm < 0):
    imm = 2**12 + imm 
  imm_binary = format(imm, '012b')
  inst = imm_binary + src1_binary + str(funct3) + dst_binary + str(opcode)
  return int(inst, 2)


def IShift_Gen(shamt, src1, funct3, dst, opcode, funct7):
  src1_binary = reg2binary(src1)
  dst_binary = reg2binary(dst)
  shamt_binary = format(shamt, '05b')
  inst = str(funct7) + shamt_binary + src1_binary + str(funct3) + dst_binary + str(opcode)
  return int(inst, 2)

def Store_Gen(src2, src1, imm, funct3, opcode):
  src1_binary = reg2binary(src1)
  src2_binary = reg2binary(src2)
  if (imm < 0):
    imm = 2**12 + imm 
  imm_binary = format(imm, '012b')
  # print(imm_binary[0:7])
  # print(imm_binary[7:12])
  inst = imm_binary[0:7]+ src2_binary + src1_binary + str(funct3) + imm_binary[7:12] + str(opcode)
  return int(inst, 2)

def Load_Gen(src1, imm, funct3, dst, opcode):
  src1_binary = reg2binary(src1)
  dst_binary = reg2binary(dst)
  if (imm < 0):
    imm = 2**12 + imm 
  imm_binary = format(imm, '012b')
  inst = imm_binary + src1_binary + str(funct3) + dst_binary + str(opcode)
  return int(inst, 2)

def Branch_Gen(src1, src2, imm, funct3, opcode):
  src1_binary = reg2binary(src1)
  src2_binary = reg2binary(src2)
  if (imm < 0):
    imm = 2**12 + imm 
  imm_binary = format(imm, '012b')
  inst = imm_binary[0] + imm_binary[2:8] + src2_binary + src1_binary + str(funct3) + imm_binary[8:12] + imm_binary[1] + str(opcode)
  return int(inst, 2)

def LUI_Gen(imm, dst, opcode):
  dst_binary = reg2binary(dst)
  imm_binary = format(imm, '020b')
  inst = imm_binary + dst_binary + str(opcode)
  return int(inst, 2)


# return a 32 bit binary instruction
# input is a decimal integer of index of register 
def Add(dst, src1, src2):
  opcode = '0110011'
  funct7 = '0000000'
  funct3 = '000'
  inst = Rtype_Gen(funct7, src2, src1, funct3, dst, opcode)
  return  inst

def Sub(dst, src1, src2):
  opcode = '0110011'
  funct7 = '0100000'
  funct3 = '000'
  inst = Rtype_Gen(funct7, src2, src1, funct3, dst, opcode)
  return  inst

def SRA (dst, src1, src2):
  opcode = '0110011'
  funct7 = '0100000'
  funct3 = '101'
  inst = Rtype_Gen(funct7, src2, src1, funct3, dst, opcode)
  return  inst

def Sll(dst, src1, src2):
  opcode = '0110011'
  funct7 = '0000000'
  funct3 = '001'
  inst = Rtype_Gen(funct7, src2, src1, funct3, dst, opcode)
  return  inst

def Slt(dst, src1, src2):
  opcode = '0110011'
  funct7 = '0000000'
  funct3 = '010'
  inst = Rtype_Gen(funct7, src2, src1, funct3, dst, opcode)
  return  inst

def Sltu(dst, src1, src2):
  opcode = '0110011'
  funct7 = '0000000'
  funct3 = '011'
  inst = Rtype_Gen(funct7, src2, src1, funct3, dst, opcode)
  return  inst

def Addi(dst, src1, imm):
  opcode = '0010011'
  funct3 = '000'
  inst = Itype_Gen(imm, src1, funct3, dst, opcode)
  return inst

def Srli(dst, src1, shamt):
  opcode = '0010011'
  funct3 = '101'
  funct7 = '0000000'
  inst = IShift_Gen(shamt, src1, funct3, dst, opcode, funct7)
  return inst

def Slli(dst, src1, shamt):
  opcode = '0010011'
  funct3 = '001'
  funct7 = '0000000'
  inst = IShift_Gen(shamt, src1, funct3, dst, opcode, funct7)
  return inst

def StoreW(src2, src1, offset):
  opcode = '0100011'
  funct3 = '010'
  inst = Store_Gen(src2, src1, offset, funct3, opcode)
  return inst

def StoreB(src2, src1, offset):
  opcode = '0100011'
  funct3 = '000'
  inst = Store_Gen(src2, src1, offset, funct3, opcode)
  return inst

def StoreH(src2, src1, offset):
  opcode = '0100011'
  funct3 = '001'
  inst = Store_Gen(src2, src1, offset, funct3, opcode)
  return inst

def LoadB(dst, src1, offset):
  opcode = '0000011'
  funct3 = '000'
  inst = Load_Gen(src1, offset, funct3, dst, opcode)
  return inst

def LoadBU(dst, src1, offset):
  opcode = '0000011'
  funct3 = '100'
  inst = Load_Gen(src1, offset, funct3, dst, opcode)
  return inst

def LoadHU(dst, src1, offset):
  opcode = '0000011'
  funct3 = '101'
  inst = Load_Gen(src1, offset, funct3, dst, opcode)
  return inst

def LoadH(dst, src1, offset):
  opcode = '0000011'
  funct3 = '001'
  inst = Load_Gen(src1, offset, funct3, dst, opcode)
  return inst

def LoadW(dst, src1, offset):
  opcode = '0000011'
  funct3 = '010'
  inst = Load_Gen(src1, offset, funct3, dst, opcode)
  return inst

def BEQ(src1, src2, offset):
  opcode = '1100011'
  funct3 = '000'
  inst = Branch_Gen(src1, src2, offset, funct3, opcode)
  return inst

def BNE(src1, src2, offset):
  opcode = '1100011'
  funct3 = '001'
  inst = Branch_Gen(src1, src2, offset, funct3, opcode)
  return inst

def LUI(dst, imm):
  opcode = '0110111'
  inst = LUI_Gen(imm, dst, opcode)
  return inst

def AUIPC(dst, imm): 
  opcode = '0010111'
  inst = LUI_Gen(imm, dst, opcode)
  return inst

def JAL(rd, offset):
  opcode = '1101111'
  rd_binary = reg2binary(rd)
  if (offset < 0):
    offset = 2**20 + offset 
  offset_binary = format(offset, '020b')
  inst = offset_binary[0] + offset_binary[10:20] + offset_binary[9] + offset_binary[1:9] + rd_binary + str(opcode)
  return int(inst, 2)

def Halt():
  return 0xffffffff


def Regsiter_Gen():
  Registers = [
        0x00000000,  # x0, hardwired to 0
        0x00000008,  # x1, initialized to 1
        0xf000fff2,  # x2, initialized to 2
        0x00000006,  # x3,
        0x00000004,   # x4
        0x00000005,  # x5
        0x00000003,  # x6
        0x00000009,  # x7
        # add more as needed
  ]
  remaining = 32 - len(Registers)
  for i in range(remaining):
    Registers.append(0x00000000)
  return Registers


def Instruction_Gen():
  instructions = []
  ### write the assembly code here to generate the machine code
  instructions.append(Slt(4,2,3))
  instructions.append(StoreW(2, 0, 1020))
  instructions.append(SRA(3, 2, 1))
  instructions.append(BEQ(0, 1, 3))
  instructions.append(Addi(1, 1, -1))
  instructions.append(BNE(0,1,-2))
  # instructions.append(BNE(0,0,1))
  # instructions.append(BNE(0,0,1))
  # instructions.append(BNE(0,0,1))
  # instructions.append(Sub(6, 4, 5))
  # instructions.append(BNE(0,0,1))
  # instructions.append(BNE(0,0,1))
  # instructions.append(Add(1, 1, 1))
  # instructions.append(LoadH(1, 0, 1020))
  # instructions.append(LoadB(3, 0, 8))
  # instructions.append(LoadW(2, 0, 4))
  # instructions.append(LoadB(5, 0, 4))
  # instructions.append(Add(2, 2, 2))
  # instructions.append(Sub(3, 3, 3))
  # instructions.append(StoreB(2, 0, 1024))
  # instructions.append(StoreB(1, 0, 1023))
  # instructions.append(Addi(1, 0, 1))
  # instructions.append(Srli(1, 1, 1))
  # instructions.append(Add(2, 0, 2))
  instructions.append(Addi(1, 1, -1))
  instructions.append(Sltu(5, 1, 4))
  instructions.append(LUI(8, 128))
  instructions.append(AUIPC(5, 128))
  instructions.append(AUIPC(6, 128))
  instructions.append(JAL(9, 1))
  instructions.append(AUIPC(7, 128))
  instructions.append(Halt())

  return instructions

def write_mem_in(filename, instructions):
    with open(filename, 'w') as f:
        for inst in instructions:
            # Convert the 32-bit instruction into four 8-bit values and write them in reverse
            f.write(f"{inst & 0x000000FF:02x}\n")
            f.write(f"{(inst & 0x0000FF00) >> 8:02x}\n")
            f.write(f"{(inst & 0x00FF0000) >> 16:02x}\n")
            f.write(f"{(inst & 0xFF000000) >> 24:02x}\n")
        remaining = 1025 - len(instructions) * 4
        for i in range(remaining):
            f.write("00\n")

def write_reg_in(filename, registers):
    with open(filename, 'w') as f:
        for reg in registers:
            # Write 32-bit values directly
            f.write(f"{reg:08x}\n")

if __name__ == "__main__":
    # register initial values in hexadecimal format
    registers = Regsiter_Gen()

    # memory initial values in hexadecimal format
    instructions = Instruction_Gen()

    # write the initial values into files
    write_mem_in("mem_in.hex", instructions)
    write_reg_in("regs_in.hex", registers)