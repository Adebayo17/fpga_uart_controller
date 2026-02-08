`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.01.2026 15:56:43
// Design Name: 
// Module Name: tb_uart_rx
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


module tb_uart_rx;

    // === 1. Parameters & Signals ===
    localparam int CLOCK_RATE = 125_000_000;
    localparam int BAUD_RATE  = 115_200;
    localparam int BIT_PERIOD = 1_000_000_000 / BAUD_RATE;
    
    logic clk = 0;
    logic rst;
    logic tick_16x;
    logic rx_serial;
    logic rx_dv;
    logic [7:0] rx_byte;
    
    // === 2. VERIFICATION STRUCTURE ===
    byte expected_q[$];
    
    int error_count = 0;
    int test_count  = 0;
    
    // === 3. INSTANCIATION === 
    baud_rate_generator #(
        .CLOCK_RATE(CLOCK_RATE),
        .BAUD_RATE(BAUD_RATE)
    ) u_baud_gen(.*);       // ".*" automatically connects signals with the same name!
    
    uart_rx dut(
        .clk        (clk),
        .rst        (rst),
        .tick_16x   (tick_16x),
        .rx_serial  (rx_serial),
        .rx_dv      (rx_dv),
        .rx_byte    (rx_byte)
    );
    
    // Clock Generation
    always #4 clk <= ~clk;
    
    
    // === 4. AUTOMATIC TASKS ===
    task automatic send_byte(input byte data);
        begin
            // We add the data to our waiting list for future verification
            expected_q.push_back(data);
            
            // Start bit '0'
            rx_serial <= 0;
            #(BIT_PERIOD);
            
            // Data bits (LSB first)
            for (int i=0; i<8; i++) begin 
                rx_serial <= data[i];
                #(BIT_PERIOD);
            end 
            
            // Stop Bit (1)
            rx_serial <= 1;
            #(BIT_PERIOD);
        end 
    endtask 
    
    // === 5. MONITORING PROCESS (CHECKER) ===
    // This block runs in parallel with the sending process. It's the "brain" that checks it.
    initial begin 
        byte observed_data;
        byte expected_data;
        
        forever begin 
            // We're waiting for the DUT to say, "I received something."
            @(posedge clk);
            if (rx_dv) begin
                observed_data = rx_byte;
                
                // We check what we are supposed to receive
                if (expected_q.size() == 0) begin 
                    $error("[MONITOR] Error: Receive %h but nothing is expected !", observed_data);
                    error_count++;
                end else begin 
                    expected_data = expected_q.pop_front(); // Taking the oldest
                    
                    // IMMEDIATE ASSERTION
                    assert (observed_data == expected_data)
                        else $error("[MONITOR] Mismatch! Expected: %h, Receive %h ", expected_data, observed_data);
                end 
            end 
        end 
    end 
    
    // === 6. MAIN SCENARIO ===
    initial begin 
        // Init
        rst = 1;
        rx_serial = 1;
        #100 rst = 0;
        #1000;
        
        $display("=== Starting UART_RX Tests ===");
        
        // A. Directed tests (Corner Cases)
        test_count++; $display("Test %0d: Limit (0x00, 0xFF)", test_count);
        send_byte(8'h00);
        #(BIT_PERIOD * 2);
        send_byte(8'hFF);
        #(BIT_PERIOD * 5);
        
        // B. Random Tests
        test_count++; $display("Test %0d: Random Burst (20 bytes)", test_count);
        
        repeat(20) begin 
            byte rand_val;
            void'(std::randomize(rand_val));
            
            send_byte(rand_val);
            // Note: We hardly pause at all, to test the maximum throughput!
        end 
        
        // We wait for the queue to empty (for the monitor to have checked everything).
        wait(expected_q.size() == 0);
        #5000;
        
        // C. Fault Injection (Glitch)
        test_count++; $display("Test %0d: Glitch Injection (Start bit too short)", test_count);
        rx_serial <= 0; // False start
        #(BIT_PERIOD / 4);
        rx_serial <= 1; // Return to normal
        #5000;
        
        // Final check with Assertion
        // The queue must be empty, otherwise data was missed
        assert (expected_q.size() == 0) 
            else $fatal(1, "CRITICAL ERROR: Sent data was never received!");

        if (error_count == 0) 
            $display("\n=== SUCCESS: ALL TESTS PASS ===\n");
        else 
            $display("\n=== FAILED: %0d ERRORS DETECTED ===\n", error_count);

        $finish;
        
    end 
endmodule
