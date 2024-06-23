module UART_RECEIVER 
  #(
    parameter WORD_SIZE = 8;
  )
  (
    input wire clk,
    input wire rst,
    input wire rx,
    input wire disable_data_interrupt, // to turn off data interrupt
    output reg enable_data_interrupt, // lets controller know a piece of data is available
    output reg[WORD_SIZE-1:0] data
  );
  // Parameters
  uart_parameters params();

  // Create Baud Clock Signal
  wire baud; 
  localparam BAUD_LIMIT = params.CLOCK_FREQ / params.BAUD_RATE;
  localparam QTR_BAUD = BAUD_LIMIT / 4;
  localparam THR_QTR_BAUD = BAUD_LIMIT * 0.8;
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
    data <= 0;
    enable_data_interrupt <= 0;
  end

  always @ (posedge clk) begin
    if (rst) begin
      baud_counter <= 0;
    end else if (STATE != IDLE) begin
      if (baud_counter == BAUD_LIMIT) begin
        baud_counter <= 0;
      end else begin
        baud_counter <= (baud_counter + 1);
      end
    end else begin // STATE == IDLE
      baud_counter <= 0;
    end
  end

  initial begin
    STATE <= IDLE;
  end

  always @ (posedge clk) begin // read interrupts from higher up
    if (disable_data_interrupt) begin
      enable_data_interrupt <= 0;
    end
  end

  // State Transition Logic
  always @ (posedge clk) begin
    if (rst) begin
      STATE <= IDLE;
      bit_counter <= 0;
      enable_data_interrupt <= 0;
    end else if (baud) begin
      case (STATE) 
        IDLE: begin 
          if (~rx) begin
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
          data[params.WORD_SIZE-1-bit_counter] <= rx; // catalog bit received
          if (bit_counter == (params.WORD_SIZE-1)) begin
            bit_counter <= 0;
            STATE <= STOP;
          end else begin
            bit_counter <= (bit_counter + 1);
          end
        end
        STOP: begin 
          if (rx) begin // confirm stop bit (high) // if fail, do not trigger interrupt (discard byte)
            enable_data_interrupt <= 1;
          end else begin
            enable_data_interrupt <= 0;
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
    if (disable_data_interrupt) begin
      enable_data_interrupt <= 0;
    end
  end
endmodule