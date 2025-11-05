module WB (
    input clk,
	input rst,

	input in_valid,
    output in_ready,

    input valid,

    input [31: 0] data_sram_rdata,
    input [31: 0] csr_result,
    input [31: 0] alu_result,
    input [31: 0] mul_result,
    input [31: 0] div_result,
    input [31: 0] PC,
    input [7: 0] mem_op,
    input res_from_mul,
	input res_from_div,
    input res_from_mem,
    input res_from_csr,
    input gr_we,
    input [4: 0] dest,

    output [31: 0] result_bypass,

    output rf_we,
    output [4: 0] rf_waddr,
    output [31: 0] rf_wdata,

    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,

    output this_flush,

    input has_exception,
	input [5: 0] ecode,
    input [8: 0] esubcode,
    input [31: 0] exception_maddr,
    input ertn,
    output exception_submit,
    output [5: 0] ecode_submit,
    output [8: 0] esubcode_submit,
    output [31: 0] exception_pc_submit,
    output [31: 0] exception_maddr_submit,
    output ertn_submit,

    input [31:0] csr_tid,   // for rdcntid instruction
    input rdcntid
);
    wire ready_go;
    assign ready_go = 1'b1;

    assign in_ready = ~rst & (~in_valid | ready_go);
    
    wire [31: 0] mem_result;
    wire [31: 0] final_result;

    // mem_op为1时符号扩展，mem_op为0时0扩展
    assign mem_result   = 
        {32{mem_op[0] | mem_op[3]}} &   // LB & LBU
            ({32{alu_result[1: 0] == 2'b00}} & {{24{mem_op[0] & data_sram_rdata[7]}}, data_sram_rdata[7: 0]} | 
    		{32{alu_result[1: 0] == 2'b01}} & {{24{mem_op[0] & data_sram_rdata[15]}}, data_sram_rdata[15: 8]} | 
			{32{alu_result[1: 0] == 2'b10}} & {{24{mem_op[0] & data_sram_rdata[23]}}, data_sram_rdata[23: 16]} | 
			{32{alu_result[1: 0] == 2'b11}} & {{24{mem_op[0] & data_sram_rdata[31]}}, data_sram_rdata[31: 24]}) |
		{32{mem_op[1] | mem_op[4]}} &   // LH & LHU
			({32{alu_result[1: 0] == 2'b00}} & {{16{mem_op[1] & data_sram_rdata[15]}}, data_sram_rdata[15: 0]} |
			{32{alu_result[1: 0] == 2'b10}} & {{16{mem_op[1] & data_sram_rdata[31]}}, data_sram_rdata[31: 16]}) |
	 	{32{mem_op[2]}} & data_sram_rdata;  // LW

    assign result_bypass = res_from_mem ? mem_result : res_from_csr ? csr_result : alu_result;

    assign final_result = rdcntid ? csr_tid :
                          res_from_mem ? mem_result :
                          res_from_csr ? csr_result :
                          res_from_mul ? mul_result :
                          res_from_div ? div_result :
                          alu_result;

    assign rf_we    = gr_we && valid && in_valid && !has_exception;
    assign rf_waddr = dest;
    assign rf_wdata = final_result;


    assign debug_wb_pc       = PC;
    assign debug_wb_rf_we    = {4{rf_we}};
    assign debug_wb_rf_wnum  = dest;
    assign debug_wb_rf_wdata = final_result;

    assign this_flush = in_valid && (has_exception || ertn);

    assign exception_submit = in_valid && has_exception;
    assign ecode_submit = ecode;
    assign esubcode_submit = esubcode;
    assign exception_pc_submit = PC;
    assign exception_maddr_submit = exception_maddr;
    assign ertn_submit = in_valid && ertn;
endmodule
