`timescale 1ns/1ps

module immediate_generator_tb;

    logic [31:0] instr;
    rv32i_pkg::imm_type_e imm_type;
    logic [31:0] imm_out;

    immediate_generator dut (
        .instr(instr),
        .imm_type(imm_type),
        .imm_out(imm_out)
    );

    task automatic check_imm(
        input logic [31:0] test_instr,
        input rv32i_pkg::imm_type_e test_type,
        input logic [31:0] expected
    );
        begin
            instr = test_instr;
            imm_type = test_type;
            #1;

            if (imm_out !== expected) begin
                $error("FAIL: instr=%h type=%0d expected=%h got=%h",
                       test_instr, test_type, expected, imm_out);
            end else begin
                $display("PASS: instr=%h type=%0d imm=%h",
                         test_instr, test_type, imm_out);
            end
        end
    endtask

    initial begin
        instr = 32'd0;
        imm_type = rv32i_pkg::IMM_I;
        #1;

        check_imm(
            32'b000000001000_00110_010_00101_0000011,
            rv32i_pkg::IMM_I,
            32'h00000008
        );

        check_imm(
            32'b111111111111_00110_010_00101_0000011,
            rv32i_pkg::IMM_I,
            32'hFFFFFFFF
        );

        check_imm(
            32'b0000000_00111_00110_010_01000_0100011,
            rv32i_pkg::IMM_S,
            32'h00000008
        );

        check_imm(
            32'b1111111_00111_00110_010_11111_0100011,
            rv32i_pkg::IMM_S,
            32'hFFFFFFFF
        );

        check_imm(
            32'b0000000_00010_00001_000_1000_0_1100011,
            rv32i_pkg::IMM_B,
            32'h00000010
        );

        check_imm(
            32'b1000000_00010_00001_000_0000_0_1100011,
            rv32i_pkg::IMM_B,
            32'hFFFFF000
        );

        check_imm(
            32'b1111111_00010_00001_000_1111_1_1100011,
            rv32i_pkg::IMM_B,
            32'hFFFFFFFE
        );

        check_imm(
            32'b00000000000100000001_00101_0110111,
            rv32i_pkg::IMM_U,
            32'h00101000
        );

        check_imm(
            32'b10000000000100000001_00101_0110111,
            rv32i_pkg::IMM_U,
            32'h80101000
        );

        check_imm(
            32'b00000000010000000000_00001_1101111,
            rv32i_pkg::IMM_J,
            32'h00000004
        );

        check_imm(
            32'b10000000000000000000_00001_1101111,
            rv32i_pkg::IMM_J,
            32'hFFF00000
        );

        check_imm(
            32'b11111111111111111111_00001_1101111,
            rv32i_pkg::IMM_J,
            32'hFFFFFFFE
        );

        $display("Immediate Generator testbench completed.");
        $finish;
    end

endmodule