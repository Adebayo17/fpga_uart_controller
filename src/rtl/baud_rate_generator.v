`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.01.2026 16:25:54
// Design Name: 
// Module Name: baud_rate_generator
// Project Name: Uart Controller
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


module baud_rate_generator #(
    parameter CLOCK_RATE = 125_000_000,
    parameter BAUD_RATE  = 115_200
)(
    input   wire clk,
    input   wire rst,
    output  reg  tick_16x
    );
    
    localparam MAX_COUNT = CLOCK_RATE / (BAUD_RATE * 16);
    localparam WIDTH     = $clog2(MAX_COUNT);
    
    reg [WIDTH-1:0] counter;
    
    always @(posedge clk) begin
        if (rst) begin
            counter     <= 0;
            tick_16x    <= 1'b0;
        end else begin
            if (counter >= MAX_COUNT - 1) begin
                counter     <= 0;
                tick_16x    <= 1'b1;
            end else begin 
                counter     <= counter + 1;
                tick_16x    <= 1'b0;
            end 
        end 
    end
endmodule
