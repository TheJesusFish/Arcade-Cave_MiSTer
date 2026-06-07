// Air Gallet/Sailor Moon layer 2 stores 6bpp tiles as a 4bpp page plus a
// separately packed 2bpp page. Rebuild one renderer-friendly 8-byte row.
module AirGalletLayer2TileRomAdapter(
  input         clock,
  input         reset,
  input         game_active,
  input         sailormoon_mode,
  input         io_in_rd,
  input  [31:0] io_in_addr,
  output [63:0] io_in_dout,
  output        io_in_wait_n,
  output        io_in_valid,
  output        io_cache_rd,
  output [31:0] io_cache_addr,
  input  [63:0] io_cache_dout,
  input         io_cache_wait_n,
  input         io_cache_valid
);
  localparam [2:0] STATE_IDLE       = 3'd0;
  localparam [2:0] STATE_START_LOW  = 3'd1;
  localparam [2:0] STATE_WAIT_LOW   = 3'd2;
  localparam [2:0] STATE_START_HIGH = 3'd3;
  localparam [2:0] STATE_WAIT_HIGH  = 3'd4;

  // Air Gallet stores 2 MiB of low 4bpp data followed by 1 MiB of packed
  // high-plane source. Sailor Moon uses the same idea at a larger scale:
  // 10 MiB low data followed by 5 MiB packed high-plane source.
  localparam [31:0] AIR_LAYER2_HIGH_RAW_BASE = 32'h0020_0000;
  localparam [31:0] SAILOR_LAYER2_HIGH_RAW_BASE = 32'h00a0_0000;

  reg [2:0]  stateReg;
  reg [31:0] requestAddrReg;
  reg [63:0] lowDataReg;
  reg [63:0] doutReg;
  reg        validReg;

  wire [31:0] splitLowAddr = {1'b0, requestAddrReg[31:1]};
  wire [31:0] splitHighRawAddr =
    (sailormoon_mode ? SAILOR_LAYER2_HIGH_RAW_BASE : AIR_LAYER2_HIGH_RAW_BASE) +
    {2'b00, requestAddrReg[31:2]};

  wire [31:0] lowRow =
    splitLowAddr[2] ? lowDataReg[31:0] : lowDataReg[63:32];

  function [7:0] select_byte;
    input [63:0] data;
    input [2:0]  index;
    begin
      case (index)
        3'd0: select_byte = data[63:56];
        3'd1: select_byte = data[55:48];
        3'd2: select_byte = data[47:40];
        3'd3: select_byte = data[39:32];
        3'd4: select_byte = data[31:24];
        3'd5: select_byte = data[23:16];
        3'd6: select_byte = data[15:8];
        default: select_byte = data[7:0];
      endcase
    end
  endfunction

  function [7:0] unpack_high_pair_a;
    input [7:0] data;
    begin
      unpack_high_pair_a = ((data & 8'h03) << 6) | (data & 8'h0c);
    end
  endfunction

  function [7:0] unpack_high_pair_b;
    input [7:0] data;
    begin
      unpack_high_pair_b = ((data & 8'h30) << 2) | ((data & 8'hc0) >> 4);
    end
  endfunction

  wire [2:0] highRawOffset = splitHighRawAddr[2:0];
  wire [7:0] highRaw0 = select_byte(io_cache_dout, highRawOffset);
  wire [7:0] highRaw1 = select_byte(io_cache_dout, highRawOffset + 3'd1);
  wire [7:0] highByte0 = unpack_high_pair_a(highRaw0);
  wire [7:0] highByte1 = unpack_high_pair_b(highRaw0);
  wire [7:0] highByte2 = unpack_high_pair_a(highRaw1);
  wire [7:0] highByte3 = unpack_high_pair_b(highRaw1);

  wire [63:0] splitDout = {
    2'b00, highByte0[7:6], lowRow[31:28],
    2'b00, highByte0[3:2], lowRow[27:24],
    2'b00, highByte1[7:6], lowRow[23:20],
    2'b00, highByte1[3:2], lowRow[19:16],
    2'b00, highByte2[7:6], lowRow[15:12],
    2'b00, highByte2[3:2], lowRow[11:8],
    2'b00, highByte3[7:6], lowRow[7:4],
    2'b00, highByte3[3:2], lowRow[3:0]
  };

  wire normalMode = ~game_active;
  wire startRequest = game_active & io_in_rd & io_in_wait_n;

  always @(posedge clock) begin
    if (reset) begin
      stateReg <= STATE_IDLE;
      requestAddrReg <= 32'h0000_0000;
      lowDataReg <= 64'h0000_0000_0000_0000;
      doutReg <= 64'h0000_0000_0000_0000;
      validReg <= 1'b0;
    end
    else begin
      validReg <= 1'b0;

      case (stateReg)
        STATE_IDLE: begin
          if (startRequest) begin
            requestAddrReg <= io_in_addr;
            stateReg <= STATE_START_LOW;
          end
        end

        STATE_START_LOW: begin
          if (io_cache_wait_n)
            stateReg <= STATE_WAIT_LOW;
        end

        STATE_WAIT_LOW: begin
          if (io_cache_valid) begin
            lowDataReg <= io_cache_dout;
            stateReg <= STATE_START_HIGH;
          end
        end

        STATE_START_HIGH: begin
          if (io_cache_wait_n)
            stateReg <= STATE_WAIT_HIGH;
        end

        STATE_WAIT_HIGH: begin
          if (io_cache_valid) begin
            doutReg <= splitDout;
            validReg <= 1'b1;
            stateReg <= STATE_IDLE;
          end
        end

        default: begin
          stateReg <= STATE_IDLE;
        end
      endcase
    end
  end

  assign io_cache_rd =
    normalMode ? io_in_rd :
    (stateReg == STATE_START_LOW) | (stateReg == STATE_START_HIGH);

  assign io_cache_addr =
    normalMode ? io_in_addr :
    (stateReg == STATE_START_HIGH) ? splitHighRawAddr : splitLowAddr;

  assign io_in_dout = normalMode ? io_cache_dout : doutReg;
  assign io_in_wait_n = normalMode ? io_cache_wait_n : (stateReg == STATE_IDLE);
  assign io_in_valid = normalMode ? io_cache_valid : validReg;
endmodule
