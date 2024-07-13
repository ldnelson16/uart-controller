// extra_functions.v 

`include "UART_parameters.sv"

`ifndef EXTRA_FUNCTIONS
`define EXTRA_FUNCTIONS

module button_buffer
    #(
        parameter CLOCK_CYCLES = (`CLOCK_FREQ_p / `BUTTON_BUFFER_p)
    )
    (
        input wire input_button, 
        input wire clk, 
        output output_button
    );

    reg[31:0] clk_div; // to maintain clock counter

    initial begin
        clk_div <= 0;
    end

    assign output_button = (clk_div == CLOCK_CYCLES);

    always @ (posedge clk) begin
        if (clk_div == 0) begin
            if (input_button) begin
                clk_div <= 1;
            end
        end else if (clk_div == CLOCK_CYCLES) begin
            clk_div <= 0;
        end else begin
            clk_div <= (clk_div + 1);
        end
    end

endmodule

`endif // EXTRA_FUNCTIONS