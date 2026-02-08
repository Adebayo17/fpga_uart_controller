`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.02.2026 18:05:00
// Design Name: 
// Module Name: led_pulse_extender
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module led_pulse_extender#(
    parameter CLK_FREQ = 125_000_000,
    parameter EXTEND_MS = 50            // Ignition time in milliseconds
)(
    input   wire clk,
    input   wire rst,
    input   wire signal_in,     // Fast signal (rx_dv or tx_active)
    output  reg  led_out        // Slow signal to physical LED
    );
    
    // Calcuclation of the number of cycles
    // 50ms * 125MHz = 6_250_000 cycles
    localparam MAX_COUNT = (CLK_FREQ / 1000) * EXTEND_MS;
    localparam WIDTH     = $clog2(MAX_COUNT);
    
    reg [WIDTH-1:0] counter;
    
    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            led_out <= 0;
        end else begin
            // If the input signal is active, the counter is recharged (Retriggerable)
            if (signal_in == 1'b1) begin
                counter <= MAX_COUNT;
                led_out <= 1'b1;
            end 
            // Otherwise, if the counter is not empty, it is decremented.
            else if (counter > 0) begin
                counter <= counter - 1;
                led_out <= 1'b1;
            end 
            // Otherwise, we turn it off.
            else begin
                led_out <= 1'b0;
            end
        end
    end
endmodule
