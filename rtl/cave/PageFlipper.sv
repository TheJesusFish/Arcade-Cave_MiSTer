// Double-buffer page address generator for the sprite frame buffer.
module PageFlipper (
  input         clock,
  input         reset,
  input         io_swapWrite,
  output [31:0] io_addrRead,
  output [31:0] io_addrWrite
);
  reg [1:0] read_index;
  reg [1:0] write_index;

  always @(posedge clock) begin
    if (reset) begin
      read_index <= 2'h0;
      write_index <= 2'h1;
    end
    else if (io_swapWrite) begin
      read_index <= {1'b0, write_index[0]};
      write_index <= {1'b0, ~write_index[0]};
    end
  end

  assign io_addrRead = {11'h121, read_index, 19'h0};
  assign io_addrWrite = {11'h121, write_index, 19'h0};
endmodule
