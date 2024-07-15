// TestBench.sv

`ifndef UART_TESTBENCHES
`define UART_TESTBENCHES

`timescale 1ns/1ns

`include "UART_parameters.sv"

module TB_test_throughput();
  // Declare signals
  reg clk; // clock
  reg rst; // reset

  reg rx_1, rx_2; // rx signals
  wire tx_1, tx_2; // tx signals

  reg write_nic_1, write_nic_2; // write signal to NIC
  reg read_nic_1, read_nic_2; // read signal to NIC

  wire data_out_1, data_out_2; // data read from NIC 
  wire read_nic_i_1, read_nic_i_2; // signals that data is to be read from NIC

  reg[`WORD_SIZE_p:0] data_in_1, data_in_2; // data sent to NIC

  reg[`WORD_SIZE_p:0] random_int_1, random_int_2; // to feed to transmit
  
  // Instantiate two UART modules
  UART_CONTROLLER uart_controller_1(
    .clk(clk),
    .rst(rst),
    .data_in(data_in_1),
    .write_nic(write_nic_1),
    .rx(rx_1),
    .data_out(data_out_1),
    .read_nic_i(read_nic_i_1),
    .tx(tx_1)
  );
  UART_CONTROLLER uart_controller_2(
    .clk(clk),
    .rst(rst),
    .data_in(data_in_2),
    .write_nic(write_nic_2),
    .rx(rx_2),
    .data_out(data_out_2),
    .read_nic_i(read_nic_i_2),
    .tx(tx_2)
  );

  // Clock signal
  initial begin
    clk <= 0; rst <= 0;
    forever #10 clk = ~clk;
  end

  // Create randomized data for uart's to send
  initial begin
    random_int_1 <= ($urandom % (2**`WORD_SIZE_p));
    random_int_2 <= ($urandom % 256);
  end
  always @ (posedge clk) begin
    random_int_1 <= ($urandom % (2**`WORD_SIZE_p));
    random_int_2 <= ($urandom % (2**`WORD_SIZE_p));
  end
  
  // Send randomized data to uart_1 (so uart_1 can send it) 2*TX_RING_SIZE_p clock cycles in a row
  integer counter_1;

  initial begin
    counter_1 = 0;
    forever begin
      @(posedge clk);
      if (counter_1 < (2 * `TX_RING_SIZE_p)) begin
        $display("Sending %0d out via transmitter 1", random_int_1);
        write_nic_1 <= 1;
        data_in_1 <= random_int_1;
        counter_1 = counter_1 + 1;
      end else begin
        write_nic_1 <= 0;
      end
    end
  end

  // Send randomized data to uart_2 (so uart_2 can send it)
  integer counter_2;

  initial begin
    counter_2 = 0;
    forever begin
      @(posedge clk);
      if (counter_2 < (2 * `TX_RING_SIZE_p)) begin
        $display("Sending %0d out via transmitter 2", random_int_2);
        write_nic_2 <= 1;
        data_in_2 <= random_int_2;
        counter_2 = counter_2 + 1;
      end else begin
        write_nic_2 <= 0;
      end
    end
  end

  // Read randomized data from uart_1 (and verify with sent data from uart_2)


  // Read randomized data from uart_2 (and verify with sent data from uart_1)
endmodule

// module TB_Controller_Simulator ();
//   // Declare signals
//   reg clk;
//   reg rst;
//   reg rx1; reg rx2;
//   wire tx1; wire tx2;

//   // Modules
//   UART_CONTROLLER uart_controller_1(
//     .clk(clk),
//     .rst(rst),
//     .rx(rx1),
//     .tx(tx1)
//   );
//   UART_CONTROLLER uart_controller_2(
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

//   UART_CONTROLLER uart_controller_2(
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