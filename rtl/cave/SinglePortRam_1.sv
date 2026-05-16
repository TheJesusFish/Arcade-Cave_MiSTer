module SinglePortRam_1(
  input         clock,
  input         io_rd,
  input         io_wr,
  input  [12:0] io_addr,
  input  [7:0]  io_din,
  output [7:0]  io_dout
);
  CaveSinglePortRam #(
    .ADDR_WIDTH  (13),
    .DATA_WIDTH  (8),
    .DEPTH       (0),
    .MASK_ENABLE (0)
  ) ram (
    .clock (clock),
    .rd    (io_rd),
    .wr    (io_wr),
    .addr  (io_addr),
    .mask  (1'b0),
    .din   (io_din),
    .dout  (io_dout)
  );
endmodule
