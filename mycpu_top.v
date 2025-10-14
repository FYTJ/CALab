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

    wire IF_out_valid;

    wire ID_in_ready;
    wire ID_out_valid;
    wire [31: 0] ID_PC;

    wire EX_in_ready;
    wire EX_out_valid;
    wire [31: 0] EX_PC;
    wire EX_br_taken;
    wire [31: 0] EX_br_target;
    wire EX_load_use_sign;
    wire [11: 0] EX_alu_op;
    wire EX_src1_is_pc;
    wire EX_src1_is_imm;
    wire EX_res_from_mem;
    wire EX_gr_we;
    wire EX_mem_we;
    wire [4: 0] EX_dest;
    wire [31: 0] EX_imm;
    wire [31: 0] EX_rj_value;
    wire [31: 0] EX_rkd_value;
    wire [31: 0] alu_result;

    wire MEM_in_ready;
    wire MEM_out_valid;
    wire [31: 0] MEM_alu_result;
    wire [31: 0] MEM_PC;
    wire MEM_res_from_mem;
    wire MEM_gr_we;
    wire MEM_mem_we;
    wire [4: 0] MEM_dest;
    wire [31: 0] MEM_rkd_value;
    
    wire WB_in_ready;
    wire [31: 0] WB_PC;
    wire [31: 0] WB_alu_result;
    wire WB_res_from_mem;
    wire WB_gr_we;
    wire [4: 0] WB_dest;

    IF IF_unit(
        .clk(clk),
        .rst(reset),
        .out_valid(IF_out_valid),
        .out_ready(ID_in_ready),
        .br_taken(EX_br_taken),
        .br_target(EX_br_target),
        .load_use_sign(EX_load_use_sign),
        .inst_sram_en(inst_sram_en),
        .inst_sram_we(inst_sram_we),
        .inst_sram_addr(inst_sram_addr),
        .inst_sram_wdata(inst_sram_wdata),
        .PC_out(ID_PC)
    );

    ID ID_unit(
        .clk(clk),
        .rst(reset),

        .in_valid(IF_out_valid),
        .out_ready(EX_in_ready),
        .in_ready(ID_in_ready),
        .out_valid(ID_out_valid),

        .alu_result(alu_result),
        .MEM_valid(EX_out_valid),
        .MEM_gr_we(MEM_gr_we),
        .MEM_dest(MEM_dest),
        .MEM_res_from_mem(MEM_res_from_mem),
        .MEM_alu_result(MEM_alu_result),
        .WB_valid(valid),
        .WB_gr_we(WB_gr_we),
        .WB_res_from_mem(WB_res_from_mem),
        .WB_dest(WB_dest),
        .WB_data_sram_rdata(data_sram_rdata),
        .WB_alu_result(WB_alu_result),
        
        .inst(inst_sram_rdata),
        .PC(ID_PC),
        .rf_raddr1(rf_raddr1),
        .rf_raddr2(rf_raddr2),
        .rf_rdata1(rf_rdata1),
        .rf_rdata2(rf_rdata2),
        .br_taken_out(EX_br_taken),
        .br_target_out(EX_br_target),
        .load_use_sign(EX_load_use_sign),
        .alu_op_out(EX_alu_op),
        .src1_is_pc_out(EX_src1_is_pc),
        .src2_is_imm_out(EX_src1_is_imm),
        .res_from_mem_out(EX_res_from_mem),
        .gr_we_out(EX_gr_we),
        .mem_we_out(EX_mem_we),
        .dest_out(EX_dest),
        .imm_out(EX_imm),
        .PC_out(EX_PC),
        .rj_value_out(EX_rj_value),
        .rkd_value_out(EX_rkd_value)
    );

    EX EX_unit(
        .clk(clk),
        .rst(reset),

        .in_valid(ID_out_valid),
        .out_ready(MEM_in_ready),
        .in_ready(EX_in_ready),
        .out_valid(EX_out_valid),

        .PC(EX_PC),
        .alu_op(EX_alu_op),
        .src1_is_pc(EX_src1_is_pc),
        .src2_is_imm(EX_src1_is_imm),
        .res_from_mem(EX_res_from_mem),
        .gr_we(EX_gr_we),
        .mem_we(EX_mem_we),
        .dest(EX_dest),
        .imm(EX_imm),
        .rj_value(EX_rj_value),
        .rkd_value(EX_rkd_value),
        .alu_result(alu_result),
        .alu_result_out(MEM_alu_result),
        .PC_out(MEM_PC),
        .res_from_mem_out(MEM_res_from_mem),
        .gr_we_out(MEM_gr_we),
        .mem_we_out(MEM_mem_we),
        .dest_out(MEM_dest),
        .rkd_value_out(MEM_rkd_value)
    );

    MEM MEM_unit(
        .clk(clk),
        .rst(reset),

        .in_valid(EX_out_valid),
        .out_ready(WB_in_ready),
        .in_ready(MEM_in_ready),
        .out_valid(MEM_out_valid),
        .valid(valid),

        .alu_result(MEM_alu_result),
        .PC(MEM_PC),
        .res_from_mem(MEM_res_from_mem),
        .gr_we(MEM_gr_we),
        .mem_we(MEM_mem_we),
        .dest(MEM_dest),
        .rkd_value(MEM_rkd_value),
        .data_sram_en(data_sram_en),
        .data_sram_we(data_sram_we),
        .data_sram_addr(data_sram_addr),
        .data_sram_wdata(data_sram_wdata),
        .alu_result_out(WB_alu_result),
        .PC_out(WB_PC),
        .res_from_mem_out(WB_res_from_mem),
        .gr_we_out(WB_gr_we),
        .dest_out(WB_dest)
    );

    WB WB_unit(
        .clk(clk),
		.rst(reset),
		.in_valid(MEM_out_valid),
        .in_ready(WB_in_ready),
        .valid(valid),

        .data_sram_rdata(data_sram_rdata),
        .alu_result(WB_alu_result),
        .PC(WB_PC),
        .res_from_mem(WB_res_from_mem),
        .gr_we(WB_gr_we),
        .dest(WB_dest),
        .rf_we(rf_we),
        .rf_waddr(rf_waddr),
        .rf_wdata(rf_wdata),
        .debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_we(debug_wb_rf_we),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata)
    );
endmodule
