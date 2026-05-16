module Queue32_UInt64(
  input         clock,
  input         reset,
  input         io_enq_valid,
  input  [63:0] io_enq_bits,
  input         io_deq_ready,
  output        io_deq_valid,
  output [63:0] io_deq_bits,
  output [5:0]  io_count,
  input         io_flush
);
  wire io_enq_ready_unused;

  CaveSyncQueue #(
    .ADDR_WIDTH (5),
    .DATA_WIDTH (64),
    .DEPTH      (32)
  ) queue (
    .clock        (clock),
    .reset        (reset),
    .io_enq_ready (io_enq_ready_unused),
    .io_enq_valid (io_enq_valid),
    .io_enq_bits  (io_enq_bits),
    .io_deq_ready (io_deq_ready),
    .io_deq_valid (io_deq_valid),
    .io_deq_bits  (io_deq_bits),
    .io_count     (io_count),
    .io_flush     (io_flush)
  );
endmodule
