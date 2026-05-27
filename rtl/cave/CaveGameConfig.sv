// Hand-maintained copy of the legacy Chisel GameConfig.scala values.
// Keep this aligned while retiring the Chisel-generated Cave.sv internals.
module CaveGameConfig (
  input      [3:0]  game_index,
  output reg [31:0] eeprom_offset,
  output reg [1:0]  sound_0_device,
  output reg [31:0] sound_0_rom_offset,
  output reg [31:0] sound_1_rom_offset,
  output reg [2:0]  layer_0_format,
  output reg [31:0] layer_0_rom_offset,
  output reg [1:0]  layer_0_palette_bank,
  output reg [8:0]  layer_0_granularity,
  output reg [2:0]  layer_1_format,
  output reg [31:0] layer_1_rom_offset,
  output reg [1:0]  layer_1_palette_bank,
  output reg [8:0]  layer_1_granularity,
  output reg [2:0]  layer_2_format,
  output reg [31:0] layer_2_rom_offset,
  output reg [1:0]  layer_2_palette_bank,
  output reg [8:0]  layer_2_granularity,
  output reg        layer_2_tile_bank_enable,
  output reg [2:0]  sprite_format,
  output reg [31:0] sprite_rom_offset,
  output reg [31:0] sprite_rom_size,
  output reg [2:0]  sprite_descramble_style,
  output reg [8:0]  sprite_granularity,
  output reg        sprite_zoom
);
  reg [8:0] granularity;
  localparam [3:0] GAME_DFEVERON = 4'h0;
  localparam [3:0] GAME_DDONPACH = 4'h1;
  localparam [3:0] GAME_DONPACHI = 4'h2;
  localparam [3:0] GAME_ESPRADE  = 4'h3;
  localparam [3:0] GAME_UOPOKO   = 4'h4;
  localparam [3:0] GAME_GUWANGE  = 4'h5;
  localparam [3:0] GAME_GAIA     = 4'h6;
  localparam [3:0] GAME_HOTDOGST = 4'h7;
  localparam [3:0] GAME_MAZINGER = 4'h8;
  localparam [3:0] GAME_AGALLET  = 4'h9;

  localparam [2:0] GFX_FORMAT_UNKNOWN  = 3'h0;
  localparam [2:0] GFX_FORMAT_4BPP     = 3'h1;
  localparam [2:0] GFX_FORMAT_4BPP_MSB = 3'h2;
  localparam [2:0] GFX_FORMAT_8BPP     = 3'h3;
  localparam [2:0] GFX_FORMAT_6BPP2    = 3'h4;
  localparam [2:0] GFX_FORMAT_6BPP     = 3'h5;

  localparam [1:0] SOUND_DEVICE_DISABLED = 2'h0;
  localparam [1:0] SOUND_DEVICE_YMZ280B  = 2'h1;
  localparam [1:0] SOUND_DEVICE_OKIM6259 = 2'h2;
  localparam [1:0] SOUND_DEVICE_Z80      = 2'h3;

  always @* begin
    granularity          = 9'h010;
    eeprom_offset       = 32'h0010_0000;
    sound_0_device      = SOUND_DEVICE_YMZ280B;
    sound_0_rom_offset  = 32'h0010_0080;
    sound_1_rom_offset  = 32'h0000_0000;
    layer_0_format      = GFX_FORMAT_4BPP;
    layer_0_rom_offset  = 32'h0050_0080;
    layer_0_palette_bank = 2'h1;
    layer_1_format      = GFX_FORMAT_4BPP;
    layer_1_rom_offset  = 32'h0070_0080;
    layer_1_palette_bank = 2'h1;
    layer_2_format      = GFX_FORMAT_UNKNOWN;
    layer_2_rom_offset  = 32'h0000_0000;
    layer_2_palette_bank = 2'h0;
    layer_2_tile_bank_enable = 1'b0;
    sprite_format       = GFX_FORMAT_4BPP;
    sprite_rom_offset   = 32'h0090_0080;
    sprite_rom_size     = 32'h0040_0000;
    sprite_descramble_style = 3'h0;
    sprite_zoom         = 1'b1;

    case (game_index)
      GAME_DFEVERON: begin
      end

      GAME_DDONPACH: begin
        granularity          = 9'h100;
        eeprom_offset       = 32'h0010_0000;
        sound_0_device      = SOUND_DEVICE_YMZ280B;
        sound_0_rom_offset  = 32'h0010_0080;
        sound_1_rom_offset  = 32'h0000_0000;
        layer_0_format      = GFX_FORMAT_4BPP;
        layer_0_rom_offset  = 32'h0050_0080;
        layer_0_palette_bank = 2'h1;
        layer_1_format      = GFX_FORMAT_4BPP;
        layer_1_rom_offset  = 32'h0070_0080;
        layer_1_palette_bank = 2'h1;
        layer_2_format      = GFX_FORMAT_8BPP;
        layer_2_rom_offset  = 32'h0090_0080;
        layer_2_palette_bank = 2'h1;
        sprite_format       = GFX_FORMAT_4BPP_MSB;
        sprite_rom_offset   = 32'h00b0_0080;
        sprite_zoom         = 1'b0;
      end

      GAME_DONPACHI: begin
        granularity          = 9'h010;
        eeprom_offset       = 32'h0008_0000;
        sound_0_device      = SOUND_DEVICE_OKIM6259;
        sound_0_rom_offset  = 32'h0008_0080;
        sound_1_rom_offset  = 32'h0028_0080;
        layer_0_format      = GFX_FORMAT_4BPP;
        layer_0_rom_offset  = 32'h0038_0080;
        layer_0_palette_bank = 2'h1;
        layer_1_format      = GFX_FORMAT_4BPP;
        layer_1_rom_offset  = 32'h0048_0080;
        layer_1_palette_bank = 2'h1;
        layer_2_format      = GFX_FORMAT_4BPP;
        layer_2_rom_offset  = 32'h0058_0080;
        layer_2_palette_bank = 2'h1;
        sprite_format       = GFX_FORMAT_4BPP_MSB;
        sprite_rom_offset   = 32'h005c_0080;
        sprite_zoom         = 1'b0;
      end

      GAME_ESPRADE: begin
        granularity          = 9'h100;
        eeprom_offset       = 32'h0010_0000;
        sound_0_device      = SOUND_DEVICE_YMZ280B;
        sound_0_rom_offset  = 32'h0010_0080;
        sound_1_rom_offset  = 32'h0000_0000;
        layer_0_format      = GFX_FORMAT_8BPP;
        layer_0_rom_offset  = 32'h0050_0080;
        layer_0_palette_bank = 2'h1;
        layer_1_format      = GFX_FORMAT_8BPP;
        layer_1_rom_offset  = 32'h00d0_0080;
        layer_1_palette_bank = 2'h1;
        layer_2_format      = GFX_FORMAT_8BPP;
        layer_2_rom_offset  = 32'h0150_0080;
        layer_2_palette_bank = 2'h1;
        sprite_format       = GFX_FORMAT_8BPP;
        sprite_rom_offset   = 32'h0190_0080;
        sprite_rom_size     = 32'h0100_0000;
        sprite_zoom         = 1'b1;
      end

      GAME_UOPOKO: begin
        granularity          = 9'h100;
        eeprom_offset       = 32'h0010_0000;
        sound_0_device      = SOUND_DEVICE_YMZ280B;
        sound_0_rom_offset  = 32'h0010_0080;
        sound_1_rom_offset  = 32'h0000_0000;
        layer_0_format      = GFX_FORMAT_8BPP;
        layer_0_rom_offset  = 32'h0030_0080;
        layer_0_palette_bank = 2'h1;
        layer_1_format      = GFX_FORMAT_UNKNOWN;
        layer_1_rom_offset  = 32'h0000_0000;
        layer_1_palette_bank = 2'h0;
        layer_2_format      = GFX_FORMAT_UNKNOWN;
        layer_2_rom_offset  = 32'h0000_0000;
        layer_2_palette_bank = 2'h0;
        sprite_format       = GFX_FORMAT_4BPP;
        sprite_rom_offset   = 32'h0070_0080;
        sprite_zoom         = 1'b1;
      end

      GAME_GUWANGE: begin
        granularity          = 9'h100;
        eeprom_offset       = 32'h0010_0000;
        sound_0_device      = SOUND_DEVICE_YMZ280B;
        sound_0_rom_offset  = 32'h0010_0080;
        sound_1_rom_offset  = 32'h0000_0000;
        layer_0_format      = GFX_FORMAT_8BPP;
        layer_0_rom_offset  = 32'h0050_0080;
        layer_0_palette_bank = 2'h1;
        layer_1_format      = GFX_FORMAT_8BPP;
        layer_1_rom_offset  = 32'h00d0_0080;
        layer_1_palette_bank = 2'h1;
        layer_2_format      = GFX_FORMAT_8BPP;
        layer_2_rom_offset  = 32'h0110_0080;
        layer_2_palette_bank = 2'h1;
        sprite_format       = GFX_FORMAT_8BPP;
        sprite_rom_offset   = 32'h0150_0080;
        sprite_zoom         = 1'b1;
      end

      GAME_GAIA: begin
        granularity          = 9'h100;
        eeprom_offset       = 32'h0000_0000;
        sound_0_device      = SOUND_DEVICE_YMZ280B;
        sound_0_rom_offset  = 32'h0010_0000;
        sound_1_rom_offset  = 32'h0000_0000;
        layer_0_format      = GFX_FORMAT_8BPP;
        layer_0_rom_offset  = 32'h00d0_0000;
        layer_0_palette_bank = 2'h1;
        layer_1_format      = GFX_FORMAT_8BPP;
        layer_1_rom_offset  = 32'h0110_0000;
        layer_1_palette_bank = 2'h1;
        layer_2_format      = GFX_FORMAT_8BPP;
        layer_2_rom_offset  = 32'h0150_0000;
        layer_2_palette_bank = 2'h1;
        sprite_format       = GFX_FORMAT_4BPP;
        sprite_rom_offset   = 32'h0190_0000;
        sprite_zoom         = 1'b1;
      end

      GAME_HOTDOGST: begin
        granularity          = 9'h010;
        eeprom_offset       = 32'h0010_0000;
        sound_0_device      = SOUND_DEVICE_Z80;
        sound_0_rom_offset  = 32'h0010_0080;
        sound_1_rom_offset  = 32'h0014_0080;
        layer_0_format      = GFX_FORMAT_4BPP;
        layer_0_rom_offset  = 32'h001c_0080;
        layer_0_palette_bank = 2'h0;
        layer_1_format      = GFX_FORMAT_4BPP;
        layer_1_rom_offset  = 32'h0024_0080;
        layer_1_palette_bank = 2'h0;
        layer_2_format      = GFX_FORMAT_4BPP;
        layer_2_rom_offset  = 32'h002c_0080;
        layer_2_palette_bank = 2'h0;
        sprite_format       = GFX_FORMAT_4BPP;
        sprite_rom_offset   = 32'h0034_0080;
        sprite_zoom         = 1'b1;
      end

      GAME_MAZINGER: begin
        granularity          = 9'h010;
        eeprom_offset       = 32'h0010_0000;
        sound_0_device      = SOUND_DEVICE_Z80;
        sound_0_rom_offset  = 32'h0010_0080;
        sound_1_rom_offset  = 32'h0012_0080;
        layer_0_format      = GFX_FORMAT_4BPP;
        layer_0_rom_offset  = 32'h001a_0080;
        layer_0_palette_bank = 2'h0;
        layer_1_format      = GFX_FORMAT_6BPP;
        layer_1_rom_offset  = 32'h003a_0080;
        layer_1_palette_bank = 2'h1;
        layer_2_format      = GFX_FORMAT_UNKNOWN;
        layer_2_rom_offset  = 32'h0000_0000;
        layer_2_palette_bank = 2'h0;
        sprite_format       = GFX_FORMAT_4BPP;
        sprite_rom_offset   = 32'h005a_0080;
        sprite_zoom         = 1'b1;
      end

      GAME_AGALLET: begin
        granularity          = 9'h010;
        eeprom_offset       = 32'h0008_0000;
        sound_0_device      = SOUND_DEVICE_Z80;
        sound_0_rom_offset  = 32'h0008_0080;
        sound_1_rom_offset  = 32'h0010_0080;
        layer_0_format      = GFX_FORMAT_4BPP;
        layer_0_rom_offset  = 32'h0050_0080;
        layer_0_palette_bank = 2'h1;
        layer_1_format      = GFX_FORMAT_4BPP;
        layer_1_rom_offset  = 32'h0070_0080;
        layer_1_palette_bank = 2'h2;
        layer_2_format      = GFX_FORMAT_6BPP2;
        layer_2_rom_offset  = 32'h0090_0080;
        layer_2_palette_bank = 2'h3;
        layer_2_tile_bank_enable = 1'b1;
        sprite_format       = GFX_FORMAT_4BPP;
        sprite_rom_offset   = 32'h00d0_0080;
        sprite_rom_size     = 32'h0040_0000;
        sprite_descramble_style = 3'h0;
        sprite_zoom         = 1'b1;
      end

      default: begin
      end
    endcase

    layer_0_granularity = granularity;
    layer_1_granularity = granularity;
    layer_2_granularity = granularity;
    sprite_granularity  = granularity;

    if (game_index == GAME_AGALLET)
      layer_2_granularity = 9'h040;
  end
endmodule
