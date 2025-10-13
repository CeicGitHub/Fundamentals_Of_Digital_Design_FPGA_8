// =============================================================================
// ALU NAND Module - 8 bits
// Lab 2: Arithmetic Logic Unit - Caravel SoC Design
// =============================================================================

module alu_nand (
    input  [7:0] A,
    input  [7:0] B,
    output [7:0] Y
);
    assign Y = ~(A & B);
endmodule