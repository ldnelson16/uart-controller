module UART_main
  (
    output		     [7:0]		HEX0,
    output		     [7:0]		HEX1,
    output		     [7:0]		HEX2,
    output		     [7:0]		HEX3,
    output		     [7:0]		HEX4,
    output		     [7:0]		HEX5,

    output                  TX,
    input                   RX,

    input                   MAX10_CLK1_50,

    input          [1:0]    KEY,

    input 		     [9:0]		SW,

    output         [7:0]    LEDR
  );

  assign TX = KEY[0];

  // signals for/from UART controllers
  reg rst;
  wire nic_to_os_interrupt1, nic_to_os_interrupt2;
  wire[7:0] rec_data_from_nic1, rec_data_from_nic2;
  wire tx1,tx2,rx1,rx2;
  assign rx1 = tx2;
  assign rx2 = tx1;

  wire button1, button2;
  reg which_button; // 0 for b1, 1 for b2

  reg[31:0] clk_div;

  initial begin
    clk_div <= 0;
    which_button <= 0;
  end

  parameter HALF_SECOND = 50000000 / 2;

  assign button1 = ~KEY[0] && SW[8] && ~SW[9];
  assign button2 = ~KEY[1] && SW[9] && ~SW[8];

  always @ (posedge MAX10_CLK1_50) begin
    if (clk_div == 0) begin
      if (button1) begin
        clk_div <= 1;
        which_button <= 0;
      end else if (button2) begin
        clk_div <= 1;
        which_button <= 1;
      end
    end else if (clk_div == HALF_SECOND) begin
      clk_div <= 0;
    end else begin
      clk_div <= (clk_div + 1);
    end
  end

  assign button1_f = ~which_button && (clk_div == HALF_SECOND);
  assign button2_f = which_button  && (clk_div == HALF_SECOND);


  initial begin // assign some values
    rst <= 0;
  end

  // signals for/from OS simulator
  wire write_nic1, write_nic2, read_nic1, read_nic2;
  wire[7:0] data_for_nic1, data_for_nic2;
  
  UART_OS_simulator OS1(
    .clk(MAX10_CLK1_50),
    .send_button(button1_f),
    .send_data_from_buttons(SW[7:0]),
    .rec_data_from_nic(rec_data_from_nic1),
    .send_data_i(nic_to_os_interrupt1),
    .editing_input_data(SW[8] && ~SW[9]),
    .send_data_to_nic(data_for_nic1),
    .write_nic(write_nic1),
    .read_nic(read_nic1),
    .D0(HEX3),
    .D1(HEX4),
    .D2(HEX5),
    .LEDR_for_num_data_rcvd(LEDR[3:0])
  );
  UART_CONTROLLER controller1(
    .clk(MAX10_CLK1_50),
    .rst(rst),
    .data_in(data_for_nic1),
    .write_nic(write_nic1),
    .read_nic(read_nic1),
    .rx(rx1),
    .data_out(rec_data_from_nic1),
    .read_nic_i(nic_to_os_interrupt1),
    .tx(tx1)
  );

  UART_OS_simulator OS2(
    .clk(MAX10_CLK1_50),
    .send_button(button2_f),
    .send_data_from_buttons(SW[7:0]),
    .rec_data_from_nic(rec_data_from_nic2),
    .send_data_i(nic_to_os_interrupt2),
    .editing_input_data(SW[9] && ~SW[8]),
    .send_data_to_nic(data_for_nic2),
    .write_nic(write_nic2),
    .read_nic(read_nic2),
    .D0(HEX0),
    .D1(HEX1),
    .D2(HEX2),
    .LEDR_for_num_data_rcvd(LEDR[7:4])
  );
  UART_CONTROLLER controller2(
    .clk(MAX10_CLK1_50),
    .rst(rst),
    .data_in(data_for_nic2),
    .write_nic(write_nic2),
    .read_nic(read_nic2),
    .rx(rx2),
    .data_out(rec_data_from_nic2),
    .read_nic_i(nic_to_os_interrupt2),
    .tx(tx2)
  );

endmodule

