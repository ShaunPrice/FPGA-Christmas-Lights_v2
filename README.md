# FPGA-Christmas-Lights_v2
Streams to multiple ws2811 pixel strings from a stream of pixel data in the dollowing format:
<pre><code>
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

The current configuration streams 24 universes or 512 pixels.

The example code for streaming the pixel code into the FPGA from an ESP32 or Teensy 3.5 reading the Xlights fseq file over SPI is in the following repository:

[SD_Reader](https://www.github.com/ShaunPrice/SD_Reader/)

