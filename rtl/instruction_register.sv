module ir_reg (
    input  logic        clk,

    input  logic        ir_write,
    input  logic [31:0] instr_in,
    output logic [31:0] instr_out
);

always_ff @(posedge clk) begin
    if(ir_write)
        instr_out <= instr_in;
end

endmodule