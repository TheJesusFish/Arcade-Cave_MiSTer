module VideoTiming_1(
  input        clock,
  input        reset,
  input  [8:0] io_display_x,
  input  [8:0] io_display_y,
  input  [8:0] io_frontPorch_x,
  input  [8:0] io_frontPorch_y,
  input  [8:0] io_retrace_x,
  input  [8:0] io_retrace_y,
  input  [3:0] io_offset_x,
  input  [3:0] io_offset_y,
  output       io_timing_clockEnable,
  output       io_timing_displayEnable,
  output [8:0] io_timing_pos_x,
  output [8:0] io_timing_pos_y,
  output       io_timing_hSync,
  output       io_timing_vSync,
  output       io_timing_hBlank,
  output       io_timing_vBlank
);
  CaveVideoTiming #(
    .H_TOTAL (10'h1BD),
    .V_TOTAL (10'h106)
  ) timing (
    .clock                   (clock),
    .reset                   (reset),
    .io_display_x            (io_display_x),
    .io_display_y            (io_display_y),
    .io_frontPorch_x         (io_frontPorch_x),
    .io_frontPorch_y         (io_frontPorch_y),
    .io_retrace_x            (io_retrace_x),
    .io_retrace_y            (io_retrace_y),
    .io_offset_x             (io_offset_x),
    .io_offset_y             (io_offset_y),
    .io_timing_clockEnable   (io_timing_clockEnable),
    .io_timing_displayEnable (io_timing_displayEnable),
    .io_timing_pos_x         (io_timing_pos_x),
    .io_timing_pos_y         (io_timing_pos_y),
    .io_timing_hSync         (io_timing_hSync),
    .io_timing_vSync         (io_timing_vSync),
    .io_timing_hBlank        (io_timing_hBlank),
    .io_timing_vBlank        (io_timing_vBlank)
  );
endmodule
