module mdr_reg (
    input  logic        clk,

    input  logic        mdr_write,
    input  logic [31:0] mdr_in,
    output logic [31:0] mdr_out
);

always_ff @(posedge clk) begin
    if(mdr_write)
        mdr_out <= mdr_in;
end

endmodule