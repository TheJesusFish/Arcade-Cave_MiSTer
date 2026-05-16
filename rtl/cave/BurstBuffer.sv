module BurstBuffer(
  input         clock,
  input         reset,
  input         io_in_wr,
  input  [26:0] io_in_addr,
  input  [15:0] io_in_din,
  output        io_out_wr,
  output [31:0] io_out_addr,
  output [63:0] io_out_din,
  input         io_out_burstDone
);
  reg        write_pending;
  reg        busy;
  reg [1:0]  word_counter;
  reg [26:0] addr;
  reg [63:0] line;

  wire latch_input = io_in_wr & ~write_pending;
  wire gathered_word_ready = word_counter == 2'd3;
  wire [63:0] next_line = {
    gathered_word_ready ? io_in_din : line[63:48],
    word_counter == 2'd2 ? io_in_din : line[47:32],
    word_counter == 2'd1 ? io_in_din : line[31:16],
    word_counter == 2'd0 ? io_in_din : line[15:0]
  };

  always @(posedge clock) begin
    if (reset) begin
      write_pending <= 1'b0;
      busy <= 1'b0;
      word_counter <= 2'd0;
    end
    else begin
      write_pending <= ~io_out_burstDone & ((latch_input & gathered_word_ready) | write_pending);
      busy <= ~io_out_burstDone & (io_in_wr | busy);
      if (latch_input)
        word_counter <= word_counter + 2'd1;
    end

    if (latch_input)
      line <= next_line;
    if (io_in_wr & ~busy)
      addr <= io_in_addr;
  end

  assign io_out_wr = write_pending;
  assign io_out_addr = {5'h0, addr[26:3], 3'h0};
  assign io_out_din = line;
endmodule
