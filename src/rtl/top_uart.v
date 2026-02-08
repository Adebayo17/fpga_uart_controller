`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.01.2026 16:40:21
// Design Name: 
// Module Name: top_uart
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


module top_uart(
    input   wire clk,
    input   wire btn_rst,
    input   wire usb_uart_rx,
    output  wire usb_uart_tx,
    output  wire led_rx_active,
    output  wire led_tx_active
    );
    
    wire rst_clean;
    wire tick_connection;               // The "tick_16x" signal that connects everyone
    wire rx_dv_connection;
    wire [7:0] rx_byte_connection;
    wire tx_active_connection;
    wire tx_done_connection;
    
    // 1. Reset sync
    reset_sync u_rst_sync (
        .clk(clk),
        .rst_async_in(btn_rst), 
        .rst_sync_out(rst_clean) 
    );

    // 2. Baud Rate Generator 
    // 125 MHz / (115200 * 16) = ~68
    baud_rate_generator #(
        .CLOCK_RATE(125000000),
        .BAUD_RATE(115200)
    ) u_baud_gen (
        .clk(clk),
        .rst(rst_clean),
        .tick_16x(tick_connection)      // <--- Output to RX et TX
    );

    // 3. UART RX 
    uart_rx u_rx (
        .clk(clk),
        .rst(rst_clean),
        .tick_16x(tick_connection), 
        .rx_serial(usb_uart_rx),
        .rx_dv(rx_dv_connection),
        .rx_byte(rx_byte_connection)
    );

    // 4. UART TX 
    uart_tx u_tx (
        .clk(clk),
        .rst(rst_clean),
        .tick_16x(tick_connection), 
        .tx_dv(rx_dv_connection),       // Loopback : RX Valid déclenche TX
        .tx_byte(rx_byte_connection),
        .tx_active(tx_active_connection),
        .tx_serial(usb_uart_tx),
        .tx_done(tx_done_connection)
    );
    
    
    // --- 5. LED EXTENDERS (Visual Feedback) ---

    // LED 0 : Flashes when RECEIVING (RX)
    led_pulse_extender #(
        .EXTEND_MS(50) 
    ) u_led_rx (
        .clk(clk),
        .rst(rst_clean),
        .signal_in(rx_dv_connection),       // 8ns pulse
        .led_out(led_rx_active)             // 50ms pulse
    );

    // LED 1 : Flashes when EMETTING (TX)
    led_pulse_extender #(
        .EXTEND_MS(50)
    ) u_led_tx (
        .clk(clk),
        .rst(rst_clean),
        .signal_in(tx_active_connection),       // Long Signal (~86us)
        .led_out(led_tx_active)                 // 50ms pulse min
    );
endmodule
