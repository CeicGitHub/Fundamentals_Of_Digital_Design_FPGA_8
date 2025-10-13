module alu_mul (
    input  [7:0] A,
    input  [7:0] B,
    output [7:0] Y
);
    // Para 8 bits, el producto puede ser hasta 16 bits, pero truncamos a 8
    assign Y = A * B;
endmodule