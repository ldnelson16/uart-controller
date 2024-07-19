// TestBench.sv

`ifndef UART_TESTBENCHES
`define UART_TESTBENCHES

`timescale 1ns/1ns

`include "UART_parameters.sv"

// structs for tracking frames
typedef struct packed {
  int datum;
  int time_sent;
  bit received;
} frame;

class port; 
  // member variables
  frame tx_data[1000:0]; int tx_data_size; int tx_data_received;
  frame rx_data[1000:0]; int rx_data_size;
  bit verbose;
  int port_number;

  // constructor
  function new (int port_number_in, bit verbose_in);
    tx_data_size = 0; tx_data_received = 0;
    rx_data_size = 0;
    port_number = port_number_in;
    verbose = verbose_in;
  endfunction

  // log_tx: logs a transmitted message to a port
  function void log_tx (int datum);
    if (verbose) begin 
      $display("Transmitting on port %0d. Data: %0t, Time = %0t.",port_number, datum, $time);
    end
    tx_data[tx_data_size].datum = datum;
    tx_data[tx_data_size].time_sent = $time;
    tx_data[tx_data_size].received = `FALSE;
    tx_data_size++;
  endfunction

  // log_rx: logs a received message to a port
  function void log_rx (int datum);
    if (verbose) begin 
      $display("Receiving on port %0d. Data: %0t, Time = %0t.",port_number, datum, $time);
    end
    rx_data[rx_data_size].datum = datum;
    rx_data[rx_data_size].time_sent = $time;
    rx_data[rx_data_size].received = `FALSE;
    rx_data_size++;
  endfunction

  // log_successful_tx
  function void log_successful_tx (int datum);
    for (int i=tx_data_size; i>=0; --i) begin
      if (tx_data[i].datum == datum) begin
        tx_data[i].received = `TRUE;
        ++tx_data_received;
        $display("Ratio: %d/%d", tx_data_received, tx_data_size);
        return;
      end
    end
  endfunction
  
endclass

class topology;
  // member variables
  port ports[2];
  
  // constructor
  function new (int num_ports);
    for (int i=0; i<num_ports; ++i) begin
      ports[i] = new(i, `TRUE);
    end
  endfunction

  function void log_tx (int datum, int port_number);
    ports[port_number].log_tx(datum);
  endfunction

  function void log_rx (int datum, int port_number);
    ports[port_number].log_rx(datum);
    ports[(port_number % 2)+1].log_successful_tx(datum);
  endfunction
endclass

module TB_test_throughput();
  // Declare signals
  reg clk; integer cycle = 0; // clock  / cycle number
  reg rst; // reset

  always @ (posedge clk) begin cycle++; end

  wire tx_0, tx_1; // tx/rx signals

  reg write_nic_0, write_nic_1; // write signal to NIC
  reg read_nic_0, read_nic_1; // read signal to NIC

  wire[`WORD_SIZE_p-1:0] data_out_0, data_out_1; // data read from NIC 
  wire read_nic_i_0, read_nic_i_1; // signals that data is to be read from NIC

  reg[`WORD_SIZE_p-1:0] data_in_0, data_in_1; // data sent to NIC

  reg[`WORD_SIZE_p-1:0] random_int_0, random_int_1; // to feed to transmit
  
  // Instantiate two UART modules
  UART_CONTROLLER uart_controller_0(
    .clk(clk),
    .rst(rst),
    .data_in(data_in_0),
    .write_nic(write_nic_0),
    .read_nic(read_nic_0),
    .rx(tx_1),
    .data_out(data_out_0),
    .read_nic_i(read_nic_i_0),
    .tx(tx_0)
  );
  UART_CONTROLLER uart_controller_1(
    .clk(clk),
    .rst(rst),
    .data_in(data_in_1),
    .write_nic(write_nic_1),
    .read_nic(read_nic_1),
    .rx(tx_0),
    .data_out(data_out_1),
    .read_nic_i(read_nic_i_1),
    .tx(tx_1)
  );

  // Clock signal
  initial begin
    clk <= 0; rst <= 0;
    forever #10 clk = ~clk;
  end

  // Create randomized data for uart's to send
  initial begin
    random_int_0 <= ($urandom % (2**`WORD_SIZE_p));
    random_int_1 <= ($urandom % 256);
  end
  always @ (posedge clk) begin
    random_int_0 <= ($urandom % (2**`WORD_SIZE_p));
    random_int_1 <= ($urandom % (2**`WORD_SIZE_p));
  end

  topology topology = new(2);

  int send_for_max = (`CLOCK_FREQ_p / `BAUD_RATE_p) * (`WORD_SIZE_p + 2);
  reg[11:0] clock_counter;

  initial begin clock_counter = 0; end

  always @ (posedge clk) begin
    if (clock_counter == send_for_max) begin
      clock_counter <= 0;
    end else begin
      clock_counter <= (clock_counter + 1);
    end
  end
  
  // Send randomized data to uart_0 (so uart_0 can send it) 2*TX_RING_SIZE_p clock cycles in a row
  integer counter_0;

  initial begin
    counter_0 = 0;
    @ (posedge clk);
    forever begin
      @(posedge clk);
      if ((clock_counter == send_for_max) && (counter_0 < (20000 * `TX_RING_SIZE_p))) begin
        write_nic_0 <= 1; 
        data_in_0 <= random_int_0;
        counter_0 = counter_0 + 1;
        topology.log_tx(random_int_0,0);
      end else begin
        write_nic_0 <= 0;
      end
    end
  end

  // Send randomized data to uart_1 (so uart_1 can send it)
  integer counter_1;

  initial begin
    counter_1 = 0;
    forever begin
      @(posedge clk);
      if ((clock_counter == send_for_max) && (counter_1 < (20000 * `TX_RING_SIZE_p))) begin
        write_nic_1 <= 1; 
        data_in_1 <= random_int_1;
        counter_1 = counter_1 + 1;
        topology.log_tx(random_int_1,1);
      end else begin
        write_nic_1 <= 0;
      end
    end
  end

  reg trail_read_nic_0, trail_read_nic_1; 

  initial begin trail_read_nic_0 <= 0; trail_read_nic_1 <= 0; end
  always @ (posedge clk) begin trail_read_nic_0 <= read_nic_0;  trail_read_nic_1 <= read_nic_1; end

  // Read data from uart_0 (and verify with sent data from uart_1)
  initial begin
    forever begin
      @ (posedge clk);
      if (read_nic_i_0) begin
        read_nic_0 <= 1;
      end else begin
        read_nic_0 <= 0;
      end
      if (trail_read_nic_0) begin
        topology.log_rx(data_out_0,0);
      end 
    end
  end

  // Read data from uart_1 (and verify with sent data from uart_0)
endmodule

// module TB_Controller_Simulator ();
//   // Declare signals
//   reg clk;
//   reg rst;
//   reg rx1; reg rx2;
//   wire tx1; wire tx2;

//   // Modules
//   UART_CONTROLLER uart_controller_0(
//     .clk(clk),
//     .rst(rst),
//     .rx(rx1),
//     .tx(tx1)
//   );
//   UART_CONTROLLER uart_controller_1(
//     .clk(clk),
//     .rst(rst),
//     .rx(rx2),
//     .tx(tx2)
//   );

//   initial begin
//     // clock
//     clk <= 0;
//     forever #10 clk = ~clk; // 20 ns cycle // 50 MHz
//   end

//   integer i,j; // for loop
//   wire[params.WORD_SIZE-1:0] random_word;
//   assign random_word = j**2 + 3*j + 5 + (j+1)**3;

//   // Simulate rx;
//   initial begin : simulator
//     // CORRECT BYTE
//     rx1 <= 1; #(params.BAUD*6); // IDLE
//     for (j=0; j < 14; j = j + 1) begin : named_for
//       rx1 <= 0; #(params.BAUD); // START BIT
//       for (i = 0; i < 8; i = i + 1) begin
//         rx1 <= random_word[i]; // Alternate between 0 and 1
//         #(params.BAUD); // 1 baud cycle per bit
//       end

//       rx1 <= 1; #(params.BAUD); // END BIT
//       rx1 <=1; #(params.BAUD*(0.25*j)); // IDLE
//     end : named_for

//     // FAIL BYTE (DUE TO END BIT)
//     rx1 <= 1; #(params.BAUD*6); // IDLE
//     rx1 <= 0; #(params.BAUD); // START BIT

//     for (i = 0; i < 8; i = i + 1) begin
//       rx1 <= i % 2; // Alternate between 0 and 1
//       #(params.BAUD); // 1 baud cycle per bit
//     end

//     rx1 <= 0; #(params.BAUD); // ERROR! END BIT
//     rx1 <=1; #(params.BAUD*6); // IDLE
//   end : simulator

// endmodule

// module TB_OS_Write_to_NIC_and_Read_from_NIC ();
//   // parameters
//   uart_parameters params();

//   // Declare signals
//   reg clk;
//   reg rst;
//   wire tx1; wire tx2;

//   reg[7:0] data_in1, data_in2;
//   wire[7:0] data_out1, data_out2;

//   wire read_nic_i1, read_nic_i2;

//   reg write_nic1, write_nic2, read_nic1, read_nic2;

//   // Modules
//   UART_CONTROLLER uart_controller1(
//     .clk(clk),
//     .rst(rst),
//     .data_in(data_in1),
//     .write_nic(write_nic1), 
//     .read_nic(read_nic1), 
//     .rx(tx2),
//     .data_out(data_out1),
//     .read_nic_i(read_nic_i1),
//     .tx(tx1)
//   );

//   UART_CONTROLLER uart_controller_1(
//     .clk(clk),
//     .rst(rst),
//     .data_in(data_in2),
//     .write_nic(write_nic2), 
//     .read_nic(read_nic2), 
//     .rx(tx1),
//     .data_out(data_out2),
//     .read_nic_i(read_nic_i2),
//     .tx(tx2)
//   );

//   initial begin
//     data_in1 <= 8'b01010101;
//     write_nic1 <= 1; #20;
//     write_nic1 <= 0; #40;
//     data_in1 <= 8'b10101010;
//     write_nic1 <= 1; #20;
//     write_nic1 <= 0; #3000000;
//     read_nic2 <= 1; #20;
//     read_nic2 <= 0; #40;
//     read_nic2 <= 1; #20;
//     read_nic2 <= 0; 
//   end

//   initial begin
//     // clock
//     clk <= 0;
//     forever #10 clk = ~clk; // 20 ns cycle // 50 MHz
//   end



// endmodule

// module TB_Transmittor_Simulator (); // Test Receiver
//   // parameters
//   uart_parameters params();
  
//   // signals
//   reg clk;
//   reg rst;
//   reg rx;
//   reg disable_data_interrupt; // lets receiver know controller finished handling enable_data_interrupt
//   wire enable_data_interrupt; // lets controller know that receiver has finished receiving a piece of data
//   wire[7:0] read_data;

//   // modules
//   UART_RECEIVER uart_receiver(
//     .clk(clk),
//     .rst(rst),
//     .rx(rx),
//     .disable_data_interrupt(disable_data_interrupt),
//     .enable_data_interrupt(enable_data_interrupt),
//     .data(read_data)
//   );

//   initial begin
//     // clock
//     clk <= 0;
//     forever #10 clk = ~clk; // 20 ns cycle // 50 MHz
//   end

//   integer i; // for loop

//   // Simulate rx;
//   initial begin : simulator
//     // CORRECT BYTE
//     rx <= 1; #(params.BAUD*6); // IDLE
//     rx <= 0; #(params.BAUD); // START BIT

//     for (i = 0; i < 8; i = i + 1) begin
//       rx <= i % 2; // Alternate between 0 and 1
//       #(params.BAUD); // 1 baud cycle per bit
//     end

//     rx <= 1; #(params.BAUD); // END BIT
//     rx <=1; #(params.BAUD*6); // IDLE

//     // FAIL BYTE (DUE TO END BIT)
//     rx <= 1; #(params.BAUD*6); // IDLE
//     rx <= 0; #(params.BAUD); // START BIT

//     for (i = 0; i < 8; i = i + 1) begin
//       rx <= i % 2; // Alternate between 0 and 1
//       #(params.BAUD); // 1 baud cycle per bit
//     end

//     rx <= 0; #(params.BAUD); // ERROR! END BIT
//     rx <=1; #(params.BAUD*6); // IDLE
//   end : simulator
// endmodule

// module TB_Main_Simulator ();

//   wire[7:0] HEX0_m, HEX1_m, HEX2_m, HEX3_m, HEX4_m, HEX5_m, LEDR_m;
//   reg clk;
//   reg[1:0] KEY_m;
//   reg[9:0] SW_m;
//   reg rx; wire tx;

//   UART_main main(
//     .HEX0(HEX0_m),
//     .HEX1(HEX1_m),
//     .HEX2(HEX2_m),
//     .HEX3(HEX3_m),
//     .HEX4(HEX4_m),
//     .HEX5(HEX5_m),
//     .TX(tx),
//     .RX(rx),
//     .CLK(clk),
//     .KEY(KEY_m),
//     .SW(SW_m),
//     .LEDR(LEDR_m)
//   );

//   initial begin
//     KEY_m[1:0] <= 2'b11; #50;
//     SW_m[7:0] <= 8'b10101010; SW_m[8] <= 1; #500;
//     KEY_m[0] <= 0; #200000;
//     KEY_m[0] <= 1;
//   end

//   initial begin
//     // clock
//     clk <= 0;
//     forever #10 clk = ~clk; // 20 ns cycle // 50 MHz
//   end

// endmodule

`endif // UART_TESTBENCHES