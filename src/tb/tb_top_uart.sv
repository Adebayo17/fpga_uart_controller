`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.02.2026 17:30:04
// Design Name: 
// Module Name: tb_top_uart
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


module tb_top_uart;

    // --- 1. PARAMETERS ---
    localparam int CLOCK_RATE       = 125_000_000;
    localparam int BAUD_RATE        = 115_200;
    localparam int BIT_PERIOD_NS    = 1_000_000_000 / BAUD_RATE;
    
    // --- 2. SIGNALS ---
    logic clk = 0;
    logic rst;
    logic led_rx_active;
    logic led_tx_active;
    
    // Signals seen from the PC side (Testbench)
    logic pc_tx_line; // What the TB sends (connected to rx of the FPGA)
    logic pc_rx_line; // What the TB receives (connected to the FPGA's tx)

    // Testbench variables
    byte data_sent;
    byte data_received;
    int error_count = 0;

    // --- 3. TOP LEVEL INSTANCIATION ---
    top_uart dut (
        .clk(clk),
        .btn_rst(rst),
        .usb_uart_rx(pc_tx_line),   // The PC communicates via the FPGA's RX input.
        .usb_uart_tx(pc_rx_line),   // The PC listens to the TX from the FPGA
        .led_rx_active(led_rx_active),
        .led_tx_active(led_tx_active)
    );

    // Clock Generation
    always #4 clk <= ~clk;

    // --- 4. LOW-LEVEL TASKS (PHY LAYER) ---

    // Task: Simulate sending a byte from the PC
    task automatic pc_send_byte(input byte data);
        begin
            // Start Bit
            pc_tx_line <= 0;
            #(BIT_PERIOD_NS);
            
            // Data Bits
            for (int i=0; i<8; i++) begin
                pc_tx_line <= data[i];
                #(BIT_PERIOD_NS);
            end
            
            // Stop Bit
            pc_tx_line <= 1;
            #(BIT_PERIOD_NS);
        end
    endtask

    // Task: Simulate reception and decoding by the PC
    task automatic pc_receive_byte(output byte data);
        begin
            // Waiting for the Start Bit (Falling Edge)
            wait(pc_rx_line == 0);
            
            repeat(2) @(posedge clk); 
            assert (led_tx_active == 1) 
                else $error("[ASSERT FAIL] TX LED should be ON during transmission!");
            
            // We position ourselves in the middle of the first data bit
            // (1.5 periods: 1 for the Start, 0.5 to reach the middle of bit 0)
            #(BIT_PERIOD_NS + (BIT_PERIOD_NS / 2));
            
            // 8-bit sampling
            for (int i=0; i<8; i++) begin
                data[i] = pc_rx_line;
                #(BIT_PERIOD_NS);
            end
            
            // Summary check of the Stop Bit 
            // At this point, we should be in the middle of the stop bit
            if (pc_rx_line !== 1) $warning("Stop bit suspect !");
        end
    endtask

    // --- 5. TEST SCENARIO (MAIN) ---
    initial begin
        $display("\n==============================================");
        $display("   TESTBENCH: Top Level UART Loopback");
        $display("==============================================\n");

        // Init
        rst = 1; pc_tx_line = 1; // Idle High
        #200 rst = 0;
        #1000;

        $display("[INFO] System Reset Released. Starting Loopback Test...");

        // Test boucle (10 iterations)
        repeat(10) begin
            
            // 1. Generate random data
            void'(std::randomize(data_sent));
            
            // 2. Launch Sending and Receiving in PARALLEL
            fork
                // Processus A : PC sends
                begin
                    $display("[PC TX] Sending 0x%h...", data_sent);
                    pc_send_byte(data_sent);
                    
                    repeat(5) @(posedge clk);
                    
                    assert (led_rx_active == 1) 
                        else $error("[ASSERT FAIL] RX LED did not light up after reception!");
                end

                // Processus B : PC listens (with a timeout to prevent it from crashing if it freezes)
                begin
                    fork 
                        begin
                            pc_receive_byte(data_received);
                        end
                        begin
                            // // Safety timeout (e.g., time of 3 full frames)
                            #(BIT_PERIOD_NS * 30);
                            $error("[TIMEOUT] Pas de reponse du FPGA !");
                            data_received = 8'hXX; // Force error
                        end
                    join_any // The first one to finish kills the other
                    disable fork;
                end
            join // Wait until both sending AND receiving are complete.

            // 3. Comparison (Scoreboard Check)
            if (data_received === data_sent) begin
                $display("[PC RX] Success! Received 0x%h", data_received);
            end else begin
                $display("[PC RX] ERROR! Sent 0x%h, Got 0x%h", data_sent, data_received);
                error_count++;
            end
            
            // Check LEDs are ON (double check)
            if (led_rx_active && led_tx_active)
                $display("[LEDS] Visual feedback confirmed ON.");
            else 
                $warning("[LEDS] One or both LEDs are OFF!");

            // A short break between packages
            #(BIT_PERIOD_NS * 2);
        end

        // Final Result
        if (error_count == 0)
             $display("\n--- [PASSED] SYSTEM LOOPBACK FUNCTIONAL ---\n");
        else
             $display("\n--- [FAILED] %0d ERRORS DETECTED ---\n", error_count);
        
        $finish;
    end

endmodule
