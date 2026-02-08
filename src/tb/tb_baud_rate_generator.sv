`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.01.2026 16:43:00
// Design Name: 
// Module Name: tb_baud_rate_generator
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


module tb_baud_rate_generator;

    // === 1. Parameters & Types ===
    localparam int CLOCK_RATE = 125_000_000;
    localparam int BAUD_RATE  = 115_200;
    
    // Theoretical period of the 16x tick in nanoseconds
    // 1 / (115200 * 16) = ~542.5 ns
    localparam real EXPECTED_PERIOD_NS = 1_000_000_000.0 / (BAUD_RATE * 16.0);
    localparam real TOLERANCE_PERCENT  = 2.0; // Allow 2% deviation due to integer division

    // 'logic' type for signals
    logic clk = 0;
    logic rst;
    logic tick_16x;

    // === 2. DUT Instance ===
    baud_rate_generator #(
        .CLOCK_RATE(CLOCK_RATE),
        .BAUD_RATE(BAUD_RATE)
    ) dut (.*); // Implicit connection

    // === 3. Clock Generation ===
    always #4 clk <= ~clk; // 125 MHz

    // === 4. Assertions (Concurrent Checks) ===
    
    // Property: When Reset is active, tick_16x must remain 0
    property ResetCheck;
        @(posedge clk) rst |=> (tick_16x == 0);
    endproperty

    assert property (ResetCheck) 
        else $error("[ASSERTION FAIL] tick_16x did not clear after Sync Reset!");


    // === 5. Main Test Sequence ===
    initial begin
        realtime t_last = 0;
        realtime t_now = 0;
        realtime t_diff = 0;
        real error_pct = 0;
        
        $display("\n==============================================");
        $display("   TESTBENCH: Baud Rate Generator");
        $display("   Target Baud: %0d | Target Tick Period: %0.3f ns", BAUD_RATE, EXPECTED_PERIOD_NS);
        $display("==============================================\n");

        // 1. Initialization
        rst = 1;
        #100;
        rst = 0;
        $display("[INFO] Reset released. Waiting for ticks...");

        // 2. Synchronization
        // Wait for the first tick to establish a baseline
        @(posedge tick_16x);
        t_last = $realtime; 

        // 3. Measurement Loop
        // We verify the next 20 ticks
        repeat(20) begin
            @(posedge tick_16x);
            t_now = $realtime;
            t_diff = t_now - t_last;
            
            // Calculate Error Percentage
            error_pct = ((t_diff - EXPECTED_PERIOD_NS) / EXPECTED_PERIOD_NS) * 100.0;
            if (error_pct < 0) error_pct = -error_pct; // Abs value

            $display("[MEASURE] Tick Interval: %0.3f ns | Error: %0.2f%%", t_diff, error_pct);

            // Immediate Assertion for Timing
            assert (error_pct < TOLERANCE_PERCENT) 
                else $error("[TIMING FAIL] Error exceeds tolerance! Expected: %0.3f, Got: %0.3f", EXPECTED_PERIOD_NS, t_diff);

            t_last = t_now;
        end

        // 4. Reset Test
        $display("\n[INFO] Testing Reset Behavior...");
        rst = 1;
        #500;
        // The Concurrent Assertion (ResetCheck) above is automatically checking this during the wait.
        
        rst = 0;
        @(posedge tick_16x); // Wait for recovery
        $display("[INFO] Recovery successful.");

        $display("\n==============================================");
        $display("   SIMULATION SUCCESSFUL");
        $display("==============================================\n");
        $finish;
    end 
endmodule
