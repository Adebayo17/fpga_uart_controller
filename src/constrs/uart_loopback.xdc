## 1. Clock Signal
set_property -dict { PACKAGE_PIN H16    IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L13P_T2_MRCC_35 Sch=SYSCLK
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];#set


## 2. Reset Button (BTN0)
set_property -dict { PACKAGE_PIN D19    IOSTANDARD LVCMOS33 } [get_ports { btn_rst }]; #IO_L4P_T0_35 Sch=BTN0


## 3. UART Interface (mapped on PMOD JA)
# FPGA RX (Input) -> JA Pin 1 (Y18)
# Connected to ESP32 TX
set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { usb_uart_rx }]; #IO_L17P_T2_34 Sch=JA1_P (Pin 1)

# FPGA TX (Output) -> JA Pin 2 (Y19)
# Connected to ESP32 RX
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { usb_uart_tx }]; #IO_L17N_T2_34 Sch=JA1_N (Pin 2)


## 4. Debug LEDs
# LED0 On: Receive data (rx_dv) 
# LED1 On: Transmit Data (tx_active)
set_property -dict { PACKAGE_PIN R14    IOSTANDARD LVCMOS33 } [get_ports { led_rx_active }]; #IO_L6N_T0_VREF_34 Sch=LED0
set_property -dict { PACKAGE_PIN P14    IOSTANDARD LVCMOS33 } [get_ports { led_tx_active }]; #IO_L6P_T0_34 Sch=LED1