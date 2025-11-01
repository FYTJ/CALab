module IF (
    input clk,
    input rst,

    input out_ready,
    output reg out_valid,
    input ex_flush,
    input ertn_flush,

    input [31: 0] ex_entry,
    input [31: 0] ertn_entry,
    input br_taken,
    input [31: 0] br_target,
    output inst_sram_en,
    output [3: 0] inst_sram_we,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    output reg [31: 0] PC_out,
    
    input next_exception,

    output reg has_exception_out,
    output reg [5: 0] ecode_out,
    output reg [8: 0] esubcode_out
);
    wire ready_go;
    reg in_valid;
    assign ready_go = 1'b1;

    always @(posedge clk) begin
        in_valid <= !rst;
    end

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end
        else if (out_ready) begin
            out_valid <= !rst && ready_go;
        end
    end

    wire [31:0] seq_pc;
    wire [31:0] nextpc;

    assign seq_pc       = out_ready ? PC_out + 32'h4: PC_out;
    assign nextpc       = out_ready && ex_flush ? ex_entry : ertn_flush ? ertn_entry : br_taken ? br_target : seq_pc;

    assign inst_sram_en    = !this_exception;
    assign inst_sram_we    = 4'b0;
    assign inst_sram_addr  = nextpc & ~32'b11;
    assign inst_sram_wdata = 32'b0;

    wire ADEF;
    assign ADEF = nextpc[1: 0] != 0;

    wire this_exception;
    assign this_exception = next_exception || ADEF;

    always @(posedge clk) begin
		if (rst) begin
			PC_out <= 32'h1c000000;
		end
		else if (in_valid && ready_go && out_ready) begin
			PC_out <= nextpc;
		end
	end

    always @(posedge clk) begin
        if (rst) begin
            has_exception_out <= 1'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            has_exception_out <= ADEF;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            ecode_out <= 6'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            ecode_out <= {6{ADEF}} & 6'h8;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            esubcode_out <= 9'b0;
        end
        else if (in_valid && ready_go && out_ready) begin
            esubcode_out <= {9{ADEF}} & 9'h0;
        end
    end
endmodule
