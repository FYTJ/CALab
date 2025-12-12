module MEM (
    input clk,
	input rst,

    input in_valid,
    input out_ready,
    output in_ready,
    output reg out_valid,
    input valid,
    input ex_flush,
    input ertn_flush,

    output to_mul_resp_ready,
    input from_mul_resp_valid,
    input [63: 0] mul_result,

    
    output to_div_resp_ready,
    input from_div_resp_valid,
    input [31: 0] div_quotient,
    input [31: 0] div_remainder,

    input [31: 0] csr_result,
    input [31: 0] alu_result,
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
    input RDW_data_valid,

    // sram-like interface
    output req,
    output wr,
    output [1:0] size,
    output [31:0] addr,
    output [3:0] wstrb,
    output [31:0] wdata,
    input addr_ok,
    input data_ok,
    input [31:0] rdata,
    
    output [31: 0] result_bypass,

    output reg [31: 0] csr_result_out,
    output reg [31: 0] alu_result_out,
    output reg [31: 0] mul_result_out,
    output reg [31: 0] div_result_out,
    output reg [31: 0] PC_out,
    output reg [7: 0] mem_op_out,
    output reg res_from_mul_out,
	output reg res_from_div_out,
    output reg res_from_mem_out,
    output reg res_from_csr_out,
    output reg gr_we_out,
    output reg mem_we_out,
    output reg [4: 0] dest_out,
    output reg [31: 0] data_out,
    output reg data_valid_out,

    output this_flush,
    input RDW_flush,
    input WB_flush,

    input has_exception,
	input [5: 0] ecode,
    input [8: 0] esubcode,
    input [31: 0] exception_maddr,
    input ertn,
    output reg has_exception_out,
	output reg [5: 0] ecode_out,
    output reg [8: 0] esubcode_out,
    output reg [31: 0] exception_maddr_out,
    output reg ertn_out,

    input rdcntid,
    output reg rdcntid_out,

    input tlbsrch,
    input tlbrd,
    input tlbwr,
    input tlbfill,
    input invtlb,
    input [4:0] invtlb_op,

    output wire tlbsrch_to_csr,
    output wire tlbrd_to_csr,
    output wire tlbwr_to_csr,
    output wire tlbfill_to_csr,
    output wire invtlb_to_csr,
    output wire [4:0] invtlb_op_to_csr,

    output this_tlb_refetch,
    input RDW_this_tlb_refetch,

    output reg tlb_out,

    input tlb_flush,

    input [5:0] mmu_ecode_d,
    input [8:0] mmu_esubcode_d
);

    reg handshake_done;

    always @(posedge clk) begin
        if(rst) begin
            handshake_done <= 1'b0;
        end
        else if((req && addr_ok) || out_ready) begin
            handshake_done <= !out_ready;
        end
    end

    reg data_valid;
    reg [31:0] data;
    wire ready_go;
    assign ready_go = !in_valid  ||
                      this_flush ||
                      !(res_from_mul && !(to_mul_resp_ready && from_mul_resp_valid)) &&
                      !(res_from_div && !(to_div_resp_ready && from_div_resp_valid)) &&
                      !((res_from_mem || mem_we) && !(|mmu_ecode_d) && !(req && addr_ok || handshake_done));

    assign in_ready = ~rst & (~in_valid | ready_go & out_ready);

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end
        else if (out_ready) begin
            out_valid <= in_valid && ready_go && !ex_flush && !ertn_flush && !tlb_flush;
        end
    end

    assign req = in_valid && !handshake_done && !this_flush && (res_from_mem || mem_we) && !this_tlb_refetch && !(|mmu_ecode_d);
    assign wr = (|wstrb);
    assign wstrb  = {4{mem_we && valid && in_valid && !this_flush && !this_tlb_refetch}} & (
                        ({4{mem_op[5]}} & (4'b0001 << alu_result[1: 0])) |  // SB
                        ({4{mem_op[6]}} & (4'b0011 << alu_result[1: 0])) |  // SH
                        ({4{mem_op[7]}} & 4'b1111)  // SW;
                    );
    assign addr  = alu_result;
    assign wdata = {32{mem_op[5]}} & {4{rkd_value[7:0]}} | 
                   {32{mem_op[6]}} & {2{rkd_value[15: 0]}} |
                   {32{mem_op[7]}} & rkd_value;
    assign size = {2{mem_op[0] | mem_op[3] | mem_op[5]}} & 2'b00 | 
                  {2{mem_op[1] | mem_op[4] | mem_op[6]}} & 2'b01 |
                  {2{mem_op[2] | mem_op[7]}} & 2'b10;

    always @(posedge clk) begin
        if(rst) begin
            data_valid <= 1'b0;
            data <= 32'd0;
        end

        else if(in_valid && ready_go && out_ready) begin
            data_valid <= 1'b0;
        end

        else if(handshake_done && data_ok && !data_valid && (data_valid_out || RDW_data_valid) && !out_ready) begin
            data_valid <= 1'b1;
            data <= rdata;
        end
    end

    always @(posedge clk) begin
		if (rst) begin
            data_valid_out <= 1'b0;
			data_out <= 32'd0;
		end
        else if (ex_flush || ertn_flush || tlb_flush) begin
            data_valid_out <= 1'b0;
			data_out <= 32'd0;
        end
		else if (in_valid && ready_go && out_ready) begin
			data_valid_out <= data_valid;
            data_out <= data;
		end
	end
    
    assign to_mul_resp_ready = in_valid && res_from_mul;
    assign to_div_resp_ready = in_valid && res_from_div;

    assign this_flush = in_valid && (has_exception || RDW_flush || WB_flush || ertn);

    assign this_tlb_refetch = in_valid && (tlbsrch || tlbrd || tlbwr || tlbfill || invtlb || RDW_this_tlb_refetch);

    assign tlbsrch_to_csr = in_valid && tlbsrch;
    assign tlbrd_to_csr   = in_valid && tlbrd;
    assign tlbwr_to_csr   = in_valid && tlbwr;
    assign tlbfill_to_csr = in_valid && tlbfill;
    assign invtlb_to_csr  = in_valid && invtlb;
    assign invtlb_op_to_csr = {5{in_valid}} & invtlb_op;

    assign result_bypass = res_from_csr ? csr_result : alu_result;

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
			csr_result_out <= 32'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			csr_result_out <= csr_result;
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
			mul_result_out <= 32'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			mul_result_out <= {32{res_from_mul}} & {32{mul_op[2] | mul_op[1]}} & mul_result[63: 32] |
                              {32{res_from_mul}} & {32{mul_op[0]}} & mul_result[31: 0];
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			div_result_out <= 32'b0;
		end
		else if (in_valid && ready_go && out_ready) begin
			div_result_out <= {32{res_from_div}} & {32{div_op[0] | div_op[1]}} & div_quotient |
                              {32{res_from_div}} & {32{div_op[2] | div_op[3]}} & div_remainder;
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
            has_exception_out <= 1'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            has_exception_out <= has_exception || ((|mmu_ecode_d) & (res_from_mem || mem_we));
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            exception_maddr_out <= 32'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            exception_maddr_out <= exception_maddr;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            ecode_out <= 6'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            if(!has_exception) begin
                ecode_out <= mmu_ecode_d & {6{(res_from_mem || mem_we)}};
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
            if(!has_exception) begin
                esubcode_out <= mmu_esubcode_d & {9{(res_from_mem || mem_we)}};
            end
            else begin
                esubcode_out <= esubcode;
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
            tlb_out <= 1'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            tlb_out <= tlbsrch || tlbrd || tlbwr || tlbfill || invtlb;
        end
    end
endmodule
