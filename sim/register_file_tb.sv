module register_file_tb;

    logic        clk;

    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    logic [4:0]  rd_addr;
    logic [31:0] rd_data;
    logic        rd_we;

    int pass_count = 0;
    int fail_count = 0;

    register_file dut (
        .clk      (clk),
        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data),
        .rd_addr  (rd_addr),
        .rd_data  (rd_data),
        .rd_we    (rd_we)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic write_and_check (
        input logic [4:0]  addr,
        input logic [31:0] data
    );
        begin
            rd_addr = addr;
            rd_data = data;
            rd_we   = 1'b1;

            @(posedge clk);
            #1;

            rd_we = 1'b0;

            rs1_addr = addr;
            #1;

            if (rs1_data !== data) begin
                $error(
                    "FAIL: write/read x%0d | expected = 0x%08h, got = 0x%08h",
                    addr, data, rs1_data
                );
                fail_count++;
            end
            else begin
                $display(
                    "PASS: write/read x%0d = 0x%08h",
                    addr, rs1_data
                );
                pass_count++;
            end
        end
    endtask

    task automatic read_check (
        input logic [4:0]  addr1,
        input logic [31:0] expected1,
        input logic [4:0]  addr2,
        input logic [31:0] expected2
    );
        begin
            rs1_addr = addr1;
            rs2_addr = addr2;

            #1;

            if (rs1_data !== expected1) begin
                $error(
                    "FAIL: rs1 read x%0d | expected = 0x%08h, got = 0x%08h",
                    addr1, expected1, rs1_data
                );
                fail_count++;
            end
            else begin
                $display(
                    "PASS: rs1 read x%0d = 0x%08h",
                    addr1, rs1_data
                );
                pass_count++;
            end

            if (rs2_data !== expected2) begin
                $error(
                    "FAIL: rs2 read x%0d | expected = 0x%08h, got = 0x%08h",
                    addr2, expected2, rs2_data
                );
                fail_count++;
            end
            else begin
                $display(
                    "PASS: rs2 read x%0d = 0x%08h",
                    addr2, rs2_data
                );
                pass_count++;
            end
        end
    endtask

    initial begin

        rs1_addr = 5'd0;
        rs2_addr = 5'd0;
        rd_addr  = 5'd0;
        rd_data  = 32'd0;
        rd_we    = 1'b0;

        $display("");
        $display("TEST 1: Basic write/read");
        write_and_check(5'd5, 32'h1234_5678);

        $display("");
        $display("TEST 2: Read x0 without writing");

        rs1_addr = 5'd0;
        #1;

        if (rs1_data !== 32'd0) begin
            $error(
                "FAIL: x0 read | expected = 0x00000000, got = 0x%08h",
                rs1_data
            );
            fail_count++;
        end
        else begin
            $display("PASS: x0 reads as zero");
            pass_count++;
        end

        $display("");
        $display("TEST 3: Write to x0 must have no architectural effect");

        rd_addr = 5'd0;
        rd_data = 32'hDEAD_BEEF;
        rd_we   = 1'b1;

        @(posedge clk);
        #1;

        rd_we = 1'b0;

        rs1_addr = 5'd0;
        #1;

        if (rs1_data !== 32'd0) begin
            $error(
                "FAIL: x0 write | expected = 0x00000000, got = 0x%08h",
                rs1_data
            );
            fail_count++;
        end
        else begin
            $display("PASS: write to x0 has no architectural effect");
            pass_count++;
        end

        $display("");
        $display("TEST 4: Multiple independent registers");

        write_and_check(5'd1, 32'h1111_1111);
        write_and_check(5'd2, 32'h2222_2222);
        write_and_check(5'd3, 32'h3333_3333);

        $display("");
        $display("TEST 5: Two independent read ports");

        read_check(
            5'd1,
            32'h1111_1111,
            5'd3,
            32'h3333_3333
        );

        $display("");
        $display("TEST 6: Both read ports access the same register");

        read_check(
            5'd2,
            32'h2222_2222,
            5'd2,
            32'h2222_2222
        );

        $display("");
        $display("TEST 7: rd_we = 0 must prevent write");

        rd_addr = 5'd5;
        rd_data = 32'hFFFF_FFFF;
        rd_we   = 1'b0;

        @(posedge clk);
        #1;

        rs1_addr = 5'd5;
        #1;

        if (rs1_data !== 32'h1234_5678) begin
            $error(
                "FAIL: rd_we=0 changed x5 | expected = 0x12345678, got = 0x%08h",
                rs1_data
            );
            fail_count++;
        end
        else begin
            $display(
                "PASS: rd_we=0 preserved x5 = 0x%08h",
                rs1_data
            );
            pass_count++;
        end

        $display("");
        $display("========================================");
        $display("Register File Testbench Summary");
        $display("========================================");
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");

        $display("");

        $finish;
    end

endmodule