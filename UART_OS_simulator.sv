// UART_OS_simulator.v

`include "BINARY2SEG.sv"

`ifndef UART_OS_SIMULATORS
`define UART_OS_SIMULATORS

module UART_OS_simulator_HEX // for HEX display
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
    output [7:0] D0,D1,D2,
    output reg [3:0] LEDR_for_num_data_rcvd,
    output reg [3:0] LEDR_for_num_data_tmtd
  );

  reg[7:0] data_display;

  reg trail_read_nic;

  initial begin 
    trail_read_nic <= 0;
  end

  always @ (posedge clk) begin
    trail_read_nic <= read_nic;
  end

  initial begin
    data_display <= 0;
    LEDR_for_num_data_rcvd <= 0;
    LEDR_for_num_data_tmtd <= 0;
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
      LEDR_for_num_data_rcvd = (LEDR_for_num_data_rcvd + 1);
    end
  end

  // Write to NIC logic
  always @ (posedge clk) begin
    if (send_button) begin
      send_data_to_nic <= send_data_from_buttons;
      write_nic <= 1;
      LEDR_for_num_data_tmtd <= (LEDR_for_num_data_tmtd + 1);
    end else begin
      write_nic <= 0;
    end
  end

  // Logic for what to display
  always @ (posedge clk) begin
    if (editing_input_data) begin
      data_display <= send_data_from_buttons;
    end else if (trail_read_nic) begin // one cycle after read_nic was issued (since it uses one cycle memory retrieval)
      data_display <= rec_data_from_nic;
    end
  end

  // Display logic using Bin-> 7seg
  Binary_2_7SEG display_data(
    .N(data_display),
    .D0(D0),
    .D1(D1),
    .D2(D2)
  );

endmodule

module UART_OS_simulator_binary // for BINARY DISPLAY
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
    output [7:0] Display,
    output reg [3:0] LEDR_for_num_data_rcvd,
    output reg [3:0] LEDR_for_num_data_tmtd
  );

  reg[7:0] data_display;

  reg trail_read_nic;

  initial begin 
    trail_read_nic <= 0;
  end

  always @ (posedge clk) begin
    trail_read_nic <= read_nic;
  end

  initial begin
    data_display <= 0;
    LEDR_for_num_data_rcvd <= 0;
    LEDR_for_num_data_tmtd <= 0;
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
      LEDR_for_num_data_rcvd = (LEDR_for_num_data_rcvd + 1);
    end
  end

  // Write to NIC logic
  always @ (posedge clk) begin
    if (send_button) begin
      send_data_to_nic <= send_data_from_buttons;
      write_nic <= 1;
      LEDR_for_num_data_tmtd <= (LEDR_for_num_data_tmtd + 1);
    end else begin
      write_nic <= 0;
    end
  end

  // Logic for what to display
  always @ (posedge clk) begin
    if (editing_input_data) begin
      data_display <= send_data_from_buttons;
    end else if (trail_read_nic) begin // one cycle after read_nic was issued (since it uses one cycle memory retrieval)
      data_display <= rec_data_from_nic;
    end
  end

  // Display logic using Bin-> 7seg
  assign Display = data_display;

endmodule

`endif // UART_OS_SIMULATORS