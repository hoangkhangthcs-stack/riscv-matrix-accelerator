`timescale 1ns/1ps

module decoder_tb;

    import rv32i_pkg::*;

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

    task automatic check(
        input logic [31:0] expected_instr,
        input instr_type_e expected_instr_type,
        input alu_op_e expected_alu_op,
        input imm_type_e expected_imm_type,
        input logic [4:0] expected_rd,
        input logic [4:0] expected_rs1,
        input logic [4:0] expected_rs2,
        input logic [2:0] expected_funct3,
        input logic expected_illegal
    );

        instr = expected_instr;
        test_count ++;
        #1;

        if (
            instr_type === expected_instr_type &&
            alu_op === expected_alu_op &&
            imm_type === expected_imm_type &&
            rd_addr === expected_rd &&
            rs1_addr === expected_rs1 &&
            rs2_addr === expected_rs2 &&
            funct3 === expected_funct3 &&
            illegal === expected_illegal
        ) begin
            $display("PASS: test %d instr=%b", test_count, instr);
            pass_count++;
        end
        else begin
            fail_count++;

            $display("FAIL: test %d", test_count);
            $display("instr        = %b", instr);
            $display("instr_type   = %s", instr_type.name());
            $display("expected     = %s", expected_instr_type.name());
            $display("alu_op       = %s", alu_op.name());
            $display("expected     = %s", expected_alu_op.name());
            $display("imm_type     = %s", imm_type.name());
            $display("expected     = %s", expected_imm_type.name());
            $display("rd           = %0d", rd_addr);
            $display("expected rd  = %0d", expected_rd);
            $display("rs1          = %0d", rs1_addr);
            $display("expected rs1 = %0d", expected_rs1);
            $display("rs2          = %0d", rs2_addr);
            $display("expected rs2 = %0d", expected_rs2);
            $display("funct3       = %b", funct3);
            $display("expected     = %b", expected_funct3);
            $display("illegal      = %b", illegal);
            $display("expected     = %b", expected_illegal);
        end
    endtask

    initial begin

        check(
            {7'b0000000, 5'd7, 5'd6, 3'b000, 5'd5, 7'b0110011},
            ALU_REG,
            ALU_ADD,
            IMM_NA,
            5'd5,
            5'd6,
            5'd7,
            3'b000,
            1'b0
        );

        check(
            {7'b0100000, 5'd7, 5'd6, 3'b000, 5'd5, 7'b0110011},
            ALU_REG,
            ALU_SUB,
            IMM_NA,
            5'd5,
            5'd6,
            5'd7,
            3'b000,
            1'b0
        );

        check(
            {7'b0000000, 5'd7, 5'd6, 3'b101, 5'd5, 7'b0110011},
            ALU_REG,
            ALU_SRL,
            IMM_NA,
            5'd5,
            5'd6,
            5'd7,
            3'b101,
            1'b0
        );

        check(
            {7'b0100000, 5'd7, 5'd6, 3'b101, 5'd5, 7'b0110011},
            ALU_REG,
            ALU_SRA,
            IMM_NA,
            5'd5,
            5'd6,
            5'd7,
            3'b101,
            1'b0
        );

        check(
            {12'hC00, 5'd6, 3'b000, 5'd5, 7'b0010011},
            ALU_IMM,
            ALU_ADD,
            IMM_I,
            5'd5,
            5'd6,
            5'd0,
            3'b000,
            1'b0
        );

        check(
            {7'b0000000, 5'd7, 5'd6, 3'b001, 5'd5, 7'b0010011},
            ALU_IMM,
            ALU_SLL,
            IMM_I,
            5'd5,
            5'd6,
            5'd7,
            3'b001,
            1'b0
        );

        check(
            {7'b0000000, 5'd7, 5'd6, 3'b101, 5'd5, 7'b0010011},
            ALU_IMM,
            ALU_SRL,
            IMM_I,
            5'd5,
            5'd6,
            5'd7,
            3'b101,
            1'b0
        );

        check(
            {7'b0100000, 5'd7, 5'd6, 3'b101, 5'd5, 7'b0010011},
            ALU_IMM,
            ALU_SRA,
            IMM_I,
            5'd5,
            5'd6,
            5'd7,
            3'b101,
            1'b0
        );

        check(
            {12'h008, 5'd6, 3'b010, 5'd5, 7'b0000011},
            LOAD,
            ALU_ADD,
            IMM_I,
            5'd5,
            5'd6,
            5'd8,
            3'b010,
            1'b0
        );

        check(
            {7'h00, 5'd7, 5'd6, 3'b010, 5'h08, 7'b0100011},
            STORE,
            ALU_ADD,
            IMM_S,
            5'd8,
            5'd6,
            5'd7,
            3'b010,
            1'b0
        );

        check(
            {1'b0, 6'b000000, 5'd2, 5'd1, 3'b000, 4'b1000, 1'b0, 7'b1100011},
            BRANCH,
            ALU_SUB,
            IMM_B,
            5'd16,
            5'd1,
            5'd2,
            3'b000,
            1'b0
        );

        check(
            {1'b0, 6'b000000, 5'd2, 5'd1, 3'b001, 4'b1000, 1'b0, 7'b1100011},
            BRANCH,
            ALU_SUB,
            IMM_B,
            5'd16,
            5'd1,
            5'd2,
            3'b001,
            1'b0
        );

        check(
            {1'b0, 6'b000000, 5'd2, 5'd1, 3'b100, 4'b1000, 1'b0, 7'b1100011},
            BRANCH,
            ALU_SLT,
            IMM_B,
            5'd16,
            5'd1,
            5'd2,
            3'b100,
            1'b0
        );

        check(
            {1'b0, 6'b000000, 5'd2, 5'd1, 3'b101, 4'b1000, 1'b0, 7'b1100011},
            BRANCH,
            ALU_SLT,
            IMM_B,
            5'd16,
            5'd1,
            5'd2,
            3'b101,
            1'b0
        );

        check(
            {1'b0, 6'b000000, 5'd2, 5'd1, 3'b110, 4'b1000, 1'b0, 7'b1100011},
            BRANCH,
            ALU_SLTU,
            IMM_B,
            5'd16,
            5'd1,
            5'd2,
            3'b110,
            1'b0
        );

        check(
            {1'b0, 6'b000000, 5'd2, 5'd1, 3'b111, 4'b1000, 1'b0, 7'b1100011},
            BRANCH,
            ALU_SLTU,
            IMM_B,
            5'd16,
            5'd1,
            5'd2,
            3'b111,
            1'b0
        );

        check(
            {12'h123, 5'd6, 3'b000, 5'd5, 7'b1100111},
            JALR,
            ALU_ADD,
            IMM_I,
            5'd5,
            5'd6,
            5'd3,
            3'b000,
            1'b0
        );

        check(
            {20'h00010, 5'd5, 7'b1101111},
            JAL,
            ALU_ADD,
            IMM_J,
            5'd5,
            5'd2,
            5'd0,
            3'b000,
            1'b0
        );

        check(
            {20'hABCDE, 5'd5, 7'b0110111},
            LUI,
            ALU_ADD,
            IMM_U,
            5'd5,
            5'd0,
            5'd28,
            3'b110,
            1'b0
        );

        check(
            {20'hABCDE, 5'd5, 7'b0010111},
            AUIPC,
            ALU_ADD,
            IMM_U,
            5'd5,
            5'd27,
            5'd28,
            3'b110,
            1'b0
        );

        instr = 32'hFFFFFFFF;
        #1;

        if (
            instr_type === ILLEGAL &&
            illegal === 1'b0 &&
            imm_type === IMM_NA &&
            alu_op === ALU_ADD
        ) begin
            pass_count++;
        end
        else begin
            fail_count++;
            $display("FAIL: default opcode");
        end

        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);

        if (fail_count == 0)
            $display("DECODER PASS A: PASS");
        else
            $display("DECODER PASS A: FAIL");

        $finish;
    end

endmodule