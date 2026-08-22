module alu_tb;

import rv32i_pkg::*;
logic [31:0] operand_a;
logic [31:0] operand_b;
alu_op_e alu_op;
logic [31:0] result;

int test_count = 0;
int pass = 0;
int error = 0;

alu dut(
    .operand_a(operand_a),
    .operand_b(operand_b),
    .alu_op(alu_op),
    .result(result)
);

task automatic check(
    input string testname, 
    input logic [31:0] a,
    input logic [31:0] b,
    input alu_op_e op,
    input logic [31:0] expected
);
    test_count ++;
    operand_a = a;
    operand_b = b;
    alu_op = op;
    #1;
    if(result === expected) begin
        $display(
            "PASS: testname=%s  op=%s   A=0x%h  B=0x%h | result=0x%h    expected=0x%h",
            testname,
            op.name(),
            a,
            b,
            result,
            expected
        );
        pass++;
    end
    else begin
        $error(
            "FAIL: testname=%s  op=%s  A=0x%h B=0x%h | result=0x%h  expected=0x%h",
            testname,
            op.name(),
            a,
            b,
            result,
            expected
        );
        error++;
    end
endtask 

initial begin
    check(
        .testname("ADD(normal)"),
        .a(32'h0000_0005),
        .b(32'h0000_0003),
        .op(ALU_ADD),
        .expected(32'h0000_0008)
    );

    check(
        .testname("ADD(wrap around)"),
        .a(32'hFFFFFFFF),
        .b(32'h0000_0001),
        .op(ALU_ADD),
        .expected(32'h0000_0000)
    );

    check(
        .testname("SUB(normal)"),
        .a(32'h0000_0010),
        .b(32'h0000_0003),
        .op(ALU_SUB),
        .expected(32'h0000_000D)
    );

    check(
        .testname("SUB(wrap around)"),
        .a(32'h0000_0000),
        .b(32'h0000_0001),
        .op(ALU_SUB),
        .expected(32'hFFFFFFFF)
    );

    check(
        .testname("SLL(shift by 0)"),
        .a(32'h1234_5678),
        .b(32'h0000_0000),
        .op(ALU_SLL),
        .expected(32'h1234_5678)
    );

    check(
        .testname("SLL(shift by 31)"),
        .a(32'h0000_0001),
        .b(32'h0000_001F),
        .op(ALU_SLL),
        .expected(32'h8000_0000)
    );

    check(
        .testname("SLL(operand_b with garbage value)"),
        .a(32'h0000_0001),
        .b(32'hFFFF_FFE5),
        .op(ALU_SLL),
        .expected(32'h0000_0020)
    );

    check(
        .testname("SRL(shift by 1)"),
        .a(32'h8000_0000),
        .b(32'd1),
        .op(ALU_SRL),
        .expected(32'h4000_0000)
    );

    check(
        .testname("SRA(shift by 1)"),
        .a(32'h8000_0000),
        .b(32'd1),
        .op(ALU_SRA),
        .expected(32'hC000_0000)
    );

    check(
        .testname("SLT(true case)"),
        .a(32'hFFFF_FFFF),
        .b(32'd1),
        .op(ALU_SLT),
        .expected(32'd1)
    );

    check(
        .testname("SLT(false case)"),
        .a(32'h0000_0005),
        .b(32'hFFFF_FFFD),
        .op(ALU_SLT),
        .expected(32'd0)
    );

    check(
        .testname("SLTU(true case)"),
        .a(32'h0000_0005),
        .b(32'hFFFF_FFFD),
        .op(ALU_SLTU),
        .expected(32'd1)
    );

    check(
        .testname("SLTU(false case)"),
        .a(32'hFFFF_FFFF),
        .b(32'd1),
        .op(ALU_SLTU),
        .expected(32'd0)
    );

    check(
        .testname("XOR"),
        .a(32'hAAAA_AAAA),
        .b(32'h5555_5555),
        .op(ALU_XOR),
        .expected(32'hFFFF_FFFF)
    );

    check(
        .testname("OR"),
        .a(32'hAAAA_AAAA),
        .b(32'h5555_5555),
        .op(ALU_OR),
        .expected(32'hFFFF_FFFF)
    );

    check(
        .testname("AND"),
        .a(32'hAAAA_AAAA),
        .b(32'h5555_5555),
        .op(ALU_AND),
        .expected(32'h0000_0000)
    );

    check(
        .testname("Invalid"),
        .a(32'hABCD_ABCD),
        .b(32'hABCD_ABCD),
        .op(alu_op_e'(4'hA)),
        .expected(32'd0)
    );
    
    $display("");
    $display("========================================");
    $display("             ALU TEST RESULT");
    $display("========================================");
    $display("Total tests : %d", test_count);
    $display("Pass        : %d", pass);
    $display("Errors      : %d", error);

    if(error == 0) 
        $display("RESULT   : PASS");
    else 
        $display("RESULT   : FAIL");

    $display("========================================");
    $finish;
end
endmodule