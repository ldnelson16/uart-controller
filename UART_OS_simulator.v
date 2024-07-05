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
    output[7:0] D0,D1,D2,
    output[3:0] LEDR_for_num_data_rcvd
  );

  reg[7:0] data_display;
  reg[3:0] num_data_received;

  initial begin
    data_display <= 0;
    num_data_received <= 0;
    write_nic <= 0;
    read_nic <= 0;
  end

  // Read from NIC logic // and increment num_data_received
  if (send_data_i) begin
    read_nic <= 1;
  end else begin
    read_nic <= 0;
  end
  if (read_nic) begin
    data_display <= rec_data_from_nic;
    num_data_received = (num_data_received + 1);
  end
  
  // Write to NIC logic
  if (send_button) begin
    send_data_to_nic <= send_data_from_buttons;
    write_nic <= 1;
  end else begin
    write_nic <= 0;
  end

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
