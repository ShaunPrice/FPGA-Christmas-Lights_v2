# FPGA-Christmas-Lights_v2
Streams to multiple ws2811 pixel strings from a stream of pixel data in the xlights fseq format with a leading byte for the universe being sent:
<pre><code>
[universe][pixel1]...[pixelx]

where:
Universe = [1-byte universe (Zero based - 0 to 255)]
PIXEL    = [[1-byte Red][1-byte Green][1-byte Blue]]
</code></pre>

The current configuration streams 16 universes or 150 pixels.

The example code for streaming the pixel code into the FPGA from an ESP32 or Teensy 3.5 reading the Xlights fseq file over SPI is in the following repository:

[SD_Reader](https://www.github.com/ShaunPrice/SD_Reader/)

