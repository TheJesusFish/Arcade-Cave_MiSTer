module BurstMemArbiter_1(
  input         clock,
  input         reset,
  input         io_in_0_wr,
  input  [24:0] io_in_0_addr,
  input  [15:0] io_in_0_din,
  output        io_in_0_wait_n,
  output        io_in_0_burstDone,
  input         io_in_1_rd,
  input  [24:0] io_in_1_addr,
  output [15:0] io_in_1_dout,
  output        io_in_1_wait_n,
  output        io_in_1_valid,
  input         io_in_2_rd,
  input         io_in_2_wr,
  input  [24:0] io_in_2_addr,
  input  [15:0] io_in_2_din,
  output [15:0] io_in_2_dout,
  output        io_in_2_wait_n,
  output        io_in_2_valid,
  input         io_in_3_rd,
  input  [24:0] io_in_3_addr,
  output [15:0] io_in_3_dout,
  output        io_in_3_wait_n,
  output        io_in_3_valid,
  input         io_in_4_rd,
  input  [24:0] io_in_4_addr,
  output [15:0] io_in_4_dout,
  output        io_in_4_wait_n,
  output        io_in_4_valid,
  input         io_in_5_rd,
  input  [24:0] io_in_5_addr,
  output [15:0] io_in_5_dout,
  output        io_in_5_wait_n,
  output        io_in_5_valid,
  input         io_in_6_rd,
  input  [24:0] io_in_6_addr,
  output [15:0] io_in_6_dout,
  output        io_in_6_wait_n,
  output        io_in_6_valid,
  input         io_in_7_rd,
  input  [24:0] io_in_7_addr,
  output [15:0] io_in_7_dout,
  output        io_in_7_wait_n,
  output        io_in_7_valid,
  output        io_out_rd,
  output        io_out_wr,
  output [24:0] io_out_addr,
  output [15:0] io_out_din,
  input  [15:0] io_out_dout,
  input         io_out_wait_n,
  input         io_out_valid,
  input         io_out_burstDone
);

  localparam [7:0] REQ_NONE = 8'b00000000;
  localparam [7:0] REQ_0    = 8'b00000001;
  localparam [7:0] REQ_1    = 8'b00000010;
  localparam [7:0] REQ_2    = 8'b00000100;
  localparam [7:0] REQ_3    = 8'b00001000;
  localparam [7:0] REQ_4    = 8'b00010000;
  localparam [7:0] REQ_5    = 8'b00100000;
  localparam [7:0] REQ_6    = 8'b01000000;
  localparam [7:0] REQ_7    = 8'b10000000;

  reg        busy_reg;
  reg [7:0]  locked_request;

  wire request_0 = io_in_0_wr;
  wire request_1 = io_in_1_rd;
  wire request_2 = io_in_2_rd | io_in_2_wr;
  wire request_3 = io_in_3_rd;
  wire request_4 = io_in_4_rd;
  wire request_5 = io_in_5_rd;
  wire request_6 = io_in_6_rd;
  wire request_7 = io_in_7_rd;

  wire [7:0] next_request =
    request_0 ? REQ_0 :
    request_1 ? REQ_1 :
    request_2 ? REQ_2 :
    request_3 ? REQ_3 :
    request_4 ? REQ_4 :
    request_5 ? REQ_5 :
    request_6 ? REQ_6 :
    request_7 ? REQ_7 :
    REQ_NONE;

  wire [7:0] chosen = busy_reg ? locked_request : next_request;
  wire       no_request_chosen = chosen == REQ_NONE;
  wire       selected_read =
    (chosen[1] & io_in_1_rd) |
    (chosen[2] & io_in_2_rd) |
    (chosen[3] & io_in_3_rd) |
    (chosen[4] & io_in_4_rd) |
    (chosen[5] & io_in_5_rd) |
    (chosen[6] & io_in_6_rd) |
    (chosen[7] & io_in_7_rd);
  wire       selected_write = (chosen[0] & io_in_0_wr) | (chosen[2] & io_in_2_wr);
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

  assign io_in_0_wait_n = (no_request_chosen | chosen[0]) & io_out_wait_n;
  assign io_in_0_burstDone = chosen[0] & io_out_burstDone;
  assign io_in_1_dout = io_out_dout;
  assign io_in_1_wait_n = (no_request_chosen | chosen[1]) & io_out_wait_n;
  assign io_in_1_valid = chosen[1] & io_out_valid;
  assign io_in_2_dout = io_out_dout;
  assign io_in_2_wait_n = (no_request_chosen | chosen[2]) & io_out_wait_n;
  assign io_in_2_valid = chosen[2] & io_out_valid;
  assign io_in_3_dout = io_out_dout;
  assign io_in_3_wait_n = (no_request_chosen | chosen[3]) & io_out_wait_n;
  assign io_in_3_valid = chosen[3] & io_out_valid;
  assign io_in_4_dout = io_out_dout;
  assign io_in_4_wait_n = (no_request_chosen | chosen[4]) & io_out_wait_n;
  assign io_in_4_valid = chosen[4] & io_out_valid;
  assign io_in_5_dout = io_out_dout;
  assign io_in_5_wait_n = (no_request_chosen | chosen[5]) & io_out_wait_n;
  assign io_in_5_valid = chosen[5] & io_out_valid;
  assign io_in_6_dout = io_out_dout;
  assign io_in_6_wait_n = (no_request_chosen | chosen[6]) & io_out_wait_n;
  assign io_in_6_valid = chosen[6] & io_out_valid;
  assign io_in_7_dout = io_out_dout;
  assign io_in_7_wait_n = (no_request_chosen | chosen[7]) & io_out_wait_n;
  assign io_in_7_valid = chosen[7] & io_out_valid;
  assign io_out_rd = selected_read;
  assign io_out_wr = selected_write;
  assign io_out_addr =
    (chosen[0] ? io_in_0_addr : 25'h0) |
    (chosen[1] ? io_in_1_addr : 25'h0) |
    (chosen[2] ? io_in_2_addr : 25'h0) |
    (chosen[3] ? io_in_3_addr : 25'h0) |
    (chosen[4] ? io_in_4_addr : 25'h0) |
    (chosen[5] ? io_in_5_addr : 25'h0) |
    (chosen[6] ? io_in_6_addr : 25'h0) |
    (chosen[7] ? io_in_7_addr : 25'h0);
  assign io_out_din =
    (chosen[0] ? io_in_0_din : 16'h0) |
    (chosen[2] ? io_in_2_din : 16'h0);
endmodule
