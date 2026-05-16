// Queues 32-bit framebuffer writes and expands them onto the 64-bit DDR write bus.
module RequestQueue_1 (
  input         clock,
  input         io_enable,
  input         io_readClock,
  input         io_in_wr,
  input  [16:0] io_in_addr,
  input  [31:0] io_in_din,
  output        io_out_wr,
  output [31:0] io_out_addr,
  output [7:0]  io_out_mask,
  output [63:0] io_out_din,
  input         io_out_wait_n
);
  wire        fifo_deq_valid;
  wire [16:0] fifo_deq_addr;
  wire [31:0] fifo_deq_din;
  wire [3:0]  fifo_deq_mask;

  DualClockFIFO_7 fifo (
    .clock            (clock),
    .io_readClock     (io_readClock),
    .io_deq_ready     (io_out_wait_n),
    .io_deq_valid     (fifo_deq_valid),
    .io_deq_bits_addr (fifo_deq_addr),
    .io_deq_bits_din  (fifo_deq_din),
    .io_deq_bits_mask (fifo_deq_mask),
    .io_enq_valid     (io_in_wr),
    .io_enq_bits_wr   (io_in_wr),
    .io_enq_bits_addr (io_in_addr),
    .io_enq_bits_din  (io_in_din)
  );

  assign io_out_wr = io_enable & fifo_deq_valid;
  assign io_out_addr = {13'b0, fifo_deq_addr, 2'b00};
  assign io_out_mask = fifo_deq_addr[0] ? {fifo_deq_mask, 4'b0000} : {4'b0000, fifo_deq_mask};
  assign io_out_din = {2{fifo_deq_din}};
endmodule
