module DualClockFIFO_1(
  input         clock,
  input         io_readClock,
  output [63:0] io_deq_bits,
  input         io_enq_valid,
  input  [63:0] io_enq_bits
);
  wire io_deq_valid_unused;
  wire io_enq_ready_unused;

  CaveDualClockFIFO #(
    .DATA_WIDTH (64),
    .DEPTH      (4)
  ) fifo (
    .write_clock (clock),
    .read_clock  (io_readClock),
    .deq_ready   (1'b1),
    .deq_valid   (io_deq_valid_unused),
    .deq_bits    (io_deq_bits),
    .enq_ready   (io_enq_ready_unused),
    .enq_valid   (io_enq_valid),
    .enq_bits    (io_enq_bits)
  );
endmodule
