module AsyncMemArbiter(
  input         clock,
  input         reset,
  input         io_in_0_rd,
  input         io_in_0_wr,
  input  [6:0]  io_in_0_addr,
  input  [15:0] io_in_0_din,
  output [15:0] io_in_0_dout,
  output        io_in_0_wait_n,
  output        io_in_0_valid,
  input         io_in_1_rd,
  input         io_in_1_wr,
  input  [6:0]  io_in_1_addr,
  input  [15:0] io_in_1_din,
  output [15:0] io_in_1_dout,
  output        io_in_1_wait_n,
  output        io_in_1_valid,
  output        io_out_rd,
  output        io_out_wr,
  output [6:0]  io_out_addr,
  output [15:0] io_out_din,
  input  [15:0] io_out_dout,
  input         io_out_wait_n,
  input         io_out_valid
);

  localparam [1:0] REQ_NONE = 2'b00;
  localparam [1:0] REQ_0    = 2'b01;
  localparam [1:0] REQ_1    = 2'b10;

  reg        read_busy;
  reg [1:0]  locked_request;

  wire request_0 = io_in_0_rd | io_in_0_wr;
  wire request_1 = io_in_1_rd | io_in_1_wr;
  wire [1:0] next_request =
    request_0 ? REQ_0 :
    request_1 ? REQ_1 :
    REQ_NONE;

  wire [1:0] chosen = read_busy ? locked_request : next_request;
  wire       no_request_chosen = chosen == REQ_NONE;
  wire       selected_read = (chosen[0] & io_in_0_rd) | (chosen[1] & io_in_1_rd);
  wire       selected_write = (chosen[0] & io_in_0_wr) | (chosen[1] & io_in_1_wr);
  wire       accepted_read = ~read_busy & selected_read & io_out_wait_n;

  always @(posedge clock) begin
    if (reset) begin
      read_busy <= 1'b0;
      locked_request <= REQ_NONE;
    end
    else begin
      read_busy <= ~io_out_valid & (accepted_read | read_busy);
      if (accepted_read & ~io_out_valid)
        locked_request <= next_request;
    end
  end // always @(posedge)

  assign io_in_0_dout = io_out_dout;
  assign io_in_0_wait_n = (no_request_chosen | chosen[0]) & io_out_wait_n;
  assign io_in_0_valid = chosen[0] & io_out_valid;
  assign io_in_1_dout = io_out_dout;
  assign io_in_1_wait_n = (no_request_chosen | chosen[1]) & io_out_wait_n;
  assign io_in_1_valid = chosen[1] & io_out_valid;
  assign io_out_rd = selected_read;
  assign io_out_wr = selected_write;
  assign io_out_addr =
    (chosen[0] ? io_in_0_addr : 7'h0) |
    (chosen[1] ? io_in_1_addr : 7'h0);
  assign io_out_din =
    (chosen[0] ? io_in_0_din : 16'h0) |
    (chosen[1] ? io_in_1_din : 16'h0);
endmodule
