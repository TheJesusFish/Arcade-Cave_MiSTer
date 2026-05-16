module cacheEntryMem_128x77 (
  input  [6:0]  R0_addr,
  input         R0_en,
  input         R0_clk,
  output [76:0] R0_data,
  input  [6:0]  W0_addr,
  input         W0_en,
  input         W0_clk,
  input  [76:0] W0_data
);
  CaveSyncReadMem #(
    .ADDR_WIDTH (7),
    .DATA_WIDTH (77),
    .DEPTH      (128)
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
