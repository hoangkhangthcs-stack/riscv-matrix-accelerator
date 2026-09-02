module alu_out_reg (
    input  logic        clk,

    input  logic        alu_out_write,
    input  logic [31:0] alu_result_in,   
    output logic [31:0] alu_out
);

always_ff @(posedge clk) begin
    if(alu_out_write)
        alu_out <= alu_result_in;
end

endmodule