// Queues 16-bit framebuffer writes and expands them onto the 64-bit DDR write bus.
module RequestQueue (
  input         clock,
  input         io_enable,
  input         io_readClock,
  input         io_in_wr,
  input  [16:0] io_in_addr,
  input  [15:0] io_in_din,
  output        io_in_wait_n,
  output        io_out_wr,
  output [31:0] io_out_addr,
  output [7:0]  io_out_mask,
  output [63:0] io_out_din,
  input         io_out_wait_n
);
  wire        fifo_deq_valid;
  wire [16:0] fifo_deq_addr;
  wire [15:0] fifo_deq_din;
  wire [1:0]  fifo_deq_mask;

  function [7:0] expand_mask;
    input [1:0] addr_low;
    input [1:0] mask;
    begin
      case (addr_low)
        2'h0: expand_mask = {6'b000000, mask};
        2'h1: expand_mask = {4'b0000, mask, 2'b00};
        2'h2: expand_mask = {2'b00, mask, 4'b0000};
        2'h3: expand_mask = {mask, 6'b000000};
      endcase
    end
  endfunction

  DualClockFIFO_6 fifo (
    .clock            (clock),
    .io_readClock     (io_readClock),
    .io_deq_ready     (io_out_wait_n),
    .io_deq_valid     (fifo_deq_valid),
    .io_deq_bits_addr (fifo_deq_addr),
    .io_deq_bits_din  (fifo_deq_din),
    .io_deq_bits_mask (fifo_deq_mask),
    .io_enq_ready     (io_in_wait_n),
    .io_enq_valid     (io_in_wr),
    .io_enq_bits_wr   (io_in_wr),
    .io_enq_bits_addr (io_in_addr),
    .io_enq_bits_din  (io_in_din)
  );

  assign io_out_wr = io_enable & fifo_deq_valid;
  assign io_out_addr = {14'b0, fifo_deq_addr, 1'b0};
  assign io_out_mask = expand_mask(fifo_deq_addr[1:0], fifo_deq_mask);
  assign io_out_din = {4{fifo_deq_din}};
endmodule
