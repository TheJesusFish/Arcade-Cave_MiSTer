// Signed audio mixer with fixed-point gain and 16-bit output clipping.
module AudioMixer (
  input         clock,
  input  [13:0] io_in_4,
  input  [13:0] io_in_3,
  input  [15:0] io_in_2,
  input  [15:0] io_in_1,
  input  [15:0] io_in_0,
  output [15:0] io_out
);
  localparam signed [21:0] MIN_SAMPLE = -22'sd32768;
  localparam signed [21:0] MAX_SAMPLE =  22'sd32767;

  wire signed [18:0] channel_1_gain =
    $signed({{3{io_in_1[15]}}, io_in_1}) * 19'sd3;
  wire signed [21:0] channel_3_gain =
    $signed({{6{io_in_3[13]}}, io_in_3, 2'b00}) * 22'sd26;

  wire signed [22:0] sum_0_1 =
    $signed({{3{io_in_0[15]}}, io_in_0, 4'b0000})
    + $signed({{4{channel_1_gain[18]}}, channel_1_gain});
  wire signed [23:0] sum_0_2 =
    $signed({sum_0_1[22], sum_0_1})
    + $signed({{4{io_in_2[15]}}, io_in_2, 4'b0000});
  wire signed [24:0] sum_0_3 =
    $signed({sum_0_2[23], sum_0_2})
    + $signed({{3{channel_3_gain[21]}}, channel_3_gain});
  wire signed [25:0] mix_sum =
    $signed({sum_0_3[24], sum_0_3})
    + $signed({{6{io_in_4[13]}}, io_in_4, 6'b000000});

  wire signed [21:0] scaled_sum = mix_sum[25:4];
  wire signed [21:0] clipped_low = scaled_sum < MIN_SAMPLE ? MIN_SAMPLE : scaled_sum;
  wire signed [21:0] clipped = clipped_low < MAX_SAMPLE ? clipped_low : MAX_SAMPLE;

  reg signed [21:0] audio_reg;

  always @(posedge clock)
    audio_reg <= clipped;

  assign io_out = audio_reg[15:0];
endmodule
