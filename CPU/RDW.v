module RDW (
    input clk,
    input rst,
    
    // pipeline control signals
    input in_valid,
    input out_ready,
    output in_ready,
    output reg out_valid,

    input ex_flush,
    input ertn_flush,

    // input from MEM
    input [31:0] data_from_MEM,
    input data_valid_from_MEM,
    // input discard_from_MEM,

    input [31: 0] PC,
    input [31: 0] csr_result,
    input [31: 0] alu_result,
    input [31: 0] mul_result,
    input [31: 0] div_result,
    input [7: 0] mem_op,
    input res_from_mul,
	input res_from_div,
    input res_from_mem,
    input res_from_csr,
    input gr_we,
    input mem_we,
    input [4: 0] dest,
    output [31:0] result_bypass,

    // sram-like interface
    input data_ok,
    input [31:0] rdata,

    // output regs
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
    output reg [4: 0] dest_out,
    output reg [31:0] data_out,
    output reg data_valid,

    // exception handle
    output this_flush,
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

    output this_tlb_refetch,

    input tlb,
    output tlb_submit,
    output [31:0] tlb_flush_entry
);
    assign this_flush = in_valid && (has_exception || WB_flush || ertn);
    wire ready_go;
    //reg data_valid;
    reg [31:0] data;
    // reg discard;

    assign ready_go = !in_valid ||
                      this_flush ||
                      //ex_flush || ertn_flush ||
                    ////////////////////////////////////////////////////////////////////////
                    //   (!res_from_mem && !mem_we) ||
                    //   data_valid_from_MEM || data_ok || data_valid;
                    ////////////////////////////////////////////////////////////////////////
                      !((res_from_mem || mem_we) && !(data_valid_from_MEM || data_ok || data_valid));
    
    assign in_ready = !rst && (!in_valid || ready_go && out_ready);

    wire [31:0] data_out_wire = data_valid_from_MEM ? data_from_MEM :
                                data_valid ? data :
                                data_ok ? rdata :
                                32'd0;

    // wire discard_from_RDW = (ex_flush || ertn_flush) && !(data_valid_from_MEM || data_ok || data_valid) && (res_from_mem || mem_we);

    assign this_tlb_refetch = in_valid && tlb;

    assign tlb_submit = in_valid && tlb;

    assign tlb_flush_entry = PC + 4;

    assign result_bypass = res_from_csr ? csr_result : alu_result;

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end
        else if (out_ready) begin
            out_valid <= in_valid && ready_go && !ex_flush && !ertn_flush;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            data_valid <= 1'b0;
            data <= 32'd0;
        end
        else if(ex_flush || ertn_flush) begin
            data_valid <= 1'b0;
            data <= 32'd0;
        end
        else if(data_ok && out_ready && (data_valid_from_MEM || data_valid)) begin
            data_valid <= 1'b1;
            data <= rdata;
        end
        else if(data_ok && !out_ready && !(data_valid_from_MEM || data_valid)) begin
            data_valid <= 1'b1;
            data <= rdata;
        end
        else if(in_valid && ready_go && out_ready) begin
            data_valid <= 1'b0;
            data <= 32'd0;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            data_out <= 32'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            data_out <= data_out_wire;
        end
    end

    // always @(posedge clk) begin
    //     if(rst) begin
    //         discard <= 1'b0;
    //     end
    //     else if(data_ok) begin
    //         discard <= 1'b0;
    //     end
    //     else if(discard_from_MEM || discard_from_RDW) begin
    //         discard <= 1'b1;
    //     end
    // end

    // idiot delivery
    always @(posedge clk) begin
        if(rst) begin
            csr_result_out <= 32'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            csr_result_out <= csr_result;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            alu_result_out <= 32'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            alu_result_out <= alu_result;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            mul_result_out <= 32'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            mul_result_out <= mul_result;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            div_result_out <= 32'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            div_result_out <= div_result;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            PC_out <= 32'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            PC_out <= PC;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            mem_op_out <= 8'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            mem_op_out <= mem_op;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            res_from_mul_out <= 1'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            res_from_mul_out <= res_from_mul;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            res_from_div_out <= 1'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            res_from_div_out <= res_from_div;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            res_from_mem_out <= 1'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            res_from_mem_out <= res_from_mem;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            res_from_csr_out <= 1'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            res_from_csr_out <= res_from_csr;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            gr_we_out <= 1'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            gr_we_out <= gr_we;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            dest_out <= 5'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            dest_out <= dest;
        end
    end

    // exception handle
    always @(posedge clk) begin
        if (rst) begin
            has_exception_out <= 1'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            has_exception_out <= has_exception;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            ecode_out <= 6'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            ecode_out <= ecode;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            esubcode_out <= 9'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            esubcode_out <= esubcode;
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
            ertn_out <= 32'b0;
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