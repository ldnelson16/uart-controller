module UART_TRANSMITTER
  #(
    parameter WORD_SIZE;  
  )
  (
    input wire clk,
    input wire rst,
    input wire[WORD_SIZE-1:0] data,
    input wire tx_send;
    output reg tx_sent_i; // interrupt saying i sent the data
    output reg tx
  );
  // Create Baud Clock Signals
  wire baud; 
  localparam BAUD_LIMIT = CLOCK_FREQ / BAUD_RATE;
  reg[15:0] baud_counter;

  initial begin 
    baud_counter <= 0;
  end

  assign baud = (baud_counter == 0);

  // Bit Counter Variables (where you are in writing out a word)
  reg[$clog2(WORD_SIZE)-1:0] bit_counter;

  // State variables
  reg STATE;
  
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
          baud_counter <= 0;
        end
        START begin
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
          if (tx_send) begin
            STATE <= START;
          end
        end
        START: begin
          tx <= 0;
          STATE <= TRANSMIT;
        end
        TRANSMIT: begin 
          tx <= data[WORD_SIZE-bit_counter-1];
          if (bit_counter == (WORD_SIZE-1)) begin
            bit_counter <= 0;
            STATE <= DONE;
          end else begin
            bit_counter <= (bit_counter + 1);
            STATE <= TRANSMIT;
          end
        end
        DONE: begin
          tx <= 1;
          STATE <= IDLE;
        end
      endcase
    end
  end

  always @ (posedge clk) begin
    if (rst) begin
      tx_sent_i <= 0;;
    end else begin
      case (STATE):
        DONE: begin
          tx_sent_i <= 1;
        end
        default: begin
          tx_sent_i <= 0;
        end 
      endcase
    end
  end
endmodule