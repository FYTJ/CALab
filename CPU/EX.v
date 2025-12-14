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

	input [31: 0] csr_result,
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
	
	output [31: 0] result_bypass,
	
	output reg [31: 0] csr_result_out,
    output reg [31: 0] alu_result_out,
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
	output reg [31: 0] rj_value_out,
    output reg [31: 0] rkd_value_out,

	output this_flush,
	input MEM_flush,
    input RDW_flush,
    input WB_flush,

	input has_exception,
	input [5: 0] ecode,
    input [8: 0] esubcode,
	input [31:0] exception_maddr,
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
	input [63:0] count,

	input tlbsrch,
	input tlbrd,
	input tlbwr,
	input tlbfill,
	input invtlb,
	input [4:0] invtlb_op,

	output reg tlbsrch_out,
	output reg tlbrd_out,
	output reg tlbwr_out,
	output reg tlbfill_out,
	output reg invtlb_out,
	output reg [4:0] invtlb_op_out,

	output this_tlb_refetch,
	input MEM_this_tlb_refetch,
	input RDW_this_tlb_refetch,

	input tlb_flush,

	input csr_flush_input,
    output this_csr_refetch,
    output csr_flush_submit,
	output [31:0] csr_flush_target_submit,

	output wire mem_inst
);
    wire ready_go;
    assign ready_go = !in_valid ||
					  this_flush ||
					  this_tlb_refetch ||
					  !(res_from_mul && !(from_mul_req_ready && to_mul_req_valid)) && !(res_from_div && !(from_div_req_ready && to_div_req_valid));

    assign in_ready = ~rst & (~in_valid | ready_go & out_ready);

	assign to_mul_req_valid = in_valid && res_from_mul && !this_flush && !this_tlb_refetch;
	assign to_div_req_valid = in_valid && res_from_div && !this_flush && !this_tlb_refetch;

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end
        else if (out_ready) begin
            out_valid <= in_valid && ready_go && !ex_flush && !ertn_flush && !tlb_flush;
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

	assign result_bypass = res_from_csr ? (rdcntvl_w ? count[31:0] : rdcntvh_w ? count[63:32] : csr_result) : alu_result;

	assign mem_inst = in_valid && (res_from_mem || mem_we);

	wire ALE;
	assign ALE = (mem_op[1] || mem_op[4] || mem_op[6]) && alu_result[0] != 1'b0 ||
		     (mem_op[2] || mem_op[7]) && alu_result[1:0] != 2'b00;

	assign this_flush = in_valid && (has_exception || MEM_flush || RDW_flush || WB_flush || ALE || ertn);

	assign this_tlb_refetch = in_valid && (tlbsrch || tlbrd || tlbwr || tlbfill || invtlb || MEM_this_tlb_refetch || RDW_this_tlb_refetch);

	assign this_csr_refetch = in_valid && csr_flush_input;
	assign csr_flush_submit = in_valid && csr_flush_input;
	assign csr_flush_target_submit = PC + 4;

    always @(posedge clk) begin
		if (rst) begin
			csr_result_out <= 32'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			csr_result_out <= rdcntvl_w ? count[31:0] :
							  rdcntvh_w ? count[63:32] :
							  csr_result;
		end
	end

	always @(posedge clk) begin
		if (rst) begin
			alu_result_out <= 32'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			alu_result_out <= alu_result;
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
			rj_value_out <= 32'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			rj_value_out <= rj_value;
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
		if(!has_exception) begin
			exception_maddr_out <= alu_result & {32{ALE}};
		end
		else begin
    			exception_maddr_out <= exception_maddr;
		end
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

	always @(posedge clk) begin
		if (rst) begin
			tlbsrch_out <= 1'b0;
			tlbrd_out   <= 1'b0;
			tlbwr_out   <= 1'b0;
			tlbfill_out <= 1'b0;
			invtlb_out  <= 1'b0;
			invtlb_op_out <= 5'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			tlbsrch_out <= tlbsrch;
			tlbrd_out   <= tlbrd;
			tlbwr_out   <= tlbwr;
			tlbfill_out <= tlbfill;
			invtlb_out  <= invtlb;
			invtlb_op_out <= invtlb_op;
		end
	end
endmodule
