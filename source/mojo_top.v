//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:39:36 07/29/2018 
// Design Name: 
// Module Name:    mojo_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mojo_top(
    // 50MHz clock input
    input  clk,
    // Input from reset button (active low)
    input  rst_n,
    // cclk input from AVR, high when AVR is ready
    input  cclk,
    // Outputs to the 8 onboard LEDs
    output[7:0] led,
    // AVR SPI connections
    output spi_miso,
    input  spi_ss,
    input  spi_mosi,
    input  spi_sck,
    // AVR ADC channel select
    output [3:0] spi_channel,
    // Serial connections
    input  avr_tx,      // AVR Tx => FPGA Rx
    output avr_rx,     // AVR Rx => FPGA Tx
    input  avr_rx_busy, // AVR Rx buffer full
   
    output [24:0] lights,
  
    // Lights Data SPI connections
    input  sender_cs,     // Lights SPI Chip Select
    input  sender_mosi,   // Lights SPI MOSO
    output sender_miso,   // Lights SPI MISO
    input  sender_sck,    // Lights SPI Clock
    output sender_done   // Lights SPI Done
);

localparam CLOCK = 50000000;
localparam UNIVERSES = 24;
localparam PIXEL_COUNT = 512;
// localparam LIGHTS_CLOCK = 20; // 20 Frames per second
localparam START = 0, HEADER_UNIVERSE = 1,HEADER_PIXELS = 2, HEADER_RED_INDEX = 3, HEADER_GREEN_INDEX = 4, HEADER_BLUE_INDEX = 5;
localparam RECEIVE = 6, COLOR1 = 7, COLOR2 = 8, COLOR3 = 9;

reg [7:0] pixels = PIXEL_COUNT;
reg [7:0] LIGHTS_CLOCK = 20; // 20 Frames per second
reg [7:0] redIndex = 0, greenIndex = 1, blueIndex = 2;  // Used for colour ordering (e.g. RGB=0,1,2; BGR=2,1,0; GRB=1,0,2 )

integer colour = COLOR1; // Used to keep track of the current colour from the SPI incomming data
wire rst = ~rst_n; // make reset active high

// These signals should be high-z when not used
assign spi_miso = 1'bz;
assign avr_rx = 1'bz;
assign spi_channel = 4'bzzzz;

reg [7:0] pixelRed_out   [UNIVERSES-1:0];
reg [7:0] pixelGreen_out [UNIVERSES-1:0];
reg [7:0] pixelBlue_out  [UNIVERSES-1:0];

wire pixelSending       [UNIVERSES-1:0];
wire pixelDataRequest   [UNIVERSES-1:0];
wire neopixel_out       [UNIVERSES-1:0];
wire [7:0] pixelAddress [UNIVERSES-1:0];

integer universe_out;

reg  sender_cs_reg;
wire sender_busy;
wire sender_new_data;
wire [7:0] sender_data_in;
wire [7:0] sender_data_out;
reg ready_to_display[UNIVERSES-1:0];

reg [2:0] state;     // Lights State
reg [2:0] spi_state = START; // SPI Receive State

// RGB Lights Data
reg  [7:0] universe;

integer data_index = 0;
reg [7:0] data_red  [UNIVERSES-1:0][PIXEL_COUNT-1:0];
reg [7:0] data_green  [UNIVERSES-1:0][PIXEL_COUNT-1:0];
reg [7:0] data_blue  [UNIVERSES-1:0][PIXEL_COUNT-1:0];

integer counter;
reg previousPixelSending;

assign led[0] = sender_mosi;
assign led[1] = sender_sck;
assign led[2] = ready_to_display[0];
assign led[3] = ready_to_display[1];
assign led[4] = ready_to_display[2];
assign led[5] = ready_to_display[3];
assign led[6] = ready_to_display[4];
assign led[7] = ready_to_display[5];

genvar index;  

generate
for (index=0; index < UNIVERSES; index=index+1)  
  begin: mappingArray
    assign lights[index] = neopixel_out[index];
  end
endgenerate

generate
for (index=0; index < UNIVERSES; index=index+1)  
  begin: neopixelArray
     ws2811 #(.NUM_PIXELS(PIXEL_COUNT),.SYSTEM_CLOCK(CLOCK)) myNeopixel  (
      .clk(clk),
      .reset(rst),
      .start(ready_to_display[index]),
      .sending(pixelSending[index]),
      .address(pixelAddress[index]),
      .red_in(pixelRed_out[index]),
      .green_in(pixelGreen_out[index]),
      .blue_in(pixelBlue_out[index]),
      .data_request(pixelDataRequest[index]),
      .DO(neopixel_out[index])
    );
  end  
endgenerate  

spi_peripheral  senderSPI (
    .clk(clk),
    .rst(rst),
    .cs(sender_cs),
    .sdo(sender_miso),
    .sdi(sender_mosi),
    .sck(sender_sck),
    .done(sender_done),
    .data_in(sender_data_in),
    .data_out(sender_data_out)
  );

// Data Format
// ============
// byte[0] Universe (0 o 23)
// byte[1] Pixels (0 o 511)
// byte[2] RED index (0,1,2)    // Used to order RGB
// byte[3] GREEN index (0,1,2)  // Used to order RGB
// byte[4] BLUE index (0,1,2)   // Used to order RGB
// byte[5 t0 7] Pixel 1 RGB
// byte[8 to 10] Pixel 2 RGB
// ...
// byte[770 to 772] Pixel 256 RGB

always @(posedge clk)
begin
  case (spi_state)
  START:  // Wait here to start
  begin
    data_index = 0;
    
    // Only request data if the slave has data to send.
    if (sender_cs == 1'b0)
    begin
      spi_state = HEADER_UNIVERSE;
    end
  end
  HEADER_UNIVERSE:
  begin
    if (sender_done == 1'b1)
    begin
      universe <= sender_data_out;
      spi_state = HEADER_PIXELS;
    end
  end
  HEADER_PIXELS:
  begin
    if (sender_done == 1'b1)
    begin
      pixels <= sender_data_out;
      spi_state = HEADER_RED_INDEX;
    end
  end
  HEADER_RED_INDEX:
  begin
    if (sender_done == 1'b1)
    begin
      redIndex <= sender_data_out;
      spi_state = HEADER_GREEN_INDEX;
    end
  end
  HEADER_GREEN_INDEX:
  begin
    if (sender_done == 1'b1)
    begin
      greenIndex <= sender_data_out;
      spi_state = HEADER_BLUE_INDEX;
    end
  end
  HEADER_BLUE_INDEX:
  begin
    if (sender_done == 1'b1)
    begin
      blueIndex <= sender_data_out;
      spi_state = RECEIVE;
    end
  end
  RECEIVE: // Receive data
  begin
    // Start LIGHTS when CS goes high
    if (sender_cs == 1'b1)
    begin
      spi_state = START;
    end
    else if (data_index == pixels)
    begin
      ready_to_display[universe] <= 1'b1;
      colour = COLOR1;  // Reset the colour
    end
    else
    begin
      case (colour)
      COLOR1:
      begin
        if (sender_done == 1'b1)
        begin
          if (redIndex == 0)
          begin
            data_red[universe][data_index] <= sender_data_out;
          end
          else if (greenIndex == 0)
          begin
            data_green[universe][data_index] <= sender_data_out;
          end
          else if (greenIndex == 0)
          begin
            data_blue[universe][data_index] <= sender_data_out;
          end
          colour = COLOR2;
          data_index = data_index + 1;
        end
      end
      COLOR2:
      begin
        if (sender_done == 1'b1)
        begin
          if (redIndex == 1)
          begin
            data_red[universe][data_index] <= sender_data_out;
          end
          else if (greenIndex == 1)
          begin
            data_green[universe][data_index] <= sender_data_out;
          end
          else if (greenIndex == 1)
          begin
            data_blue[universe][data_index] <= sender_data_out;
          end
          colour = COLOR3;
        end
      end      
      COLOR3:
      begin
        if (sender_done == 1'b1)
        begin
          if (redIndex == 2)
          begin
            data_red[universe][data_index] <= sender_data_out;
          end
          else if (greenIndex == 2)
          begin
            data_green[universe][data_index] <= sender_data_out;
          end
          else if (greenIndex == 2)
          begin
            data_blue[universe][data_index] <= sender_data_out;
          end
          colour = COLOR1;
        end
      end
      endcase
    end
  end
  endcase
  
  // Transmit the Code
  for (universe_out = 0; universe_out < UNIVERSES; universe_out = universe_out + 1)
  begin 
    // Are we ready for the next pixel?
    if (pixelDataRequest[universe_out] == 1'b1)
    begin
        // Reset the ready to display flag
        ready_to_display[universe_out] <= 1'b0;  

                // Display the pixels
        pixelRed_out [universe_out] <= data_red [universe_out][pixelAddress[universe_out]];
        pixelGreen_out [universe_out] <= data_green [universe_out][pixelAddress[universe_out]];
        pixelBlue_out [universe_out] <= data_blue [universe_out][pixelAddress[universe_out]];
      end
    end
end

endmodule