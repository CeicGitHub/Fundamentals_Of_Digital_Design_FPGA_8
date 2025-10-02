`timescale 1ns/1ps

module lifo_tb;
  // Parámetros del DUT
  localparam DATA_W = 32;
  localparam ADDR_W = 8;
  localparam DEPTH  = 256;

  // Señales hacia el DUT
  reg                   clk;
  reg                   rst_n;
  reg                   push;
  reg                   pop;
  reg  [DATA_W-1:0]     data_in;
  wire [DATA_W-1:0]     data_out;
  wire                  full, empty, error;

  // Instancia del DUT
  lifo_top #(
    .DATA_WIDTH(DATA_W),
    .ADDR_WIDTH(ADDR_W),
    .DEPTH(DEPTH)
  ) dut (
    .clk    (clk),
    .rst_n  (rst_n),
    .push   (push),
    .pop    (pop),
    .data_in(data_in),
    .data_out(data_out),
    .full   (full),
    .empty  (empty),
    .error  (error)
  );

  // Reloj 100 MHz (10 ns)
  initial clk = 0;
  always #5 clk = ~clk;

  // Tareas útiles
  task do_push(input [DATA_W-1:0] val);
    begin
      @(negedge clk);
      data_in <= val;
      push    <= 1'b1;
      pop     <= 1'b0;
      @(negedge clk);
      push    <= 1'b0;
    end
  endtask

  task do_pop;
    begin
      @(negedge clk);
      push <= 1'b0;
      pop  <= 1'b1;
      @(negedge clk);
      pop  <= 1'b0;
    end
  endtask

  // Estímulos
  initial begin
    // Iniciales
    push    = 0;
    pop     = 0;
    data_in = 0;

    // Reset activo-bajo
    rst_n = 0;
    repeat(5) @(negedge clk);
    rst_n = 1;

    // Pushear 3 palabras
    do_push(32'hA1A1_0001);
    do_push(32'hB2B2_0002);
    do_push(32'hC3C3_0003);

    // Popear 2 (debe salir 0003 y luego 0002)
    do_pop();
    // Espera un ciclo para ver data_out estable y muestrearlo:
    @(negedge clk);
    do_pop();
    @(negedge clk);

    // Pushear otra y popear 2 (0004 y luego 0001)
    do_push(32'hD4D4_0004);
    do_pop();
    @(negedge clk);
    do_pop();
    @(negedge clk);

    // Underflow de prueba (POP con pila vacía) → error=1
    do_pop();
    @(negedge clk);

    repeat(5) @(negedge clk);
    $finish;
  end
endmodule
