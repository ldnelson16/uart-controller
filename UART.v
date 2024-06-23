module UART_CONTROLLER 
  (
    input wire clk,
    input wire rst,
    input wire[params.WORD_SIZE-1:0] data_to_send;
    input wire data_to_send_i; // these come from os, telling UART to send data (will eventually be different methodology)
    input wire rx,
    output reg[params.WORD_SIZE-1:0] data_received;
    output reg data_received_i;
    output wire tx
  );
  // Parameters
  uart_parameters params(); 

  // Interrupt signals / Receive
  wire rx_data_i; wire[params.WORD_SIZE-1:0] rx_data; // Receiver has data to be read / data to be read
  reg disable_data_interrupt;

  // Interrupt signals / Transmit
  reg tx_send_data; reg[params.WORD_SIZE-1:0] tx_data; // Transmittor needs to send data / data to be sent
  wire tx_sent_data;

  // Initialize interrupts
  initial begin 
    disable_data_interrupt <= 0;
  end

  // Memory
  localparam rx_RING_SIZE = 10;
  reg[params.WORD_SIZE-1:0] rx_ring_buffer[rx_RING_SIZE-1:0]; // ring buffer memory item
  reg[$clog2(rx_RING_SIZE)-1:0] rx_ring_size; // to store how many elements are in ring buffer
  reg[$clog2(rx_RING_SIZE)-1:0] rx_read_ptr; // to point to where data begins in ring buffer
  reg[$clog2(rx_RING_SIZE)-1:0] rx_write_ptr; // to point to first address data doesn't exist in ring buffer

  localparam tx_RING_SIZE = 10;
  reg[params.WORD_SIZE-1:0] tx_ring_buffer[tx_RING_SIZE-1:0]; // ring buffer memory item
  reg[$clog2(tx_RING_SIZE)-1:0] tx_ring_size; // to store how many elements are in ring buffer
  reg[$clog2(tx_RING_SIZE)-1:0] tx_read_ptr; // to point to where data begins in ring buffer
  reg[$clog2(tx_RING_SIZE)-1:0] tx_write_ptr; // to point to first address data doesn't exist in ring buffer

  initial begin
    rx_ring_size <= 0;
    rx_read_ptr <= 0;
    rx_write_ptr <= 0;
    tx_ring_size <= 0;
    tx_read_ptr <= 0;
    tx_write_ptr <= 0;
  end

  // Module Objects
  UART_RECEIVER uart_receiver(
    .clk(clk), 
    .rst(rst), 
    .rx(rx), 
    .disable_data_interrupt(disable_data_interrupt), 
    .enable_data_interrupt(rx_data_i), 
    .data(rx_data)
  );
  UART_TRANSMITTER uart_transmitter(
    .clk(clk), 
    .rst(rst), 
    .data(tx_data),
    .tx_send(tx_send_data),
    .tx_sent_i(tx_sent_data),
    .tx(tx)
  );

  // Read from UART receiver logic
  always @ (posedge clk) begin
    if (rst) begin
      rx_ring_size <= 0;
      rx_read_ptr <= 0;
      rx_write_ptr <= 0;
    end else begin
      if (rx_data_i && !disable_data_interrupt) begin // need to read data
        rx_ring_buffer[rx_write_ptr] <= rx_data;
        if (rx_write_ptr == (rx_RING_SIZE-1)) begin
          rx_write_ptr <= 0;
        end else begin
          rx_write_ptr <= (rx_write_ptr + 1);
        end
        if (rx_ring_size != rx_RING_SIZE) begin
          rx_ring_size = (rx_ring_size + 1);
        end else begin 
          if (rx_read_ptr == rx_RING_SIZE) begin
            rx_read_ptr <= 0;
          end else begin
            rx_read_ptr <= (rx_read_ptr + 1);
          end
        end
        disable_data_interrupt <= 1; // value is read
      end
      else begin
        disable_data_interrupt <= 0;
      end
    end
  end

  // Send to UART transmittor logic
  always @ (posedge clk) begin
    if (rst) begin 
      tx_ring_size <= 0;
      tx_read_ptr <= 0;
      tx_write_ptr <= 0;
    end else begin 
      if ((tx_ring_size >= 1) && (tx_send_data == 0)) begin
        tx_data <= tx_ring_buffer[tx_read_ptr];
        tx_send_data <= 1;
        tx_ring_size = (tx_ring_size - 1);
        if (tx_read_ptr == (tx_RING_SIZE-1)) begin
          tx_read_ptr <= 0;
        end else begin
          tx_read_ptr <= (tx_read_ptr + 1);
        end
      end else if (tx_sent_data) begin
        tx_send_data <= 0;
      end
    end
  end

endmodule