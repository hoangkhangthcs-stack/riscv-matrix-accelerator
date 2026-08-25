module a_reg (
    input  logic        clk,
    input  logic        a_write,
    input  logic [31:0] a_in,     
    output logic [31:0] a_out
);

always_ff @(posedge clk) begin
    if(a_write) 
        a_out <= a_in;
end

endmodule