// Linear interpolation helper for YMZ280B sample playback.
module LERP (
  input  [16:0] io_samples_0,
  input  [16:0] io_samples_1,
  input  [9:0]  io_index,
  output [16:0] io_out
);
  wire signed [16:0] sample_0 = io_samples_0;
  wire signed [16:0] sample_1 = io_samples_1;
  wire signed [17:0] slope = {sample_1[16], sample_1} - {sample_0[16], sample_0};
  wire signed [25:0] slope_ext = {{8{slope[17]}}, slope};
  wire signed [25:0] scaled_offset = slope_ext * $signed({16'h0000, io_index});
  wire signed [16:0] interpolated = scaled_offset[25:9] + sample_0;

  assign io_out = interpolated;
endmodule
