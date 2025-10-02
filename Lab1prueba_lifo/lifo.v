//todo: LIFO con controlador y SRAM (macro simulada)
//! Ricardo Martines Torres Lopez y Cesar Eduardo Inda Ceniceros
//? Lab1: Modulo8 SKY130 SRAM MACROS --> LIFO

`timescale 1ns/1ps
`default_nettype none // esto lo agregamos para evitar errores por nets implícitas

//*Aqui se agrego una memoria simple para simular la macro de SRAM
//* de amanera que si "SYNC_READ" es 0, la lectura es combinacional
//* y si es 1, la lectura es sincrónica (1 ciclo de latencia después)

module simple_memory #(
    parameter integer DATA_WIDTH = 32,
    parameter integer ADDR_WIDTH = 8,
    parameter integer DEPTH      = 256,
    parameter integer SYNC_READ  = 0  // 0: combinacional, 1: sincrónica
)(
`ifdef USE_POWER_PINS
    inout vccd1,   // no usados aquí, pero quedan para compatibilidad
    inout vssd1,
`endif
    input  wire                     clk,
    input  wire                     we,
    input  wire [ADDR_WIDTH-1:0]    addr,
    input  wire [DATA_WIDTH-1:0]    data_in,
    output reg  [DATA_WIDTH-1:0]    data_out
);

    // Memoria
    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    // Inicialización (solo sim)
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) memory[i] = {DATA_WIDTH{1'b0}};
        data_out = {DATA_WIDTH{1'b0}};
    end

    // Escritura sincrónica
    always @(posedge clk) begin
        if (we && (addr < DEPTH)) begin
            memory[addr] <= data_in;
        end
    end

generate
if (SYNC_READ == 0) begin : g_comb_read
    // Lectura combinacional
    always @(*) begin
        if (addr < DEPTH) data_out = memory[addr];
        else              data_out = {DATA_WIDTH{1'b0}};
    end
end else begin : g_sync_read
    // Lectura sincrónica (1 ciclo de latencia)
    always @(posedge clk) begin
        if (addr < DEPTH) data_out <= memory[addr];
        else              data_out <= {DATA_WIDTH{1'b0}};
    end
end
endgenerate

    // Ayuda a lint/síntesis: evita warnings por pines de power sin uso real
    // synthesis translate_off
`ifdef USE_POWER_PINS
    wire _unused_pwr_ = &{1'b0, vccd1, vssd1};
`endif
    // synthesis translate_on

endmodule


module sky130_sram_1kbyte_1rw1r_32x256_8 #(
    parameter integer SYNC_READ = 0  // propaga a simple_memory
)(
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif
    // Puerto 0: 1RW
    input  wire          clk0,
    input  wire          csb0,     // activo en bajo
    input  wire          web0,     // activo en bajo (0=write)
    input  wire [7:0]    addr0,
    input  wire [31:0]   din0,
    output wire [31:0]   dout0,
    // Puerto 1: 1R (no usado / deshabilitado)
    input  wire          clk1,
    input  wire          csb1,
    input  wire [7:0]    addr1,
    output wire [31:0]   dout1
);
    // Escribimos sólo cuando el chip está habilitado y web0=0
    wire mem_we   = (~csb0) & (~web0);
    wire [31:0] mem_dout;

    simple_memory #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(8),
        .DEPTH     (256),
        .SYNC_READ (SYNC_READ)
    ) u_behav_mem (
    `ifdef USE_POWER_PINS
        .vccd1(vccd1),
        .vssd1(vssd1),
    `endif
        .clk     (clk0),
        .we      (mem_we),
        .addr    (addr0),
        .data_in (din0),
        .data_out(mem_dout)
    );

    // Cuando csb0=1 (deshabilitado) forzamos 0s
    assign dout0 = (~csb0) ? mem_dout : 32'h0000_0000;

    // Puerto 1 deshabilitado
    assign dout1 = 32'h0000_0000;

    // Evitar warnings por señales no usadas del puerto 1
    // synthesis translate_off
    wire _unused_rp1_ = &{1'b0, clk1, csb1, addr1[0]};
    // synthesis translate_on
endmodule


module lifo_controller #(
    parameter integer ADDR_WIDTH = 8,   // 256 entradas -> 8 bits
    parameter integer DEPTH      = 256
)(
`ifdef USE_POWER_PINS
    inout vccd1,   // 1.8V
    inout vssd1,   // GND
`endif
    input  wire                   clk,
    input  wire                   rst_n,  // reset asíncrono activo-bajo

    input  wire                   push,
    input  wire                   pop,

    output reg                    sram_we,         // 1 = escritura, 0 = lectura
    output reg  [ADDR_WIDTH-1:0]  sram_addr,       // dirección efectiva

    output wire [ADDR_WIDTH-1:0]  stack_pointer,   // puntero "next free"
    output wire                   full,
    output wire                   empty,
    output reg                    error
);
    // Puntero con bit extra para detectar lleno exacto
    reg [ADDR_WIDTH:0] sp_counter; // 0..DEPTH

    assign stack_pointer = sp_counter[ADDR_WIDTH-1:0];
    assign full  = (sp_counter == DEPTH);
    assign empty = (sp_counter == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sp_counter <= { (ADDR_WIDTH+1){1'b0} };
            sram_we    <= 1'b0;
            sram_addr  <= { ADDR_WIDTH{1'b0} };
            error      <= 1'b0;
        end else begin
            error   <= 1'b0;
            sram_we <= 1'b0; 

            if (push && pop) begin
                error <= 1'b1; 
            end else if (push) begin
                if (!full) begin
                    sram_we    <= 1'b1;                         // write
                    sram_addr  <= sp_counter[ADDR_WIDTH-1:0];   // dir = sp
                    sp_counter <= sp_counter + 1'b1;            // sp++
                end else begin
                    error <= 1'b1; // overflow
                end
            end else if (pop) begin
                if (!empty) begin
                    sram_we    <= 1'b0;                         // read
                    sram_addr  <= sp_counter[ADDR_WIDTH-1:0] - 1'b1; // sp-1
                    sp_counter <= sp_counter - 1'b1;            // sp--
                end else begin
                    error <= 1'b1; // underflow
                end
            end
        end
    end

    // synthesis translate_off
    always @(posedge clk) begin
        if (rst_n) begin
            if (sp_counter > DEPTH) $fatal(1, "LIFO: sp_counter > DEPTH");
        end
    end
    // synthesis translate_on
endmodule


module lifo_top #(
    parameter integer DATA_WIDTH = 32,
    parameter integer DEPTH      = 256,
    parameter integer ADDR_WIDTH = 8, // $clog2(DEPTH)
    parameter integer SYNC_READ  = 0  // 0: comb 1: sync
)(
`ifdef USE_POWER_PINS
    inout vccd1,   // 1.8V
    inout vssd1,   // GND
`endif
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     push,
    input  wire                     pop,
    input  wire [DATA_WIDTH-1:0]    data_in,
    output reg  [DATA_WIDTH-1:0]    data_out,

    output wire                     full,
    output wire                     empty,
    output wire                     error
);
    // Señales internas SRAM
    wire [ADDR_WIDTH-1:0] sram_addr;
    wire                  sram_we;         // 1=write
    wire [DATA_WIDTH-1:0] sram_data_in = data_in;
    wire [DATA_WIDTH-1:0] sram_data_out;

    // Habilitación de chip cuando hay operación
    wire mem_en = (push | pop);

    // Controlador
    lifo_controller #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DEPTH      (DEPTH)
    ) u_ctrl (
    `ifdef USE_POWER_PINS
        .vccd1     (vccd1),
        .vssd1     (vssd1),
    `endif
        .clk       (clk),
        .rst_n     (rst_n),
        .push      (push),
        .pop       (pop),
        .sram_we   (sram_we),
        .sram_addr (sram_addr),
        .stack_pointer(), // conectar si quieres observar SP
        .full      (full),
        .empty     (empty),
        .error     (error)
    );

    // "Macro" SRAM (wrapper behavioral)
    sky130_sram_1kbyte_1rw1r_32x256_8 #(
        .SYNC_READ (SYNC_READ)
    ) u_sram (
    `ifdef USE_POWER_PINS
        .vccd1 (vccd1),
        .vssd1 (vssd1),
    `endif
        .clk0   (clk),
        .csb0   (~mem_en),      // activo en bajo
        .web0   (~sram_we),     // activo en bajo
        .addr0  (sram_addr),
        .din0   (sram_data_in),
        .dout0  (sram_data_out),

        .clk1   (clk),
        .csb1   (1'b1),
        .addr1  (8'b0),
        .dout1  ()
    );

    // Registrar dato leído al hacer POP. Mantener data_out estable si no hay POP.
    //Para obtener timing correcto si SYNC_READ=1
    reg data_valid_int;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out       <= {DATA_WIDTH{1'b0}};
            data_valid_int <= 1'b0;
        end else begin
            // Marca y captura en POP
            data_valid_int <= pop;
            if (pop) data_out <= sram_data_out;
            // Si  SYNC_READ=1 es 1 ciclo después,
            // cambia a: if (data_valid_int) data_out <= sram_data_out;
        end
    end

endmodule

`default_nettype wire

