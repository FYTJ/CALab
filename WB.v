module WB (
    input clk,
	input rst,

	input in_valid,
    output in_ready,

    input valid,

    input [31: 0] data_sram_rdata,
    input [31: 0] alu_result,
    input [31: 0] PC,
    input res_from_mem,
    input gr_we,
    input [4: 0] dest,

    output rf_we,
    output [4: 0] rf_waddr,
    output [31: 0] rf_wdata,

    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    wire ready_go;
    assign ready_go = 1'b1;

    assign in_ready = ~rst & (~in_valid | ready_go);
    
    wire [31: 0] mem_result;
    wire [31: 0] final_result;
    assign mem_result   = data_sram_rdata;
    assign final_result = res_from_mem ? mem_result : alu_result;

    assign rf_we    = gr_we && valid && in_valid;
    assign rf_waddr = dest;
    assign rf_wdata = final_result;


    assign debug_wb_pc       = PC;
    assign debug_wb_rf_we    = {4{rf_we}};
    assign debug_wb_rf_wnum  = dest;
    assign debug_wb_rf_wdata = final_result;
endmodule
