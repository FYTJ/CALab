module Div( // @[src/main/scala/DIV/DIV.scala 44:7]
  input         clock, // @[src/main/scala/DIV/DIV.scala 44:7]
  input         reset, // @[src/main/scala/DIV/DIV.scala 44:7]
  output        io_in_ready, // @[src/main/scala/DIV/DIV.scala 45:16]
  input         io_in_valid, // @[src/main/scala/DIV/DIV.scala 45:16]
  input  [1:0]  io_in_bits_divOp, // @[src/main/scala/DIV/DIV.scala 45:16]
  input  [31:0] io_in_bits_dividend, // @[src/main/scala/DIV/DIV.scala 45:16]
  input  [31:0] io_in_bits_divisor, // @[src/main/scala/DIV/DIV.scala 45:16]
  input         io_out_ready, // @[src/main/scala/DIV/DIV.scala 45:16]
  output        io_out_valid, // @[src/main/scala/DIV/DIV.scala 45:16]
  output [31:0] io_out_bits_quotient, // @[src/main/scala/DIV/DIV.scala 45:16]
  output [31:0] io_out_bits_remainder // @[src/main/scala/DIV/DIV.scala 45:16]
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [63:0] _RAND_4;
`endif // RANDOMIZE_REG_INIT
  reg [5:0] clk_counter; // @[src/main/scala/DIV/DIV.scala 49:30]
  reg  status; // @[src/main/scala/DIV/DIV.scala 50:25]
  wire  _abs_dividend_T_2 = io_in_bits_divOp == 2'h0 | io_in_bits_divOp == 2'h2; // @[src/main/scala/DIV/DIV.scala 52:59]
  wire  abs_dividend_sign = io_in_bits_dividend[31]; // @[src/main/scala/DIV/DIV.scala 31:25]
  wire [31:0] _abs_dividend_T_4 = 32'h0 - io_in_bits_dividend; // @[src/main/scala/DIV/DIV.scala 32:19]
  wire [31:0] _abs_dividend_T_5 = abs_dividend_sign ? _abs_dividend_T_4 : io_in_bits_dividend; // @[src/main/scala/DIV/DIV.scala 32:12]
  wire [31:0] abs_dividend = io_in_bits_divOp == 2'h0 | io_in_bits_divOp == 2'h2 ? _abs_dividend_T_5 :
    io_in_bits_dividend; // @[src/main/scala/DIV/DIV.scala 52:27]
  wire  abs_divisor_sign = io_in_bits_divisor[31]; // @[src/main/scala/DIV/DIV.scala 31:25]
  wire [31:0] _abs_divisor_T_4 = 32'h0 - io_in_bits_divisor; // @[src/main/scala/DIV/DIV.scala 32:19]
  wire [31:0] _abs_divisor_T_5 = abs_divisor_sign ? _abs_divisor_T_4 : io_in_bits_divisor; // @[src/main/scala/DIV/DIV.scala 32:12]
  wire [31:0] abs_divisor = _abs_dividend_T_2 ? _abs_divisor_T_5 : io_in_bits_divisor; // @[src/main/scala/DIV/DIV.scala 53:26]
  wire  sign_dividend = _abs_dividend_T_2 & abs_dividend_sign; // @[src/main/scala/DIV/DIV.scala 54:28]
  wire  sign_divisor = _abs_dividend_T_2 & abs_divisor_sign; // @[src/main/scala/DIV/DIV.scala 55:27]
  wire  sign_quotient = sign_dividend ^ sign_divisor; // @[src/main/scala/DIV/DIV.scala 56:39]
  reg [31:0] num_quotient; // @[src/main/scala/DIV/DIV.scala 58:31]
  reg [31:0] num_remainder; // @[src/main/scala/DIV/DIV.scala 59:32]
  wire [63:0] zext_dividend = {32'h0,abs_dividend}; // @[src/main/scala/DIV/DIV.scala 27:12]
  wire [32:0] zext_divisor = {1'h0,abs_divisor}; // @[src/main/scala/DIV/DIV.scala 27:12]
  reg [32:0] new_dividend; // @[src/main/scala/DIV/DIV.scala 70:31]
  wire  _T = io_in_ready & io_in_valid; // @[src/main/scala/chisel3/util/Decoupled.scala 51:35]
  wire [31:0] _num_quotient_T = sign_quotient ? 32'h1 : 32'hffffffff; // @[src/main/scala/DIV/DIV.scala 76:32]
  wire  _num_remainder_T_3 = _abs_dividend_T_2 & sign_dividend; // @[src/main/scala/DIV/DIV.scala 77:101]
  wire [31:0] _num_remainder_T_4 = ~io_in_bits_dividend; // @[src/main/scala/DIV/DIV.scala 77:121]
  wire [31:0] _num_remainder_T_6 = _num_remainder_T_4 + 32'h1; // @[src/main/scala/DIV/DIV.scala 77:142]
  wire [31:0] _GEN_1 = abs_divisor == 32'h0 ? _num_quotient_T : num_quotient; // @[src/main/scala/DIV/DIV.scala 73:36 76:26 58:31]
  wire [32:0] sub = new_dividend - zext_divisor; // @[src/main/scala/DIV/DIV.scala 64:28]
  wire  quotient_bit = ~sub[32]; // @[src/main/scala/DIV/DIV.scala 65:37]
  wire [31:0] remainder = quotient_bit ? sub[31:0] : new_dividend[31:0]; // @[src/main/scala/DIV/DIV.scala 66:28]
  wire [5:0] _num_quotient_T_2 = 6'h1f - clk_counter; // @[src/main/scala/DIV/DIV.scala 86:62]
  wire [63:0] _GEN_19 = {{63'd0}, quotient_bit}; // @[src/main/scala/DIV/DIV.scala 86:53]
  wire [63:0] _num_quotient_T_3 = _GEN_19 << _num_quotient_T_2; // @[src/main/scala/DIV/DIV.scala 86:53]
  wire [63:0] _GEN_17 = {{32'd0}, num_quotient}; // @[src/main/scala/DIV/DIV.scala 86:38]
  wire [63:0] _num_quotient_T_4 = _GEN_17 | _num_quotient_T_3; // @[src/main/scala/DIV/DIV.scala 86:38]
  wire [5:0] _new_dividend_T_5 = 6'h1e - clk_counter; // @[src/main/scala/DIV/DIV.scala 88:97]
  wire [63:0] _new_dividend_T_6 = zext_dividend >> _new_dividend_T_5; // @[src/main/scala/DIV/DIV.scala 88:91]
  wire [32:0] _new_dividend_T_8 = {remainder,_new_dividend_T_6[0]}; // @[src/main/scala/DIV/DIV.scala 88:59]
  wire [5:0] _clk_counter_T_1 = clk_counter + 6'h1; // @[src/main/scala/DIV/DIV.scala 89:36]
  wire  _T_4 = io_out_ready & io_out_valid; // @[src/main/scala/chisel3/util/Decoupled.scala 51:35]
  wire [31:0] _GEN_6 = clk_counter == 6'h20 & _T_4 ? 32'h0 : num_quotient; // @[src/main/scala/DIV/DIV.scala 90:54 92:22 58:31]
  wire [63:0] _GEN_7 = clk_counter < 6'h20 ? _num_quotient_T_4 : {{32'd0}, _GEN_6}; // @[src/main/scala/DIV/DIV.scala 84:37 86:22]
  wire [63:0] _GEN_13 = _T ? {{32'd0}, _GEN_1} : _GEN_7; // @[src/main/scala/DIV/DIV.scala 72:23]
  wire [31:0] _io_out_bits_quotient_T_4 = ~num_quotient; // @[src/main/scala/DIV/DIV.scala 97:119]
  wire [31:0] _io_out_bits_quotient_T_6 = _io_out_bits_quotient_T_4 + 32'h1; // @[src/main/scala/DIV/DIV.scala 97:133]
  wire [31:0] _io_out_bits_remainder_T_4 = ~num_remainder; // @[src/main/scala/DIV/DIV.scala 98:121]
  wire [31:0] _io_out_bits_remainder_T_6 = _io_out_bits_remainder_T_4 + 32'h1; // @[src/main/scala/DIV/DIV.scala 98:136]
  wire [63:0] _GEN_18 = reset ? 64'h0 : _GEN_13; // @[src/main/scala/DIV/DIV.scala 58:{31,31}]
  assign io_in_ready = ~status; // @[src/main/scala/DIV/DIV.scala 95:27]
  assign io_out_valid = clk_counter == 6'h20; // @[src/main/scala/DIV/DIV.scala 96:33]
  assign io_out_bits_quotient = _abs_dividend_T_2 & sign_quotient ? _io_out_bits_quotient_T_6 : num_quotient; // @[src/main/scala/DIV/DIV.scala 97:32]
  assign io_out_bits_remainder = _num_remainder_T_3 ? _io_out_bits_remainder_T_6 : num_remainder; // @[src/main/scala/DIV/DIV.scala 98:33]
  always @(posedge clock) begin
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 49:30]
      clk_counter <= 6'h0; // @[src/main/scala/DIV/DIV.scala 49:30]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 72:23]
      if (abs_divisor == 32'h0) begin // @[src/main/scala/DIV/DIV.scala 73:36]
        clk_counter <= 6'h20; // @[src/main/scala/DIV/DIV.scala 75:25]
      end else begin
        clk_counter <= 6'h0; // @[src/main/scala/DIV/DIV.scala 80:25]
      end
    end else if (clk_counter < 6'h20) begin // @[src/main/scala/DIV/DIV.scala 84:37]
      clk_counter <= _clk_counter_T_1; // @[src/main/scala/DIV/DIV.scala 89:21]
    end
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 50:25]
      status <= 1'h0; // @[src/main/scala/DIV/DIV.scala 50:25]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 72:23]
      if (abs_divisor == 32'h0) begin // @[src/main/scala/DIV/DIV.scala 73:36]
        status <= 1'h0; // @[src/main/scala/DIV/DIV.scala 78:20]
      end else begin
        status <= 1'h1; // @[src/main/scala/DIV/DIV.scala 81:20]
      end
    end else if (!(clk_counter < 6'h20)) begin // @[src/main/scala/DIV/DIV.scala 84:37]
      if (clk_counter == 6'h20 & _T_4) begin // @[src/main/scala/DIV/DIV.scala 90:54]
        status <= 1'h0; // @[src/main/scala/DIV/DIV.scala 91:16]
      end
    end
    num_quotient <= _GEN_18[31:0]; // @[src/main/scala/DIV/DIV.scala 58:{31,31}]
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 59:32]
      num_remainder <= 32'h0; // @[src/main/scala/DIV/DIV.scala 59:32]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 72:23]
      if (abs_divisor == 32'h0) begin // @[src/main/scala/DIV/DIV.scala 73:36]
        if (_abs_dividend_T_2 & sign_dividend) begin // @[src/main/scala/DIV/DIV.scala 77:33]
          num_remainder <= _num_remainder_T_6;
        end else begin
          num_remainder <= io_in_bits_dividend;
        end
      end
    end else if (clk_counter < 6'h20) begin // @[src/main/scala/DIV/DIV.scala 84:37]
      if (quotient_bit) begin // @[src/main/scala/DIV/DIV.scala 66:28]
        num_remainder <= sub[31:0];
      end else begin
        num_remainder <= new_dividend[31:0];
      end
    end
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 70:31]
      new_dividend <= zext_dividend[63:31]; // @[src/main/scala/DIV/DIV.scala 70:31]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 72:23]
      if (!(abs_divisor == 32'h0)) begin // @[src/main/scala/DIV/DIV.scala 73:36]
        new_dividend <= zext_dividend[63:31]; // @[src/main/scala/DIV/DIV.scala 82:26]
      end
    end else if (clk_counter < 6'h20) begin // @[src/main/scala/DIV/DIV.scala 84:37]
      if (clk_counter == 6'h1f) begin // @[src/main/scala/DIV/DIV.scala 88:28]
        new_dividend <= 33'h0;
      end else begin
        new_dividend <= _new_dividend_T_8;
      end
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  clk_counter = _RAND_0[5:0];
  _RAND_1 = {1{`RANDOM}};
  status = _RAND_1[0:0];
  _RAND_2 = {1{`RANDOM}};
  num_quotient = _RAND_2[31:0];
  _RAND_3 = {1{`RANDOM}};
  num_remainder = _RAND_3[31:0];
  _RAND_4 = {2{`RANDOM}};
  new_dividend = _RAND_4[32:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
