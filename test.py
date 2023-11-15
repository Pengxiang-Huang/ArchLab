import os 
import sys
from Instruction import Instruction


def check_mem(addr, value):
  actual_addr = None # calcualte the addr carefully!
  actual_value = None
  with open("mem_out.hex", 'r') as f:
    lines = f.readlines()
    actual_value = int(lines[actual_addr])

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
    actual_value = int(lines[actual_index])

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
  os.system("./a.out")
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
  registers = set_reg(registers, 1, 1)
  registers = set_reg(registers, 2, 2)
  # generate the instructions
  instructions.Sub(3, 2, 1)
  run(registers, instructions.myinst)
  # check the result
  check_reg(3, 1)
  return


def test():
  test_add()
  test_sub()
  # pls add more for the other instructions
  return 


if __name__ == "__main__":
  test()