module BurstReadDMA(
  input         clock,
  input         reset,
  input         io_start,
  output        io_busy,
  output        io_in_rd,
  output [31:0] io_in_addr,
  input  [63:0] io_in_dout,
  input         io_in_wait_n,
  input         io_in_valid,
  input         io_in_burstDone,
  output        io_out_wr,
  output [31:0] io_out_addr,
  output [63:0] io_out_din,
  input         io_out_wait_n
);

  localparam [5:0] FIFO_LOW_WATERMARK = 6'd17;

  wire        fifo_enq_valid;
  wire        fifo_deq_valid;
  wire [5:0]  fifo_count;
  reg         read_enable;
  reg         write_enable;
  reg         read_pending;
  reg  [21:0] word_counter;
  reg  [17:0] burst_counter;

  wire        busy = read_enable | write_enable;
  wire        start = io_start & ~busy;
  wire        read = read_enable & ~read_pending & (fifo_count < FIFO_LOW_WATERMARK);
  wire        write = write_enable & fifo_deq_valid;
  wire        effective_write = write & io_out_wait_n;
  wire        last_word_accepted = effective_write & (&word_counter);
  wire        last_burst_done = io_in_burstDone & (&burst_counter);

  always @(posedge clock) begin
    if (reset) begin
      read_enable <= 1'b0;
      write_enable <= 1'b0;
      read_pending <= 1'b0;
      word_counter <= 22'd0;
      burst_counter <= 18'd0;
    end
    else begin
      read_enable <= start | (read_enable & ~last_burst_done);
      write_enable <= start | (write_enable & ~last_word_accepted);
      read_pending <= ~io_in_burstDone & ((read & io_in_wait_n) | read_pending);
      if (effective_write)
        word_counter <= word_counter + 22'd1;
      if (io_in_burstDone)
        burst_counter <= burst_counter + 18'd1;
    end
  end // always @(posedge)

  assign fifo_enq_valid = io_in_valid & read_pending;

  Queue32_UInt64 fifo (
    .clock        (clock),
    .reset        (reset),
    .io_enq_valid (fifo_enq_valid),
    .io_enq_bits  (io_in_dout),
    .io_deq_ready (effective_write),
    .io_deq_valid (fifo_deq_valid),
    .io_deq_bits  (io_out_din),
    .io_count     (fifo_count),
    .io_flush     (start)
  );

  assign io_busy = busy;
  assign io_in_rd = read;
  assign io_in_addr = {7'h0, burst_counter, 7'h0};
  assign io_out_wr = write;
  assign io_out_addr = {7'h0, word_counter, 3'h0};
endmodule
