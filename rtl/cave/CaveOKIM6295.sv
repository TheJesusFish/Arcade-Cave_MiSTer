module CaveOKIM6295 #(
  parameter [16:0] CEN_STEP = 17'h0873
) (
  input         clock,
  input         reset,
  input         io_cpu_wr,
  input  [7:0]  io_cpu_din,
  output [7:0]  io_cpu_dout,
  output [17:0] io_rom_addr,
  input  [7:0]  io_rom_dout,
  input         io_rom_valid,
  output        io_audio_valid,
  output [13:0] io_audio_bits
);
  wire adpcm_cen;

  CaveClockEnable #(
    .STEP (CEN_STEP)
  ) clock_enable (
    .clock  (clock),
    .enable (adpcm_cen)
  );

  jt6295 adpcm (
    .rst      (reset),
    .clk      (clock),
    .cen      (adpcm_cen),
    .ss       (1'b1),
    .wrn      (~io_cpu_wr),
    .din      (io_cpu_din),
    .dout     (io_cpu_dout),
    .rom_addr (io_rom_addr),
    .rom_data (io_rom_dout),
    .rom_ok   (io_rom_valid),
    .sound    (io_audio_bits),
    .sample   (io_audio_valid)
  );
endmodule
