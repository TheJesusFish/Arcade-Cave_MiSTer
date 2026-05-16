module AsyncReadMemArbiter(
  input         clock,
  input         reset,
  input         io_in_0_rd,
  input  [24:0] io_in_0_addr,
  output [7:0]  io_in_0_dout,
  output        io_in_0_valid,
  input         io_in_1_rd,
  input  [24:0] io_in_1_addr,
  output [7:0]  io_in_1_dout,
  output        io_in_1_wait_n,
  output        io_in_1_valid,
  input         io_in_2_rd,
  input  [24:0] io_in_2_addr,
  output [7:0]  io_in_2_dout,
  input         io_in_3_rd,
  input  [24:0] io_in_3_addr,
  output [7:0]  io_in_3_dout,
  output        io_out_rd,
  output [24:0] io_out_addr,
  input  [7:0]  io_out_dout,
  input         io_out_wait_n,
  input         io_out_valid
);

  localparam [3:0] REQ_NONE = 4'b0000;
  localparam [3:0] REQ_0    = 4'b0001;
  localparam [3:0] REQ_1    = 4'b0010;
  localparam [3:0] REQ_2    = 4'b0100;
  localparam [3:0] REQ_3    = 4'b1000;

  reg        read_busy;
  reg [3:0]  locked_request;

  wire [3:0] next_request =
    io_in_0_rd ? REQ_0 :
    io_in_1_rd ? REQ_1 :
    io_in_2_rd ? REQ_2 :
    io_in_3_rd ? REQ_3 :
    REQ_NONE;

  wire [3:0] chosen = read_busy ? locked_request : next_request;
  wire       no_request_chosen = chosen == REQ_NONE;
  wire       selected_read =
    (chosen[0] & io_in_0_rd) |
    (chosen[1] & io_in_1_rd) |
    (chosen[2] & io_in_2_rd) |
    (chosen[3] & io_in_3_rd);
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
  assign io_in_0_valid = chosen[0] & io_out_valid;
  assign io_in_1_dout = io_out_dout;
  assign io_in_1_wait_n = (no_request_chosen | chosen[1]) & io_out_wait_n;
  assign io_in_1_valid = chosen[1] & io_out_valid;
  assign io_in_2_dout = io_out_dout;
  assign io_in_3_dout = io_out_dout;
  assign io_out_rd = selected_read;
  assign io_out_addr =
    (chosen[0] ? io_in_0_addr : 25'h0) |
    (chosen[1] ? io_in_1_addr : 25'h0) |
    (chosen[2] ? io_in_2_addr : 25'h0) |
    (chosen[3] ? io_in_3_addr : 25'h0);
endmodule
