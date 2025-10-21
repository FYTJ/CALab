module EX (
    input clk,
	input rst,

    input in_valid,
    input out_ready,
    output in_ready,
    output reg out_valid,

	input from_mul_req_ready,
	output to_mul_req_valid,
	input from_div_req_ready,
	output to_div_req_valid,

    input [31: 0] PC,
	input [7: 0] load_op,
	input [11: 0] alu_op,
	input [2: 0] mul_op,
	input [3: 0] div_op,
    input src1_is_pc,
    input src2_is_imm,
	input res_from_mul,
	input res_from_div,
    input res_from_mem,
    input gr_we,
    input mem_we,
    input [4: 0] dest,
    input [31:0] imm,
    input [31: 0] rj_value,
    input [31: 0] rkd_value,
	output [31: 0] src1_wire,
	output [31: 0] src2_wire,
	output [31: 0] result,
    
    output reg [31: 0] result_out,
    output reg [31: 0] PC_out,
	output reg [7: 0] load_op_out,
	output reg [2: 0] mul_op_out,
	output reg [3: 0] div_op_out,
	output reg res_from_mul_out,
    output reg res_from_div_out,
    output reg res_from_mem_out,
    output reg gr_we_out,
    output reg mem_we_out,
    output reg [4: 0] dest_out,
    output reg [31: 0] rkd_value_out
);
    wire ready_go;
    assign ready_go = !in_valid ||
					  !(res_from_mul && !(from_mul_req_ready && to_mul_req_valid)) &&
					  !(res_from_div && !(from_div_req_ready && to_div_req_valid));

    assign in_ready = ~rst & (~in_valid | ready_go & out_ready);

	assign to_mul_req_valid = in_valid && res_from_mul;
	assign to_div_req_valid = in_valid && res_from_div;

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end
        else if (out_ready) begin
            out_valid <= in_valid & ready_go;
        end
    end

	wire [31: 0] src1;
    wire [31: 0] src2;
	wire [31: 0] alu_result;
	// wire [63: 0] mul_result;
	// wire [31: 0] final_mul_result = {32{res_from_mul}} & {32{mul_op[2] | mul_op[1]}} & mul_result[63: 32] |
    //                           {32{res_from_mul}} & {32{mul_op[0]}} & mul_result[31: 0];
	// assign result = res_from_mul ? final_mul_result : alu_result;
	assign result = alu_result;

	alu u_alu(
        .alu_op     (alu_op    ),
        .alu_src1   (src1  ),
        .alu_src2   (src2  ),
        .alu_result (alu_result)
    );

	// multiplier u_mul(
    //     .mul_clk(clk),
    //     .reset(rst),
    //     .mul_op(mul_op),
    //     .x(src1),
    //     .y(src2),
    //     .result(mul_result)
    // );

    assign src1 = src1_is_pc  ? PC[31:0] : rj_value;
    assign src2 = src2_is_imm ? imm : rkd_value;
	assign src1_wire = src1;
	assign src2_wire = src2;
    
    always @(posedge clk) begin
		if (rst) begin
			result_out <= 32'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			result_out <= result;
		end
	end

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
            load_op_out <= 8'b0;
        end
        else if (in_valid & ready_go & out_ready) begin
			load_op_out <= load_op;
		end
    end

	always @(posedge clk) begin
        if (rst) begin
            mul_op_out <= 3'b0;
        end
        else if (in_valid & ready_go & out_ready) begin
			mul_op_out <= mul_op;
		end
    end

	always @(posedge clk) begin
        if (rst) begin
            div_op_out <= 4'b0;
        end
        else if (in_valid & ready_go & out_ready) begin
			div_op_out <= div_op;
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
			gr_we_out <= 1'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			gr_we_out <= gr_we;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			mem_we_out <= 1'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			mem_we_out <= mem_we;
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

    always @(posedge clk) begin
		if (rst) begin
			rkd_value_out <= 32'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			rkd_value_out <= rkd_value;
		end
	end
endmodule
