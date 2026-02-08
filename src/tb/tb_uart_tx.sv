`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.01.2026 16:56:51
// Design Name: 
// Module Name: tb_uart_tx
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


module tb_uart_tx;

    // --- Parameters ---
    localparam int CLOCK_RATE = 125_000_000;
    localparam int BAUD_RATE  = 115_200;
    localparam int BIT_PERIOD_NS = 1_000_000_000 / BAUD_RATE; // ~8680 ns

    // --- Signals ---
    logic clk = 0;
    logic rst;
    logic tick_16x;
    
    // DUT Interface
    logic tx_dv;
    logic [7:0] tx_byte;
    logic tx_active;
    logic tx_serial;
    logic tx_done;

    // Scoreboard Variables
    byte captured_data; // Data decoded by the testbench
    
    // --- Instantiations ---
    
    // 1. Baud Rate Generator (Required to drive the TX)
    baud_rate_generator #(.CLOCK_RATE(CLOCK_RATE), .BAUD_RATE(BAUD_RATE)) 
    u_baud_gen (
        .clk(clk), .rst(rst), .tick_16x(tick_16x)
    );

    // 2. DUT (Transmitter)
    uart_tx dut (
        .clk(clk), 
        .rst(rst), 
        .tick_16x(tick_16x),
        .tx_dv(tx_dv), 
        .tx_byte(tx_byte),
        .tx_active(tx_active), 
        .tx_serial(tx_serial), 
        .tx_done(tx_done)
    );

    // Clock
    always #4 clk <= ~clk;

    // --- Tasks ---

    // Task to mimic a UART Receiver (The Testbench "reads" the wire)
    task automatic sample_uart_output(output byte data_out);
        begin
            // 1. Wait for Start Bit (Falling Edge)
            wait(tx_serial == 0);
            
            // 2. Wait to reach the center of the Start Bit
            // + center of the first data bit
            #(BIT_PERIOD_NS + (BIT_PERIOD_NS / 2));

            // 3. Sample 8 Data Bits
            for (int i=0; i<8; i++) begin
                data_out[i] = tx_serial;
                #(BIT_PERIOD_NS); // Wait one bit duration
            end

            // 4. Verify Stop Bit
            if (tx_serial !== 1) 
                $warning("[MONITOR] Stop bit missing or malformed!");
        end
    endtask


    // --- Main Test Process ---
    initial begin
        $display("\n==============================================");
        $display("   TESTBENCH: UART Transmitter");
        $display("==============================================\n");

        // Init
        rst = 1; tx_dv = 0; tx_byte = 0;
        #100 rst = 0;
        #1000;

        // Loop for Random Testing
        repeat(10) begin
            byte data_to_send;
            byte data_received;
            
            // 1. Randomize Data
            void'(std::randomize(data_to_send));

            $display("[TEST] Driving Byte: 0x%h", data_to_send);

            // 2. Launch Parallel Threads (Fork/Join)
            fork
                // Thread A: Drive the DUT
                begin
                    @(posedge clk);
                    tx_byte <= data_to_send;
                    tx_dv   <= 1;
                    @(posedge clk);
                    tx_dv   <= 0;
                    
                    // Wait for DUT to finish
                    wait(tx_done == 1); 
                end

                // Thread B: Monitor the Serial Line
                begin
                    sample_uart_output(data_received);
                end
            join

            // 3. Compare Results (Self-Checking)
            assert (data_to_send == data_received)
                $display("[PASS] Sent: 0x%h | Recv: 0x%h", data_to_send, data_received);
            else
                $error("[FAIL] Sent: 0x%h | Recv: 0x%h", data_to_send, data_received);

            // Small delay between transfers
            #2000;
        end

        // Idle Line Check
        #100;
        assert (tx_serial == 1) else $error("TX Line is not IDLE (High)!");

        $display("\n==============================================");
        $display("   ALL TESTS COMPLETED");
        $display("==============================================\n");
        $finish;
    end
endmodule
