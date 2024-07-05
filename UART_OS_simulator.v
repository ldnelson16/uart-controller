module UART_OS_simulator
  #(

  )
  (
    input wire send_button,
    input wire[7:0] send_data_from_buttons,
    input wire[7:0] rec_data_from_nic,
    input wire send_data_i,
    output reg[7:0] send_data_to_nic;
    output reg write_nic,
    output reg read_nic,
    output reg[7:0] D0,D1,D2,
    output[3:0] LEDR_for_num_data_rcvd
  );

  reg[7:0] data_display;
  reg[3:0] num_data_received;

  // Read from NIC logic // and increment num_data_received

  // Write to NIC logic

  // Display logic using Bin-> 7seg
  Binary_2_7SEG display_data_sent_from_1(
    .N(data_display),
    .D0(D0),
    .D1(D1),
    .D2(D2)
  );

  // Display logic for counters
  assign LEDR_for_num_data_rcvd = num_data_received;

endmodule