module decoder_tb;

    import rv32i_pkg::*;

    typedef struct {
        string name;
        logic [31:0] instr;
        instr_type_e exp_instr_type;
        alu_op_e exp_alu_op;
        imm_type_e exp_imm_type;
        logic [4:0] exp_rd_addr;
        logic [4:0] exp_rs1_addr;
        logic [4:0] exp_rs2_addr;
        logic [2:0] exp_funct3;
        logic exp_illegal;
    } test_vector_t;

    logic [31:0] instr;
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;
    logic [2:0]  funct3;
    alu_op_e     alu_op;
    imm_type_e   imm_type;
    instr_type_e instr_type;
    logic        illegal;

    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    decoder dut (
        .instr(instr),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .funct3(funct3),
        .alu_op(alu_op),
        .imm_type(imm_type),
        .instr_type(instr_type),
        .illegal(illegal)
    );

    test_vector_t vectors[] = '{

        '{"ADD x5,x6,x7",
          32'h007302b3,
          ALU_REG, ALU_ADD, IMM_NA,
          5'd5, 5'd6, 5'd7, 3'b000, 1'b0},

        '{"SUB x5,x6,x7",
          32'h407302b3,
          ALU_REG, ALU_SUB, IMM_NA,
          5'd5, 5'd6, 5'd7, 3'b000, 1'b0},

        '{"SLL x5,x6,x7",
          32'h007312b3,
          ALU_REG, ALU_SLL, IMM_NA,
          5'd5, 5'd6, 5'd7, 3'b001, 1'b0},

        '{"SLT x5,x6,x7",
          32'h007322b3,
          ALU_REG, ALU_SLT, IMM_NA,
          5'd5, 5'd6, 5'd7, 3'b010, 1'b0},

        '{"SLTU x5,x6,x7",
          32'h007332b3,
          ALU_REG, ALU_SLTU, IMM_NA,
          5'd5, 5'd6, 5'd7, 3'b011, 1'b0},

        '{"XOR x5,x6,x7",
          32'h007342b3,
          ALU_REG, ALU_XOR, IMM_NA,
          5'd5, 5'd6, 5'd7, 3'b100, 1'b0},

        '{"SRL x5,x6,x7",
          32'h007352b3,
          ALU_REG, ALU_SRL, IMM_NA,
          5'd5, 5'd6, 5'd7, 3'b101, 1'b0},

        '{"SRA x5,x6,x7",
          32'h407352b3,
          ALU_REG, ALU_SRA, IMM_NA,
          5'd5, 5'd6, 5'd7, 3'b101, 1'b0},

        '{"OR x5,x6,x7",
          32'h007362b3,
          ALU_REG, ALU_OR, IMM_NA,
          5'd5, 5'd6, 5'd7, 3'b110, 1'b0},

        '{"AND x5,x6,x7",
          32'h007372b3,
          ALU_REG, ALU_AND, IMM_NA,
          5'd5, 5'd6, 5'd7, 3'b111, 1'b0},

        '{"ADDI x5,x6,-512",
          32'he0030293,
          ALU_IMM, ALU_ADD, IMM_I,
          5'd5, 5'd6, 5'd0, 3'b000, 1'b0},

        '{"SLLI x5,x6,5",
          32'h00531293,
          ALU_IMM, ALU_SLL, IMM_I,
          5'd5, 5'd6, 5'd5, 3'b001, 1'b0},

        '{"SLTI x5,x6,-1",
          32'hfff32293,
          ALU_IMM, ALU_SLT, IMM_I,
          5'd5, 5'd6, 5'd31, 3'b010, 1'b0},

        '{"SLTIU x5,x6,2047",
          32'h7ff33293,
          ALU_IMM, ALU_SLTU, IMM_I,
          5'd5, 5'd6, 5'd31, 3'b011, 1'b0},

        '{"XORI x5,x6,0x155",
          32'h15534293,
          ALU_IMM, ALU_XOR, IMM_I,
          5'd5, 5'd6, 5'd21, 3'b100, 1'b0},

        '{"SRLI x5,x6,5",
          32'h00535293,
          ALU_IMM, ALU_SRL, IMM_I,
          5'd5, 5'd6, 5'd5, 3'b101, 1'b0},

        '{"SRAI x5,x6,5",
          32'h40535293,
          ALU_IMM, ALU_SRA, IMM_I,
          5'd5, 5'd6, 5'd5, 3'b101, 1'b0},

        '{"ORI x5,x6,0x2a",
          32'h02a36293,
          ALU_IMM, ALU_OR, IMM_I,
          5'd5, 5'd6, 5'd10, 3'b110, 1'b0},

        '{"ANDI x5,x6,0x3f",
          32'h03f37293,
          ALU_IMM, ALU_AND, IMM_I,
          5'd5, 5'd6, 5'd31, 3'b111, 1'b0},

        '{"BEQ x6,x7,16",
          32'h00730863,
          BRANCH, ALU_SUB, IMM_B,
          5'd16, 5'd6, 5'd7, 3'b000, 1'b0},

        '{"BNE x6,x7,16",
          32'h00731863,
          BRANCH, ALU_SUB, IMM_B,
          5'd16, 5'd6, 5'd7, 3'b001, 1'b0},

        '{"BLT x6,x7,16",
          32'h00734863,
          BRANCH, ALU_SLT, IMM_B,
          5'd16, 5'd6, 5'd7, 3'b100, 1'b0},

        '{"BGE x6,x7,16",
          32'h00735863,
          BRANCH, ALU_SLT, IMM_B,
          5'd16, 5'd6, 5'd7, 3'b101, 1'b0},

        '{"BLTU x6,x7,16",
          32'h00736863,
          BRANCH, ALU_SLTU, IMM_B,
          5'd16, 5'd6, 5'd7, 3'b110, 1'b0},

        '{"BGEU x6,x7,16",
          32'h00737863,
          BRANCH, ALU_SLTU, IMM_B,
          5'd16, 5'd6, 5'd7, 3'b111, 1'b0},

        '{"LB x5,8(x6)",
          32'h00830283,
          LOAD, ALU_ADD, IMM_I,
          5'd5, 5'd6, 5'd8, 3'b000, 1'b0},

        '{"LH x5,8(x6)",
          32'h00831283,
          LOAD, ALU_ADD, IMM_I,
          5'd5, 5'd6, 5'd8, 3'b001, 1'b0},

        '{"LW x5,8(x6)",
          32'h00832283,
          LOAD, ALU_ADD, IMM_I,
          5'd5, 5'd6, 5'd8, 3'b010, 1'b0},

        '{"LBU x5,8(x6)",
          32'h00834283,
          LOAD, ALU_ADD, IMM_I,
          5'd5, 5'd6, 5'd8, 3'b100, 1'b0},

        '{"LHU x5,8(x6)",
          32'h00835283,
          LOAD, ALU_ADD, IMM_I,
          5'd5, 5'd6, 5'd8, 3'b101, 1'b0},

        '{"SB x7,8(x6)",
          32'h00730423,
          STORE, ALU_ADD, IMM_S,
          5'd8, 5'd6, 5'd7, 3'b000, 1'b0},

        '{"SH x7,8(x6)",
          32'h00731423,
          STORE, ALU_ADD, IMM_S,
          5'd8, 5'd6, 5'd7, 3'b001, 1'b0},

        '{"SW x7,8(x6)",
          32'h00732423,
          STORE, ALU_ADD, IMM_S,
          5'd8, 5'd6, 5'd7, 3'b010, 1'b0},

        '{"JAL x5,0x15554",
          32'h554152ef,
          JAL, ALU_ADD, IMM_J,
          5'd5, 5'd2, 5'd20, 3'b101, 1'b0},

        '{"JALR x5,12(x6)",
          32'h00c302e7,
          JALR, ALU_ADD, IMM_I,
          5'd5, 5'd6, 5'd12, 3'b000, 1'b0},

        '{"LUI x5,0x12345",
          32'h123452b7,
          LUI, ALU_ADD, IMM_U,
          5'd5, 5'd0, 5'd3, 3'b101, 1'b0},

        '{"AUIPC x5,0x12345",
          32'h12345297,
          AUIPC, ALU_ADD, IMM_U,
          5'd5, 5'd8, 5'd3, 3'b101, 1'b0},

        '{"Illegal R-type funct7",
          32'h027302b3,
          ALU_REG, ALU_ADD, IMM_NA,
          5'd5, 5'd6, 5'd7, 3'b000, 1'b1},

        '{"Illegal SLLI funct7",
          32'h40531293,
          ALU_IMM, ALU_SLL, IMM_I,
          5'd5, 5'd6, 5'd5, 3'b001, 1'b1},

        '{"Illegal SRLI/SRAI funct7",
          32'h02535293,
          ALU_IMM, ALU_SRL, IMM_I,
          5'd5, 5'd6, 5'd5, 3'b101, 1'b1},

        '{"Illegal LOAD funct3",
          32'h00833283,
          LOAD, ALU_ADD, IMM_I,
          5'd5, 5'd6, 5'd8, 3'b011, 1'b1},

        '{"Illegal STORE funct3",
          32'h00733423,
          STORE, ALU_ADD, IMM_S,
          5'd8, 5'd6, 5'd7, 3'b011, 1'b1},

        '{"Illegal JALR funct3",
          32'h00c312e7,
          JALR, ALU_ADD, IMM_I,
          5'd5, 5'd6, 5'd12, 3'b001, 1'b1},

        '{"Illegal BRANCH funct3",
          32'h00732863,
          BRANCH, ALU_SUB, IMM_B,
          5'd16, 5'd6, 5'd7, 3'b010, 1'b1},

        '{"Illegal SYSTEM",
          32'h00000073,
          ILLEGAL, ALU_ADD, IMM_NA,
          5'd0, 5'd0, 5'd0, 3'b000, 1'b1},

        '{"Illegal FENCE",
          32'h0000000f,
          ILLEGAL, ALU_ADD, IMM_NA,
          5'd0, 5'd0, 5'd0, 3'b000, 1'b1},

        '{"Illegal unmatched opcode",
          32'h00000000,
          ILLEGAL, ALU_ADD, IMM_NA,
          5'd0, 5'd0, 5'd0, 3'b000, 1'b1}
    };

    task automatic check(test_vector_t tv);
        instr = tv.instr;
        test_count++;
        #1;

        if (
            instr_type === tv.exp_instr_type &&
            alu_op === tv.exp_alu_op &&
            imm_type === tv.exp_imm_type &&
            rd_addr === tv.exp_rd_addr &&
            rs1_addr === tv.exp_rs1_addr &&
            rs2_addr === tv.exp_rs2_addr &&
            funct3 === tv.exp_funct3 &&
            illegal === tv.exp_illegal
        ) begin
            $display("PASS: %s", tv.name);
            pass_count++;
        end
        else begin
            $display("FAIL: %s", tv.name);
            $display("instr_type = %s | expected = %s",
                     instr_type.name(), tv.exp_instr_type.name());
            $display("alu_op     = %s | expected = %s",
                     alu_op.name(), tv.exp_alu_op.name());
            $display("imm_type   = %s | expected = %s",
                     imm_type.name(), tv.exp_imm_type.name());
            $display("rd         = %0d | expected = %0d",
                     rd_addr, tv.exp_rd_addr);
            $display("rs1        = %0d | expected = %0d",
                     rs1_addr, tv.exp_rs1_addr);
            $display("rs2        = %0d | expected = %0d",
                     rs2_addr, tv.exp_rs2_addr);
            $display("funct3     = %b | expected = %b",
                     funct3, tv.exp_funct3);
            $display("illegal    = %b | expected = %b",
                     illegal, tv.exp_illegal);
            fail_count++;
        end
    endtask

    initial begin
        foreach (vectors[i]) begin
            check(vectors[i]);
        end

        $display("");
        $display("========================================");
        $display("Decoder Pass B Verification Summary");
        $display("========================================");
        $display("Total : %0d", test_count);
        $display("PASS  : %0d", pass_count);
        $display("FAIL  : %0d", fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("PASS: ALL TESTS PASSED");
        else
            $fatal(1, "FAIL: %0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule