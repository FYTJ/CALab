module WB (
    input clk,
	input rst,

	input in_valid,
    output in_ready,

    input valid,

    input [31: 0] data_sram_rdata,
    input [31: 0] result,
    input [31: 0] PC,
    input [7: 0] load_op,
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
    // load_op为1时符号扩展，load_op为0时0扩展
    assign mem_result   = 
        {32{load_op[0] | load_op[3]}} &   // LB & LBU
            ({32{result[1: 0] == 2'b00}} & {{24{load_op[3] & data_sram_rdata[7]}}, data_sram_rdata[7: 0]} | 
    		{32{result[1: 0] == 2'b01}} & {{24{load_op[3] & data_sram_rdata[15]}}, data_sram_rdata[15: 8]} | 
			{32{result[1: 0] == 2'b10}} & {{24{load_op[3] & data_sram_rdata[23]}}, data_sram_rdata[23: 16]} | 
			{32{result[1: 0] == 2'b11}} & {{24{load_op[3] & data_sram_rdata[31]}}, data_sram_rdata[31: 24]}) |
		{32{load_op[1] | load_op[4]}} &   // LH & LHU
			({32{result[1: 0] == 2'b00}} & {{16{load_op[4] & data_sram_rdata[15]}}, data_sram_rdata[15: 0]} |
			{32{result[1: 0] == 2'b10}} & {{16{load_op[4] & data_sram_rdata[31]}}, data_sram_rdata[31: 16]}) |
	 	{32{load_op[2]}} & data_sram_rdata;  // LW
    assign final_result = res_from_mem ? mem_result : result;

    assign rf_we    = gr_we && valid && in_valid;
    assign rf_waddr = dest;
    assign rf_wdata = final_result;


    assign debug_wb_pc       = PC;
    assign debug_wb_rf_we    = {4{rf_we}};
    assign debug_wb_rf_wnum  = dest;
    assign debug_wb_rf_wdata = final_result;
endmodule
