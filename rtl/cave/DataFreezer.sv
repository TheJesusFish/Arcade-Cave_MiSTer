module DataFreezer(
  input         clock,
  input         reset,
  input         io_targetClock,
  input         io_in_rd,
  input         io_in_wr,
  input  [6:0]  io_in_addr,
  input  [15:0] io_in_din,
  output [15:0] io_in_dout,
  output        io_in_wait_n,
  output        io_in_valid,
  output        io_out_rd,
  output        io_out_wr,
  output [6:0]  io_out_addr,
  output [15:0] io_out_din,
  input  [15:0] io_out_dout,
  input         io_out_wait_n,
  input         io_out_valid
);

  reg        target_clock_toggle;
  reg        target_clock_toggle_d;
  reg        wait_n_latched;
  reg        valid_latched;
  reg [15:0] data_latched;
  reg        data_latched_valid;
  reg        pending_read;
  reg        pending_write;
  reg        clear_read_d;

  wire       clear = target_clock_toggle ^ target_clock_toggle_d;
  wire       wait_n = io_out_wait_n | (wait_n_latched & ~clear);
  wire       valid = io_out_valid | (valid_latched & ~clear);
  wire       clear_read = clear & clear_read_d;
  wire       output_read = io_in_rd & (~pending_read | clear_read);
  wire       output_write = io_in_wr & (~pending_write | clear);

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
      pending_write <= 1'b0;
    end
    else begin
      wait_n_latched <= io_out_wait_n | (~clear & wait_n_latched);
      valid_latched <= io_out_valid | (~clear & valid_latched);
      data_latched_valid <= ~clear & (io_out_valid | data_latched_valid);
      pending_read <= (io_in_rd & io_out_wait_n) | (~clear_read & pending_read);
      pending_write <= (io_in_wr & io_out_wait_n) | (~clear & pending_write);
    end
  end // always @(posedge)

  assign io_in_dout = (data_latched_valid & ~clear) ? data_latched : io_out_dout;
  assign io_in_wait_n = wait_n;
  assign io_in_valid = valid;
  assign io_out_rd = output_read;
  assign io_out_wr = output_write;
  assign io_out_addr = io_in_addr;
  assign io_out_din = io_in_din;
endmodule
