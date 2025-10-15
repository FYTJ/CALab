module MEM (
    input clk,
	input rst,

    input in_valid,
    input out_ready,
    output in_ready,
    output reg out_valid,

    input valid,

    input [31: 0] alu_result,
    input [31: 0] PC,
    input [7: 0] load_op,
    input res_from_mem,
    input gr_we,
    input mem_we,
    input [4: 0] dest,
    input [31: 0] rkd_value,

    output data_sram_en,
    output [3: 0] data_sram_we,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,

    output reg [31: 0] alu_result_out,
    output reg [31: 0] PC_out,
    output reg [7: 0] load_op_out,
    output reg res_from_mem_out,
    output reg gr_we_out,
    output reg [4: 0] dest_out
);
    wire ready_go;
    assign ready_go = 1'b1;
    
    assign in_ready = ~rst & (~in_valid | ready_go & out_ready);

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
                                ({4{load_op[5]}} & (4'b0001 << alu_result[1: 0])) |  // SB
                                ({4{load_op[6]}} & (4'b0011 << alu_result[1: 0])) |  // SH
                                ({4{load_op[7]}} & 4'b1111)  // SW;
                            );
    assign data_sram_addr  = alu_result;
    assign data_sram_wdata = rkd_value;

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
			alu_result_out <= 32'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			alu_result_out <= alu_result;
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
			dest_out <= 5'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			dest_out <= dest;
		end
	end
endmodule
