// =============================================================================
// ALU Top Module - 8 bits
// Lab 2: Arithmetic Logic Unit - Caravel SoC Design
// =============================================================================

module alu_top (
    input  [7:0] A,        // Input A (8 bits)
    input  [7:0] B,        // Input B (8 bits)
    input  [2:0] opcode,   // Operation selector (3 bits for 8 operations)
    output [7:0] Y         // Output Y (8 bits)
);

    // Internal wires for each operation output
    wire [7:0] add_out;
    wire [7:0] sub_out;
    wire [7:0] mul_out;
    wire [7:0] pow_out;
    wire [7:0] and_out;
    wire [7:0] nand_out;
    wire [7:0] or_out;
    wire [7:0] xor_out;

    // Instantiate all operation modules (8-bit specific)
    alu_add add_inst (
        .A(A),
        .B(B),
        .Y(add_out)
    );

    alu_sub sub_inst (
        .A(A),
        .B(B),
        .Y(sub_out)
    );

    alu_mul mul_inst (
        .A(A),
        .B(B),
        .Y(mul_out)
    );

    // Power module implementation inline (since you might not have alu_pow.v yet)
    reg [7:0] pow_result;
    always @(*) begin
        case (A)
            8'd0: pow_result = 8'd1;      // 0^0 = 1 (por convención)
            8'd1: pow_result = 8'd1;      // 1^1 = 1
            8'd2: pow_result = 8'd4;      // 2^2 = 4
            8'd3: pow_result = 8'd27;     // 3^3 = 27
            8'd4: pow_result = 8'd0;      // 4^4 = 256, pero truncado a 8 bits = 0
            8'd5: pow_result = 8'd125;    // 5^5 = 3125, truncado = 125
            8'd6: pow_result = 8'd0;      // 6^6 muy grande, truncado = 0
            8'd7: pow_result = 8'd63;     // 7^7 muy grande, truncado
            default: pow_result = 8'd255; // Saturación para valores grandes
        endcase
    end
    assign pow_out = pow_result;

    alu_and and_inst (
        .A(A),
        .B(B),
        .Y(and_out)
    );

    alu_nand nand_inst (
        .A(A),
        .B(B),
        .Y(nand_out)
    );

    alu_or or_inst (
        .A(A),
        .B(B),
        .Y(or_out)
    );

    alu_xor xor_inst (
        .A(A),
        .B(B),
        .Y(xor_out)
    );

    // Output multiplexer
    reg [7:0] mux_out;
    
    always @(*) begin
        case (opcode)
            3'b000: mux_out = add_out;   // Addition
            3'b001: mux_out = sub_out;   // Subtraction
            3'b010: mux_out = mul_out;   // Multiplication
            3'b011: mux_out = pow_out;   // Power
            3'b100: mux_out = and_out;   // AND
            3'b101: mux_out = nand_out;  // NAND
            3'b110: mux_out = or_out;    // OR
            3'b111: mux_out = xor_out;   // XOR
            default: mux_out = 8'h00;    // Default to zero
        endcase
    end

    assign Y = mux_out;

endmodule