module BurstMemArbiter_2(
  input         clock,
  input         reset,
  input         io_in_0_rd,
  input  [31:0] io_in_0_addr,
  output [63:0] io_in_0_dout,
  output        io_in_0_wait_n,
  output        io_in_0_valid,
  output        io_in_0_burstDone,
  input         io_in_1_wr,
  input  [31:0] io_in_1_addr,
  input  [63:0] io_in_1_din,
  output        io_in_1_wait_n,
  output        io_in_1_burstDone,
  input         io_in_2_wr,
  input  [31:0] io_in_2_addr,
  input  [7:0]  io_in_2_mask,
  input  [63:0] io_in_2_din,
  output        io_in_2_wait_n,
  output        io_out_rd,
  output        io_out_wr,
  output [31:0] io_out_addr,
  output [7:0]  io_out_mask,
  output [63:0] io_out_din,
  input  [63:0] io_out_dout,
  input         io_out_wait_n,
  input         io_out_valid,
  output [7:0]  io_out_burstLength,
  input         io_out_burstDone
);

  localparam [2:0] REQ_NONE = 3'b000;
  localparam [2:0] REQ_0    = 3'b001;
  localparam [2:0] REQ_1    = 3'b010;
  localparam [2:0] REQ_2    = 3'b100;

  reg        busy_reg;
  reg [2:0]  locked_request;

  wire request_0 = io_in_0_rd;
  wire request_1 = io_in_1_wr;
  wire request_2 = io_in_2_wr;

  wire [2:0] next_request =
    request_0 ? REQ_0 :
    request_1 ? REQ_1 :
    request_2 ? REQ_2 :
    REQ_NONE;

  wire [2:0] chosen = busy_reg ? locked_request : next_request;
  wire       no_request_chosen = chosen == REQ_NONE;
  wire       selected_read = chosen[0] & io_in_0_rd;
  wire       selected_write = (chosen[1] & io_in_1_wr) | (chosen[2] & io_in_2_wr);
  wire       effective_request = ~busy_reg & (selected_read | selected_write) & io_out_wait_n;

  always @(posedge clock) begin
    if (reset) begin
      busy_reg <= 1'b0;
      locked_request <= REQ_NONE;
    end
    else begin
      busy_reg <= ~io_out_burstDone & (effective_request | busy_reg);
      if (effective_request & ~io_out_burstDone)
        locked_request <= next_request;
    end
  end // always @(posedge)

  assign io_in_0_dout = io_out_dout;
  assign io_in_0_wait_n = (no_request_chosen | chosen[0]) & io_out_wait_n;
  assign io_in_0_valid = chosen[0] & io_out_valid;
  assign io_in_0_burstDone = chosen[0] & io_out_burstDone;
  assign io_in_1_wait_n = (no_request_chosen | chosen[1]) & io_out_wait_n;
  assign io_in_1_burstDone = chosen[1] & io_out_burstDone;
  assign io_in_2_wait_n = (no_request_chosen | chosen[2]) & io_out_wait_n;
  assign io_out_rd = selected_read;
  assign io_out_wr = selected_write;
  assign io_out_addr =
    (chosen[0] ? io_in_0_addr : 32'h0) |
    (chosen[1] ? io_in_1_addr : 32'h0) |
    (chosen[2] ? io_in_2_addr : 32'h0);
  assign io_out_mask = {8{chosen[1]}} | (chosen[2] ? io_in_2_mask : 8'h0);
  assign io_out_din =
    (chosen[1] ? io_in_1_din : 64'h0) |
    (chosen[2] ? io_in_2_din : 64'h0);
  assign io_out_burstLength =
    (chosen[0] ? 8'd16 : 8'd0) |
    (chosen[1] ? 8'd64 : 8'd0) |
    (chosen[2] ? 8'd1 : 8'd0);
endmodule
