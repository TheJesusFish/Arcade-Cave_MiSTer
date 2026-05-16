module cacheEntryMem_8x93 (
  input  [2:0]  R0_addr,
  input         R0_en,
  input         R0_clk,
  output [92:0] R0_data,
  input  [2:0]  W0_addr,
  input         W0_en,
  input         W0_clk,
  input  [92:0] W0_data
);
  CaveSyncReadMem #(
    .ADDR_WIDTH (3),
    .DATA_WIDTH (93),
    .DEPTH      (8)
  ) memory (
    .read_addr  (R0_addr),
    .read_en    (R0_en),
    .read_clk   (R0_clk),
    .read_data  (R0_data),
    .write_addr (W0_addr),
    .write_en   (W0_en),
    .write_clk  (W0_clk),
    .write_data (W0_data)
  );
endmodule
