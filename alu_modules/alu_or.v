module alu_or (
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif
    input  [7:0] A,
    input  [7:0] B,
    output [7:0] Y
);
    assign Y = A | B;
endmodule
