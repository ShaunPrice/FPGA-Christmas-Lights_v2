# FPGA-Christmas-Lights_v2

Note: This project is based on a retired product https://alchitry.com/products/mojo-v3 the Mojo FPGA. This development board may be available from third parties or the code could be modified for other FPGA's.

The project displays up to 24 ws2812b/ws2811 pixels universes with 512 pixels per universe or 12,288 pixels.

The example code for streaming the pixel code into the FPGA from an ESP32 or Teensy 3.5 reading the Xlights fseq file over SPI is in the following repository:

[SD_Reader](https://www.github.com/ShaunPrice/SD_Reader/) << Requires update for new format.

## Format for a Universe
Streams to multiple ws2811 pixel strings from a stream of pixel data in the dollowing format:<pre><code>
 byte[0] Universe (0 o 23)
 byte[1] Pixels (0 o 511)
 byte[2] RED index (0,1,2)    // Used to order RGB
 byte[3] GREEN index (0,1,2)  // Used to order RGB
 byte[4] BLUE index (0,1,2)   // Used to order RGB
 byte[5 t0 7] Pixel 1 RGB
 byte[8 to 10] Pixel 2 RGB
 ...
 byte[1541 to 1543] Pixel 512 RGB
</code></pre>

## Pinout
The pinout for the Mojo V3 FPGA is as follows:<pre><code>
Universe 1 = 35
Universe 2 = 34
Universe 3 = 33
Universe 4 = 32
Universe 5 = 30
Universe 6 = 29
Universe 7 = 27
Universe 8 = 26
Universe 9 = 24
Universe 10 = 23
Universe 11 = 22
Universe 12 = 21
Universe 13 = 17
Universe 14 = 16
Universe 15 = 15
Universe 16 = 14
Universe 17 = 93
Universe 18 = 92
Universe 19 = 88
Universe 20 = 87
Universe 21 = 85
Universe 22 = 84
Universe 23 = 83
Universe 24 = 82

SPI hs = 58
SPI cs = 57
SPI mosi = 67
SPI miso = 66
SPI sck = 74
</code></pre>
