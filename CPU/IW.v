module IW (
    input clk,
    input rst,
    
    // pipeline control signals
    input in_valid,
    input out_ready,
    output in_ready,
    output reg out_valid,

    input br_taken,

    // input from IF
    input [31:0] PC_from_IF,
    input [31:0] inst_from_IF,
    input inst_valid_from_IF,
    input discard_from_IF,

    // sram-like interface
    input data_ok,
    input [31:0] rdata,

    // output regs
    output reg [31:0] inst_out,
    output reg [31:0] PC_out,

    output reg [1:0] discard,
    output reg inst_valid,

    // exception
    input ex_flush,
    input ertn_flush,
    input ID_flush,
    input EX_flush,
    input MEM_flush,
    input RDW_flush,
    input WB_flush,

    input has_exception,
    input [5: 0] ecode,
    input [8: 0] esubcode,
    output reg has_exception_out,
    output reg [5: 0] ecode_out,
    output reg [8: 0] esubcode_out,

    input ID_this_tlb_refetch,
    input EX_this_tlb_refetch,
    input MEM_this_tlb_refetch,
    input RDW_this_tlb_refetch,

    input tlb_flush
);
    wire this_flush = in_valid && (has_exception || ID_flush || EX_flush || MEM_flush || RDW_flush || WB_flush);
    wire ready_go;
    reg [31:0] inst;
    
    wire br_flush = br_taken && !this_flush && !this_tlb_refetch;

    assign ready_go = !in_valid ||
                      ex_flush || ertn_flush ||
                      br_flush ||
                      tlb_flush ||
                      (~(|discard)) && (inst_valid_from_IF || data_ok || inst_valid);

    
    assign in_ready = !rst && (!in_valid || ready_go && out_ready);

    wire [31:0] inst_out_wire = inst_valid_from_IF ? inst_from_IF :
                                inst_valid ? inst :
                                data_ok ? rdata :
                                32'd0;

    wire discard_from_IW = (ex_flush || ertn_flush || br_flush || tlb_flush) && in_valid && !(inst_valid_from_IF || (data_ok && (~(|discard))) || inst_valid);

    wire this_tlb_refetch = in_valid && (ID_this_tlb_refetch || EX_this_tlb_refetch || MEM_this_tlb_refetch || RDW_this_tlb_refetch);

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end
        else if (out_ready) begin
            out_valid <= in_valid && ready_go && !ex_flush && !ertn_flush && !br_flush && !tlb_flush;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            inst_valid <= 1'b0;
            inst <= 32'd0;
        end
        // else if(ex_flush || ertn_flush) begin
        else if(ex_flush || ertn_flush || br_flush || tlb_flush) begin
            inst_valid <= 1'b0;
            inst <= 32'd0;
        end
        // else if(data_ok && out_ready && (inst_valid_from_IF || inst_valid)) begin
        else if(data_ok && out_ready && (inst_valid_from_IF || inst_valid) && (~(|discard))) begin
            inst_valid <= 1'b1;
            inst <= rdata;
        end
        // else if(data_ok && !out_ready && !(inst_valid_from_IF || inst_valid)) begin
        else if(data_ok && !out_ready && !(inst_valid_from_IF || inst_valid) && (~(|discard))) begin
            inst_valid <= 1'b1;
            inst <= rdata;
        end
        else if(in_valid && ready_go && out_ready) begin
            inst_valid <= 1'b0;
            inst <= 32'd0;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            inst_out <= 32'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            inst_out <= inst_out_wire;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            PC_out <= 32'd0;
        end
        else if(in_valid && ready_go && out_ready) begin
            PC_out <= PC_from_IF;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            discard <= 2'd0;
        end
        else if((|discard) && data_ok) begin
            discard <= discard - 2'b01;
        end
        else if(discard_from_IF ^ discard_from_IW) begin
            discard <= discard + 2'b01;
        end
        else if(discard_from_IF && discard_from_IW) begin
            discard <= discard + 2'b10;
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
endmodule