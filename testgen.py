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
  inst = imm_binary[5:12]+ src2_binary + src1_binary + str(funct3) + imm_binary[0:5] + str(opcode)
  return int(inst, 2)

def Load_Gen(src1, imm, funct3, dst, opcode):
  src1_binary = reg2binary(src1)
  dst_binary = reg2binary(dst)
  if (imm < 0):
    imm = 2**12 + imm 
  imm_binary = format(imm, '012b')
  inst = imm_binary + src1_binary + str(funct3) + dst_binary + str(opcode)
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

def Sll(dst, src1, src2):
  opcode = '0110011'
  funct7 = '0000000'
  funct3 = '001'
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

def LoadW(dst, src1, offset):
  opcode = '0000011'
  funct3 = '010'
  inst = Load_Gen(src1, offset, funct3, dst, opcode)
  return inst

def Halt():
  return 0x11111111


def Regsiter_Gen():
  Registers = [
        0x00000000,  # x0, hardwired to 0
        0x00000008,  # x1, initialized to 1
        0x00000002,  # x2, initialized to 2
        0x00000000,  # x3, will hold the result of the ADD operation
        0x00000000   # x4, will hold the result of the SUB operation
        # add more as needed
  ]
  return Registers


def Instruction_Gen():
  instructions = []
  ### write the assembly code here to generate the machine code
  instructions.append(Add(3, 1, 2))
  # instructions.append(StoreB(3, 0, 1024))
  instructions.append(StoreB(3, 0, 1024))
  instructions.append(LoadB(4, 0, 1))
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