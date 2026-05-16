module SpriteFrameBuffer(
  input         clock,
  input         reset,
  input         io_videoClock,
  input         io_enable,
  input         io_swap,
  input  [8:0]  io_video_pos_y,
  input         io_video_hBlank,
  input  [8:0]  io_lineBuffer_addr,
  output [15:0] io_lineBuffer_dout,
  input         io_frameBuffer_wr,
  input  [16:0] io_frameBuffer_addr,
  input  [15:0] io_frameBuffer_din,
  output        io_frameBuffer_wait_n,
  output        io_ddr_rd,
  output        io_ddr_wr,
  output [31:0] io_ddr_addr,
  output [7:0]  io_ddr_mask,
  output [63:0] io_ddr_din,
  input  [63:0] io_ddr_dout,
  input         io_ddr_wait_n,
  input         io_ddr_valid,
  output [7:0]  io_ddr_burstLength,
  input         io_ddr_burstDone
);
  wire        lineBuffer_wr;
  wire [6:0]  lineBuffer_addr;
  wire [63:0] lineBuffer_din;

  wire        lineBufferDma_start;
  wire        lineBufferDma_in_rd;
  wire [31:0] lineBufferDma_in_addr;
  wire [63:0] lineBufferDma_in_dout;
  wire        lineBufferDma_in_wait_n;
  wire        lineBufferDma_in_valid;
  wire        lineBufferDma_in_burstDone;
  wire [31:0] lineBufferDma_out_addr;

  wire        frameBufferDma_start = io_enable & io_swap;
  wire        frameBufferDma_out_wr;
  wire [31:0] frameBufferDma_out_addr;
  wire [63:0] frameBufferDma_out_din;
  wire        frameBufferDma_out_wait_n;
  wire        frameBufferDma_out_burstDone;

  wire        queue_out_wr;
  wire [31:0] queue_out_addr;
  wire [7:0]  queue_out_mask;
  wire [63:0] queue_out_din;
  wire        queue_out_wait_n;

  wire [31:0] page_addrRead;
  wire [31:0] page_addrWrite;
  wire [31:0] ddr_lineBuffer_addr;
  wire [31:0] ddr_frameBufferClear_addr;
  wire [31:0] ddr_frameBufferQueue_addr;

  reg hBlank_r;
  reg hBlank;
  reg hBlankPrev;

  always @(posedge clock) begin
    hBlank_r <= io_video_hBlank;
    hBlank <= hBlank_r;
    hBlankPrev <= hBlank;
  end

  assign lineBufferDma_start = io_enable & hBlank & ~hBlankPrev;
  assign lineBuffer_addr = lineBufferDma_out_addr[9:3];

  TrueDualPortRam_11 lineBuffer (
    .clock         (clock),
    .io_clockB     (io_videoClock),
    .io_portA_wr   (lineBuffer_wr),
    .io_portA_addr (lineBuffer_addr),
    .io_portA_din  (lineBuffer_din),
    .io_portB_addr (io_lineBuffer_addr),
    .io_portB_dout (io_lineBuffer_dout)
  );

  PageFlipper pageFlipper (
    .clock        (clock),
    .reset        (reset),
    .io_swapWrite (frameBufferDma_start),
    .io_addrRead  (page_addrRead),
    .io_addrWrite (page_addrWrite)
  );

  BurstReadDMA_1 lineBufferDma (
    .clock           (clock),
    .reset           (reset),
    .io_start        (lineBufferDma_start),
    .io_in_rd        (lineBufferDma_in_rd),
    .io_in_addr      (lineBufferDma_in_addr),
    .io_in_dout      (lineBufferDma_in_dout),
    .io_in_wait_n    (lineBufferDma_in_wait_n),
    .io_in_valid     (lineBufferDma_in_valid),
    .io_in_burstDone (lineBufferDma_in_burstDone),
    .io_out_wr       (lineBuffer_wr),
    .io_out_addr     (lineBufferDma_out_addr),
    .io_out_din      (lineBuffer_din)
  );

  RequestQueue queue (
    .clock         (clock),
    .io_enable     (io_enable),
    .io_readClock  (clock),
    .io_in_wr      (io_frameBuffer_wr),
    .io_in_addr    (io_frameBuffer_addr),
    .io_in_din     (io_frameBuffer_din),
    .io_in_wait_n  (io_frameBuffer_wait_n),
    .io_out_wr     (queue_out_wr),
    .io_out_addr   (queue_out_addr),
    .io_out_mask   (queue_out_mask),
    .io_out_din    (queue_out_din),
    .io_out_wait_n (queue_out_wait_n)
  );

  BurstWriteDMA frameBufferDma (
    .clock            (clock),
    .reset            (reset),
    .io_start         (frameBufferDma_start),
    .io_out_wr        (frameBufferDma_out_wr),
    .io_out_addr      (frameBufferDma_out_addr),
    .io_out_din       (frameBufferDma_out_din),
    .io_out_wait_n    (frameBufferDma_out_wait_n),
    .io_out_burstDone (frameBufferDma_out_burstDone)
  );

  assign ddr_lineBuffer_addr =
    32'(lineBufferDma_in_addr
        + 32'(page_addrRead + {13'h0, 9'(io_video_pos_y + 9'h1), 10'h0}));
  assign ddr_frameBufferClear_addr = 32'(frameBufferDma_out_addr + page_addrWrite);
  assign ddr_frameBufferQueue_addr = 32'(queue_out_addr + page_addrWrite);

  BurstMemArbiter_2 ddrArbiter (
    .clock              (clock),
    .reset              (reset),
    .io_in_0_rd         (lineBufferDma_in_rd),
    .io_in_0_addr       (ddr_lineBuffer_addr),
    .io_in_0_dout       (lineBufferDma_in_dout),
    .io_in_0_wait_n     (lineBufferDma_in_wait_n),
    .io_in_0_valid      (lineBufferDma_in_valid),
    .io_in_0_burstDone  (lineBufferDma_in_burstDone),
    .io_in_1_wr         (frameBufferDma_out_wr),
    .io_in_1_addr       (ddr_frameBufferClear_addr),
    .io_in_1_din        (frameBufferDma_out_din),
    .io_in_1_wait_n     (frameBufferDma_out_wait_n),
    .io_in_1_burstDone  (frameBufferDma_out_burstDone),
    .io_in_2_wr         (queue_out_wr),
    .io_in_2_addr       (ddr_frameBufferQueue_addr),
    .io_in_2_mask       (queue_out_mask),
    .io_in_2_din        (queue_out_din),
    .io_in_2_wait_n     (queue_out_wait_n),
    .io_out_rd          (io_ddr_rd),
    .io_out_wr          (io_ddr_wr),
    .io_out_addr        (io_ddr_addr),
    .io_out_mask        (io_ddr_mask),
    .io_out_din         (io_ddr_din),
    .io_out_dout        (io_ddr_dout),
    .io_out_wait_n      (io_ddr_wait_n),
    .io_out_valid       (io_ddr_valid),
    .io_out_burstLength (io_ddr_burstLength),
    .io_out_burstDone   (io_ddr_burstDone)
  );
endmodule
