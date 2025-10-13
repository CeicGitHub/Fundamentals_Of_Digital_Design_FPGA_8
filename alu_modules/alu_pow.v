module alu_pow (
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif
    input  [7:0] A,
    output [7:0] Y
);
    reg [7:0] result;
    
    always @(*) begin
        case (A)
            8'd0: result = 8'd1;      // 0^0 = 1 (por convención)
            8'd1: result = 8'd1;      // 1^1 = 1
            8'd2: result = 8'd4;      // 2^2 = 4
            8'd3: result = 8'd27;     // 3^3 = 27
            8'd4: result = 8'd0;      // 4^4 = 256, truncado a 8 bits = 0
            8'd5: result = 8'd125;    // 5^5 = 3125, truncado = 125
            8'd6: result = 8'd0;      // 6^6 muy grande, truncado = 0
            8'd7: result = 8'd63;     // 7^7 muy grande, truncado
            default: result = 8'd255; // Saturación para valores grandes
        endcase
    end
    
    assign Y = result;
endmodule
