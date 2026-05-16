module CPU_1(
  input         clock,
  input         reset,
  output [15:0] io_addr,
  input  [7:0]  io_din,
  output [7:0]  io_dout,
  output        io_rd,
  output        io_wr,
  output        io_rfsh,
  output        io_mreq,
  output        io_iorq,
  input         io_int,
  input         io_nmi
);
  reg [2:0] clock_divider;

  wire mreq_n;
  wire iorq_n;
  wire rd_n;
  wire wr_n;
  wire rfsh_n;

  always @(posedge clock) begin
    if (reset)
      clock_divider <= 3'd0;
    else
      clock_divider <= clock_divider + 3'd1;
  end

  T80s cpu (
    .RESET_n (~reset),
    .CLK     (clock),
    .CEN     (&clock_divider),
    .WAIT_n  (1'b1),
    .INT_n   (~io_int),
    .NMI_n   (~io_nmi),
    .BUSRQ_n (1'b1),
    .M1_n    (),
    .MREQ_n  (mreq_n),
    .IORQ_n  (iorq_n),
    .RD_n    (rd_n),
    .WR_n    (wr_n),
    .RFSH_n  (rfsh_n),
    .HALT_n  (),
    .BUSAK_n (),
    .A       (io_addr),
    .DI      (io_din),
    .DO      (io_dout),
    .REG     ()
  );

  assign io_rd = ~rd_n;
  assign io_wr = ~wr_n;
  assign io_rfsh = ~rfsh_n;
  assign io_mreq = ~mreq_n;
  assign io_iorq = ~iorq_n;
endmodule
