// Core-side YM2151 wrapper for Z80 sound boards.
module YM2151 #(
  parameter WRITE_HOLD_CYCLES = 16
)(
  input         clock,
  input         reset,
  input         io_cpu_wr,
  input         io_cpu_addr,
  input  [7:0]  io_cpu_din,
  output [7:0]  io_cpu_dout,
  output        io_irq,
  output        io_audio_valid,
  output [15:0] io_audio_bits
);
  wire ym_cen;
  wire ym_cen_p1;
  wire ym_irq_n;
  wire ym_sample;
  wire signed [15:0] ym_left;
  wire signed [15:0] ym_right;
  wire signed [16:0] ym_mono_sum = {ym_left[15], ym_left} + {ym_right[15], ym_right};
  localparam integer WRITE_HOLD_RELOAD =
    WRITE_HOLD_CYCLES <= 1 ? 0 :
    WRITE_HOLD_CYCLES > 16 ? 15 :
    WRITE_HOLD_CYCLES - 1;

  reg [3:0] write_hold;
  reg       write_addr;
  reg [7:0] write_data;
  wire      chip_cpu_wr = io_cpu_wr | (write_hold != 4'd0);
  wire      chip_cpu_addr = io_cpu_wr ? io_cpu_addr : write_addr;
  wire [7:0] chip_cpu_din = io_cpu_wr ? io_cpu_din : write_data;

  always @(posedge clock) begin
    if (reset) begin
      write_hold <= 4'd0;
      write_addr <= 1'b0;
      write_data <= 8'h00;
    end
    else if (io_cpu_wr) begin
      write_hold <= WRITE_HOLD_RELOAD;
      write_addr <= io_cpu_addr;
      write_data <= io_cpu_din;
    end
    else if (write_hold != 4'd0) begin
      write_hold <= write_hold - 4'd1;
    end
  end

  CaveClockEnable #(
    .STEP (17'h2000)
  ) clock_enable (
    .clock  (clock),
    .enable (ym_cen)
  );

  CaveClockEnable #(
    .STEP (17'h1000)
  ) half_clock_enable (
    .clock  (clock),
    .enable (ym_cen_p1)
  );

  jt51 ym2151 (
    .rst    (reset),
    .clk    (clock),
    .cen    (ym_cen),
    .cen_p1 (ym_cen_p1),
    .cs_n   (1'b0),
    .wr_n   (~chip_cpu_wr),
    .a0     (chip_cpu_addr),
    .din    (chip_cpu_din),
    .dout   (io_cpu_dout),
    .ct1    (),
    .ct2    (),
    .irq_n  (ym_irq_n),
    .sample (ym_sample),
    .left   (),
    .right  (),
    .xleft  (ym_left),
    .xright (ym_right)
  );

  assign io_irq = ~ym_irq_n;
  assign io_audio_valid = ym_sample;
  assign io_audio_bits = ym_mono_sum[16:1];
endmodule
