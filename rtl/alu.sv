module alu(
    input  logic [31:0] operand_a,
    input  logic [31:0] operand_b,
    input  rv32i_pkg::alu_op_e alu_op,
    output logic [31:0] result
);

always_comb begin
    unique case(alu_op) 
        rv32i_pkg::ALU_ADD :  result = operand_a + operand_b;
        rv32i_pkg::ALU_SUB :  result = operand_a - operand_b;
        rv32i_pkg::ALU_SLL :  result = operand_a << operand_b[4:0];
        rv32i_pkg::ALU_SLT :  result = ($signed(operand_a) < $signed(operand_b))
                                ? 32'd1 : 32'd0;
        rv32i_pkg::ALU_SLTU:  result = (operand_a < operand_b) ? 32'd1 : 32'd0;
        rv32i_pkg::ALU_XOR :  result = operand_a ^ operand_b;
        rv32i_pkg::ALU_SRL :  result = operand_a >> operand_b[4:0];
        rv32i_pkg::ALU_SRA :  result = $signed(operand_a) >>> operand_b[4:0];
        rv32i_pkg::ALU_OR  :  result = operand_a | operand_b;
        rv32i_pkg::ALU_AND :  result = operand_a & operand_b;
        default :  result = '0;
    endcase
end

endmodule