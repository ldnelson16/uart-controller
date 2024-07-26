// uart_params.sv

`ifndef UART_PARAMETERS
`define UART_PARAMETERS

// Basic parameters
`define TRUE 1
`define FALSE 0

// UART parameters
`define WORD_SIZE_p 8 // size of data being sent per UART frame
`define BAUD_RATE_p 1250000 // bauds per second
`define CLOCK_FREQ_p 50000000 // 50 MHz system clock
`define BAUD_p (CLOCK_FREQ_p / BAUD_RATE_p) // clock cycles per baud
`define TX_RING_SIZE_p 15 // 
`define RX_RING_SIZE_p 15 // size of ring buffer ^^
`define BUTTON_BUFFER_p 1 // proportion of a second for button buffer

`endif // UART_PARAMETERS