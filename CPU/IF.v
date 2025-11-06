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
    input br_stall,
    input ID_in_valid,
    input [1:0] discard,
    input IW_inst_valid,

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

    // output regs
    output reg [31: 0] PC_out,
    output reg [31: 0] inst_out,
    output reg inst_valid_out,
    output reg has_exception_out,
    output reg [5: 0] ecode_out,
    output reg [8: 0] esubcode_out,

    output discard_out_wire
);
    wire ready_go;
    reg in_valid;

    always @(posedge clk) begin
        in_valid <= !rst;
    end

    // common values
    assign wr = 1'b0;
    assign size = 2'b10; // 4 bytes, 32 bits
    assign wstrb = 4'd0;
    assign wdata = 32'd0;

    reg handshake_done;

    always @(posedge clk) begin
        if(rst) begin
            handshake_done <= 1'b0;
        end
        else if((req && addr_ok) || out_ready) begin
            handshake_done <= !out_ready;
        end
    end

    reg br_taken_reg;
    reg [31:0] br_target_reg;
    reg ex_flush_reg;
    reg [31:0] ex_entry_reg;
    reg ertn_flush_reg;
    reg [31:0] ertn_entry_reg;
    wire br_taken_preserved = br_taken | br_taken_reg;
    wire [31:0] br_target_preserved = br_taken ? br_target : br_target_reg;
    wire ex_flush_preserved = ex_flush | ex_flush_reg;
    wire [31:0] ex_entry_preserved = ex_flush ? ex_entry : ex_entry_reg;
    wire ertn_flush_preserved = ertn_flush | ertn_flush_reg;
    wire [31:0] ertn_entry_preserved = ertn_flush ? ertn_entry : ertn_entry_reg;

    reg inst_valid;
    reg [31:0] inst;
    assign ready_go = req && addr_ok || (handshake_done && !ex_entry_preserved && !ertn_entry_preserved);
    assign req = !handshake_done && !(br_stall && ID_in_valid) || ex_entry_preserved || ertn_entry_preserved;
    
    // discard the first instruction after exception flush
    assign discard_out_wire = (ex_flush || ertn_flush || br_taken) && handshake_done && !inst_valid;

    wire [31:0] seq_pc;
    wire [31:0] nextpc;

    assign seq_pc       = PC_out + 32'h4;
    assign nextpc       = ex_flush_preserved ? ex_entry_preserved :
                          ertn_flush_preserved ? ertn_entry_preserved :
                          br_taken_preserved ? br_target_preserved : seq_pc;

    assign addr  = nextpc & ~32'b11;

    always @(posedge clk) begin
        if(rst) begin
            inst_valid <= 1'b0;
            inst <= 32'd0;
        end
        else if(ex_flush || ertn_flush) begin
            inst_valid <= 1'b0;
            inst <= 32'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            inst_valid <= 1'b0;
            inst <= 32'd0;
        end
        else if(handshake_done && data_ok && !inst_valid && !out_ready && (inst_valid_out || IW_inst_valid) && (~(|discard))) begin
            inst_valid <= 1'b1;
            inst <= rdata;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end
        else if (out_ready) begin
            out_valid <= !rst && ready_go && (!ex_flush && !ertn_flush || req && addr_ok);
        end
    end

    wire ADEF;
    assign ADEF = nextpc[1: 0] != 0;

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
            inst_valid_out <= 1'b0;
			inst_out <= 32'd0;
		end
        else if (ex_flush || ertn_flush) begin
            inst_valid_out <= 1'b0;
			inst_out <= 32'd0;
        end
		else if (in_valid && ready_go && out_ready) begin
			inst_valid_out <= inst_valid;
            inst_out <= inst;
		end
	end

    always @(posedge clk) begin
        if(rst) begin
            br_taken_reg <= 1'b0;
        end
        else if(in_valid && ready_go && out_ready) begin
            br_taken_reg <= 1'b0;
        end
        else if(br_taken) begin
            br_taken_reg <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            br_target_reg <= 32'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            br_target_reg <= 32'd0;
        end
        else if(br_taken) begin
            br_target_reg <= br_target;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            ex_flush_reg <= 1'b0;
        end
        else if(in_valid && ready_go && out_ready) begin
            ex_flush_reg <= 1'b0;
        end
        else if(ex_flush) begin
            ex_flush_reg <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            ex_entry_reg <= 32'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            ex_entry_reg <= 32'd0;
        end
        else if(ex_flush) begin
            ex_entry_reg <= ex_entry;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            ertn_flush_reg <= 1'b0;
        end
        else if(in_valid && ready_go && out_ready) begin
            ertn_flush_reg <= 1'b0;
        end
        else if(ertn_flush) begin
            ertn_flush_reg <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            ertn_entry_reg <= 32'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            ertn_entry_reg <= 32'd0;
        end
        else if(ertn_flush) begin
            ertn_entry_reg <= ertn_entry;
        end
    end

    // exception handle
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
