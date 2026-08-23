package rv32i_pkg;
    typedef enum logic [3:0]{
        ALU_ADD, ALU_SUB, ALU_SLL, ALU_SLT, ALU_SLTU, 
        ALU_XOR, ALU_SRL, ALU_SRA, ALU_OR, ALU_AND
    }alu_op_e;

    typedef enum logic [2:0]{
        IMM_I, IMM_S, IMM_B, IMM_U, IMM_J
    }imm_type_e;
endpackage