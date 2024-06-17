module TestBench ();
  // Values
  parameter WORD_SIZE = 15;

  // Declare signals
  reg clk;
  reg rst;
  reg input_data[WORD_SIZE:0];
  reg rx;
  wire tx;

  // Modules
  UART_CONTROLLER #(.BAUD_RATE(9600), .CLOCK_FREQ(50000000)) uart_controller(
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .tx(tx)
  );

  initial begin
    // clock
    clk <= 0;
    forever #10 clk = ~clk; // 50 MHz
  end

  initial begin
    rx <= 1; #1000
    rx <= 0;
  end

endmodule