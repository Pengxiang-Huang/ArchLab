import os 
import sys
from Instruction import Instruction
import subprocess


#      lui, auipc
#      jal, jalr, beq, bne, blt, bge, bltu, bgeu
#      lb, lh, lw, lbu, lhu, sb, sh, sw
#      addi, slti, xori, ori, andi, slli, srli, srai,
#      add, sub, sll, slt, sltu, xor, srl, sra, or, and
#      for slt and rest,still not test cuz permission denied of a.out
def check_mem(addr, value):
  actual_addr = addr + 1 # calcualte the addr carefully!
  actual_value = None
  with open("mem_out.hex", 'r') as f:
    lines = f.readlines()
    actual_value = int(lines[actual_addr],16)

  if actual_value != value:
    print("Test Failed!")
    print("expected value: ", hex(value))
    print("actual value: ", hex(actual_value))
    print("################\n")
  else:
    print("Test Passed!")
    print("################\n")
  return

# read the regs_out.hex file and check the values the specific register
def check_reg(reg_index, value):
  actual_index = reg_index + 1 # since reg0 begin with line 2
  actual_value = None
  with open("regs_out.hex", 'r') as f:
    lines = f.readlines()
    actual_value = int(lines[actual_index],16)
    

  if actual_value != value:
    print("Test Failed!")
    print("expected value: ", hex(value))
    print("actual value: ", hex(actual_value))
    print("################\n")
  else:
    print("Test Passed!")
    print("################\n")
  return

# set the value for a single register
def set_reg(registers, reg_index, value):
  if value < 0:
    value = 2**32 + value
  registers[reg_index] = value
  return registers

# initialize all register values to 0
def Reg_Init():
  Registers = []
  total = 32 
  for i in range(total):
    Registers.append(0x00000000)
  return Registers

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

# write the instructions and registers into the input files
# then execute the program
def run(registers, instructions):
  print("Running the program")
  write_mem_in("mem_in.hex", instructions)
  write_reg_in("regs_in.hex", registers)
  # the program should be comiled as a.out
  os.system("./lab2forlab3.vvp")
  return


def test_add():
  print("Testing add instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 1, 1)
  registers = set_reg(registers, 2, 2)
  # generate the instructions
  instructions.Add(3, 2, 1)
  run(registers, instructions.myinst)
  # check the result
  check_reg(3, 3)
  return

def test_sub():
  print("Testing sub instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 2)
  # generate the instructions
  instructions.Sub(5, 4, 3)
  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 1)
  return

def test_sll():
  print("Testing sll instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 2)
  # generate the instructions
  instructions.Sll(5, 4, 3)
  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 4)
  return

def test_slt():
  print("Testing slt instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Slt(5, 3, 4)
  instructions.Slt(6, 4, 3)
  instructions.Slt(8, 7, 3)

  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 1)
  check_reg(6, 0)
  check_reg(8, 1)
  return

def test_sltu():
  print("Testing sltu instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Slt(5, 3, 4)
  instructions.Slt(6, 4, 3)

  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 1)
  check_reg(6, 0)
  return

def test_xor():
  print("Testing xor instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 7)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Xor(5, 3, 4)
  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 5)
  return

def test_srl():
  print("Testing srl instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Srl(5, 4, 3)
  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 1)
  return

def test_srl():
  print("Testing srl instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Srl(5, 4, 3)
  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 1)
  return

def test_sra():
  print("Testing sra instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.SRA(5, 4, 3)
  instructions.SRA(8, 7, 3)
  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 1)
  check_reg(8, int("ffffffff",16))
  return

def test_or():
  print("Testing or instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 7)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Or(5, 4, 3)

  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 7)

  return

def test_and():
  print("Testing and instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 7)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.And(5, 4, 3)

  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 2)
  
  return

def test_addi():
  print("Testing addi instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 7)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Addi(5, 4, 3)

  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 5)
  
  return

def test_slti():
  print("Testing slti instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 7)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Slti(5, 4, 3)
  instructions.Slti(6, 3, 3)
  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 1)
  check_reg(6, 0)
  
  return

def test_xori():
  print("Testing xori instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 7)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Xori(5, 4, 8)

  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 10)

  return

def test_ori():
  print("Testing ori instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 7)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Ori(5, 4, 8)

  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 10)

  return

def test_andi():
  print("Testing andi instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 7)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Andi(5, 4, 10)

  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 2)

  return

def test_slli():
  print("Testing slli instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 7)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Slli(5, 4, 1)

  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 4)

  return


def test_srli():
  print("Testing srli instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 7)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -1)
  # generate the instructions
  instructions.Srli(5, 4, 1)

  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 1)

  return

def test_srai():
  print("Testing srai instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 7)
  registers = set_reg(registers, 4, 2)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.Srai(5, 4, 1)
  instructions.Srai(8, 7, 1)

  run(registers, instructions.myinst)
  # check the result
  check_reg(5, 1)
  check_reg(8, int("ffffffff",16))

  return

def test_lb():
  print("Testing lb instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 1)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.LoadB(6, 4, 1)
  
  
  instructions.LoadB(8,4,8)
  instructions.Add(10,11,12)
  
  
  # instructions.SRA(15,3,4)
  # instructions.LoadB(8,4,3)
  

  run(registers, instructions.myinst)
  # check the result
  check_reg(6, int("12",16))
  check_reg(8, int("ffffff85",16))
  

  return

def test_lh():
  print("Testing lh instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 1)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.LoadH(6, 4, 1)
  instructions.LoadH(8, 4, 0)
  
  instructions.LoadH(9,4,11)
  instructions.Add(10,11,12)

  run(registers, instructions.myinst)
  # check the result
  check_reg(6, int("12",16))
  check_reg(8, int("1303",16))
  check_reg(9, int("ffff8533",16))
  

  return

def test_lw():
  print("Testing lw instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 1)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.LoadW(6, 4, 1)
  instructions.LoadW(7, 4, 3)
  

  run(registers, instructions.myinst)
  # check the result
  check_reg(6, int("00122303",16))
  check_reg(7, int("00322383",16))
  

  return

def test_lbu():
  print("Testing lbu instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 1)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.LoadBU(6, 4, 1)
  # instructions.SRA(15,3,4)
  # instructions.LoadB(8,4,3)
  

  run(registers, instructions.myinst)
  # check the result
  check_reg(6, int("12",16))
  

  return


def test_lhu():
  print("Testing lh instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 1)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.LoadH(6, 4, 1)
  instructions.LoadH(8, 4, 0)
  
  instructions.LoadH(9,4,11)
  instructions.Add(10,11,12)
  
  

  run(registers, instructions.myinst)
  # check the result
  check_reg(6, int("12",16))
  check_reg(8, int("1303",16))
  

  return

def test_sb():
  print("Testing sb instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 1)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.StoreB(7, 4, 1)
  instructions.LoadB(8,4,8)
  instructions.Add(10,11,12)
  
  
  # instructions.SRA(15,3,4)
  # instructions.LoadB(8,4,3)
  

  run(registers, instructions.myinst)
  # check the result
  check_mem(2,int("fe",16))
  

  return

def test_sh():
  print("Testing sh instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 1)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.StoreH(7, 4, 1)
  instructions.LoadB(8,4,8)
  instructions.Add(10,11,12)

  run(registers, instructions.myinst)
  # check the result
  check_mem(2,int("fe",16))
  check_mem(3,int("ff",16))
  

  return

def test_sw():
  print("Testing sw instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 1)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.StoreW(7, 4, 1)
  instructions.LoadB(8,4,8)
  instructions.Add(10,11,12)

  run(registers, instructions.myinst)
  # check the result
  check_mem(0,int("fe",16))
  check_mem(1,int("ff",16))
  check_mem(2,int("ff",16))
  check_mem(3,int("ff",16))

  

  return

def test_beq():
  print("Testing beq instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, -2)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.BEQ(7, 4, 12)
  instructions.LoadB(8,4,8)
  instructions.Add(10,11,12)
  
  run(registers, instructions.myinst)
  # check the result
 

  

  return

def test_beq():
  print("Testing beq instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, -2)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.BEQ(7, 4, 12)
  instructions.LoadB(8,4,8)
  instructions.Add(10,11,12)
  instructions.BEQ(7,3,8)
  
  run(registers, instructions.myinst)
  print("if pc at 10 is 0000000c, pc at 20 is 00000010, then the test is passed")
  # check the result
 

  

  return

def test_bne():
  print("Testing bne instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, -2)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.BNE(7, 3, 12)
  instructions.LoadB(8,4,8)
  instructions.Add(10,11,12)
  instructions.BNE(7,4,8)
  
  run(registers, instructions.myinst)
  print("\nif pc at 10 is 0000000c, pc at 20 is 00000010, then the test is passed\n")
  # check the result
 

  

  return

def test_blt():
  print("Testing blt instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 4)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.BLT(7, 3, 12)
  instructions.LoadB(8,4,8)
  instructions.Add(10,11,12)
  instructions.BLT(4,3,8)
  
  run(registers, instructions.myinst)
  print("\nif pc at 10 is 0000000c, pc at 20 is 00000010, then the test is passed\n")
  # check the result
 

  

  return

def test_bge():
  print("Testing bge instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 4)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.BGE(4, 3, 12)
  instructions.LoadB(8,4,8)
  instructions.Add(10,11,12)
  instructions.BGE(7,3,8)
  
  run(registers, instructions.myinst)
  print("\nif pc at 10 is 0000000c, pc at 20 is 00000010, then the test is passed\n")
  # check the result
 

  

  return


def test_bltu():
  print("Testing bltu instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 4)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.BLTU(3, 7, 12)
  instructions.LoadB(8,4,8)
  instructions.Add(10,11,12)
  instructions.BLTU(4,3,8)
  
  run(registers, instructions.myinst)
  print("\nif pc at 10 is 0000000c, pc at 20 is 00000010, then the test is passed\n")
  # check the result
 

  

  return

def test_bgeu():
  print("Testing bgeu instruction")
  #initialize the registers and instructions
  registers = Reg_Init()
  instructions  = Instruction()
  # set the register values
  registers = set_reg(registers, 3, 1)
  registers = set_reg(registers, 4, 4)
  registers = set_reg(registers, 7, -2)
  # generate the instructions
  instructions.BGEU(7, 3, 12)
  instructions.LoadB(8,4,8)
  instructions.Add(10,11,12)
  instructions.BGEU(4,7,8)
  
  run(registers, instructions.myinst)
  print("\nif pc at 10 is 0000000c, pc at 20 is 00000010, then the test is passed\n")
  # check the result
 

  

  return

#      lui, auipc
#      jal, jalr, beq, bne, blt, bge, bltu, bgeu
#      lb, lh, lw, lbu, lhu, sb, sh, sw
#      addi, slti, xori, ori, andi, slli, srli, srai,
#      add, sub, sll, slt, sltu, xor, srl, sra, or, and
#      from lh, not test yet
def test():
  # test_add()
  
  test_bgeu()
  # pls add more for the other instructions
  return 


if __name__ == "__main__":
  test()