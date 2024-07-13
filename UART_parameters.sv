// uart_params.sv

`ifndef UART_PARAMETERS
`define UART_PARAMETERS

  // UART parameters
`define WORD_SIZE_p 8 // size of data being sent per UART frame
`define BAUD_RATE_p 9600 // bauds per second
`define CLOCK_FREQ_p 50000000 // 50 MHz system clock
`define BAUD_p (CLOCK_FREQ_p / BAUD_RATE_p) // clock cycles per baud
`define TX_RING_SIZE_p 10 // 
`define RX_RING_SIZE_p 10 // size of ring buffer ^^
`define BUTTON_BUFFER_p 1 // proportion of a second for button buffer

`endif // UART_PARAMETERS