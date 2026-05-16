// Four 16-bit registers exposed as a tiny memory-mapped register file.
module RegisterFile (
  input         clock,
  input         io_mem_wr,
  input  [1:0]  io_mem_addr,
  input  [15:0] io_mem_din,
  output [15:0] io_regs_0
);
  reg [15:0] regs_0;
  reg [15:0] regs_1;
  reg [15:0] regs_2;
  reg [15:0] regs_3;

  always @(posedge clock) begin
    if (io_mem_wr) begin
      case (io_mem_addr)
        2'h0: regs_0 <= io_mem_din;
        2'h1: regs_1 <= io_mem_din;
        2'h2: regs_2 <= io_mem_din;
        2'h3: regs_3 <= io_mem_din;
      endcase
    end
  end

  assign io_regs_0 = regs_0;
endmodule
