module UART_main
  (
    output		     [7:0]		HEX0,
    output		     [7:0]		HEX1,
    output		     [7:0]		HEX2,
    output		     [7:0]		HEX3,
    output		     [7:0]		HEX4,
    output		     [7:0]		HEX5,

    input          [1:0]    KEY,

    input 		     [9:0]		SW
  );
  

  Binary_2_7SEG
    (
      .N(SW[7:0]),
      .D0(HEX0),
      .D1(HEX1),
      .D2(HEX2)
    );

endmodule

