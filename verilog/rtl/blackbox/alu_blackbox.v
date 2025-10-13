// Blackbox definitions for ALU macros
/// sta-blackbox

module alu_add (
    inout vccd1,
    inout vssd1,
    input [7:0] A,
    input [7:0] B,
    output [7:0] Y
);
endmodule

module alu_sub (
    inout vccd1,
    inout vssd1,
    input [7:0] A,
    input [7:0] B,
    output [7:0] Y
);
endmodule

module alu_mul (
    inout vccd1,
    inout vssd1,
    input [7:0] A,
    input [7:0] B,
    output [7:0] Y
);
endmodule

module alu_pow (
    inout vccd1,
    inout vssd1,
    input [7:0] A,
    output [7:0] Y
);
endmodule

module alu_and (
    inout vccd1,
    inout vssd1,
    input [7:0] A,
    input [7:0] B,
    output [7:0] Y
);
endmodule

module alu_nand (
    inout vccd1,
    inout vssd1,
    input [7:0] A,
    input [7:0] B,
    output [7:0] Y
);
endmodule

module alu_or (
    inout vccd1,
    inout vssd1,
    input [7:0] A,
    input [7:0] B,
    output [7:0] Y
);
endmodule

module alu_xor (
    inout vccd1,
    inout vssd1,
    input [7:0] A,
    input [7:0] B,
    output [7:0] Y
);
endmodule
