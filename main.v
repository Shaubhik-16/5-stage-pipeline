module pipe_MIPS32(clk1, clk2);
input clk1, clk2;
reg [31:0] pc, if_id_ir, if_id_npc;
reg [31:0] id_ex_ir, id_ex_npc, id_ex_a, id_ex_b, id_ex_imm;
reg [2:0] id_ex_type, ex_mem_type, mem_wb_type;
reg [31:0] ex_mem_ir, ex_mem_alu, ex_mem_b;
reg ex_mem_cond;
reg [31:0] mem_wb_ir, mem_wb_alu, mem_wb_lmd;

reg [31:0] Reg [0:31];
reg [31:0] mem[0:1023];


parameter add=6'b000000, sub=6'b000001, And=6'b000010, Or=6'b000011, slt=6'b000100; 
parameter mul=6'b000101, hlt=6'b111111, lw=6'b001000, sw=6'b001001, addi=6'b001010;
parameter subi=6'b001011, slti=6'b001100, bneqz=6'b001101, beqz=6'b001110;


parameter rr_alu=3'b000, rm_alu=3'b001, load=3'b010, store=3'b011, branch=3'b100,
          halt=3'b101;

reg halted;
reg taken_branch;

always@(posedge clk1)
begin
if(halted==0)
begin
if(((ex_mem_ir[31:26]==beqz) && (ex_mem_cond==1)) || ((ex_mem_ir[31:26]==bneqz) && (ex_mem_cond==0)))
begin
if_id_ir <= #2 mem[ex_mem_alu];
taken_branch <= #2 1'b1;
if_id_npc <= #2 ex_mem_alu+1;
pc <= #2 ex_mem_alu+1;
end
else
begin
if_id_ir <= #2 mem[pc];
if_id_npc <= #2 pc+1;
pc <= #2 pc+1;
end
end
end

always@(posedge clk2)
begin
if(halted==0)
begin
if(if_id_ir[25:21]==5'b00000)
id_ex_a <= 0;
else
id_ex_a <= #2 Reg[if_id_ir[25:21]];

if(if_id_ir[20:16]==5'b00000)
id_ex_b <= 0;
else
id_ex_b <= #2 Reg[if_id_ir[20:16]];

id_ex_npc <= #2 if_id_npc;
id_ex_ir <= #2 if_id_ir;
id_ex_imm <= #2 {{16{if_id_ir[15]}}, {if_id_ir[15:0]}};

case(if_id_ir[31:26])
add,sub,And,Or,slt,mul: id_ex_type <= rr_alu;
addi,subi,slti: id_ex_type <= rm_alu;
lw: id_ex_type <= load;
sw: id_ex_type <= store;
bneqz,beqz: id_ex_type <= branch;
hlt:  id_ex_type <= halt;
default: id_ex_type <= halt;
endcase
end
end

always@(posedge clk1)
begin
if(halted==0)
begin
ex_mem_type <= #2 id_ex_type;
ex_mem_ir <= #2 id_ex_ir;
taken_branch <= #2 0;

case(id_ex_type)
rr_alu:
begin
case(id_ex_ir[31:26])
add: ex_mem_alu <= #2 id_ex_a + id_ex_b;
sub: ex_mem_alu <= #2 id_ex_a - id_ex_b;
And: ex_mem_alu <= #2 id_ex_a & id_ex_b;
Or: ex_mem_alu <= #2 id_ex_a | id_ex_b;
slt: ex_mem_alu <= #2 id_ex_a < id_ex_b;
mul: ex_mem_alu <= #2 id_ex_a * id_ex_b;
default: ex_mem_alu <= #2 32'hxxxxxxxx;
endcase
end

rm_alu: 
begin
case(id_ex_ir[31:26])
addi: ex_mem_alu <= #2 id_ex_a + id_ex_imm;
subi: ex_mem_alu <= #2 id_ex_a - id_ex_imm;
slti: ex_mem_alu <= #2 id_ex_a < id_ex_imm;
default: ex_mem_alu <= #2 32'hxxxxxxxx;
endcase
end

load, store:
begin
ex_mem_alu <= #2 id_ex_a + id_ex_imm;
ex_mem_b <= #2 id_ex_b;
end

branch:
begin
ex_mem_alu <= #2 id_ex_npc + id_ex_imm;
ex_mem_cond <= #2 (id_ex_a==0);
end
endcase
end
end

always@(posedge clk2)
begin
if(halted==0)
begin
mem_wb_type <= #2 ex_mem_type;
mem_wb_ir <= #2 ex_mem_ir;
case(ex_mem_type)
rr_alu, rm_alu: mem_wb_alu <= #2 ex_mem_alu;
load: mem_wb_lmd <= #2 mem[ex_mem_alu];
store: if(taken_branch==0)
mem[ex_mem_alu] <= #2 ex_mem_b;
endcase
end
end

always@(posedge clk1)
begin
if (taken_branch==0)
begin
case(mem_wb_type)
rr_alu: Reg[mem_wb_ir[15:11]] <= #2 mem_wb_alu;
rm_alu: Reg[mem_wb_ir[20:16]] <= #2 mem_wb_alu;
load:  Reg[mem_wb_ir[20:16]] <= #2 mem_wb_lmd;
halt: halted <= #2 1'b1;
endcase
end
end

endmodule
