module UART_CONTROLLER 
  #(
    parameter BAUD_RATE = 9600, // 9.6 KHz
    parameter CLOCK_FREQ = 50000000 // 50 MHz
  )
  (
    input wire clk,
    input wire rst,
    input wire rx,
    output wire tx
  );
  // Module Objects
  UART_RECEIVER uart_receiver(.clk(clk), .rst(rst), .rx(rx));
  UART_TRANSMITTER uart_transmitter(.clk(clk), .rst(rst), .tx(tx));
endmodule

module UART_RECEIVER 
  #( 
    parameter BAUD_RATE = 9600, // 9.6 KHz
    parameter CLOCK_FREQ = 50000000 // 50 MHz
  ) 
  (
    input wire clk,
    input wire rst,
    input wire rx
  );
  // Create Baud Clock Signal
  wire baud; 
  localparam BAUD_LIMIT = CLOCK_FREQ / BAUD_RATE;
  localparam QTR_BAUD = BAUD_LIMIT / 4;
  reg[15:0] baud_counter;

  initial begin 
    baud_counter <= 0;
  end
  
  assign baud = (baud_counter == 0);
  assign qtr_baud = (baud_counter == QTR_BAUD);

  // State variables
  reg[1:0] STATE;
  localparam IDLE = 0;
  localparam START = 1;
  localparam WAIT = 2;
  localparam LISTEN = 3;
  localparam STOP = 4;

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

  // State Transition Logic
  always @ (posedge clk) begin
    if (rst) begin
      STATE <= IDLE;
      baud_counter <= 0;
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

        end
        LISTEN: begin 

        end
        STOP: begin 

        end
        default: begin
          STATE <= IDLE;
        end
      endcase
    end else if (qtr_baud) begin
      case (STATE)
        WAIT: begin
          STATE <= LISTEN;
          baud_counter <= 1;
        end
        default: begin

        end
      endcase
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
  reg[15:0] baud_counter;

  initial begin 
    baud_counter <= 1;
  end
endmodule