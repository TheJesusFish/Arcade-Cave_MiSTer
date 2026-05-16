// Three visible 16-bit memory-mapped registers with byte write masks.
module RegisterFile_2 (
  input         clock,
  input         io_mem_wr,
  input  [1:0]  io_mem_addr,
  input  [1:0]  io_mem_mask,
  input  [15:0] io_mem_din,
  output [15:0] io_mem_dout,
  output [15:0] io_regs_0,
  output [15:0] io_regs_1,
  output [15:0] io_regs_2
);
  reg [15:0] regs_0;
  reg [15:0] regs_1;
  reg [15:0] regs_2;

  reg [15:0] selected_reg;

  function [15:0] apply_mask;
    input [15:0] old_value;
    input [15:0] new_value;
    input [1:0]  mask;
    begin
      apply_mask = {
        mask[1] ? new_value[15:8] : old_value[15:8],
        mask[0] ? new_value[7:0]  : old_value[7:0]
      };
    end
  endfunction

  always @(*) begin
    case (io_mem_addr)
      2'h0: selected_reg = regs_0;
      2'h1: selected_reg = regs_1;
      2'h2: selected_reg = regs_2;
      default: selected_reg = regs_0;
    endcase
  end

  always @(posedge clock) begin
    if (io_mem_wr) begin
      case (io_mem_addr)
        2'h0: regs_0 <= apply_mask(regs_0, io_mem_din, io_mem_mask);
        2'h1: regs_1 <= apply_mask(regs_1, io_mem_din, io_mem_mask);
        2'h2: regs_2 <= apply_mask(regs_2, io_mem_din, io_mem_mask);
        default: begin
        end
      endcase
    end
  end

  assign io_mem_dout = selected_reg;
  assign io_regs_0 = regs_0;
  assign io_regs_1 = regs_1;
  assign io_regs_2 = regs_2;
endmodule
