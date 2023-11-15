// Testbench for Northwestern - CompEng 361 - Lab2

module tb;
   reg clk, rst;
   wire halt;

    // reg myhalt = 0;
   // Single Cycle CPU instantiation
   SingleCycleCPU CPU (halt, clk,rst);

   // Clock Period = 10 time units
   //  (stops when halt is asserted)  
   always
     #5 clk = ~clk & !halt;

   initial begin
      // Clock and reset steup
      #0 rst = 1; clk = 0;
      #0 rst = 0;
      #0 rst = 1;

      // Load program
      #0 $readmemh("mem_in.hex", CPU.IMEM.Mem);
      #0 $readmemh("mem_in.hex", CPU.DMEM.Mem);
      #0 $readmemh("regs_in.hex", CPU.RF.Mem);

      
      // Feel free to modify to inspect whatever you want
      #0 $monitor($time,, "PC=%08x IR=%08x, funct7=%08x", 
      CPU.PC, CPU.InstWord, CPU.funct7);

      // Exits when halt is asserted
      // wait(halt);
      // assign halt to 1 only at time 60

      // #60 assign myhalt = 1;
      wait(halt);
      

      // #0 $display("CPU halt is %d, IsRtype %d, IsItype %d, IsIshift %d, IsStore %d, IsLoad %d, IsBranch %d badaddr %d ", halt, CPU.IsRtype, CPU.IsItype, CPU.IsIshift, CPU.IsStore, CPU.IsLoad, CPU.IsBranch, CPU.BadAddr);
      // Dump registers
      #0 $writememh("regs_out.hex", CPU.RF.Mem);

      // Dump memory
      #0 $writememh("mem_out.hex", CPU.DMEM.Mem);

      $finish;      
   end
   

endmodule // tb

