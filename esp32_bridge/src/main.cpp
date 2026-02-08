#include <Arduino.h>

/*
 * PROJECT: FPGA UART BRIDGE
 * Role: Transparent Bridge between PC (USB) and FPGA (UART)
 * Platform: ESP32-S3 (Freenove / DevKitC)
 */


// --- PIN CONFIGURATION ---
// Reminder: TX ESP32 -> RX FPGA | RX ESP32 -> TX FPGA
#define PIN_ESP_TX 1
#define PIN_ESP_RX 2

#define UART_BAUD_RATE 115200

// We use HardwareSeril number 1 for communication with FPGA, as Serial (number 0) is used for USB communication with PC
HardwareSerial SerialFPGA(1);

void setup() {
  // 1. Init USB Serial for communication with PC
  Serial.begin(UART_BAUD_RATE);

  // Optional wait for Serial to be ready (useful for native USB)
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB
  }

  delay(2000);

  // 2. Init UART Serial for communication with FPGA
  // config: SERIAL_8N1 for default 8 data bits, no parity, 1 stop bit
  SerialFPGA.begin(UART_BAUD_RATE, SERIAL_8N1, PIN_ESP_RX, PIN_ESP_TX);

  Serial.println("\n=== FPGA UART BRIDGE STARTED ===");
  Serial.printf("Bridge Configured on Pins: TX=%d, RX=%d\n", PIN_ESP_TX, PIN_ESP_RX);
  Serial.println("Ready to relay data...");

}

void loop() {
  // SENS 1 : PC -> FPGA
  if (Serial.available())
  {
    char dataFromPC = Serial.read();
    Serial.printf("\nReceived from PC: 0x%02X ('%c')\n", dataFromPC, isprint(dataFromPC) ? dataFromPC : '.');
    SerialFPGA.write(dataFromPC); // Relay to FPGA
  }
  
  // SENS 2 : FPGA -> PC
  if (SerialFPGA.available())
  {
    char dataFromFPGA = SerialFPGA.read();
    Serial.printf("\nReceived from FPGA: 0x%02X ('%c')\n", dataFromFPGA, isprint(dataFromFPGA) ? dataFromFPGA : '.');
    Serial.write(dataFromFPGA); // Relay to PC
  }
}

