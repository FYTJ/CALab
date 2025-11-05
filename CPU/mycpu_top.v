`include "./utils/decoder_2_4.v"
`include "./utils/decoder_4_16.v"
`include "./utils/decoder_5_32.v"
`include "./utils/decoder_6_64.v"
`include "../multiplier/multiplier.v"
`include "../multiplier/booth.v"
`include "../multiplier/wallace.v"
`include "../multiplier/full_adder.v"
`include "../divider/Div.v"

module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [3: 0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [3: 0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    reg         reset;
    always @(posedge clk) reset <= ~resetn;

    reg         valid;
    always @(posedge clk) begin
        if (reset) begin
            valid <= 1'b0;
        end
        else begin
            valid <= 1'b1;
        end
    end

    wire [ 4:0] rf_raddr1;
    wire [31:0] rf_rdata1;
    wire [ 4:0] rf_raddr2;
    wire [31:0] rf_rdata2;
    wire        rf_we   ;
    wire [ 4:0] rf_waddr;
    wire [31:0] rf_wdata;

    regfile u_regfile(
        .clk    (clk      ),
        .raddr1 (rf_raddr1),
        .rdata1 (rf_rdata1),
        .raddr2 (rf_raddr2),
        .rdata2 (rf_rdata2),
        .we     (rf_we    ),
        .waddr  (rf_waddr ),
        .wdata  (rf_wdata )
    );

    wire        csr_re;
    wire [13:0] csr_num;
    wire [31:0] csr_rvalue;
    wire        csr_we;
    wire [31:0] csr_wmask;
    wire [31:0] csr_wvalue;

    // interrupt
    wire        has_interrupt;
    wire [31:0] ex_entry;
    wire [31:0] ertn_entry;
    wire        exception_submit;
    wire [ 5:0] ecode_submit;
    wire [ 8:0] esubcode_submit;
    wire [31:0] exception_pc_submit;
    wire [31:0] exception_maddr_submit;
    wire        ertn_submit;

    wire [31:0] csr_tid;  // for rdcntid instruction
    wire [63:0] count;

    csr u_csr(
        .clk(clk),
        .rst(reset),
        .csr_re(csr_re),
        .csr_num(csr_num),
        .csr_rvalue(csr_rvalue),
        .csr_we(csr_we),
        .csr_wmask(csr_wmask),
        .csr_wvalue(csr_wvalue),
        .wb_ex(exception_submit),
        .wb_ecode(ecode_submit),
        .wb_esubcode(esubcode_submit),
        .wb_pc(exception_pc_submit),
        .wb_vaddr(exception_maddr_submit),
        .ertn_flush(ertn_submit),
        .ex_entry(ex_entry),
        .ertn_entry(ertn_entry),
        .has_int(has_interrupt),
        .tid(csr_tid),
        .count(count)
    );

    wire from_mul_req_ready;
    wire to_mul_req_valid;
    wire to_mul_resp_ready;
    wire from_mul_resp_valid;
    wire [31: 0] src1;
    wire [31: 0] src2;

    wire [63: 0] mul_result;

    wire from_div_req_ready;
    wire to_div_req_valid;
    wire to_div_resp_ready;
    wire from_div_resp_valid;
    wire [31: 0] div_quotient;
    wire [31: 0] div_remainder;

    multiplier u_mul(
        .mul_clk(clk),
        .reset(reset),
        .mul_op(EX_mul_op),
        .x(src1),
        .y(src2),

        .to_mul_req_valid(to_mul_req_valid),
        .from_mul_req_ready(from_mul_req_ready),
        .to_mul_resp_ready(to_mul_resp_ready),
        .from_mul_resp_valid(from_mul_resp_valid),

        .result(mul_result)

    );

    Div u_div(
        .clock(clk),
        .reset(reset),
        .io_in_ready(from_div_req_ready),
        .io_in_valid(to_div_req_valid),
        .io_in_bits_divOp(EX_div_op),
        .io_in_bits_dividend(EX_rj_value),
        .io_in_bits_divisor(EX_rkd_value),
        .io_out_ready(to_div_resp_ready),
        .io_out_valid(from_div_resp_valid),
        .io_out_bits_quotient(div_quotient),
        .io_out_bits_remainder(div_remainder)
    );

    wire IF_out_valid;

    wire ID_in_ready;
    wire ID_out_valid;
    wire [31: 0] ID_PC;
    wire ID_has_exception;
    wire [5: 0] ID_ecode;
    wire [8: 0] ID_esubcode;

    wire EX_in_ready;
    wire EX_out_valid;
    wire [31: 0] EX_csr_result;
    wire [31: 0] EX_PC;
    wire EX_br_taken;
    wire [31: 0] EX_br_target;
    wire [7: 0] EX_mem_op;
    wire [11: 0] EX_alu_op;
    wire [2: 0] EX_mul_op;
    wire [3: 0] EX_div_op;
    wire EX_src1_is_pc;
    wire EX_src1_is_imm;
    wire EX_res_from_mul;
    wire EX_res_from_div;
    wire EX_res_from_mem;
    wire EX_res_from_csr;
    wire EX_gr_we;
    wire EX_mem_we;
    wire [4: 0] EX_dest;
    wire [31: 0] EX_imm;
    wire [31: 0] EX_rj_value;
    wire [31: 0] EX_rkd_value;
    wire [31:0] EX_result_bypass;
    wire EX_this_flush;
    wire EX_has_exception;
    wire [5: 0] EX_ecode;
    wire [8: 0] EX_esubcode;
    wire EX_ertn;
    wire EX_rdcntid;
    wire EX_rdcntvl_w;
    wire EX_rdcntvh_w;

    wire MEM_in_ready;
    wire MEM_out_valid;
    wire [31: 0] MEM_csr_result;
    wire [31: 0] MEM_alu_result;
    wire [31: 0] MEM_PC;
    wire [7: 0] MEM_mem_op;
    wire [2: 0] MEM_mul_op;
    wire [3: 0] MEM_div_op;
    wire MEM_res_from_mul;
    wire MEM_res_from_div;
    wire MEM_res_from_mem;
    wire MEM_res_from_csr;
    wire MEM_gr_we;
    wire MEM_mem_we;
    wire [4: 0] MEM_dest;
    wire [31: 0] MEM_rkd_value;
    wire [31: 0] MEM_result_bypass;
    wire MEM_this_flush;
    wire MEM_has_exception;
    wire [5: 0] MEM_ecode;
    wire [8: 0] MEM_esubcode;
    wire [31: 0] MEM_exception_maddr;
    wire MEM_ertn;
    wire MEM_rdcntid;
    
    wire WB_in_ready;
    wire [31: 0] WB_PC;
    wire [31: 0] WB_csr_result;
    wire [31: 0] WB_alu_result;
    wire [31: 0] WB_mul_result;
    wire [31: 0] WB_div_result;
    wire [31: 0] WB_result_bypass;
    wire [7: 0] WB_mem_op;
    wire WB_res_from_mul;
    wire WB_res_from_div;
    wire WB_res_from_mem;
    wire WB_res_from_csr;
    wire WB_gr_we;
    wire [4: 0] WB_dest;
    wire WB_this_flush;
    wire WB_has_exception;
    wire [5: 0] WB_ecode;
    wire [8: 0] WB_esubcode;
    wire [31: 0] WB_exception_maddr;
    wire WB_ertn;
    wire WB_rdcntid;


    IF IF_unit(
        .clk(clk),
        .rst(reset),
        .out_valid(IF_out_valid),
        .out_ready(ID_in_ready),
        .ex_flush(exception_submit),
        .ertn_flush(ertn_submit),
        .ex_entry(ex_entry),
        .ertn_entry(ertn_entry),
        .br_taken(EX_br_taken),
        .br_target(EX_br_target),
        .inst_sram_en(inst_sram_en),
        .inst_sram_we(inst_sram_we),
        .inst_sram_addr(inst_sram_addr),
        .inst_sram_wdata(inst_sram_wdata),
        .PC_out(ID_PC),
        .has_exception_out(ID_has_exception),
        .ecode_out(ID_ecode),
        .esubcode_out(ID_esubcode)
    );

    ID ID_unit(
        .clk(clk),
        .rst(reset),

        .in_valid(IF_out_valid),
        .out_ready(EX_in_ready),
        .in_ready(ID_in_ready),
        .out_valid(ID_out_valid),
        .ex_flush(exception_submit),
        .ertn_flush(ertn_submit),

        .EX_result_bypass(EX_result_bypass),
        .MEM_valid(EX_out_valid),
        .MEM_gr_we(MEM_gr_we),
        .MEM_dest(MEM_dest),
        .MEM_res_from_mul(MEM_res_from_mul),
        .MEM_res_from_div(MEM_res_from_div),
        .MEM_res_from_mem(MEM_res_from_mem),
        .MEM_result_bypass(MEM_result_bypass),
        .MEM_rdcntid(MEM_rdcntid),
        
        .WB_valid(MEM_out_valid),
        .WB_gr_we(WB_gr_we),
        .WB_res_from_mul(WB_res_from_mul),
        .WB_res_from_div(WB_res_from_div),
        .WB_dest(WB_dest),
        .WB_result_bypass(WB_result_bypass),
        .WB_rdcntid(WB_rdcntid),
        
        .inst(inst_sram_rdata),
        .PC(ID_PC),
        .rf_raddr1(rf_raddr1),
        .rf_raddr2(rf_raddr2),
        .rf_rdata1(rf_rdata1),
        .rf_rdata2(rf_rdata2),

        .csr_re(csr_re),
        .csr_num(csr_num),
        .csr_rvalue(csr_rvalue),
        .csr_we(csr_we),
        .csr_wmask(csr_wmask),
        .csr_wvalue(csr_wvalue),

        .br_taken_out(EX_br_taken),
        .br_target_out(EX_br_target),
        .mem_op_out(EX_mem_op),
        .alu_op_out(EX_alu_op),
        .mul_op_out(EX_mul_op),
        .div_op_out(EX_div_op),
        .src1_is_pc_out(EX_src1_is_pc),
        .src2_is_imm_out(EX_src1_is_imm),
        .res_from_mul_out(EX_res_from_mul),
        .res_from_div_out(EX_res_from_div),
        .res_from_mem_out(EX_res_from_mem),
        .res_from_csr_out(EX_res_from_csr),
        .gr_we_out(EX_gr_we),
        .mem_we_out(EX_mem_we),
        .dest_out(EX_dest),
        .imm_out(EX_imm),
        .csr_result_out(EX_csr_result),
        .PC_out(EX_PC),
        .rj_value_out(EX_rj_value),
        .rkd_value_out(EX_rkd_value),
        .next_flush(EX_this_flush),
        .has_interrupt(has_interrupt),
        .has_exception(ID_has_exception),
        .ecode(ID_ecode),
        .esubcode(ID_esubcode),
        .has_exception_out(EX_has_exception),
        .ecode_out(EX_ecode),
        .esubcode_out(EX_esubcode),
        .ertn_out(EX_ertn),
        .rdcntid_out(EX_rdcntid),
        .rdcntvl_w_out(EX_rdcntvl_w),
        .rdcntvh_w_out(EX_rdcntvh_w)
    );

    EX EX_unit(
        .clk(clk),
        .rst(reset),

        .in_valid(ID_out_valid),
        .out_ready(MEM_in_ready),
        .in_ready(EX_in_ready),
        .out_valid(EX_out_valid),
        .ex_flush(exception_submit),
        .ertn_flush(ertn_submit),

        .from_mul_req_ready(from_mul_req_ready),
        .to_mul_req_valid(to_mul_req_valid),
        .from_div_req_ready(from_div_req_ready),
        .to_div_req_valid(to_div_req_valid),

        .csr_result(EX_csr_result),
        .PC(EX_PC),
        .mem_op(EX_mem_op),
        .alu_op(EX_alu_op),
        .mul_op(EX_mul_op),
        .div_op(EX_div_op),
        .src1_is_pc(EX_src1_is_pc),
        .src2_is_imm(EX_src1_is_imm),
        .res_from_mul(EX_res_from_mul),
        .res_from_div(EX_res_from_div),
        .res_from_mem(EX_res_from_mem),
        .res_from_csr(EX_res_from_csr),
        .gr_we(EX_gr_we),
        .mem_we(EX_mem_we),
        .dest(EX_dest),
        .imm(EX_imm),
        .rj_value(EX_rj_value),
        .rkd_value(EX_rkd_value),
        .src1_wire(src1),
        .src2_wire(src2),
        .result_bypass(EX_result_bypass),
        .alu_result_out(MEM_alu_result),
        .csr_result_out(MEM_csr_result),
        .PC_out(MEM_PC),
        .mem_op_out(MEM_mem_op),
        .mul_op_out(MEM_mul_op),
        .div_op_out(MEM_div_op),
        .res_from_mul_out(MEM_res_from_mul),
        .res_from_div_out(MEM_res_from_div),
        .res_from_mem_out(MEM_res_from_mem),
        .res_from_csr_out(MEM_res_from_csr),
        .gr_we_out(MEM_gr_we),
        .mem_we_out(MEM_mem_we),
        .dest_out(MEM_dest),
        .rkd_value_out(MEM_rkd_value),
        .this_flush(EX_this_flush),
        .next_flush(MEM_this_flush),
        .has_exception(EX_has_exception),
        .ecode(EX_ecode),
        .esubcode(EX_esubcode),
        .ertn(EX_ertn),
        .has_exception_out(MEM_has_exception),
        .ecode_out(MEM_ecode),
        .esubcode_out(MEM_esubcode),
        .exception_maddr_out(MEM_exception_maddr),
        .ertn_out(MEM_ertn),
        .rdcntid(EX_rdcntid),
        .rdcntid_out(MEM_rdcntid),
        .rdcntvl_w(EX_rdcntvl_w),
        .rdcntvh_w(EX_rdcntvh_w),
        .count(count)
    );

    MEM MEM_unit(
        .clk(clk),
        .rst(reset),

        .in_valid(EX_out_valid),
        .out_ready(WB_in_ready),
        .in_ready(MEM_in_ready),
        .out_valid(MEM_out_valid),
        .valid(valid),
        .ex_flush(exception_submit),
        .ertn_flush(ertn_submit),

        .mul_result(mul_result),

        .to_mul_resp_ready(to_mul_resp_ready),
        .to_div_resp_ready(to_div_resp_ready),
        .from_mul_resp_valid(from_mul_resp_valid),
        .from_div_resp_valid(from_div_resp_valid),
        .div_quotient(div_quotient),
        .div_remainder(div_remainder),

        .alu_result(MEM_alu_result),
        .csr_result(MEM_csr_result),
        .PC(MEM_PC),
        .mem_op(MEM_mem_op),
        .mul_op(MEM_mul_op),
        .div_op(MEM_div_op),
        .res_from_mul(MEM_res_from_mul),
        .res_from_div(MEM_res_from_div),
        .res_from_mem(MEM_res_from_mem),
        .res_from_csr(MEM_res_from_csr),
        .gr_we(MEM_gr_we),
        .mem_we(MEM_mem_we),
        .dest(MEM_dest),
        .rkd_value(MEM_rkd_value),
        .data_sram_en(data_sram_en),
        .data_sram_we(data_sram_we),
        .data_sram_addr(data_sram_addr),
        .data_sram_wdata(data_sram_wdata),
        .result_bypass(MEM_result_bypass),
        .csr_result_out(WB_csr_result),
        .alu_result_out(WB_alu_result),
        .mul_result_out(WB_mul_result),
        .div_result_out(WB_div_result),
        .PC_out(WB_PC),
        .mem_op_out(WB_mem_op),
        .res_from_mul_out(WB_res_from_mul),
        .res_from_div_out(WB_res_from_div),
        .res_from_mem_out(WB_res_from_mem),
        .res_from_csr_out(WB_res_from_csr),
        .gr_we_out(WB_gr_we),
        .dest_out(WB_dest),
        .this_flush(MEM_this_flush),
        .next_flush(WB_this_flush),
        .has_exception(MEM_has_exception),
        .ecode(MEM_ecode),
        .esubcode(MEM_esubcode),
        .exception_maddr(MEM_exception_maddr),
        .ertn(MEM_ertn),
        .has_exception_out(WB_has_exception),
        .ecode_out(WB_ecode),
        .esubcode_out(WB_esubcode),
        .exception_maddr_out(WB_exception_maddr),
        .ertn_out(WB_ertn),
        .rdcntid(MEM_rdcntid),
        .rdcntid_out(WB_rdcntid)
    );

    WB WB_unit(
        .clk(clk),
		.rst(reset),
		.in_valid(MEM_out_valid),
        .in_ready(WB_in_ready),
        .valid(valid),

        .data_sram_rdata(data_sram_rdata),
        .csr_result(WB_csr_result),
        .alu_result(WB_alu_result),
        .mul_result(WB_mul_result),
        .div_result(WB_div_result),
        .PC(WB_PC),
        .mem_op(WB_mem_op),
        .res_from_mem(WB_res_from_mem),
        .res_from_csr(WB_res_from_csr),
        .res_from_mul(WB_res_from_mul),
        .res_from_div(WB_res_from_div),
        .gr_we(WB_gr_we),
        .dest(WB_dest),
        .result_bypass(WB_result_bypass),
        .rf_we(rf_we),
        .rf_waddr(rf_waddr),
        .rf_wdata(rf_wdata),
        .debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_we(debug_wb_rf_we),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata),
        .this_flush(WB_this_flush),
        .has_exception(WB_has_exception),
        .ecode(WB_ecode),
        .esubcode(WB_esubcode),
        .exception_maddr(WB_exception_maddr),
        .ertn(WB_ertn),
        .exception_submit(exception_submit),
        .ecode_submit(ecode_submit),
        .esubcode_submit(esubcode_submit),
        .exception_pc_submit(exception_pc_submit),
        .exception_maddr_submit(exception_maddr_submit),
        .ertn_submit(ertn_submit),
        .csr_tid(csr_tid),
        .rdcntid(WB_rdcntid)
    );
endmodule
