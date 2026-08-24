module decoder(
    input  logic [31:0]             instr,

    output logic [4:0]              rs1_addr,
    output logic [4:0]              rs2_addr,
    output logic [4:0]              rd_addr,
    output logic [2:0]              funct3,
    output rv32i_pkg::alu_op_e      alu_op,
    output rv32i_pkg::imm_type_e    imm_type,
    output rv32i_pkg::instr_type_e  instr_type,
    output logic                    illegal
);

import rv32i_pkg::*;

logic [6:0] opcode;
assign opcode = instr[6:0];
logic funct7_base_ok;
assign funct7_base_ok = (instr[31] == 1'b0) && (instr[29:25] == '0);
always_comb begin
    illegal = 1'b0;
    funct3 = instr[14:12];
    rs1_addr = instr[19:15];
    rs2_addr = instr[24:20];
    rd_addr = instr[11:7];
    unique case(opcode)
        7'b0110011: begin
            imm_type = IMM_NA;
            instr_type = ALU_REG;
            if(funct7_base_ok) begin
                unique case(funct3)
                    3'b000: alu_op = alu_op_e'((instr[30]) ? ALU_SUB : ALU_ADD);
                    3'b001: begin
                        alu_op = ALU_SLL;
                        illegal = !(instr[30] == 1'b0);
                    end
                    3'b010: begin
                        alu_op = ALU_SLT;
                        illegal = !(instr[30] == 1'b0);
                    end
                    3'b011: begin
                        alu_op = ALU_SLTU;
                        illegal = !(instr[30] == 1'b0);
                    end
                    3'b100: begin
                        alu_op = ALU_XOR;
                        illegal = !(instr[30] == 1'b0);
                    end
                    3'b101: alu_op = alu_op_e'((instr[30]) ? ALU_SRA : ALU_SRL);
                    3'b110: begin
                        alu_op = ALU_OR;
                        illegal = !(instr[30] == 1'b0);
                    end
                    3'b111: begin
                        alu_op = ALU_AND;
                        illegal = !(instr[30] == 1'b0);
                    end
                endcase
            end
            else begin
                alu_op = ALU_ADD;
                illegal = 1'b1;
            end
        end
        7'b0010011: begin
            imm_type = IMM_I;
            instr_type = ALU_IMM;
            unique case(funct3)
                3'b000: alu_op = ALU_ADD;
                3'b001: begin
                    alu_op = ALU_SLL;
                    illegal = !funct7_base_ok || instr[30];   
                end
                3'b010: alu_op = ALU_SLT;
                3'b011: alu_op = ALU_SLTU;
                3'b100: alu_op = ALU_XOR;
                3'b101: begin
                    alu_op = alu_op_e'((instr[30]) ? ALU_SRA : ALU_SRL);
                    illegal = !funct7_base_ok;
                end
                3'b110: alu_op = ALU_OR;
                3'b111: alu_op = ALU_AND;
            endcase
        end
        7'b0000011: begin
            imm_type = IMM_I;
            instr_type = LOAD;
            alu_op = ALU_ADD;
            illegal = !(instr[14:12] inside {3'b000, 3'b001, 3'b010, 3'b100, 3'b101});
        end
        7'b0100011: begin
            imm_type = IMM_S;
            instr_type = STORE;
            alu_op = ALU_ADD;
            illegal = !(instr[14:12] inside {3'b000, 3'b001, 3'b010});
        end
        7'b1100011: begin
            imm_type = IMM_B;
            instr_type = BRANCH;
            unique case(funct3[2:1])
                2'b00:   alu_op = ALU_SUB;   
                2'b10:   alu_op = ALU_SLT;
                2'b11:   alu_op = ALU_SLTU;
                default: begin 
                    alu_op = ALU_SUB;  
                    illegal = 1'b1;
                end
            endcase
        end
        7'b1101111: begin
            imm_type = IMM_J;
            instr_type = JAL;
            alu_op = ALU_ADD;
        end
        7'b1100111: begin
            imm_type = IMM_I;
            instr_type = JALR;
            alu_op = ALU_ADD;
            illegal = !(instr[14:12] == 3'b000);
        end        
        7'b0110111: begin
            imm_type = IMM_U;
            instr_type = LUI;
            alu_op = ALU_ADD;
            rs1_addr = '0;
        end
        7'b0010111: begin
            imm_type = IMM_U;
            instr_type = AUIPC;
            alu_op = ALU_ADD;
        end
        7'b1110011: begin
            imm_type = IMM_NA;
            instr_type = ILLEGAL;
            alu_op = ALU_ADD;
            illegal = 1'b1;
        end
        7'b0001111: begin
            imm_type = IMM_NA;
            instr_type = ILLEGAL;
            alu_op = ALU_ADD;
            illegal = 1'b1;
        end
        default: begin
            imm_type = IMM_NA;
            instr_type = ILLEGAL;
            alu_op = ALU_ADD;
            illegal = 1'b1;
        end
    endcase
end
endmodule