`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.01.2026 16:30:04
// Design Name: 
// Module Name: uart_tx
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


module uart_tx(
    input   wire        clk,
    input   wire        rst,
    input   wire        tick_16x,
    input   wire        tx_dv,
    input   wire [7:0]  tx_byte,
    output  reg         tx_active,
    output  reg         tx_serial,
    output  reg         tx_done
    );
    
    localparam S_IDLE  = 2'b00;
    localparam S_START = 2'b01;
    localparam S_DATA  = 2'b10;
    localparam S_STOP  = 2'b11;
    
    reg [1:0] state;
    reg [3:0] tick_count;
    reg [2:0] bit_index;
    reg [7:0] tx_data_latch;
    
    always @(posedge clk) begin 
        if (rst) begin
            state           <= S_IDLE;
            tx_active       <= 0;
            tx_serial       <= 1;
            tx_done         <= 0;
            tick_count      <= 0;
            bit_index       <= 0;
            tx_data_latch   <= 0;
        end else begin 
            
            // FSM runs only on validation (except IDLE)
            case (state)
                S_IDLE: begin
                    tx_active       <= 0;
                    tx_serial       <= 1;
                    tx_done         <= 0;
                    tick_count      <= 0;
                    bit_index       <= 0;
                    tx_data_latch   <= 0;
                    
                    if (tx_dv) begin
                        tx_data_latch <= tx_byte;
                        state         <= S_START;
                    end 
                end 
                
                // Start Bit : Output at '0' for 16 ticks
                S_START: begin
                    tx_active       <= 1;
                    tx_serial       <= 0;
                    
                    if (tick_16x) begin
                        if (tick_count == 15) begin 
                            tick_count  <= 0;
                            state       <= S_DATA;
                        end else begin
                            tick_count <= tick_count + 1;
                        end 
                    end 
                end 
                
                // Data Bits : We sent each Bit for 16 ticks
                S_DATA: begin
                    tx_serial <= tx_data_latch[bit_index];
                    
                    if (tick_16x) begin
                        if (tick_count == 15) begin     // 16 ticks = 1 full bit
                            tick_count <= 0;
                            if (bit_index == 7) begin 
                                bit_index <= 0;
                                state <= S_STOP;
                            end else begin 
                                bit_index <= bit_index + 1;
                            end 
                        end else begin
                            tick_count <= tick_count + 1;
                        end 
                    end 
                end 
                
                // Stop Bit : '1' for 16 ticks
                S_STOP: begin
                    tx_serial   <= 1;
                    
                    if (tick_16x) begin
                        if (tick_count == 15) begin     // End of Bit Stop
                            tx_done <= 1;
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




