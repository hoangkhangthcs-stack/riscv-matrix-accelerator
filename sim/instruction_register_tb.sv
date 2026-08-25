module ir_reg_tb;

    logic        clk;
    logic        ir_write;
    logic [31:0] instr_in;
    logic [31:0] instr_out;

    ir_reg dut (
        .clk(clk),
        .ir_write(ir_write),
        .instr_in(instr_in),
        .instr_out(instr_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        ir_write = 0;
        instr_in = 32'h0000_0000;

        instr_in = 32'h1234_5678;
        ir_write = 1;

        @(posedge clk);
        #1;

        if (instr_out === 32'h1234_5678)
            $display("PASS: IR write");
        else
            $display("FAIL: IR write, instr_out=%h", instr_out);

        ir_write = 0;
        instr_in = 32'hDEAD_BEEF;

        @(posedge clk);
        #1;

        if (instr_out === 32'h1234_5678)
            $display("PASS: IR hold");
        else
            $display("FAIL: IR hold, instr_out=%h", instr_out);

        ir_write = 1;
        instr_in = 32'hA5A5_5A5A;

        @(posedge clk);
        #1;

        if (instr_out === 32'hA5A5_5A5A)
            $display("PASS: second IR write");
        else
            $display("FAIL: second IR write, instr_out=%h", instr_out);

        $finish;
    end

endmodule