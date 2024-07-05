module Binary_2_7SEG
	#(parameter W = 8)				// Default bit width
	(input [W-1:0] N,					// W-bit "signed" number			
	 output [6:0] D2, D1, D0		// 7SEG display for the three digits
	);

// Named HEX Outputs
	localparam ZERO 	= 7'b1000000;	// 64
	localparam ONE		= 7'b1111001; 	// 121
	localparam TWO		= 7'b0100100; 	// 36
	localparam THREE	= 7'b0110000; 	// 48
	localparam FOUR	= 7'b0011001; 	// 25
	localparam FIVE	= 7'b0010010; 	// 18
	localparam SIX		= 7'b0000010; 	// 2
	localparam SEVEN	= 7'b1111000; 	// 120
	localparam EIGHT	= 7'b0000000; 	// 0
	localparam NINE	= 7'b0010000; 	// 16
	localparam MINUS	= 7'b0111111;	// 63
	localparam OFF		= 7'b1111111; 	// 127

// Load the look-up table
	reg [6:0] LUT[0:9];					// Magnitude Look-up Table
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
	wire [W-1:0] Quotient0, Quotient1, Digit0, Digit1, Digit2;
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