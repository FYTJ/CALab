module IF (
    input clk,
    input rst,

    input out_ready,
    output reg out_valid,

    input br_taken,
    input [31: 0] br_target,
    output inst_sram_en,
    output [3: 0] inst_sram_we,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    output reg [31: 0] PC_out
);
    wire ready_go;
    reg in_valid;
    assign ready_go = 1'b1;

    always @(posedge clk) begin
        in_valid <= ~rst;
    end

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end
        else if (out_ready) begin
            out_valid <= ~rst & ready_go;
        end
    end

    wire [31:0] seq_pc;
    wire [31:0] nextpc;

    assign seq_pc       = PC_out + 32'h4;
    assign nextpc       = br_taken ? br_target : seq_pc;

    assign inst_sram_en = ready_go;
    assign inst_sram_we    = 4'b0;
    assign inst_sram_addr  = nextpc;
    assign inst_sram_wdata = 32'b0;

    always @(posedge clk) begin
		if (rst) begin
			PC_out <= 32'h1c000000;
		end
		else if (in_valid & ready_go & out_ready) begin
			PC_out <= nextpc;
		end
	end
endmodule
