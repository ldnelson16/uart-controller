// UART.v

`include "UART_parameters.sv"
`include "UART_RECEIVER.sv"
`include "UART_TRANSMITTER.sv"

`ifndef UART
`define UART

module UART_CONTROLLER 
  #(
    parameter rx_RING_SIZE =`RX_RING_SIZE_p,
    parameter tx_RING_SIZE = `TX_RING_SIZE_p,
    parameter WORD_SIZE = `WORD_SIZE_p
  )
  (
    input wire clk,
    input wire rst,
    input wire[WORD_SIZE-1:0] data_in,
    input wire write_nic, // these come from os, os is writing a piece of data to go out
    input wire read_nic, //                    , os is reading a piece of data that was brought in (alerted to by read_nic_i)
    input wire rx,
    output reg[WORD_SIZE-1:0] data_out,
    output reg read_nic_i, // tells OS to read me
    output wire tx
  );

  // Interrupt signals / Receive
  wire rx_data_i; wire[WORD_SIZE-1:0] rx_data; // Receiver has data to be read / data to be read

  // Interrupt signals / Transmit
  reg tx_data_i; reg[WORD_SIZE-1:0] tx_data; // Transmittor needs to send data / data to be sent
  wire tx_avbl_i;

  // Initialize interrupts
  initial begin 
    tx_data_i <= 0;
    read_nic_i <= 0;
    data_out <= 0;
  end

  // Memory
  reg[WORD_SIZE-1:0] rx_ring_buffer[rx_RING_SIZE-1:0]; // ring buffer memory item
  reg[$clog2(rx_RING_SIZE)-1:0] rx_ring_size; // to store how many elements are in ring buffer
  reg[$clog2(rx_RING_SIZE)-1:0] rx_read_ptr; // to point to where data begins in ring buffer
  reg[$clog2(rx_RING_SIZE)-1:0] rx_write_ptr; // to point to first address data doesn't exist in ring buffer

  reg[WORD_SIZE-1:0] tx_ring_buffer[tx_RING_SIZE-1:0]; // ring buffer memory item
  reg[$clog2(tx_RING_SIZE)-1:0] tx_ring_size; // to store how many elements are in ring buffer
  reg[$clog2(tx_RING_SIZE)-1:0] tx_read_ptr; // to point to where data begins in ring buffer
  reg[$clog2(tx_RING_SIZE)-1:0] tx_write_ptr; // to point to first address data doesn't exist in ring buffer

  // Note memory does not need to be initialized as it is considered empty

  // initialize memory pointers / sizes
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
    .data_read(rx_data),
    .rx_avbl_i(rx_data_i)
  );
  UART_TRANSMITTER uart_transmitter(
    .clk(clk), 
    .rst(rst), 
    .data_send(tx_data),
    .tx_send_i(tx_data_i),
    .tx_avbl_i(tx_avbl_i),
    .tx(tx)
  );

  always @ (posedge clk) begin
    if (rst) begin
      rx_ring_size <= 0;
      rx_read_ptr <= 0;
      rx_write_ptr <= 0;
    end else begin
      // Read from UART receiver logic
      if (rx_data_i) begin // need to read data
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
      end
      // Listen for OS Read Commands to NIC (UART)
      if (rx_ring_size >= 1 && ~read_nic_i && ~read_nic) begin
        read_nic_i <= 1;
      end else begin
        read_nic_i <= 0;
      end
      if (read_nic) begin
        data_out <= rx_ring_buffer[rx_read_ptr];
        if (rx_read_ptr == (rx_RING_SIZE - 1)) begin
          rx_read_ptr <= 0;
        end else begin
          rx_read_ptr <= (rx_read_ptr + 1);
        end
        rx_ring_size <= (rx_ring_size - 1);
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
      // Send to UART transmittor logic
      if (tx_ring_size >= 1 && tx_avbl_i) begin
        tx_data <= tx_ring_buffer[tx_read_ptr];
        tx_data_i <= 1;
        tx_ring_size = (tx_ring_size - 1);
        if (tx_read_ptr == (tx_RING_SIZE-1)) begin
          tx_read_ptr <= 0;
        end else begin
          tx_read_ptr <= (tx_read_ptr + 1);
        end
      end else begin
        tx_data_i <= 0;
      end
      // Listen for OS NIC Commands to NIC (UART)
      if (write_nic) begin
        tx_ring_buffer[tx_write_ptr] <= data_in;
        if (tx_write_ptr == (tx_RING_SIZE - 1)) begin
          tx_write_ptr <= 0;
        end else begin
          tx_write_ptr <= (tx_write_ptr + 1);
        end
        if (tx_ring_size != tx_RING_SIZE) begin
          tx_ring_size <= (tx_ring_size + 1);
        end else begin
          if (tx_read_ptr == (tx_RING_SIZE - 1)) begin
            tx_read_ptr <= 0;
          end else begin
            tx_read_ptr <= (tx_read_ptr + 1);
          end
        end
      end
    end
  end

endmodule

`endif // UART