module OKIM6295(
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
  CaveOKIM6295 #(
    .CEN_STEP (17'h0873)
  ) oki (
    .clock          (clock),
    .reset          (reset),
    .io_cpu_wr      (io_cpu_wr),
    .io_cpu_din     (io_cpu_din),
    .io_cpu_dout    (io_cpu_dout),
    .io_rom_addr    (io_rom_addr),
    .io_rom_dout    (io_rom_dout),
    .io_rom_valid   (io_rom_valid),
    .io_audio_valid (io_audio_valid),
    .io_audio_bits  (io_audio_bits)
  );
endmodule
