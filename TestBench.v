`timescale 1ns/1ns

// TB_Transmitter_Simulator.v
`include "UART_parameters.vh"

module TB_Controller_Simulator ();
  // parameters
  uart_parameters params();

  // Declare signals
  reg clk;
  reg rst;
  reg rx1; reg rx2;
  wire tx1; wire tx2;

  // Modules
  UART_CONTROLLER uart_controller_1(
    .clk(clk),
    .rst(rst),
    .rx(rx1),
    .tx(tx1)
  );
  UART_CONTROLLER uart_controller_2(
    .clk(clk),
    .rst(rst),
    .rx(rx2),
    .tx(tx2)
  );

  initial begin
    // clock
    clk <= 0;
    forever #10 clk = ~clk; // 20 ns cycle // 50 MHz
  end

  integer i,j; // for loop
  wire[params.WORD_SIZE-1:0] random_word;
  assign random_word = j**2 + 3*j + 5 + (j+1)**3;

  // Simulate rx;
  initial begin : simulator
    // CORRECT BYTE
    rx1 <= 1; #(params.BAUD*6); // IDLE
    for (j=0; j < 14; j = j + 1) begin : named_for
      rx1 <= 0; #(params.BAUD); // START BIT
      for (i = 0; i < 8; i = i + 1) begin
        rx1 <= random_word[i]; // Alternate between 0 and 1
        #(params.BAUD); // 1 baud cycle per bit
      end

      rx1 <= 1; #(params.BAUD); // END BIT
      rx1 <=1; #(params.BAUD*(0.25*j)); // IDLE
    end : named_for

    // FAIL BYTE (DUE TO END BIT)
    rx1 <= 1; #(params.BAUD*6); // IDLE
    rx1 <= 0; #(params.BAUD); // START BIT

    for (i = 0; i < 8; i = i + 1) begin
      rx1 <= i % 2; // Alternate between 0 and 1
      #(params.BAUD); // 1 baud cycle per bit
    end

    rx1 <= 0; #(params.BAUD); // ERROR! END BIT
    rx1 <=1; #(params.BAUD*6); // IDLE
  end : simulator

endmodule

module TB_OS_Write_to_NIC_and_Read_from_NIC ();
  // parameters
  uart_parameters params();

  // Declare signals
  reg clk;
  reg rst;
  wire tx1; wire tx2;

  reg[7:0] data_in1, data_in2;
  wire[7:0] data_out1, data_out2;

  wire read_nic_i1, read_nic_i2;

  reg write_nic1, write_nic2, read_nic1, read_nic2;

  // Modules
  UART_CONTROLLER uart_controller1(
    .clk(clk),
    .rst(rst),
    .data_in(data_in1),
    .write_nic(write_nic1), 
    .read_nic(read_nic1), 
    .rx(tx2),
    .data_out(data_out1),
    .read_nic_i(read_nic_i1),
    .tx(tx1)
  );

  UART_CONTROLLER uart_controller_2(
    .clk(clk),
    .rst(rst),
    .data_in(data_in2),
    .write_nic(write_nic2), 
    .read_nic(read_nic2), 
    .rx(tx1),
    .data_out(data_out2),
    .read_nic_i(read_nic_i2),
    .tx(tx2)
  );

  initial begin
    data_in1 <= 8'b01010101;
    write_nic1 <= 1; #20;
    write_nic1 <= 0; #40;
    data_in1 <= 8'b10101010;
    write_nic1 <= 1; #20;
    write_nic1 <= 0; #3000000;
    read_nic2 <= 1; #20;
    read_nic2 <= 0; #40;
    read_nic2 <= 1; #20;
    read_nic2 <= 0; 
  end

  initial begin
    // clock
    clk <= 0;
    forever #10 clk = ~clk; // 20 ns cycle // 50 MHz
  end



endmodule

module TB_Transmittor_Simulator (); // Test Receiver
  // parameters
  uart_parameters params();
  
  // signals
  reg clk;
  reg rst;
  reg rx;
  reg disable_data_interrupt; // lets receiver know controller finished handling enable_data_interrupt
  wire enable_data_interrupt; // lets controller know that receiver has finished receiving a piece of data
  wire[7:0] read_data;

  // modules
  UART_RECEIVER uart_receiver(
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .disable_data_interrupt(disable_data_interrupt),
    .enable_data_interrupt(enable_data_interrupt),
    .data(read_data)
  );

  initial begin
    // clock
    clk <= 0;
    forever #10 clk = ~clk; // 20 ns cycle // 50 MHz
  end

  integer i; // for loop

  // Simulate rx;
  initial begin : simulator
    // CORRECT BYTE
    rx <= 1; #(params.BAUD*6); // IDLE
    rx <= 0; #(params.BAUD); // START BIT

    for (i = 0; i < 8; i = i + 1) begin
      rx <= i % 2; // Alternate between 0 and 1
      #(params.BAUD); // 1 baud cycle per bit
    end

    rx <= 1; #(params.BAUD); // END BIT
    rx <=1; #(params.BAUD*6); // IDLE

    // FAIL BYTE (DUE TO END BIT)
    rx <= 1; #(params.BAUD*6); // IDLE
    rx <= 0; #(params.BAUD); // START BIT

    for (i = 0; i < 8; i = i + 1) begin
      rx <= i % 2; // Alternate between 0 and 1
      #(params.BAUD); // 1 baud cycle per bit
    end

    rx <= 0; #(params.BAUD); // ERROR! END BIT
    rx <=1; #(params.BAUD*6); // IDLE
  end : simulator
endmodule

module TB_Main_Simulator ();

  wire[7:0] HEX0_m, HEX1_m, HEX2_m, HEX3_m, HEX4_m, HEX5_m, LEDR_m;
  reg clk;
  reg[1:0] KEY_m;
  reg[9:0] SW_m;

  UART_main main(
    .HEX0(HEX0_m),
    .HEX1(HEX1_m),
    .HEX2(HEX2_m),
    .HEX3(HEX3_m),
    .HEX4(HEX4_m),
    .HEX5(HEX5_m),
    .MAX10_CLK1_50(clk),
    .KEY(KEY_m),
    .SW(SW_m),
    .LEDR(LEDR_m)
  );

  initial begin
    KEY_m[1:0] <= 2'b11;
    SW_m[7:0] <= 8'b10101010; SW_m[8] <= 1; SW_m[9] <= 0; #500;
    KEY_m[0] <= 0; #200000;
    KEY_m[0] <= 0;
  end

  initial begin
    // clock
    clk <= 0;
    forever #10 clk = ~clk; // 20 ns cycle // 50 MHz
  end

endmodule
