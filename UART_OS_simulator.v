module UART_OS_simulator
  (
    input wire clk,
    input wire send_button,
    input wire[7:0] send_data_from_buttons,
    input wire[7:0] rec_data_from_nic,
    input wire send_data_i,
    input wire editing_input_data,
    output reg[7:0] send_data_to_nic,
    output reg write_nic,
    output reg read_nic,
    output [6:0] D0,D1,D2,
    output reg [3:0] LEDR_for_num_data_rcvd
  );

  reg[7:0] data_display;
  reg[3:0] num_data_received;

  initial begin
    data_display <= 0;
    num_data_received <= 0;
    write_nic <= 0;
    read_nic <= 0;
    send_data_to_nic <= 0;
  end

  // Read from NIC logic // and increment num_data_received
  always @ (posedge clk) begin
    if (send_data_i) begin
      read_nic <= 1;
    end else begin
      read_nic <= 0;
    end
    if (read_nic) begin
      num_data_received = (num_data_received + 1);
    end
  end

  // Write to NIC logic
  always @ (posedge clk) begin
    if (send_button) begin
      send_data_to_nic <= send_data_from_buttons;
      write_nic <= 1;
    end else begin
      write_nic <= 0;
    end
  end

  // Logic for what to display
  always @ (posedge clk) begin
    if (send_button) begin
      data_display <= send_data_from_buttons;
    end else if (read_nic) begin
      data_display <= rec_data_from_nic;
    end
  end

  // Display logic using Bin-> 7seg
  Binary_2_7SEG display_data_sent_from_1(
    .N(data_display),
    .D0(D0),
    .D1(D1),
    .D2(D2)
  );

  // Display logic for counters
  always @ (posedge clk) begin 
    LEDR_for_num_data_rcvd <= num_data_received;
  end

endmodule
