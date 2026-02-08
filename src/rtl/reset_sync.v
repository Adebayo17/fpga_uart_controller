`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.02.2026 17:02:53
// Design Name: 
// Module Name: reset_sync
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


module reset_sync(
    input   wire clk,
    input   wire rst_async_in,  // Physical button (BTN0)
    output  reg  rst_sync_out   // Clean signal for the system
    );
    
    reg rst_meta;   // Intermediate flip-flop
    
    always @(posedge clk) begin
        rst_meta        <= rst_async_in;
        rst_sync_out    <= rst_meta;
    end 
endmodule
