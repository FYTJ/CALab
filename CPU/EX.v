module EX (
    input clk,
	input rst,

    input in_valid,
    input out_ready,
    output in_ready,
    output reg out_valid,
	input ex_flush,
	input ertn_flush,

	input from_mul_req_ready,
	output to_mul_req_valid,
	input from_div_req_ready,
	output to_div_req_valid,

	input [31: 0] result,
    input [31: 0] PC,
	input [7: 0] mem_op,
	input [11: 0] alu_op,
	input [2: 0] mul_op,
	input [3: 0] div_op,
    input src1_is_pc,
    input src2_is_imm,
	input res_from_mul,
	input res_from_div,
    input res_from_mem,
	input res_from_csr,
    input gr_we,
    input mem_we,
    input [4: 0] dest,
    input [31:0] imm,
    input [31: 0] rj_value,
    input [31: 0] rkd_value,
	output [31: 0] src1_wire,
	output [31: 0] src2_wire,
	output [31: 0] result_out_wire,
    
    output reg [31: 0] result_out,
    output reg [31: 0] PC_out,
	output reg [7: 0] mem_op_out,
	output reg [2: 0] mul_op_out,
	output reg [3: 0] div_op_out,
	output reg res_from_mul_out,
    output reg res_from_div_out,
    output reg res_from_mem_out,
	output reg res_from_csr_out,
    output reg gr_we_out,
    output reg mem_we_out,
    output reg [4: 0] dest_out,
    output reg [31: 0] rkd_value_out,

	output this_flush,
    input next_flush,

	input has_exception,
	input [5: 0] ecode,
    input [8: 0] esubcode,
	input ertn,
    output reg has_exception_out,
	output reg [5: 0] ecode_out,
    output reg [8: 0] esubcode_out,
	output reg [31: 0] exception_maddr_out,
	output reg ertn_out,

	input rdcntid,
	output reg rdcntid_out,
	input rdcntvl_w,
	input rdcntvh_w,
	input [63:0] count
);
    wire ready_go;
    assign ready_go = !in_valid ||
		      this_flush||
		      !(res_from_mul && !(from_mul_req_ready && to_mul_req_valid)) && !(res_from_div && !(from_div_req_ready && to_div_req_valid));

    assign in_ready = ~rst & (~in_valid | ready_go & out_ready);

	assign to_mul_req_valid = in_valid && res_from_mul && !this_flush;
	assign to_div_req_valid = in_valid && res_from_div && !this_flush;

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end
        else if (out_ready) begin
            out_valid <= in_valid && ready_go && !ex_flush && !ertn_flush;
        end
    end

	wire [31: 0] src1;
    wire [31: 0] src2;
	wire [31: 0] alu_result;

	alu u_alu(
        .alu_op     (alu_op    ),
        .alu_src1   (src1  ),
        .alu_src2   (src2  ),
        .alu_result (alu_result)
    );

    assign src1 = src1_is_pc  ? PC[31:0] : rj_value;
    assign src2 = src2_is_imm ? imm : rkd_value;
	assign src1_wire = src1;
	assign src2_wire = src2;

	wire ALE;
	assign ALE = (mem_op[1] || mem_op[4] || mem_op[6]) && alu_result[0] != 1'b0 ||
		     (mem_op[2] || mem_op[7]) && alu_result[1:0] != 2'b00;

	assign this_flush = in_valid && (has_exception || next_flush || ALE || ertn);

	assign result_out_wire = rdcntvl_w ? count[31:0] :
						  	 rdcntvh_w ? count[63:32] :
						  	 res_from_csr ? result :
						  	 alu_result;
    always @(posedge clk) begin
		if (rst) begin
			result_out <= 32'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			result_out <= result_out_wire;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			PC_out <= 32'h1c000000;
		end
		else if (in_valid && ready_go && out_ready) begin
			PC_out <= PC;
		end
	end

	always @(posedge clk) begin
        if (rst) begin
            mem_op_out <= 8'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
			mem_op_out <= mem_op;
		end
    end

	always @(posedge clk) begin
        if (rst) begin
            mul_op_out <= 3'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
			mul_op_out <= mul_op;
		end
    end

	always @(posedge clk) begin
        if (rst) begin
            div_op_out <= 4'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
			div_op_out <= div_op;
		end
    end

	always @(posedge clk) begin
		if (rst) begin
			res_from_mul_out <= 1'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			res_from_mul_out <= res_from_mul;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			res_from_div_out <= 1'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			res_from_div_out <= res_from_div;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			res_from_mem_out <= 1'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			res_from_mem_out <= res_from_mem;
		end
	end

	always @(posedge clk) begin
		if (rst) begin
			res_from_csr_out <= 1'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			res_from_csr_out <= res_from_csr;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			gr_we_out <= 1'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			gr_we_out <= gr_we;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			mem_we_out <= 1'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			mem_we_out <= mem_we;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			dest_out <= 5'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			dest_out <= dest;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			rkd_value_out <= 32'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			rkd_value_out <= rkd_value;
		end
	end

	always @(posedge clk) begin
        if (rst) begin
            has_exception_out <= 1'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            has_exception_out <= has_exception || ALE;
        end
    end

	always @(posedge clk) begin
        if (rst) begin
            ecode_out <= 6'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            if (!has_exception) begin
                ecode_out <= {6{ALE}} & 6'h9;
            end
            else begin
                ecode_out <= ecode;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            esubcode_out <= 9'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            if (!has_exception) begin
                esubcode_out <= 9'b0;
            end
            else begin
                esubcode_out <= esubcode;
            end
        end
    end

	always @(posedge clk) begin
        if (rst) begin
            exception_maddr_out <= 32'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            exception_maddr_out <= alu_result;
        end
    end

	always @(posedge clk) begin
		if (rst) begin
			ertn_out <= 1'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			ertn_out <= ertn;
		end
	end

	always @(posedge clk) begin
		if (rst) begin
			rdcntid_out <= 1'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			rdcntid_out <= rdcntid;
		end
	end
endmodule
