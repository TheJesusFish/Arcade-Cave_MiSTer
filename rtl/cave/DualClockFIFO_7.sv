module DualClockFIFO_7(
  input         clock,
  input         io_readClock,
  input         io_deq_ready,
  output        io_deq_valid,
  output [16:0] io_deq_bits_addr,
  output [31:0] io_deq_bits_din,
  output [3:0]  io_deq_bits_mask,
  input         io_enq_valid,
  input         io_enq_bits_wr,
  input  [16:0] io_enq_bits_addr,
  input  [31:0] io_enq_bits_din
);
  wire io_enq_ready_unused;
  wire [53:0] fifo_data = {io_enq_bits_wr, io_enq_bits_addr, io_enq_bits_din, 4'hF};
  wire [53:0] fifo_q;

  CaveDualClockFIFO #(
    .DATA_WIDTH (54),
    .DEPTH      (16)
  ) fifo (
    .write_clock (clock),
    .read_clock  (io_readClock),
    .deq_ready   (io_deq_ready),
    .deq_valid   (io_deq_valid),
    .deq_bits    (fifo_q),
    .enq_ready   (io_enq_ready_unused),
    .enq_valid   (io_enq_valid),
    .enq_bits    (fifo_data)
  );

  assign io_deq_bits_addr = fifo_q[52:36];
  assign io_deq_bits_din = fifo_q[35:4];
  assign io_deq_bits_mask = fifo_q[3:0];
endmodule
