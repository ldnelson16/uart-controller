// UART_RECEIVER.v

`include "UART_parameters.sv"

`ifndef UART_RECEIVER
`define UART_RECEIVER

module UART_RECEIVER 
  #(
    parameter WORD_SIZE = `WORD_SIZE_p,
    parameter CLOCK_FREQ = `CLOCK_FREQ_p,
    parameter BAUD_RATE = `BAUD_RATE_p
  )
  (
    input wire clk,
    input wire rst,
    input wire rx,
    output reg[WORD_SIZE-1:0] data_read,
    output reg rx_avbl_i // lets controller know a piece of data is available
  );

  // Create Baud Clock Signal
  wire baud; 
  localparam BAUD_LIMIT = CLOCK_FREQ / BAUD_RATE;
  localparam QTR_BAUD = BAUD_LIMIT / 4;
  localparam THR_QTR_BAUD = BAUD_LIMIT * 4 / 5;
  reg[15:0] baud_counter;

  initial begin 
    baud_counter <= 0;
  end
  
  assign baud = (baud_counter == 0);
  assign qtr_baud = (baud_counter == QTR_BAUD);
  assign thr_qtr_baud = (baud_counter == THR_QTR_BAUD);

  // State variables
  reg[2:0] STATE;
  localparam IDLE = 0;
  localparam START = 1;
  localparam WAIT = 2;
  localparam LISTEN = 3;
  localparam STOP = 4;
  localparam SECONDWAIT = 5;

  // Bit Counter Variables (where you are in writing out a word)
  reg[$clog2(WORD_SIZE)-1:0] bit_counter;

  initial begin
    bit_counter <= 0;
    data_read <= 0;
    rx_avbl_i <= 0;
  end

  initial begin
    STATE <= IDLE;
  end

  wire negedge_rx; reg prev_rx;
  assign negedge_rx = (prev_rx && ~rx);

  initial begin
    prev_rx <= 1;
  end

  // State Transition Logic to read serial incoming data
  always @ (posedge clk) begin
    if (rst) begin
      STATE <= IDLE;
      bit_counter <= 0;
      rx_avbl_i <= 0;
      baud_counter <= 0;
    end else if (STATE != IDLE) begin
      if (baud_counter == BAUD_LIMIT) begin
        baud_counter <= 0;
      end else begin
        baud_counter <= (baud_counter + 1);
      end
    end else begin
      baud_counter <= 0;
    end
    if (baud && ~rst) begin
      case (STATE) 
        IDLE: begin 
          if (negedge_rx) begin // to catch negedge of rx
            STATE <= START;
            baud_counter <= 1; // to override the 0
          end
        end
        START: begin
          STATE <= WAIT;
        end
        WAIT: begin 
          // do nothing, as this is exited at quarter_baud
        end
        LISTEN: begin 
          data_read[WORD_SIZE-1-bit_counter] <= rx; // catalog bit received
          if (bit_counter == (WORD_SIZE-1)) begin
            bit_counter <= 0;
            STATE <= STOP;
          end else begin
            bit_counter <= (bit_counter + 1);
          end
        end
        STOP: begin 
          if (rx) begin // confirm stop bit (high) // if fail, do not trigger interrupt (discard byte)
            rx_avbl_i <= 1;
          end else begin
            rx_avbl_i <= 0;
          end
          STATE <= SECONDWAIT;
        end
        default: begin
          STATE <= IDLE;
        end
      endcase
    end else if (qtr_baud) begin
      case (STATE)
        WAIT: begin
          STATE <= LISTEN;
          baud_counter <= 0;
        end
        default: begin

        end
      endcase
    end else if (thr_qtr_baud) begin
      case (STATE)
        SECONDWAIT: begin
          STATE <= IDLE; // to allow for time to run out on last bit
        end
      endcase
    end
    if (rx_avbl_i) begin
      rx_avbl_i <= 0;
    end
    prev_rx <= rx;
  end
endmodule

`endif // UART_RECEIVER