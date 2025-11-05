module IW (
    input clk,
    input rst,
    
    // pipeline control signals
    input in_valid,
    input out_ready,
    output in_ready,
    output reg out_valid,

    input br_flush,

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

    // exception
    input ex_flush,
    input ertn_flush,
    input next_flush,

    input has_exception,
    input [5: 0] ecode,
    input [8: 0] esubcode,
    output reg has_exception_out,
    output reg [5: 0] ecode_out,
    output reg [8: 0] esubcode_out
);
    wire this_flush = in_valid && (has_exception || next_flush);
    wire ready_go;
    reg inst_valid;
    reg [31:0] inst;
    reg discard;

    assign ready_go = !in_valid ||
                      this_flush ||
                      br_flush ||
                      !discard && (inst_valid_from_IF || data_ok || inst_valid);

    
    assign in_ready = !rst && (!in_valid || ready_go && out_ready);

    wire [31:0] inst_out_wire = inst_valid_from_IF ? inst_from_IF :
                                inst_valid ? inst :
                                data_ok ? rdata :
                                32'd0;

    wire discard_from_IW = (ex_flush || ertn_flush) && !(inst_valid_from_IF || data_ok || inst_valid);

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end
        else if (out_ready) begin
            out_valid <= in_valid && ready_go && !ex_flush && !ertn_flush && !br_flush;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            inst_valid <= 1'b0;
            inst <= 32'd0;
        end
        else if(ex_flush || ertn_flush) begin
            inst_valid <= 1'b0;
            inst <= 32'd0;
        end
        else if(data_ok && out_ready && (inst_valid_from_IF || inst_valid)) begin
            inst_valid <= 1'b1;
            inst <= rdata;
        end
        else if(data_ok && !out_ready && !(inst_valid_from_IF || inst_valid)) begin
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
            discard <= 1'b0;
        end
        else if(data_ok) begin
            discard <= 1'b0;
        end
        else if(discard_from_IF || discard_from_IW) begin
            discard <= 1'b1;
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