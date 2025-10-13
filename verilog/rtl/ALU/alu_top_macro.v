// alu_top_macro.v


module alu_top_macro
(
`ifdef USE_POWER_PINS
    inout vccd1,    // 1.8V
    inout vssd1,    // GND
`endif
    input  [7:0] A,
    input  [7:0] B,
    input  [2:0] opcode,
    output [7:0] Y
);

    alu_top u_alu_top (
        .A      (A),
        .B      (B),
        .opcode (opcode),
        .Y      (Y)
    );

endmodule

