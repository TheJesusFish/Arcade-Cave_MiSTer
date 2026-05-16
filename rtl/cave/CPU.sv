module CPU(
  input         clock,
  input         reset,
  input         io_halt,
  output        io_as,
  output        io_rw,
  output        io_uds,
  output        io_lds,
  input         io_dtack,
  input         io_vpa,
  input  [2:0]  io_ipl,
  output [2:0]  io_fc,
  output [22:0] io_addr,
  input  [15:0] io_din,
  output [15:0] io_dout
);
  reg phi1_enable;
  reg phi2_enable;

  wire halt_n = ~io_halt;
  wire dtack_n = ~io_dtack;
  wire vpa_n = ~io_vpa;
  wire as_n;
  wire uds_n;
  wire lds_n;
  wire fc0;
  wire fc1;
  wire fc2;

  always @(posedge clock) begin
    if (reset)
      phi1_enable <= 1'b0;
    else
      phi1_enable <= ~phi1_enable;

    phi2_enable <= phi1_enable;
  end

  fx68k cpu (
    .clk      (clock),
    .enPhi1   (phi1_enable),
    .enPhi2   (phi2_enable),
    .extReset (reset),
    .pwrUp    (reset),
    .HALTn    (halt_n),
    .ASn      (as_n),
    .eRWn     (io_rw),
    .UDSn     (uds_n),
    .LDSn     (lds_n),
    .DTACKn   (dtack_n),
    .BERRn    (1'b1),
    .E        (),
    .VPAn     (vpa_n),
    .VMAn     (),
    .BRn      (1'b1),
    .BGn      (),
    .BGACKn   (1'b1),
    .IPL0n    (~io_ipl[0]),
    .IPL1n    (~io_ipl[1]),
    .IPL2n    (~io_ipl[2]),
    .FC0      (fc0),
    .FC1      (fc1),
    .FC2      (fc2),
    .eab      (io_addr),
    .iEdb     (io_din),
    .oEdb     (io_dout)
  );

  assign io_as = ~as_n;
  assign io_uds = ~uds_n;
  assign io_lds = ~lds_n;
  assign io_fc = {fc2, fc1, fc0};
endmodule
