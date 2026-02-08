`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.01.2026 16:30:04
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(
    input   wire        clk,
    input   wire        rst,
    input   wire        tick_16x,
    input   wire        rx_serial,
    output  reg         rx_dv,
    output  reg [7:0]   rx_byte
    );
    
    localparam S_IDLE  = 2'b00;
    localparam S_START = 2'b01;
    localparam S_DATA  = 2'b10;
    localparam S_STOP  = 2'b11;
    
    reg [1:0] state;
    reg [3:0] tick_count;   // Count till 15
    reg [2:0] bit_index;
    
    always @(posedge clk) begin
        if (rst) begin
            state       <= S_IDLE;
            rx_dv       <= 0;
            tick_count  <= 0;
            bit_index   <= 0;
            rx_byte     <= 0;
        end else begin 
            
            case (state)
                S_IDLE: begin
                    rx_dv       <= 0;
                    tick_count  <= 0;
                    bit_index   <= 0;
                    
                    if (rx_serial == 0) begin
                        state <= S_START;
                    end 
                end 
                
                S_START: begin
                    if (tick_16x) begin
                        if (tick_count == 7) begin      // 8 ticks = middle of the bit
                            if (rx_serial == 0) begin   // Check Start Valid
                                tick_count  <= 0;
                                state       <= S_DATA;
                            end else begin 
                                state       <= S_IDLE;  // False Start
                            end 
                        end else begin
                            tick_count <= tick_count + 1;
                        end 
                    end 
                end 
                
                S_DATA: begin
                    if (tick_16x) begin
                        if (tick_count == 15) begin     // 16 ticks = 1 full bit
                            tick_count          <= 0;
                            rx_byte[bit_index]  <= rx_serial;
                            
                            if (bit_index == 7) begin 
                                state       <= S_STOP;
                            end else begin 
                                bit_index   <= bit_index + 1;
                            end 
                        end else begin
                            tick_count <= tick_count + 1;
                        end 
                    end 
                end 
                
                S_STOP: begin
                    if (tick_16x) begin
                        if (tick_count == 15) begin     // 16 ticks = 1 full bit
                            rx_dv   <= 1;               // Complete
                            state   <= S_IDLE;
                        end else begin
                            tick_count <= tick_count + 1;
                        end 
                    end 
                end 
            endcase
        end 
    end 
endmodule






