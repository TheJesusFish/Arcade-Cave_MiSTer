module TrueDualPortRam_11(
  input         clock,
  input         io_clockB,
  input         io_portA_wr,
  input  [6:0]  io_portA_addr,
  input  [63:0] io_portA_din,
  input  [8:0]  io_portB_addr,
  output [15:0] io_portB_dout
);
  wire [63:0] dout_a_unused;

  CaveTrueDualPortRam #(
    .ADDR_WIDTH_A (7),
    .ADDR_WIDTH_B (9),
    .DATA_WIDTH_A (64),
    .DATA_WIDTH_B (16),
    .DEPTH_A      (128),
    .DEPTH_B      (512),
    .MASK_ENABLE  (0)
  ) ram (
    .clock_a (clock),
    .rd_a    (1'b0),
    .wr_a    (io_portA_wr),
    .addr_a  (io_portA_addr),
    .mask_a  (8'hFF),
    .din_a   (io_portA_din),
    .dout_a  (dout_a_unused),
    .clock_b (io_clockB),
    .rd_b    (1'b1),
    .addr_b  (io_portB_addr),
    .dout_b  (io_portB_dout)
  );
endmodule
