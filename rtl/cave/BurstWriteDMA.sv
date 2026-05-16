module BurstWriteDMA(
  input         clock,
  input         reset,
  input         io_start,
  output        io_out_wr,
  output [31:0] io_out_addr,
  output [63:0] io_out_din,
  input         io_out_wait_n,
  input         io_out_burstDone
);

  localparam [6:0] FIFO_ALMOST_FULL_COUNT = 7'd63;
  localparam [6:0] FIFO_BURST_READY_COUNT = 7'd64;

  wire        fifo_enq_ready;
  wire [6:0]  fifo_count;
  reg         read_enable;
  reg         write_enable;
  reg         read_pending;
  reg         write_pending;
  reg  [14:0] word_counter;
  reg  [8:0]  burst_counter;

  wire        start = io_start & ~(read_enable | write_enable);
  wire        fifo_accepting = ~read_pending & fifo_enq_ready;
  wire        fifo_has_room_for_read_data = fifo_count < FIFO_ALMOST_FULL_COUNT;
  wire        fifo_has_full_burst = fifo_count == FIFO_BURST_READY_COUNT;
  wire        read = read_enable & (fifo_accepting | fifo_has_room_for_read_data);
  wire        write = write_enable & (write_pending | fifo_has_full_burst);
  wire        effective_write = write & io_out_wait_n;
  wire        last_word_read = read & (&word_counter);
  wire        last_burst_done = io_out_burstDone & (&burst_counter);

  always @(posedge clock) begin
    if (reset) begin
      read_enable <= 1'b0;
      write_enable <= 1'b0;
      read_pending <= 1'b0;
      write_pending <= 1'b0;
      word_counter <= 15'd0;
      burst_counter <= 9'd0;
    end
    else begin
      read_enable <= start | (read_enable & ~last_word_read);
      write_enable <= start | (write_enable & ~last_burst_done);
      read_pending <= read;
      write_pending <= ~io_out_burstDone & (effective_write | write_pending);
      if (read)
        word_counter <= word_counter + 15'd1;
      if (io_out_burstDone)
        burst_counter <= burst_counter + 9'd1;
    end
  end // always @(posedge)

  Queue64_UInt64 fifo (
    .clock        (clock),
    .reset        (reset),
    .io_enq_ready (fifo_enq_ready),
    .io_enq_valid (read_pending),
    .io_deq_ready (effective_write),
    .io_deq_bits  (io_out_din),
    .io_count     (fifo_count),
    .io_flush     (start)
  );

  assign io_out_wr = write;
  assign io_out_addr = {14'h0, burst_counter, 9'h0};
endmodule
