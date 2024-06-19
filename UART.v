module UART_CONTROLLER 
  (
    input wire clk,
    input wire rst,
    input wire rx,
    output wire tx
  );
  // Parameters
  uart_parameters params(); 

  // Interrupt signals
  wire rx_data_i; wire[params.WORD_SIZE-1:0] rx_data; // Receiver has data to be read / data to be read
  reg disable_data_interrupt;

  initial begin 
    disable_data_interrupt <= 0;
  end

  // Memory
  localparam RING_SIZE = 10;
  reg[params.WORD_SIZE-1:0] ring_buffer[RING_SIZE-1:0]; // ring buffer memory item
  reg[$clog2(RING_SIZE)-1:0] ring_size; // to store how many elements are in ring buffer
  reg[$clog2(RING_SIZE)-1:0] read_ptr; // to point to where data begins in ring buffer
  reg[$clog2(RING_SIZE)-1:0] write_ptr; // to point to first address data doesn't exist in ring buffer

  initial begin
    ring_size <= 0;
    read_ptr <= 0;
    write_ptr <= 0;
  end

  // Module Objects
  UART_RECEIVER uart_receiver(.clk(clk), .rst(rst), .rx(rx), .disable_data_interrupt(disable_data_interrupt), .enable_data_interrupt(rx_data_i), .data(rx_data));
  UART_TRANSMITTER uart_transmitter(.clk(clk), .rst(rst), .tx(tx));

  // Read from receiver
  always @ (posedge clk) begin
    if (rst) begin
      ring_size <= 0;
      read_ptr <= 0;
      write_ptr <= 0;
    end else begin
      if (rx_data_i && !disable_data_interrupt) begin // need to read data
        ring_buffer[write_ptr] <= rx_data;
        if (write_ptr == (RING_SIZE-1)) begin
          write_ptr <= 0;
        end else begin
          write_ptr <= (write_ptr + 1);
        end
        if (ring_size != RING_SIZE) begin
          ring_size = (ring_size + 1);
        end else begin 
          if (read_ptr == RING_SIZE) begin
            read_ptr <= 0;
          end else begin
            read_ptr <= (read_ptr + 1);
          end
        end
        disable_data_interrupt <= 1; // value is read
      end
      else begin
        disable_data_interrupt <= 0;
      end
    end
  end
endmodule

module UART_RECEIVER 
  (
    input wire clk,
    input wire rst,
    input wire rx,
    input wire disable_data_interrupt, // to turn off data interrupt
    output reg enable_data_interrupt, // lets controller know a piece of data is available
    output reg[7:0] data
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
  reg[2:0] bit_counter;

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

module UART_TRANSMITTER
  #(  
    parameter BAUD_RATE = 9600, // 9.6 Khz
    parameter CLOCK_FREQ = 50000000 // 50 MHz
  )
  (
    input wire clk,
    input wire rst,
    output wire tx
  );
  // Create Baud Clock Signals
  wire baud; 
  localparam BAUD_LIMIT = CLOCK_FREQ / BAUD_RATE;
  reg[15:0] baud_counter;

  initial begin 
    baud_counter <= 0;
  end

  assign baud = (baud_counter == 0);

  // State variables
  reg STATE;
  
  localparam IDLE = 0;
  localparam TRANSMIT = 1;

  always @ (posedge clk) begin
    if (rst) begin
      baud_counter <= 0;
    end else begin
      case (STATE)
        IDLE: begin
          baud_counter <= 0;
        end
        TRANSMIT: begin
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
        IDLE: begin end
        TRANSMIT: begin end
      endcase
    end
  end
endmodule