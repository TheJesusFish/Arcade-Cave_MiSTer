// This file is a Codex-assisted rewrite based on the original work of
// Josh Bassett (nullobject).

module CaveOKIM6295 #(
  parameter INTERPOL = 1,
  parameter WRITE_HOLD_CYCLES = 8
)(
  input         clock,
  input         reset,
  input  [16:0] io_cen_step,
  input         io_cpu_wr,
  input  [7:0]  io_cpu_din,
  input         io_stretch_cpu_wr,
  input         io_wait_for_rom,
  output [7:0]  io_cpu_dout,
  output        io_rom_rd,
  output [17:0] io_rom_addr,
  input  [24:0] io_rom_cache_addr,
  input  [7:0]  io_rom_dout,
  input         io_rom_valid,
  output        io_audio_valid,
  output [13:0] io_audio_bits
);
  reg        adpcm_cen;
  reg [15:0] cenAccumulator;
  reg [3:0]  writeHold;
  reg [7:0]  writeDataReg;
  reg [24:0] requestedRomAddr;
  reg [7:0]  romDataReg;
  reg        romDataReady;
  wire [16:0] cenNext = {1'b0, cenAccumulator} + io_cen_step;
  wire        romAddrChanged = io_rom_cache_addr != requestedRomAddr;
  wire        bufferRomForWait = io_stretch_cpu_wr;
  wire        chipRomOk = (io_wait_for_rom & bufferRomForWait) ? romDataReady : io_rom_valid;
  wire [7:0]  chipRomData = (io_wait_for_rom & bufferRomForWait) ? romDataReg : io_rom_dout;
  wire        hold_for_rom = io_wait_for_rom & cenNext[16] & ~chipRomOk;
  localparam integer WRITE_HOLD_RELOAD =
    WRITE_HOLD_CYCLES <= 1 ? 0 :
    WRITE_HOLD_CYCLES > 16 ? 15 :
    WRITE_HOLD_CYCLES - 1;

  wire        stretchCpuWr = io_stretch_cpu_wr & (WRITE_HOLD_CYCLES > 1);
  wire        chipCpuWr = stretchCpuWr ? (io_cpu_wr | (writeHold != 4'd0)) : io_cpu_wr;
  wire [7:0]  chipCpuDin = stretchCpuWr ? (io_cpu_wr ? io_cpu_din : writeDataReg) : io_cpu_din;

  always @(posedge clock) begin
    if (reset) begin
      cenAccumulator <= 16'h0;
      adpcm_cen <= 1'b0;
      requestedRomAddr <= 25'h0;
      romDataReg <= 8'h00;
      romDataReady <= 1'b0;
    end
    else if (hold_for_rom) begin
      adpcm_cen <= 1'b0;
    end
    else begin
      cenAccumulator <= cenNext[15:0];
      adpcm_cen <= cenNext[16];
    end

    if (~reset) begin
      if (romAddrChanged) begin
        requestedRomAddr <= io_rom_cache_addr;
        romDataReady <= 1'b0;
      end
      else if (io_rom_valid) begin
        romDataReg <= io_rom_dout;
        romDataReady <= 1'b1;
      end
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      writeHold <= 4'd0;
      writeDataReg <= 8'h00;
    end
    else if (io_cpu_wr) begin
      writeHold <= WRITE_HOLD_RELOAD;
      writeDataReg <= io_cpu_din;
    end
    else if (writeHold != 4'd0) begin
      writeHold <= writeHold - 4'd1;
    end
  end

  jt6295 #(
    .INTERPOL (INTERPOL)
  ) adpcm (
    .rst      (reset),
    .clk      (clock),
    .cen      (adpcm_cen),
    .ss       (1'b1),
    .wrn      (~chipCpuWr),
    .din      (chipCpuDin),
    .dout     (io_cpu_dout),
    .rom_addr (io_rom_addr),
    .rom_data (chipRomData),
    .rom_ok   (chipRomOk),
    .sound    (io_audio_bits),
    .sample   (io_audio_valid)
  );

  assign io_rom_rd = (io_wait_for_rom & bufferRomForWait) ? (romAddrChanged | ~romDataReady) : 1'b1;
endmodule
