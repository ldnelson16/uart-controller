// uart_params.vh
`ifndef UART_PARAMS_VH
`define UART_PARAMS_VH

module uart_parameters;
  // UART parameters
  parameter integer WORD_SIZE = 8;
  parameter integer BAUD_RATE = 9600;
  parameter integer CLOCK_FREQ = 50000000; // 50 MHz system clock
  parameter integer BAUD = (10.0**9) / BAUD_RATE; // in ns
  parameter integer tx_RING_SIZE = 10;
  parameter integer rx_RING_SIZE = 10;
endmodule

`endif