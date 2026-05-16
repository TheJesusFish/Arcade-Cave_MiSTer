module Queue64_UInt64(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input         io_deq_ready,
  output [63:0] io_deq_bits,
  output [6:0]  io_count,
  input         io_flush
);
  wire io_deq_valid_unused;

  CaveSyncQueue #(
    .ADDR_WIDTH (6),
    .DATA_WIDTH (64),
    .DEPTH      (64)
  ) queue (
    .clock        (clock),
    .reset        (reset),
    .io_enq_ready (io_enq_ready),
    .io_enq_valid (io_enq_valid),
    .io_enq_bits  (64'h0),
    .io_deq_ready (io_deq_ready),
    .io_deq_valid (io_deq_valid_unused),
    .io_deq_bits  (io_deq_bits),
    .io_count     (io_count),
    .io_flush     (io_flush)
  );
endmodule
