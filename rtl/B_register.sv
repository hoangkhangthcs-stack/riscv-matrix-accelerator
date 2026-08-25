module b_reg (
    input  logic        clk,
    input  logic        b_write,
    input  logic [31:0] b_in,     
    output logic [31:0] b_out
);

always @(clk) begin
    if(b_write) 
        b_out <= b_in;
end

endmodule