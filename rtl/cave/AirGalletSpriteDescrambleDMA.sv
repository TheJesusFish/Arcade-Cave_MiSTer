module AirGalletSpriteDescrambleDMA(
  input         clock,
  input         reset,
  input         io_start,
  output        io_done,
  input  [31:0] io_gameConfig_sprite_romSize,
  input  [2:0]  io_gameConfig_sprite_descrambleStyle,
  output        io_in_rd,
  output [31:0] io_in_addr,
  input  [63:0] io_in_dout,
  input         io_in_wait_n,
  input         io_in_valid,
  input         io_in_burstDone,
  output        io_out_wr,
  output [31:0] io_out_addr,
  output [63:0] io_out_din,
  input         io_out_wait_n
);
  localparam [2:0] STATE_IDLE       = 3'd0;
  localparam [2:0] STATE_READ       = 3'd1;
  localparam [2:0] STATE_READ_WAIT  = 3'd2;
  localparam [2:0] STATE_READ_VALID = 3'd3;
  localparam [2:0] STATE_WRITE      = 3'd4;
  localparam [2:0] STATE_WRITE_DONE = 3'd5;
  localparam [2:0] STATE_DONE       = 3'd6;

  reg [2:0]  state;
  reg [15:0] readOffset;
  reg [31:0] writeOffset;
  reg [1:0]  regIdx;
  reg [15:0] readRegs_0;
  reg [15:0] readRegs_1;
  reg [15:0] readRegs_2;
  reg [15:0] readRegs_3;

  wire [31:0] readAddrLinear = writeOffset + {16'h0000, readOffset};
  wire [31:0] readAddrXor = readAddrLinear ^ 32'h0009_50c4;
  wire [23:0] readAddrDescrambled = {
    readAddrXor[23], readAddrXor[22], readAddrXor[21], readAddrXor[20],
    readAddrXor[15], readAddrXor[10], readAddrXor[12], readAddrXor[6],
    readAddrXor[11], readAddrXor[1],  readAddrXor[13], readAddrXor[3],
    readAddrXor[16], readAddrXor[17], readAddrXor[2],  readAddrXor[5],
    readAddrXor[14], readAddrXor[7],  readAddrXor[18], readAddrXor[8],
    readAddrXor[4],  readAddrXor[19], readAddrXor[9],  readAddrXor[0]
  };
  wire [31:0] readAddr =
    (io_gameConfig_sprite_descrambleStyle == 3'h1) ?
      {8'h00, readAddrDescrambled} : readAddrLinear;
  wire [63:0] shiftedReadDout = io_in_dout >> {readAddr[2:0], 3'b000};
  wire [31:0] nextWriteOffset = writeOffset + 32'd8;

  always @(posedge clock) begin
    if (reset) begin
      state <= STATE_IDLE;
      readOffset <= 16'h0000;
      writeOffset <= 32'h0000_0000;
      regIdx <= 2'h0;
      readRegs_0 <= 16'h0000;
      readRegs_1 <= 16'h0000;
      readRegs_2 <= 16'h0000;
      readRegs_3 <= 16'h0000;
    end
    else begin
      case (state)
        STATE_IDLE: begin
          if (io_start)
            state <= STATE_READ;
        end

        STATE_READ: begin
          if (io_in_valid)
            state <= STATE_READ_VALID;
          else if (io_in_wait_n)
            state <= STATE_READ_WAIT;
        end

        STATE_READ_WAIT: begin
          if (io_in_valid & io_in_burstDone)
            state <= STATE_READ_VALID;
        end

        STATE_READ_VALID: begin
          case (regIdx)
            2'h0: readRegs_0 <= shiftedReadDout[15:0];
            2'h1: readRegs_1 <= shiftedReadDout[15:0];
            2'h2: readRegs_2 <= shiftedReadDout[15:0];
            default: readRegs_3 <= shiftedReadDout[15:0];
          endcase

          readOffset <= readOffset + 16'd2;
          if (regIdx == 2'h3) begin
            state <= STATE_WRITE;
          end
          else begin
            regIdx <= regIdx + 2'd1;
            state <= STATE_READ;
          end
        end

        STATE_WRITE: begin
          if (io_out_wait_n)
            state <= STATE_WRITE_DONE;
        end

        STATE_WRITE_DONE: begin
          writeOffset <= nextWriteOffset;
          if (nextWriteOffset < io_gameConfig_sprite_romSize) begin
            readOffset <= 16'h0000;
            regIdx <= 2'h0;
            state <= STATE_READ;
          end
          else begin
            state <= STATE_DONE;
          end
        end

        default: begin
          state <= STATE_DONE;
        end
      endcase
    end
  end

  assign io_done = state == STATE_DONE;
  assign io_in_rd = state == STATE_READ;
  assign io_in_addr = readAddr & 32'hffff_fff8;
  assign io_out_wr = state == STATE_WRITE;
  assign io_out_addr = writeOffset;
  assign io_out_din = {readRegs_3, readRegs_2, readRegs_1, readRegs_0};
endmodule
