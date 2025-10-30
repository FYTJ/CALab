module MEM (
    input clk,
	input rst,

    input in_valid,
    input out_ready,
    output in_ready,
    output reg out_valid,
    input valid,

    input [63: 0] mul_result,

    output to_mul_resp_ready,
    output to_div_resp_ready,
    input from_mul_resp_valid,
    input from_div_resp_valid,
    input [31: 0] div_quotient,
    input [31: 0] div_remainder,

    input [31: 0] result,
    input [31: 0] PC,
    input [7: 0] mem_op,
    input [2: 0] mul_op,
	input [3: 0] div_op,
    input res_from_mul,
	input res_from_div,
    input res_from_mem,
    input res_from_csr,
    input gr_we,
    input mem_we,
    input [4: 0] dest,
    input [31: 0] rkd_value,

    output data_sram_en,
    output [3: 0] data_sram_we,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,

    output reg [31: 0] result_out,
    output reg [31: 0] result_bypass_out,
    output reg [31: 0] PC_out,
    output reg [7: 0] mem_op_out,
    output reg res_from_mul_out,
	output reg res_from_div_out,
    output reg res_from_mem_out,
    output reg res_from_csr_out,
    output reg gr_we_out,
    output reg [4: 0] dest_out
);
    wire ready_go;
    assign ready_go = !in_valid ||
                      !(res_from_mul && !(to_mul_resp_ready && from_mul_resp_valid)) &&
                      !(res_from_div && !(to_div_resp_ready && from_div_resp_valid));
    
    assign in_ready = ~rst & (~in_valid | ready_go & out_ready);
    assign to_mul_resp_ready = in_valid && res_from_mul;
    assign to_div_resp_ready = in_valid && res_from_div;

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end
        else if (out_ready) begin
            out_valid <= in_valid & ready_go;
        end
    end

    assign data_sram_en = 1'b1;
    assign data_sram_we    = {4{mem_we && valid && in_valid}} & (
                                ({4{mem_op[5]}} & (4'b0001 << result[1: 0])) |  // SB
                                ({4{mem_op[6]}} & (4'b0011 << result[1: 0])) |  // SH
                                ({4{mem_op[7]}} & 4'b1111)  // SW;
                            );
    assign data_sram_addr  = result & ~32'b11;
    assign data_sram_wdata = {32{mem_op[5]}} & {4{rkd_value[7:0]}} | 
                             {32{mem_op[6]}} & {2{rkd_value[15: 0]}} |
                             {32{mem_op[7]}} & rkd_value;

    wire [31: 0] result_out_wire;
    assign result_out_wire = {32{res_from_div}} & {32{div_op[0] | div_op[1]}} & div_quotient |
                             {32{res_from_div}} & {32{div_op[2] | div_op[3]}} & div_remainder |
                             {32{res_from_mul}} & {32{mul_op[2] | mul_op[1]}} & mul_result[63: 32] |
                             {32{res_from_mul}} & {32{mul_op[0]}} & mul_result[31: 0] |
                             result;

    always @(posedge clk) begin
		if (rst) begin
			PC_out <= 32'h1c000000;
		end
		else if (in_valid & ready_go & out_ready) begin
			PC_out <= PC;
		end
	end

    always @(posedge clk) begin
        if (rst) begin
            mem_op_out <= 8'b0;
        end
        else if (in_valid & ready_go & out_ready) begin
			mem_op_out <= mem_op;
		end
    end

    always @(posedge clk) begin
		if (rst) begin
			result_out <= 32'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			result_out <= result_out_wire;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			result_bypass_out <= 32'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			result_bypass_out <= result;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			res_from_mul_out <= 1'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			res_from_mul_out <= res_from_mul;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			res_from_div_out <= 1'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			res_from_div_out <= res_from_div;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			res_from_mem_out <= 1'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			res_from_mem_out <= res_from_mem;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			res_from_csr_out <= 1'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			res_from_csr_out <= res_from_csr;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			gr_we_out <= 1'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			gr_we_out <= gr_we;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			dest_out <= 5'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			dest_out <= dest;
		end
	end
endmodule
