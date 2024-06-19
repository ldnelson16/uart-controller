`timescale 1ns/1ns

// TB_Transmitter_Simulator.v
`include "UART_parameters.vh"

module TB_Controller_Simulator ();
  // parameters
  uart_parameters params();

  // Declare signals
  reg clk;
  reg rst;
  reg rx;
  wire tx;

  // Modules
  UART_CONTROLLER #(.WORD_SIZE(params.WORD_SIZE), .BAUD_RATE(params.BAUD_RATE), .CLOCK_FREQ(params.CLOCK_FREQ)) uart_controller(
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

module TB_Transmittor_Simulator (); // Test Receiver
  // parameters
  uart_parameters params();
  
  // signals
  reg clk;
  reg rst;
  reg rx;
  reg disable_data_interrupt; // lets receiver know controller finished handling enable_data_interrupt
  wire enable_data_interrupt; // lets controller know that receiver has finished receiving a piece of data
  wire[7:0] read_data;

  // modules
  UART_RECEIVER uart_receiver(
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .disable_data_interrupt(disable_data_interrupt),
    .enable_data_interrupt(enable_data_interrupt),
    .data(read_data)
  );

  initial begin
    // clock
    clk <= 0;
    forever #10 clk = ~clk; // 20 ns cycle // 50 MHz
  end

  integer i; // for loop

  // Simulate rx;
  initial begin : simulator
    // CORRECT BYTE
    rx <= 1; #(params.BAUD*6); // IDLE
    rx <= 0; #(params.BAUD); // START BIT

    for (i = 0; i < 8; i = i + 1) begin
      rx <= i % 2; // Alternate between 0 and 1
      #(params.BAUD); // 1 baud cycle per bit
    end

    rx <= 1; #(params.BAUD); // END BIT
    rx <=1; #(params.BAUD*6); // IDLE

    // FAIL BYTE (DUE TO END BIT)
    rx <= 1; #(params.BAUD*6); // IDLE
    rx <= 0; #(params.BAUD); // START BIT

    for (i = 0; i < 8; i = i + 1) begin
      rx <= i % 2; // Alternate between 0 and 1
      #(params.BAUD); // 1 baud cycle per bit
    end

    rx <= 0; #(params.BAUD); // ERROR! END BIT
    rx <=1; #(params.BAUD*6); // IDLE
  end : simulator
endmodule