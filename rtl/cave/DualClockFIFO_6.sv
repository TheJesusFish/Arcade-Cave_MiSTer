module DualClockFIFO_6(
  input         clock,
  input         io_readClock,
  input         io_deq_ready,
  output        io_deq_valid,
  output [16:0] io_deq_bits_addr,
  output [15:0] io_deq_bits_din,
  output [1:0]  io_deq_bits_mask,
  output        io_enq_ready,
  input         io_enq_valid,
  input         io_enq_bits_wr,
  input  [16:0] io_enq_bits_addr,
  input  [15:0] io_enq_bits_din
);
  wire [35:0] fifo_data = {io_enq_bits_wr, io_enq_bits_addr, io_enq_bits_din, 2'h3};
  wire [35:0] fifo_q;

  CaveDualClockFIFO #(
    .DATA_WIDTH (36),
    .DEPTH      (16)
  ) fifo (
    .write_clock (clock),
    .read_clock  (io_readClock),
    .deq_ready   (io_deq_ready),
    .deq_valid   (io_deq_valid),
    .deq_bits    (fifo_q),
    .enq_ready   (io_enq_ready),
    .enq_valid   (io_enq_valid),
    .enq_bits    (fifo_data)
  );

  assign io_deq_bits_addr = fifo_q[34:18];
  assign io_deq_bits_din = fifo_q[17:2];
  assign io_deq_bits_mask = fifo_q[1:0];
endmodule
