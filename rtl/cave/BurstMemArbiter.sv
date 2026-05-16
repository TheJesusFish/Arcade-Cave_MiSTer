module BurstMemArbiter(
  input         clock,
  input         reset,
  input         io_in_0_wr,
  input  [31:0] io_in_0_addr,
  input  [63:0] io_in_0_din,
  output        io_in_0_burstDone,
  input         io_in_1_rd,
  input  [31:0] io_in_1_addr,
  output [63:0] io_in_1_dout,
  output        io_in_1_wait_n,
  output        io_in_1_valid,
  output        io_in_1_burstDone,
  input         io_in_2_wr,
  input  [31:0] io_in_2_addr,
  input  [7:0]  io_in_2_mask,
  input  [63:0] io_in_2_din,
  output        io_in_2_wait_n,
  input         io_in_3_rd,
  input         io_in_3_wr,
  input  [31:0] io_in_3_addr,
  input  [7:0]  io_in_3_mask,
  input  [63:0] io_in_3_din,
  output [63:0] io_in_3_dout,
  output        io_in_3_wait_n,
  output        io_in_3_valid,
  input  [7:0]  io_in_3_burstLength,
  output        io_in_3_burstDone,
  input         io_in_4_rd,
  input  [31:0] io_in_4_addr,
  output [63:0] io_in_4_dout,
  output        io_in_4_wait_n,
  output        io_in_4_valid,
  input  [7:0]  io_in_4_burstLength,
  output        io_in_4_burstDone,
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

  localparam [4:0] REQ_NONE = 5'b00000;
  localparam [4:0] REQ_0    = 5'b00001;
  localparam [4:0] REQ_1    = 5'b00010;
  localparam [4:0] REQ_2    = 5'b00100;
  localparam [4:0] REQ_3    = 5'b01000;
  localparam [4:0] REQ_4    = 5'b10000;

  reg        busy_reg;
  reg [4:0]  locked_request;

  wire request_0 = io_in_0_wr;
  wire request_1 = io_in_1_rd;
  wire request_2 = io_in_2_wr;
  wire request_3 = io_in_3_rd | io_in_3_wr;
  wire request_4 = io_in_4_rd;

  wire [4:0] next_request =
    request_0 ? REQ_0 :
    request_1 ? REQ_1 :
    request_2 ? REQ_2 :
    request_3 ? REQ_3 :
    request_4 ? REQ_4 :
    REQ_NONE;

  wire [4:0] chosen = busy_reg ? locked_request : next_request;
  wire       no_request_chosen = chosen == REQ_NONE;
  wire       selected_read =
    (chosen[1] & io_in_1_rd) | (chosen[3] & io_in_3_rd) | (chosen[4] & io_in_4_rd);
  wire       selected_write =
    (chosen[0] & io_in_0_wr) | (chosen[2] & io_in_2_wr) | (chosen[3] & io_in_3_wr);
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

  assign io_in_0_burstDone = chosen[0] & io_out_burstDone;
  assign io_in_1_dout = io_out_dout;
  assign io_in_1_wait_n = (no_request_chosen | chosen[1]) & io_out_wait_n;
  assign io_in_1_valid = chosen[1] & io_out_valid;
  assign io_in_1_burstDone = chosen[1] & io_out_burstDone;
  assign io_in_2_wait_n = (no_request_chosen | chosen[2]) & io_out_wait_n;
  assign io_in_3_dout = io_out_dout;
  assign io_in_3_wait_n = (no_request_chosen | chosen[3]) & io_out_wait_n;
  assign io_in_3_valid = chosen[3] & io_out_valid;
  assign io_in_3_burstDone = chosen[3] & io_out_burstDone;
  assign io_in_4_dout = io_out_dout;
  assign io_in_4_wait_n = (no_request_chosen | chosen[4]) & io_out_wait_n;
  assign io_in_4_valid = chosen[4] & io_out_valid;
  assign io_in_4_burstDone = chosen[4] & io_out_burstDone;
  assign io_out_rd = selected_read;
  assign io_out_wr = selected_write;
  assign io_out_addr =
    (chosen[0] ? io_in_0_addr : 32'h0) |
    (chosen[1] ? io_in_1_addr : 32'h0) |
    (chosen[2] ? io_in_2_addr : 32'h0) |
    (chosen[3] ? io_in_3_addr : 32'h0) |
    (chosen[4] ? io_in_4_addr : 32'h0);
  assign io_out_mask =
    {8{chosen[0]}} |
    (chosen[2] ? io_in_2_mask : 8'h0) |
    (chosen[3] ? io_in_3_mask : 8'h0);
  assign io_out_din =
    (chosen[0] ? io_in_0_din : 64'h0) |
    (chosen[2] ? io_in_2_din : 64'h0) |
    (chosen[3] ? io_in_3_din : 64'h0);
  assign io_out_burstLength =
    (chosen[0] ? 8'd1 : 8'd0) |
    (chosen[1] ? 8'd16 : 8'd0) |
    (chosen[2] ? 8'd1 : 8'd0) |
    (chosen[3] ? io_in_3_burstLength : 8'd0) |
    (chosen[4] ? io_in_4_burstLength : 8'd0);
endmodule
