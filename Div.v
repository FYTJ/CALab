module Div( // @[src/main/scala/DIV/DIV.scala 47:7]
  input         clock, // @[src/main/scala/DIV/DIV.scala 47:7]
  input         reset, // @[src/main/scala/DIV/DIV.scala 47:7]
  output        io_in_ready, // @[src/main/scala/DIV/DIV.scala 48:16]
  input         io_in_valid, // @[src/main/scala/DIV/DIV.scala 48:16]
  input  [3:0]  io_in_bits_divOp, // @[src/main/scala/DIV/DIV.scala 48:16]
  input  [31:0] io_in_bits_dividend, // @[src/main/scala/DIV/DIV.scala 48:16]
  input  [31:0] io_in_bits_divisor, // @[src/main/scala/DIV/DIV.scala 48:16]
  input         io_out_ready, // @[src/main/scala/DIV/DIV.scala 48:16]
  output        io_out_valid, // @[src/main/scala/DIV/DIV.scala 48:16]
  output [31:0] io_out_bits_quotient, // @[src/main/scala/DIV/DIV.scala 48:16]
  output [31:0] io_out_bits_remainder // @[src/main/scala/DIV/DIV.scala 48:16]
);
  reg [5:0] clk_counter; // @[src/main/scala/DIV/DIV.scala 52:30]
  reg  status; // @[src/main/scala/DIV/DIV.scala 53:25]
  wire  _abs_dividend_T_2 = io_in_bits_divOp == 4'h1 | io_in_bits_divOp == 4'h4; // @[src/main/scala/DIV/DIV.scala 56:56]
  wire  abs_dividend_sign = io_in_bits_dividend[31]; // @[src/main/scala/DIV/DIV.scala 31:25]
  wire [31:0] _abs_dividend_T_4 = 32'h0 - io_in_bits_dividend; // @[src/main/scala/DIV/DIV.scala 32:19]
  wire [31:0] _abs_dividend_T_5 = abs_dividend_sign ? _abs_dividend_T_4 : io_in_bits_dividend; // @[src/main/scala/DIV/DIV.scala 32:12]
  wire [31:0] abs_dividend = io_in_bits_divOp == 4'h1 | io_in_bits_divOp == 4'h4 ? _abs_dividend_T_5 :
    io_in_bits_dividend; // @[src/main/scala/DIV/DIV.scala 56:24]
  wire  abs_divisor_sign = io_in_bits_divisor[31]; // @[src/main/scala/DIV/DIV.scala 31:25]
  wire [31:0] _abs_divisor_T_4 = 32'h0 - io_in_bits_divisor; // @[src/main/scala/DIV/DIV.scala 32:19]
  wire [31:0] _abs_divisor_T_5 = abs_divisor_sign ? _abs_divisor_T_4 : io_in_bits_divisor; // @[src/main/scala/DIV/DIV.scala 32:12]
  wire [31:0] abs_divisor = _abs_dividend_T_2 ? _abs_divisor_T_5 : io_in_bits_divisor; // @[src/main/scala/DIV/DIV.scala 58:23]
  wire  sign_dividend = _abs_dividend_T_2 & abs_dividend_sign; // @[src/main/scala/DIV/DIV.scala 60:25]
  wire  sign_divisor = _abs_dividend_T_2 & abs_divisor_sign; // @[src/main/scala/DIV/DIV.scala 62:24]
  wire  sign_quotient = sign_dividend ^ sign_divisor; // @[src/main/scala/DIV/DIV.scala 64:36]
  reg [31:0] num_quotient; // @[src/main/scala/DIV/DIV.scala 67:31]
  reg [31:0] num_remainder; // @[src/main/scala/DIV/DIV.scala 68:32]
  wire [63:0] zext_dividend = {32'h0,abs_dividend}; // @[src/main/scala/DIV/DIV.scala 27:12]
  wire [32:0] zext_divisor = {1'h0,abs_divisor}; // @[src/main/scala/DIV/DIV.scala 27:12]
  reg [32:0] new_dividend; // @[src/main/scala/DIV/DIV.scala 83:31]
  wire  _T = io_in_ready & io_in_valid; // @[src/main/scala/chisel3/util/Decoupled.scala 51:35]
  wire [31:0] _num_quotient_T = sign_quotient ? 32'h1 : 32'hffffffff; // @[src/main/scala/DIV/DIV.scala 89:32]
  wire  _num_remainder_T_3 = _abs_dividend_T_2 & sign_dividend; // @[src/main/scala/DIV/DIV.scala 90:101]
  wire [31:0] _num_remainder_T_4 = ~io_in_bits_dividend; // @[src/main/scala/DIV/DIV.scala 90:121]
  wire [31:0] _num_remainder_T_6 = _num_remainder_T_4 + 32'h1; // @[src/main/scala/DIV/DIV.scala 90:142]
  wire [31:0] _GEN_1 = abs_divisor == 32'h0 ? _num_quotient_T : num_quotient; // @[src/main/scala/DIV/DIV.scala 86:36 89:26 67:31]
  wire [32:0] sub = new_dividend - zext_divisor; // @[src/main/scala/DIV/DIV.scala 76:25]
  wire  quotient_bit = ~sub[32]; // @[src/main/scala/DIV/DIV.scala 77:37]
  wire [31:0] remainder = quotient_bit ? sub[31:0] : new_dividend[31:0]; // @[src/main/scala/DIV/DIV.scala 79:25]
  wire [5:0] _num_quotient_T_2 = 6'h1f - clk_counter; // @[src/main/scala/DIV/DIV.scala 99:62]
  wire [63:0] _GEN_19 = {{63'd0}, quotient_bit}; // @[src/main/scala/DIV/DIV.scala 99:53]
  wire [63:0] _num_quotient_T_3 = _GEN_19 << _num_quotient_T_2; // @[src/main/scala/DIV/DIV.scala 99:53]
  wire [63:0] _GEN_17 = {{32'd0}, num_quotient}; // @[src/main/scala/DIV/DIV.scala 99:38]
  wire [63:0] _num_quotient_T_4 = _GEN_17 | _num_quotient_T_3; // @[src/main/scala/DIV/DIV.scala 99:38]
  wire [5:0] _new_dividend_T_5 = 6'h1e - clk_counter; // @[src/main/scala/DIV/DIV.scala 101:97]
  wire [63:0] _new_dividend_T_6 = zext_dividend >> _new_dividend_T_5; // @[src/main/scala/DIV/DIV.scala 101:91]
  wire [32:0] _new_dividend_T_8 = {remainder,_new_dividend_T_6[0]}; // @[src/main/scala/DIV/DIV.scala 101:59]
  wire [5:0] _clk_counter_T_1 = clk_counter + 6'h1; // @[src/main/scala/DIV/DIV.scala 102:36]
  wire  _T_4 = io_out_ready & io_out_valid; // @[src/main/scala/chisel3/util/Decoupled.scala 51:35]
  wire [31:0] _GEN_6 = clk_counter == 6'h20 & _T_4 ? 32'h0 : num_quotient; // @[src/main/scala/DIV/DIV.scala 103:54 105:22 67:31]
  wire [63:0] _GEN_7 = clk_counter < 6'h20 ? _num_quotient_T_4 : {{32'd0}, _GEN_6}; // @[src/main/scala/DIV/DIV.scala 97:37 99:22]
  wire [63:0] _GEN_13 = _T ? {{32'd0}, _GEN_1} : _GEN_7; // @[src/main/scala/DIV/DIV.scala 85:23]
  wire [31:0] _io_out_bits_quotient_T_4 = ~num_quotient; // @[src/main/scala/DIV/DIV.scala 110:119]
  wire [31:0] _io_out_bits_quotient_T_6 = _io_out_bits_quotient_T_4 + 32'h1; // @[src/main/scala/DIV/DIV.scala 110:133]
  wire [31:0] _io_out_bits_remainder_T_4 = ~num_remainder; // @[src/main/scala/DIV/DIV.scala 111:121]
  wire [31:0] _io_out_bits_remainder_T_6 = _io_out_bits_remainder_T_4 + 32'h1; // @[src/main/scala/DIV/DIV.scala 111:136]
  wire [63:0] _GEN_18 = reset ? 64'h0 : _GEN_13; // @[src/main/scala/DIV/DIV.scala 67:{31,31}]
  assign io_in_ready = ~status; // @[src/main/scala/DIV/DIV.scala 108:27]
  assign io_out_valid = clk_counter == 6'h20; // @[src/main/scala/DIV/DIV.scala 109:33]
  assign io_out_bits_quotient = _abs_dividend_T_2 & sign_quotient ? _io_out_bits_quotient_T_6 : num_quotient; // @[src/main/scala/DIV/DIV.scala 110:32]
  assign io_out_bits_remainder = _num_remainder_T_3 ? _io_out_bits_remainder_T_6 : num_remainder; // @[src/main/scala/DIV/DIV.scala 111:33]
  always @(posedge clock) begin
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 52:30]
      clk_counter <= 6'h0; // @[src/main/scala/DIV/DIV.scala 52:30]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 85:23]
      if (abs_divisor == 32'h0) begin // @[src/main/scala/DIV/DIV.scala 86:36]
        clk_counter <= 6'h20; // @[src/main/scala/DIV/DIV.scala 88:25]
      end else begin
        clk_counter <= 6'h0; // @[src/main/scala/DIV/DIV.scala 93:25]
      end
    end else if (clk_counter < 6'h20) begin // @[src/main/scala/DIV/DIV.scala 97:37]
      clk_counter <= _clk_counter_T_1; // @[src/main/scala/DIV/DIV.scala 102:21]
    end
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 53:25]
      status <= 1'h0; // @[src/main/scala/DIV/DIV.scala 53:25]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 85:23]
      if (abs_divisor == 32'h0) begin // @[src/main/scala/DIV/DIV.scala 86:36]
        status <= 1'h0; // @[src/main/scala/DIV/DIV.scala 91:20]
      end else begin
        status <= 1'h1; // @[src/main/scala/DIV/DIV.scala 94:20]
      end
    end else if (!(clk_counter < 6'h20)) begin // @[src/main/scala/DIV/DIV.scala 97:37]
      if (clk_counter == 6'h20 & _T_4) begin // @[src/main/scala/DIV/DIV.scala 103:54]
        status <= 1'h0; // @[src/main/scala/DIV/DIV.scala 104:16]
      end
    end
    num_quotient <= _GEN_18[31:0]; // @[src/main/scala/DIV/DIV.scala 67:{31,31}]
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 68:32]
      num_remainder <= 32'h0; // @[src/main/scala/DIV/DIV.scala 68:32]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 85:23]
      if (abs_divisor == 32'h0) begin // @[src/main/scala/DIV/DIV.scala 86:36]
        if (_abs_dividend_T_2 & sign_dividend) begin // @[src/main/scala/DIV/DIV.scala 90:33]
          num_remainder <= _num_remainder_T_6;
        end else begin
          num_remainder <= io_in_bits_dividend;
        end
      end
    end else if (clk_counter < 6'h20) begin // @[src/main/scala/DIV/DIV.scala 97:37]
      if (quotient_bit) begin // @[src/main/scala/DIV/DIV.scala 79:25]
        num_remainder <= sub[31:0];
      end else begin
        num_remainder <= new_dividend[31:0];
      end
    end
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 83:31]
      new_dividend <= zext_dividend[63:31]; // @[src/main/scala/DIV/DIV.scala 83:31]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 85:23]
      if (!(abs_divisor == 32'h0)) begin // @[src/main/scala/DIV/DIV.scala 86:36]
        new_dividend <= zext_dividend[63:31]; // @[src/main/scala/DIV/DIV.scala 95:26]
      end
    end else if (clk_counter < 6'h20) begin // @[src/main/scala/DIV/DIV.scala 97:37]
      if (clk_counter == 6'h1f) begin // @[src/main/scala/DIV/DIV.scala 101:28]
        new_dividend <= 33'h0;
      end else begin
        new_dividend <= _new_dividend_T_8;
      end
    end
  end
endmodule
