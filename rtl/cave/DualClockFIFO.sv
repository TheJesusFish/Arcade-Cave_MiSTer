module DualClockFIFO(
  input         clock,
  input         io_readClock,
  input         io_deq_ready,
  output        io_deq_valid,
  output [31:0] io_deq_bits,
  input         io_enq_valid,
  input  [31:0] io_enq_bits
);
  wire io_enq_ready_unused;

  CaveDualClockFIFO #(
    .DATA_WIDTH (32),
    .DEPTH      (4)
  ) fifo (
    .write_clock (clock),
    .read_clock  (io_readClock),
    .deq_ready   (io_deq_ready),
    .deq_valid   (io_deq_valid),
    .deq_bits    (io_deq_bits),
    .enq_ready   (io_enq_ready_unused),
    .enq_valid   (io_enq_valid),
    .enq_bits    (io_enq_bits)
  );
endmodule
