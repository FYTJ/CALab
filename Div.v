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
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [63:0] _RAND_7;
`endif // RANDOMIZE_REG_INIT
  reg [31:0] dividend; // @[src/main/scala/DIV/DIV.scala 53:27]
  reg [31:0] divisor; // @[src/main/scala/DIV/DIV.scala 54:26]
  reg [3:0] divOp; // @[src/main/scala/DIV/DIV.scala 55:24]
  reg [5:0] clk_counter; // @[src/main/scala/DIV/DIV.scala 57:30]
  reg  status; // @[src/main/scala/DIV/DIV.scala 58:25]
  wire  _abs_dividend_T_2 = divOp == 4'h1 | divOp == 4'h4; // @[src/main/scala/DIV/DIV.scala 61:45]
  wire  abs_dividend_sign = dividend[31]; // @[src/main/scala/DIV/DIV.scala 31:25]
  wire [31:0] _abs_dividend_T_4 = 32'h0 - dividend; // @[src/main/scala/DIV/DIV.scala 32:19]
  wire [31:0] _abs_dividend_T_5 = abs_dividend_sign ? _abs_dividend_T_4 : dividend; // @[src/main/scala/DIV/DIV.scala 32:12]
  wire [31:0] abs_dividend = divOp == 4'h1 | divOp == 4'h4 ? _abs_dividend_T_5 : dividend; // @[src/main/scala/DIV/DIV.scala 61:24]
  wire  abs_divisor_sign = divisor[31]; // @[src/main/scala/DIV/DIV.scala 31:25]
  wire [31:0] _abs_divisor_T_4 = 32'h0 - divisor; // @[src/main/scala/DIV/DIV.scala 32:19]
  wire [31:0] _abs_divisor_T_5 = abs_divisor_sign ? _abs_divisor_T_4 : divisor; // @[src/main/scala/DIV/DIV.scala 32:12]
  wire [31:0] abs_divisor = _abs_dividend_T_2 ? _abs_divisor_T_5 : divisor; // @[src/main/scala/DIV/DIV.scala 63:23]
  wire  sign_dividend = _abs_dividend_T_2 & abs_dividend_sign; // @[src/main/scala/DIV/DIV.scala 65:25]
  wire  sign_divisor = _abs_dividend_T_2 & abs_divisor_sign; // @[src/main/scala/DIV/DIV.scala 67:24]
  wire  sign_quotient = sign_dividend ^ sign_divisor; // @[src/main/scala/DIV/DIV.scala 69:36]
  reg [31:0] num_quotient; // @[src/main/scala/DIV/DIV.scala 72:31]
  reg [31:0] num_remainder; // @[src/main/scala/DIV/DIV.scala 73:32]
  wire [63:0] zext_dividend = {32'h0,abs_dividend}; // @[src/main/scala/DIV/DIV.scala 27:12]
  wire [32:0] zext_divisor = {1'h0,abs_divisor}; // @[src/main/scala/DIV/DIV.scala 27:12]
  reg [32:0] new_dividend; // @[src/main/scala/DIV/DIV.scala 88:31]
  wire  _T = io_in_ready & io_in_valid; // @[src/main/scala/chisel3/util/Decoupled.scala 51:35]
  wire  zext_in_dividend_sign = io_in_bits_dividend[31]; // @[src/main/scala/DIV/DIV.scala 31:25]
  wire [31:0] _zext_in_dividend_T_4 = 32'h0 - io_in_bits_dividend; // @[src/main/scala/DIV/DIV.scala 32:19]
  wire [31:0] _zext_in_dividend_T_5 = zext_in_dividend_sign ? _zext_in_dividend_T_4 : io_in_bits_dividend; // @[src/main/scala/DIV/DIV.scala 32:12]
  wire [31:0] _zext_in_dividend_T_6 = io_in_bits_divOp == 4'h1 | io_in_bits_divOp == 4'h4 ? _zext_in_dividend_T_5 :
    io_in_bits_dividend; // @[src/main/scala/DIV/DIV.scala 97:46]
  wire [63:0] zext_in_dividend = {32'h0,_zext_in_dividend_T_6}; // @[src/main/scala/DIV/DIV.scala 27:12]
  wire [31:0] _num_quotient_T = sign_quotient ? 32'h1 : 32'hffffffff; // @[src/main/scala/DIV/DIV.scala 102:32]
  wire  _num_remainder_T_3 = _abs_dividend_T_2 & sign_dividend; // @[src/main/scala/DIV/DIV.scala 103:79]
  wire [31:0] _num_remainder_T_4 = ~dividend; // @[src/main/scala/DIV/DIV.scala 103:99]
  wire [31:0] _num_remainder_T_6 = _num_remainder_T_4 + 32'h1; // @[src/main/scala/DIV/DIV.scala 103:109]
  wire [31:0] _num_remainder_T_7 = _abs_dividend_T_2 & sign_dividend ? _num_remainder_T_6 : dividend; // @[src/main/scala/DIV/DIV.scala 103:33]
  wire [32:0] sub = new_dividend - zext_divisor; // @[src/main/scala/DIV/DIV.scala 81:25]
  wire  quotient_bit = ~sub[32]; // @[src/main/scala/DIV/DIV.scala 82:37]
  wire [31:0] remainder = quotient_bit ? sub[31:0] : new_dividend[31:0]; // @[src/main/scala/DIV/DIV.scala 84:25]
  wire [5:0] _num_quotient_T_2 = 6'h1f - clk_counter; // @[src/main/scala/DIV/DIV.scala 106:66]
  wire [63:0] _GEN_22 = {{63'd0}, quotient_bit}; // @[src/main/scala/DIV/DIV.scala 106:57]
  wire [63:0] _num_quotient_T_3 = _GEN_22 << _num_quotient_T_2; // @[src/main/scala/DIV/DIV.scala 106:57]
  wire [63:0] _GEN_20 = {{32'd0}, num_quotient}; // @[src/main/scala/DIV/DIV.scala 106:42]
  wire [63:0] _num_quotient_T_4 = _GEN_20 | _num_quotient_T_3; // @[src/main/scala/DIV/DIV.scala 106:42]
  wire [5:0] _new_dividend_T_4 = 6'h1e - clk_counter; // @[src/main/scala/DIV/DIV.scala 108:101]
  wire [63:0] _new_dividend_T_5 = zext_dividend >> _new_dividend_T_4; // @[src/main/scala/DIV/DIV.scala 108:95]
  wire [32:0] _new_dividend_T_7 = {remainder,_new_dividend_T_5[0]}; // @[src/main/scala/DIV/DIV.scala 108:63]
  wire [32:0] _new_dividend_T_8 = clk_counter == 6'h1f ? 33'h0 : _new_dividend_T_7; // @[src/main/scala/DIV/DIV.scala 108:32]
  wire [5:0] _clk_counter_T_1 = clk_counter + 6'h1; // @[src/main/scala/DIV/DIV.scala 109:40]
  wire [63:0] _GEN_1 = divisor == 32'h0 ? {{32'd0}, _num_quotient_T} : _num_quotient_T_4; // @[src/main/scala/DIV/DIV.scala 100:32 102:26 106:26]
  wire  _T_5 = clk_counter == 6'h20; // @[src/main/scala/DIV/DIV.scala 111:29]
  wire  _T_6 = io_out_ready & io_out_valid; // @[src/main/scala/chisel3/util/Decoupled.scala 51:35]
  wire  _GEN_4 = clk_counter == 6'h20 & _T_6 ? 1'h0 : status; // @[src/main/scala/DIV/DIV.scala 111:54 112:16 58:25]
  wire [31:0] _GEN_6 = clk_counter == 6'h20 & _T_6 ? 32'h0 : num_quotient; // @[src/main/scala/DIV/DIV.scala 111:54 114:22 72:31]
  wire [63:0] _GEN_8 = clk_counter < 6'h20 & status ? _GEN_1 : {{32'd0}, _GEN_6}; // @[src/main/scala/DIV/DIV.scala 99:63]
  wire  _GEN_11 = clk_counter < 6'h20 & status ? status : _GEN_4; // @[src/main/scala/DIV/DIV.scala 58:25 99:63]
  wire  _GEN_12 = _T | _GEN_11; // @[src/main/scala/DIV/DIV.scala 90:23 91:16]
  wire [63:0] _GEN_18 = _T ? {{32'd0}, num_quotient} : _GEN_8; // @[src/main/scala/DIV/DIV.scala 90:23 72:31]
  wire [31:0] _io_out_bits_quotient_T_4 = ~num_quotient; // @[src/main/scala/DIV/DIV.scala 119:97]
  wire [31:0] _io_out_bits_quotient_T_6 = _io_out_bits_quotient_T_4 + 32'h1; // @[src/main/scala/DIV/DIV.scala 119:111]
  wire [31:0] _io_out_bits_remainder_T_4 = ~num_remainder; // @[src/main/scala/DIV/DIV.scala 120:99]
  wire [31:0] _io_out_bits_remainder_T_6 = _io_out_bits_remainder_T_4 + 32'h1; // @[src/main/scala/DIV/DIV.scala 120:114]
  wire [63:0] _GEN_21 = reset ? 64'h0 : _GEN_18; // @[src/main/scala/DIV/DIV.scala 72:{31,31}]
  assign io_in_ready = ~status; // @[src/main/scala/DIV/DIV.scala 117:27]
  assign io_out_valid = _T_5 & status; // @[src/main/scala/DIV/DIV.scala 118:44]
  assign io_out_bits_quotient = _abs_dividend_T_2 & sign_quotient ? _io_out_bits_quotient_T_6 : num_quotient; // @[src/main/scala/DIV/DIV.scala 119:32]
  assign io_out_bits_remainder = _num_remainder_T_3 ? _io_out_bits_remainder_T_6 : num_remainder; // @[src/main/scala/DIV/DIV.scala 120:33]
  always @(posedge clock) begin
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 53:27]
      dividend <= 32'h0; // @[src/main/scala/DIV/DIV.scala 53:27]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 90:23]
      dividend <= io_in_bits_dividend; // @[src/main/scala/DIV/DIV.scala 92:18]
    end
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 54:26]
      divisor <= 32'h0; // @[src/main/scala/DIV/DIV.scala 54:26]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 90:23]
      divisor <= io_in_bits_divisor; // @[src/main/scala/DIV/DIV.scala 93:17]
    end
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 55:24]
      divOp <= 4'h1; // @[src/main/scala/DIV/DIV.scala 55:24]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 90:23]
      divOp <= io_in_bits_divOp; // @[src/main/scala/DIV/DIV.scala 94:15]
    end
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 57:30]
      clk_counter <= 6'h0; // @[src/main/scala/DIV/DIV.scala 57:30]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 90:23]
      clk_counter <= 6'h0; // @[src/main/scala/DIV/DIV.scala 95:21]
    end else if (clk_counter < 6'h20 & status) begin // @[src/main/scala/DIV/DIV.scala 99:63]
      if (divisor == 32'h0) begin // @[src/main/scala/DIV/DIV.scala 100:32]
        clk_counter <= 6'h20; // @[src/main/scala/DIV/DIV.scala 101:25]
      end else begin
        clk_counter <= _clk_counter_T_1; // @[src/main/scala/DIV/DIV.scala 109:25]
      end
    end else if (clk_counter == 6'h20 & _T_6) begin // @[src/main/scala/DIV/DIV.scala 111:54]
      clk_counter <= 6'h0; // @[src/main/scala/DIV/DIV.scala 113:21]
    end
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 58:25]
      status <= 1'h0; // @[src/main/scala/DIV/DIV.scala 58:25]
    end else begin
      status <= _GEN_12;
    end
    num_quotient <= _GEN_21[31:0]; // @[src/main/scala/DIV/DIV.scala 72:{31,31}]
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 73:32]
      num_remainder <= 32'h0; // @[src/main/scala/DIV/DIV.scala 73:32]
    end else if (!(_T)) begin // @[src/main/scala/DIV/DIV.scala 90:23]
      if (clk_counter < 6'h20 & status) begin // @[src/main/scala/DIV/DIV.scala 99:63]
        if (divisor == 32'h0) begin // @[src/main/scala/DIV/DIV.scala 100:32]
          num_remainder <= _num_remainder_T_7; // @[src/main/scala/DIV/DIV.scala 103:27]
        end else begin
          num_remainder <= remainder; // @[src/main/scala/DIV/DIV.scala 107:27]
        end
      end
    end
    if (reset) begin // @[src/main/scala/DIV/DIV.scala 88:31]
      new_dividend <= 33'h0; // @[src/main/scala/DIV/DIV.scala 88:31]
    end else if (_T) begin // @[src/main/scala/DIV/DIV.scala 90:23]
      new_dividend <= zext_in_dividend[63:31]; // @[src/main/scala/DIV/DIV.scala 98:22]
    end else if (clk_counter < 6'h20 & status) begin // @[src/main/scala/DIV/DIV.scala 99:63]
      if (!(divisor == 32'h0)) begin // @[src/main/scala/DIV/DIV.scala 100:32]
        new_dividend <= _new_dividend_T_8; // @[src/main/scala/DIV/DIV.scala 108:26]
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
  dividend = _RAND_0[31:0];
  _RAND_1 = {1{`RANDOM}};
  divisor = _RAND_1[31:0];
  _RAND_2 = {1{`RANDOM}};
  divOp = _RAND_2[3:0];
  _RAND_3 = {1{`RANDOM}};
  clk_counter = _RAND_3[5:0];
  _RAND_4 = {1{`RANDOM}};
  status = _RAND_4[0:0];
  _RAND_5 = {1{`RANDOM}};
  num_quotient = _RAND_5[31:0];
  _RAND_6 = {1{`RANDOM}};
  num_remainder = _RAND_6[31:0];
  _RAND_7 = {2{`RANDOM}};
  new_dividend = _RAND_7[32:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
