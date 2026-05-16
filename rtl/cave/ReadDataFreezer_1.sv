module ReadDataFreezer_1(
  input         clock,
  input         reset,
  input         io_targetClock,
  input         io_in_rd,
  input  [24:0] io_in_addr,
  output [7:0]  io_in_dout,
  output        io_in_wait_n,
  output        io_in_valid,
  output        io_out_rd,
  output [24:0] io_out_addr,
  input  [7:0]  io_out_dout,
  input         io_out_wait_n,
  input         io_out_valid
);

  reg       target_clock_toggle;
  reg       target_clock_toggle_d;
  reg       wait_n_latched;
  reg       valid_latched;
  reg [7:0] data_latched;
  reg       data_latched_valid;
  reg       pending_read;
  reg       clear_read_d;

  wire      clear = target_clock_toggle ^ target_clock_toggle_d;
  wire      wait_n = io_out_wait_n | (wait_n_latched & ~clear);
  wire      valid = io_out_valid | (valid_latched & ~clear);
  wire      clear_read = clear & clear_read_d;

  always @(posedge io_targetClock) begin
    if (reset)
      target_clock_toggle <= 1'b0;
    else
      target_clock_toggle <= ~target_clock_toggle;
  end // always @(posedge)

  always @(posedge clock) begin
    target_clock_toggle_d <= target_clock_toggle;
    if (io_out_valid)
      data_latched <= io_out_dout;
    clear_read_d <= valid;
    if (reset) begin
      wait_n_latched <= 1'b0;
      valid_latched <= 1'b0;
      data_latched_valid <= 1'b0;
      pending_read <= 1'b0;
    end
    else begin
      wait_n_latched <= io_out_wait_n | (~clear & wait_n_latched);
      valid_latched <= io_out_valid | (~clear & valid_latched);
      data_latched_valid <= ~clear & (io_out_valid | data_latched_valid);
      pending_read <= (io_in_rd & io_out_wait_n) | (~clear_read & pending_read);
    end
  end // always @(posedge)

  assign io_in_dout = (data_latched_valid & ~clear) ? data_latched : io_out_dout;
  assign io_in_wait_n = wait_n;
  assign io_in_valid = valid;
  assign io_out_rd = io_in_rd & (~pending_read | clear_read);
  assign io_out_addr = io_in_addr;
endmodule
