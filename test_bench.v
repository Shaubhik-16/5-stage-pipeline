module test_mips32;

reg clk1, clk2;
integer k;

pipe_MIPS32 mips(clk1, clk2);

initial
begin
clk1=0; clk2=0;
repeat(50)
begin
#5 clk1=1;  #5 clk1=0;
#5 clk2=1;  #5 clk2=0;
end
end

initial
begin
for(k=0;k<=31;k=k+1)
mips.Reg[k]=k;

mips.mem[0]=32'h28010078;
mips.mem[1]=32'h0c631800; //dummy
mips.mem[2]=32'h20220000;
mips.mem[3]=32'h0c631800; //dummy
mips.mem[4]=32'h2842002d;
mips.mem[5]=32'h0c631800; //dummy
mips.mem[6]=32'h24220001;
mips.mem[7]=32'hfc000000;

mips.mem[120]=85;

mips.pc=0;
mips.halted=0;
mips.taken_branch=0;

#500 $display("mem[120]: %4d \nmem[121]: %4d", mips.mem[120], mips.mem[121]);
end

initial
begin
$dumpfile("mips.vcd");
$dumpvars(0, mips);
#600 $finish;
end
endmodule
