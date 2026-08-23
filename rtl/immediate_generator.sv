module immediate_generator(
    input  logic [31:0] instr,
    input  rv32i_pkg::imm_type_e imm_type,
    output logic [31:0] imm_out
);
import rv32i_pkg::*;

always_comb begin
    unique case(imm_type)
        IMM_I: begin
            imm_out = {{20{instr[31]}}, instr[31:20]};
        end
        IMM_S: begin
            imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        end
        IMM_B: begin
            imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
        end
        IMM_U: begin
            imm_out = {instr[31:12], 12'b0};
        end
        IMM_J: begin
            imm_out = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
        end
        default: begin
            imm_out = '0;
        end
    endcase
end
endmodule