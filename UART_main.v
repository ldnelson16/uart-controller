module UART_main
  (
    output		     [7:0]		HEX0,
    output		     [7:0]		HEX1,
    output		     [7:0]		HEX2,
    output		     [7:0]		HEX3,
    output		     [7:0]		HEX4,
    output		     [7:0]		HEX5,

    output         two gpio
    input          two gpio

    input          [1:0]    KEY,

    input 		     [9:0]		SW
  );
  
  UART_OS_simulator OS1(

  );
  UART_controller controller1(

  );

  UART_OS_simulator OS2(

  );
  UART_controller controller2(

  );

endmodule

