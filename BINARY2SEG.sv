// BINARY2SEG.v

`ifndef BINARY2SEG
`define BINARY2SEG

`include "UART_parameters.sv"

module Binary_2_7SEG
	#(
		parameter WIDTH = `WORD_SIZE_p // Default bit width
	)				
	(
		input [WIDTH-1:0] N,					// W-bit "signed" number			
	  output [7:0] D2, D1, D0		// 7SEG display for the three digits
	);

	// Named HEX Outputs
	localparam ZERO 	= 8'b11000000;	// 64
	localparam ONE		= 8'b11111001; 	// 121
	localparam TWO		= 8'b10100100; 	// 36
	localparam THREE	= 8'b10110000; 	// 48
	localparam FOUR	= 8'b10011001; 	// 25
	localparam FIVE	= 8'b10010010; 	// 18
	localparam SIX		= 8'b10000010; 	// 2
	localparam SEVEN	= 8'b11111000; 	// 120
	localparam EIGHT	= 8'b10000000; 	// 0
	localparam NINE	= 8'b10010000; 	// 16
	localparam MINUS	= 8'b10111111;	// 63
	localparam OFF		= 8'b11111111; 	// 127

	// Load the look-up table
	reg [8:0] LUT[0:9];					// Magnitude Look-up Table
	initial begin
		LUT[0] = ZERO;
		LUT[1] = ONE;
		LUT[2] = TWO;
		LUT[3] = THREE;
		LUT[4] = FOUR;
		LUT[5] = FIVE;
		LUT[6] = SIX;
		LUT[7] = SEVEN;
		LUT[8] = EIGHT;
		LUT[9] = NINE;
	end

	// Get digits of N
	wire [WIDTH-1:0] Quotient0, Quotient1, Digit0, Digit1, Digit2;
	assign Quotient0 = N / 4'b1010;
	assign Quotient1 = Quotient0 / 4'b1010;
	assign Digit0 = N % 4'b1010;
	assign Digit1 = Quotient0 % 4'b1010;
	assign Digit2 = Quotient1 % 4'b1010;
	
	// Display: indicate out-of-range with "dashes"
	assign D2 = ((Digit2 == 'd0) ? OFF : LUT[Digit2]);
	assign D1 = ((Digit2 == 'd0) & (Digit1 == 'd0) ? OFF : LUT[Digit1]);
	assign D0	= LUT[Digit0];
endmodule

`endif // BINARY2SEG