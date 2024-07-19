// UART_TRANSMITTER.v

`ifndef UART_TRANSMITTER
`define UART_TRANSMITTER

`include "UART_parameters.sv"

module UART_TRANSMITTER
  #(
    parameter WORD_SIZE = `WORD_SIZE_p,
    parameter CLOCK_FREQ = `CLOCK_FREQ_p,
    parameter BAUD_RATE = `BAUD_RATE_p
  )
  (
    input wire clk,
    input wire rst,
    input wire[WORD_SIZE-1:0] data_send,
    input wire tx_send_i,
    output reg tx_avbl_i,
    output reg tx
  );

  // Create Baud Clock Signals
  wire baud; 
  localparam BAUD_LIMIT = CLOCK_FREQ / BAUD_RATE;
  localparam TWO_BAUD_LIMIT = 2 * BAUD_LIMIT; // for guaranteed one BAUD wait between frames transmitted
  reg[15:0] baud_counter;

  initial begin 
    baud_counter <= 0;
    tx_avbl_i <= 0;
    tx <= 1;
  end

  assign baud = (baud_counter == 0);

  // Bit Counter Variables (where you are in writing out a word)
  reg[$clog2(WORD_SIZE)-1:0] bit_counter;

  initial begin 
    bit_counter <= 0;
  end

  // State variables
  reg[1:0] STATE;
  
  localparam IDLE = 0;
  localparam START = 1;
  localparam TRANSMIT = 2;
  localparam DONE = 3;

  always @ (posedge clk) begin
    if (rst) begin
      baud_counter <= 0;
    end else begin
      case (STATE)
        IDLE: begin
          if (baud || baud_counter == TWO_BAUD_LIMIT) begin
            baud_counter <= 0;
          end else begin
            baud_counter <= (baud_counter + 1);
          end
        end
        START: begin
          if (baud_counter == BAUD_LIMIT) begin
            baud_counter <= 0;
          end else begin
            baud_counter <= (baud_counter + 1);
          end
        end
        TRANSMIT: begin
          if (baud_counter == BAUD_LIMIT) begin
            baud_counter <= 0;
          end else begin
            baud_counter <= (baud_counter + 1);
          end
        end
        DONE: begin
          if (baud_counter == BAUD_LIMIT) begin
            baud_counter <= 0;
          end else begin
            baud_counter <= (baud_counter + 1);
          end
        end
      endcase
    end
  end

  initial begin 
    STATE <= IDLE;
  end

  always @ (posedge clk) begin
    if (rst) begin
      STATE <= IDLE;
    end else begin
      case (STATE) 
        IDLE: begin 
          if (baud) begin
            if (tx_send_i) begin
              STATE <= START;
            end
            tx <= 1;
          end
        end
        START: begin
          tx <= 0;
          STATE <= TRANSMIT;
        end
        TRANSMIT: begin 
          if (baud) begin
            tx <= data_send[WORD_SIZE-bit_counter-1];
            if (bit_counter == (WORD_SIZE-1)) begin
              bit_counter <= 0;
              STATE <= DONE;
            end else begin
              bit_counter <= (bit_counter + 1);
              STATE <= TRANSMIT;
            end
        end
        end
        DONE: begin
          if (baud) begin
            tx <= 1;
            STATE <= IDLE;
          end
        end
      endcase
    end
  end

  always @ (posedge clk) begin
    if (rst) begin
      tx_avbl_i <= 0;
    end else begin
      case (STATE) 
        IDLE: begin 
          if (baud && ~tx_send_i) begin
            tx_avbl_i <= 1;
          end else begin
            tx_avbl_i <= 0;
          end
        end
        default: begin
          tx_avbl_i <= 0;
        end
      endcase
    end
  end

endmodule

`endif // UART_TRANSMITTER