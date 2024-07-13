// UART_main.v (for DE0-NANO)

//`include "UART_OS_simulator.sv"
//`include "UART.sv"
//`include "extra_functions.sv"

//`include "UART_parameters.sv"

`ifndef UART_MAIN_DE0_NANO
`define UART_MAIN_DE0_NANO

module UART_main_de0_nano
  (
    output                   TX,
    input                   RX,

    input                   CLK,

    input          [1:0]    KEY,

    input 		     [9:0]		SW,

    output         [7:0]    LED
  );

  // signals for/from UART controllers
  reg rst;
  wire nic_to_os_interrupt1, nic_to_os_interrupt2;
  wire[7:0] rec_data_from_nic1, rec_data_from_nic2;
  wire button_press;

  initial begin
    rst <= 0;
  end

  button_buffer button
  (
    .input_button(~KEY[0]),
    .clk(CLK),
    .output_button(button_press)
  );

  // signals for/from OS simulator
  wire write_nic1, write_nic2, read_nic1, read_nic2;
  wire[7:0] data_for_nic1, data_for_nic2;

  // for DE0-NANO to compile
  wire[3:0] four_junk;
  
  UART_OS_simulator_binary OS(
    .clk(CLK),
    .send_button(button_press),
    .send_data_from_buttons(LED),
    .rec_data_from_nic(rec_data_from_nic1),
    .send_data_i(nic_to_os_interrupt1),
    .editing_input_data(0),
    .send_data_to_nic(data_for_nic1),
    .write_nic(write_nic1),
    .read_nic(read_nic1),
    .Display(LED),
    .LEDR_for_num_data_rcvd(four_junk),
    .LEDR_for_num_data_tmtd(four_junk)
  ); 
  UART_CONTROLLER controller(
    .clk(CLK),
    .rst(rst),
    .data_in(data_for_nic1),
    .write_nic(write_nic1),
    .read_nic(read_nic1),
    .rx(RX),
    .data_out(rec_data_from_nic1),
    .read_nic_i(nic_to_os_interrupt1),
    .tx(TX)
  );

endmodule

`endif // UART_MAIN_DE0_NANO