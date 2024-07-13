// UART_main.v (for DE10-LITE)

`include "UART_OS_simulator.sv"
`include "UART.sv"
`include "extra_functions.sv"

`ifndef UART_MAIN_DE10_LITE
`define UART_MAIN_DE10_LITE

module UART_main_de10_lite
  (
    output		     [7:0]		HEX0,
    output		     [7:0]		HEX1,
    output		     [7:0]		HEX2,
    output		     [7:0]		HEX3,
    output		     [7:0]		HEX4,
    output		     [7:0]		HEX5,

    output                  TX,
    input                   RX,

    input                   CLK,

    input          [1:0]    KEY,

    input 		     [9:0]		SW,

    output         [7:0]    LEDR
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
  
  UART_OS_simulator_HEX OS(
    .clk(CLK),
    .send_button(button_press),
    .send_data_from_buttons(SW[7:0]),
    .rec_data_from_nic(rec_data_from_nic1),
    .send_data_i(nic_to_os_interrupt1),
    .editing_input_data(SW[8]),
    .send_data_to_nic(data_for_nic1),
    .write_nic(write_nic1),
    .read_nic(read_nic1),
    .D0(HEX0),
    .D1(HEX1),
    .D2(HEX2),
    .LEDR_for_num_data_rcvd(LEDR[3:0]),
    .LEDR_for_num_data_tmtd(LEDR[7:4])
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

`endif // UART_MAIN_DE10_LITE