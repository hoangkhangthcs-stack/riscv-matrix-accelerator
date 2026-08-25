module pc_reg_tb;

    logic        clk;
    logic        rst_n;
    logic        pc_write;
    logic [31:0] pc_next;
    logic [31:0] pc_out;

    pc_reg dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_write(pc_write),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        pc_write = 0;
        pc_next = 32'h0000_0000;

        #1;
        if (pc_out === 32'h0000_0000)
            $display("PASS: reset");
        else
            $display("FAIL: reset, pc_out=%h", pc_out);

        #9;
        rst_n = 1;
        pc_write = 1;
        pc_next = 32'h0000_1000;

        @(posedge clk);
        #1;
        if (pc_out === 32'h0000_1000)
            $display("PASS: PC write");
        else
            $display("FAIL: PC write, pc_out=%h", pc_out);

        pc_write = 0;
        pc_next = 32'h0000_2000;

        @(posedge clk);
        #1;
        if (pc_out === 32'h0000_1000)
            $display("PASS: PC hold");
        else
            $display("FAIL: PC hold, pc_out=%h", pc_out);

        pc_write = 1;
        pc_next = 32'h0000_3000;

        @(posedge clk);
        #1;
        if (pc_out === 32'h0000_3000)
            $display("PASS: second PC write");
        else
            $display("FAIL: second PC write, pc_out=%h", pc_out);

        $finish;
    end

endmodule
