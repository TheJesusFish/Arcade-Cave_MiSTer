module ReadCache_1(
  input         clock,
  input         reset,
  input         io_enable,
  input         io_in_rd,
  input  [24:0] io_in_addr,
  output [7:0]  io_in_dout,
  output        io_in_wait_n,
  output        io_in_valid,
  output        io_out_rd,
  output [24:0] io_out_addr,
  input  [15:0] io_out_dout,
  input         io_out_wait_n,
  input         io_out_valid
);
  CaveReadCache #(
    .IN_ADDR_WIDTH  (25),
    .IN_DATA_WIDTH  (8),
    .OUT_ADDR_WIDTH (25),
    .INDEX_WIDTH    (2),
    .TAG_WIDTH      (21)
  ) cache (
    .clock         (clock),
    .reset         (reset),
    .io_enable     (io_enable),
    .io_in_rd      (io_in_rd),
    .io_in_addr    (io_in_addr),
    .io_in_dout    (io_in_dout),
    .io_in_wait_n  (io_in_wait_n),
    .io_in_valid   (io_in_valid),
    .io_out_rd     (io_out_rd),
    .io_out_addr   (io_out_addr),
    .io_out_dout   (io_out_dout),
    .io_out_wait_n (io_out_wait_n),
    .io_out_valid  (io_out_valid)
  );
endmodule
