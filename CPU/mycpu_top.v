`include "./utils/decoder_2_4.v"
`include "./utils/decoder_4_16.v"
`include "./utils/decoder_5_32.v"
`include "./utils/decoder_6_64.v"
`include "../multiplier/multiplier.v"
`include "../multiplier/booth.v"
`include "../multiplier/wallace.v"
`include "../multiplier/full_adder.v"
`include "../divider/Div.v"
`include "../AXI-bridge/AXI_bridge.v"

module mycpu_top #(
    parameter TLBNUM = 16
) (
    input  wire        aclk,
    input  wire        aresetn,

    // AR channel
    output [3: 0] arid,
    output [31: 0] araddr,
    output [7: 0] arlen,
    output [2: 0] arsize,
    output [1: 0] arburst,
    output [1: 0] arlock,
    output [3: 0] arcache,
    output [2: 0] arprot,
    output arvalid,
    input arready,

    // R channel
    input [3: 0] rid,
    input [31: 0] rdata,
    input [1: 0] rresp,
    input rlast,
    input rvalid,
    output rready,

    // AW channel
    output [3: 0] awid,
    output [31: 0] awaddr,
    output [7: 0] awlen,
    output [2: 0] awsize,
    output [1: 0] awburst,
    output [1: 0] awlock,
    output [3: 0] awcache,
    output [2: 0] awprot,
    output awvalid,
    input awready,

    // W channel
    output [3: 0] wid,
    output [31: 0] wdata,
    output [3: 0] wstrb,
    output wlast,
    output wvalid,
    input wready,

    // B channel
    input [3: 0] bid,
    input [1: 0] bresp,
    input bvalid,
    output bready,

    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    wire clk = aclk;
    reg         reset;
    wire resetn = ~reset;
    always @(posedge clk) reset <= ~aresetn;

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
    wire [31:0] ex_tlbr_entry;
    wire [31:0] ertn_entry;
    wire        exception_submit;
    wire [ 5:0] ecode_submit;
    wire [ 8:0] esubcode_submit;
    wire [31:0] exception_pc_submit;
    wire [31:0] exception_maddr_submit;
    wire        ertn_submit;
    wire        ex_tlbr_submit;

    wire [31:0] csr_tid;  // for rdcntid instruction
    wire [63:0] count;

    wire [9:0]  asid_asid_value;
    wire [1: 0] crmd_plv_value;
    wire        crmd_da_value;
    wire        crmd_pg_value;
    wire [18:0] tlbehi_vppn_value;
    wire        dmw0_plv0_value;
    wire        dmw0_plv1_value;
    wire        dmw0_plv2_value;
    wire        dmw0_plv3_value;
    wire [1: 0] dmw0_mat_value;
    wire [2: 0] dmw0_pseg_value;
    wire [2: 0] dmw0_vseg_value;
    wire        dmw1_plv0_value;
    wire        dmw1_plv1_value;
    wire        dmw1_plv2_value;
    wire        dmw1_plv3_value;
    wire [1: 0] dmw1_mat_value;
    wire [2: 0] dmw1_pseg_value;
    wire [2: 0] dmw1_vseg_value;

    // TLB
    wire EX_tlbsrch;
    wire EX_tlbrd;
    wire EX_tlbwr;
    wire EX_tlbfill;
    wire EX_invtlb;
    wire [4:0] EX_invtlb_op;

    wire MEM_tlbsrch;
    wire MEM_tlbrd;
    wire MEM_tlbwr;
    wire MEM_tlbfill;
    wire MEM_invtlb;
    wire [ 4: 0] MEM_invtlb_op;

    wire MEM_tlbsrch_to_csr;
    wire MEM_tlbrd_to_csr;
    wire MEM_tlbwr_to_csr;
    wire MEM_tlbfill_to_csr;
    wire MEM_invtlb_to_csr;
    wire [4:0] MEM_invtlb_op_to_csr;

    wire ID_this_tlb_refetch;
    wire EX_this_tlb_refetch;
    wire MEM_this_tlb_refetch;
    wire RDW_this_tlb_refetch;
    
    wire RDW_tlb;
    wire tlb_submit;
    wire [31:0] tlb_flush_entry;

    wire [18:0] tlb_s0_vppn;
    wire        tlb_s0_va_bit12;
    wire [ 9:0] tlb_s0_asid;
    wire        tlb_s0_found;
    wire [$clog2(TLBNUM)-1:0] tlb_s0_index;
    wire [19:0] tlb_s0_ppn;
    wire [ 5:0] tlb_s0_ps;
    wire [ 1:0] tlb_s0_plv;
    wire [ 1:0] tlb_s0_mat;
    wire        tlb_s0_d;
    wire        tlb_s0_v;

    wire [18:0] tlb_s1_vppn;
    wire        tlb_s1_va_bit12;
    wire [ 9:0] tlb_s1_asid;
    wire        tlb_s1_found;
    wire [$clog2(TLBNUM)-1:0] tlb_s1_index;
    wire [19:0] tlb_s1_ppn;
    wire [ 5:0] tlb_s1_ps;
    wire [ 1:0] tlb_s1_plv;
    wire [ 1:0] tlb_s1_mat;
    wire        tlb_s1_d;
    wire        tlb_s1_v;

    wire tlb_we;
    wire [$clog2(TLBNUM)-1:0] tlb_w_index;
    wire tlb_w_e;
    wire [18:0] tlb_w_vppn;
    wire [ 5:0] tlb_w_ps;
    wire [ 9:0] tlb_w_asid;
    wire tlb_w_g;
    wire [19:0] tlb_w_ppn0;
    wire [ 1:0] tlb_w_plv0;
    wire [ 1:0] tlb_w_mat0;
    wire tlb_w_d0;
    wire tlb_w_v0;
    wire [19:0] tlb_w_ppn1;
    wire [ 1:0] tlb_w_plv1;
    wire [ 1:0] tlb_w_mat1;
    wire tlb_w_d1;
    wire tlb_w_v1;

    wire [$clog2(TLBNUM)-1:0] tlb_r_index;
    wire tlb_r_e;
    wire [18:0] tlb_r_vppn;
    wire [ 5:0] tlb_r_ps;
    wire [ 9:0] tlb_r_asid;
    wire tlb_r_g;
    wire [19:0] tlb_r_ppn0;
    wire [ 1:0] tlb_r_plv0;
    wire [ 1:0] tlb_r_mat0;
    wire tlb_r_d0;
    wire tlb_r_v0;
    wire [19:0] tlb_r_ppn1;
    wire [ 1:0] tlb_r_plv1;
    wire [ 1:0] tlb_r_mat1;
    wire tlb_r_d1;
    wire tlb_r_v1;

    wire  tlb_invtlb_valid;
    wire  [4: 0] tlb_invtlb_op;

    wire csr_flush_submit;
    wire [31:0] csr_flush_target_submit;
    wire EX_csr_flush;
    wire ID_this_csr_refetch;
    wire EX_this_csr_refetch;

    // csr和mmu共用端口
    assign tlb_s1_asid = MEM_tlbsrch_to_csr ? asid_asid_value : MEM_invtlb_to_csr ? MEM_rj_value[9: 0] : asid_asid_value;
    assign tlb_s1_vppn = MEM_tlbsrch_to_csr ? tlbehi_vppn_value : MEM_invtlb_to_csr ? MEM_rkd_value[31: 13] : data_sram_vaddr[31: 13];

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
        .ex_tlbr_entry(ex_tlbr_entry),
        .ertn_entry(ertn_entry),
        .has_int(has_interrupt),
        .tid(csr_tid),
        .count(count),
        
        .asid_asid_value(asid_asid_value),
        .crmd_plv_value(crmd_plv_value),
        .crmd_da_value(crmd_da_value),
        .crmd_pg_value(crmd_pg_value),
        .tlbehi_vppn_value(tlbehi_vppn_value),
        .dmw0_plv0_value(dmw0_plv0_value),
        .dmw0_plv1_value(dmw0_plv1_value),
        .dmw0_plv2_value(dmw0_plv2_value),
        .dmw0_plv3_value(dmw0_plv3_value),
        .dmw0_mat_value(dmw0_mat_value),
        .dmw0_pseg_value(dmw0_pseg_value),
        .dmw0_vseg_value(dmw0_vseg_value),
        .dmw1_plv0_value(dmw1_plv0_value),
        .dmw1_plv1_value(dmw1_plv1_value),
        .dmw1_plv2_value(dmw1_plv2_value),
        .dmw1_plv3_value(dmw1_plv3_value),
        .dmw1_mat_value(dmw1_mat_value),
        .dmw1_pseg_value(dmw1_pseg_value),
        .dmw1_vseg_value(dmw1_vseg_value),

        .tlbsrch(MEM_tlbsrch_to_csr),
        .tlbrd(MEM_tlbrd_to_csr),
        .tlbwr(MEM_tlbwr_to_csr),
        .tlbfill(MEM_tlbfill_to_csr),
        .invtlb(MEM_invtlb_to_csr),
        .invtlb_op(MEM_invtlb_op_to_csr),

        .tlb_s1_found(tlb_s1_found),
        .tlb_s1_index(tlb_s1_index),

        .tlb_we(tlb_we),
        .tlb_w_index(tlb_w_index),
        .tlb_w_e(tlb_w_e),
        .tlb_w_vppn(tlb_w_vppn),
        .tlb_w_ps(tlb_w_ps),
        .tlb_w_asid(tlb_w_asid),
        .tlb_w_g(tlb_w_g),
        .tlb_w_ppn0(tlb_w_ppn0),
        .tlb_w_plv0(tlb_w_plv0),
        .tlb_w_mat0(tlb_w_mat0),
        .tlb_w_d0(tlb_w_d0),
        .tlb_w_v0(tlb_w_v0),
        .tlb_w_ppn1(tlb_w_ppn1),
        .tlb_w_plv1(tlb_w_plv1),
        .tlb_w_mat1(tlb_w_mat1),
        .tlb_w_d1(tlb_w_d1),
        .tlb_w_v1(tlb_w_v1),

        .tlb_r_index(tlb_r_index),
        .tlb_r_e(tlb_r_e),
        .tlb_r_vppn(tlb_r_vppn),
        .tlb_r_ps(tlb_r_ps),
        .tlb_r_asid(tlb_r_asid),
        .tlb_r_g(tlb_r_g),
        .tlb_r_ppn0(tlb_r_ppn0),
        .tlb_r_plv0(tlb_r_plv0),
        .tlb_r_mat0(tlb_r_mat0),
        .tlb_r_d0(tlb_r_d0),
        .tlb_r_v0(tlb_r_v0),
        .tlb_r_ppn1(tlb_r_ppn1),
        .tlb_r_plv1(tlb_r_plv1),
        .tlb_r_mat1(tlb_r_mat1),
        .tlb_r_d1(tlb_r_d1),
        .tlb_r_v1(tlb_r_v1),

        .tlb_invtlb_valid(tlb_invtlb_valid),
        .tlb_invtlb_op(tlb_invtlb_op)
    );

    tlb u_tlb(
        .clk(clk),

        .s0_vppn(tlb_s0_vppn),
        .s0_va_bit12(tlb_s0_va_bit12),
        .s0_asid(asid_asid_value),
        .s0_found(tlb_s0_found),
        .s0_index(tlb_s0_index),
        .s0_ppn(tlb_s0_ppn),
        .s0_ps(tlb_s0_ps),
        .s0_plv(tlb_s0_plv),
        .s0_mat(tlb_s0_mat),
        .s0_d(tlb_s0_d),
        .s0_v(tlb_s0_v),

        .s1_vppn(tlb_s1_vppn),
        .s1_va_bit12(tlb_s1_va_bit12),
        .s1_asid(tlb_s1_asid),
        .s1_found(tlb_s1_found),
        .s1_index(tlb_s1_index),
        .s1_ppn(tlb_s1_ppn),
        .s1_ps(tlb_s1_ps),
        .s1_plv(tlb_s1_plv),
        .s1_mat(tlb_s1_mat),
        .s1_d(tlb_s1_d),
        .s1_v(tlb_s1_v),

        .invtlb_valid(tlb_invtlb_valid),
        .invtlb_op(tlb_invtlb_op),

        .we(tlb_we),
        .w_index(tlb_w_index),
        .w_e(tlb_w_e),
        .w_vppn(tlb_w_vppn),
        .w_ps(tlb_w_ps),
        .w_asid(tlb_w_asid),
        .w_g(tlb_w_g),
        .w_ppn0(tlb_w_ppn0),
        .w_plv0(tlb_w_plv0),
        .w_mat0(tlb_w_mat0),
        .w_d0(tlb_w_d0),
        .w_v0(tlb_w_v0),
        .w_ppn1(tlb_w_ppn1),
        .w_plv1(tlb_w_plv1),
        .w_mat1(tlb_w_mat1),
        .w_d1(tlb_w_d1),
        .w_v1(tlb_w_v1),

        .r_index(tlb_r_index),
        .r_e(tlb_r_e),
        .r_vppn(tlb_r_vppn),
        .r_ps(tlb_r_ps),
        .r_asid(tlb_r_asid),
        .r_g(tlb_r_g),
        .r_ppn0(tlb_r_ppn0),
        .r_plv0(tlb_r_plv0),
        .r_mat0(tlb_r_mat0),
        .r_d0(tlb_r_d0),
        .r_v0(tlb_r_v0),
        .r_ppn1(tlb_r_ppn1),
        .r_plv1(tlb_r_plv1),
        .r_mat1(tlb_r_mat1),
        .r_d1(tlb_r_d1),
        .r_v1(tlb_r_v1)
    );

    // MMU
    wire [31: 0] inst_sram_paddr;
    wire [31: 0] data_sram_paddr;
    wire [5: 0] mmu_ecode_i;
    wire [8: 0] mmu_esubcode_i;
    wire [5: 0] mmu_ecode_d;
    wire [8: 0] mmu_esubcode_d;

    mmu u_mmu(
        .inst_sram_vaddr(inst_sram_vaddr),
        .inst_sram_wr(inst_sram_wr),
        .data_sram_vaddr(data_sram_vaddr),
        .data_sram_wr(data_sram_wr),
        
        .crmd_plv_value(crmd_plv_value),
        .crmd_da_value(crmd_da_value),
        .crmd_pg_value(crmd_pg_value),
        .dmw0_plv0_value(dmw0_plv0_value),
        .dmw0_plv1_value(dmw0_plv1_value),
        .dmw0_plv2_value(dmw0_plv2_value),
        .dmw0_plv3_value(dmw0_plv3_value),
        .dmw0_mat_value(dmw0_mat_value),
        .dmw0_pseg_value(dmw0_pseg_value),
        .dmw0_vseg_value(dmw0_vseg_value),
        .dmw1_plv0_value(dmw1_plv0_value),
        .dmw1_plv1_value(dmw1_plv1_value),
        .dmw1_plv2_value(dmw1_plv2_value),
        .dmw1_plv3_value(dmw1_plv3_value),
        .dmw1_mat_value(dmw1_mat_value),
        .dmw1_pseg_value(dmw1_pseg_value),
        .dmw1_vseg_value(dmw1_vseg_value),

        .tlb_s0_found(tlb_s0_found),
        .tlb_s0_ppn(tlb_s0_ppn),
        .tlb_s0_plv(tlb_s0_plv),
        .tlb_s0_mat(tlb_s0_mat),
        .tlb_s0_v(tlb_s0_v),
        .tlb_s0_vppn(tlb_s0_vppn),
        .tlb_s0_va_bit12(tlb_s0_va_bit12),
        .tlb_s1_found(tlb_s1_found),
        .tlb_s1_ppn(tlb_s1_ppn),
        .tlb_s1_plv(tlb_s1_plv),
        .tlb_s1_mat(tlb_s1_mat),
        .tlb_s1_d(tlb_s1_d),
        .tlb_s1_v(tlb_s1_v),
        .tlb_s1_va_bit12(tlb_s1_va_bit12),

        .inst_sram_paddr(inst_sram_paddr),
        .data_sram_paddr(data_sram_paddr),

        .ecode_i(mmu_ecode_i),
        .esubcode_i(mmu_esubcode_i),
        .ecode_d(mmu_ecode_d),
        .esubcode_d(mmu_esubcode_d)
    );

    // inst sram-like interface
    wire        inst_sram_req;
    wire        inst_sram_wr;
    wire [1 :0] inst_sram_size;
    wire [3 :0] inst_sram_wstrb;
    wire [31:0] inst_sram_vaddr;
    wire [31:0] inst_sram_wdata;
    wire        inst_sram_addr_ok;
    wire        inst_sram_data_ok;
    wire [31:0] inst_sram_rdata;
    // data sram-like interface
    wire        data_sram_req;
    wire        data_sram_wr;
    wire [1 :0] data_sram_size;
    wire [3 :0] data_sram_wstrb;
    wire [31:0] data_sram_vaddr;
    wire [31:0] data_sram_wdata;
    wire        data_sram_addr_ok;
    wire        data_sram_data_ok;
    wire [31:0] data_sram_rdata;


    // temporary wire for AXI bridge
    wire [7: 0] inst_sram_len = 8'd0;
    wire [7: 0] data_sram_len = 8'd0;
    wire data_sram_wr_last = data_sram_req;
    wire data_sram_wr_data_valid = data_sram_req;

    AXI_bridge u_AXI_bridge (
        .clk            (clk),
        .resetn         (resetn),

        .sram_req_1     (inst_sram_req),
        .sram_wr_1      (inst_sram_wr),
        .sram_size_1    (inst_sram_size),
        .sram_addr_1    (inst_sram_paddr),
        .sram_len_1     (inst_sram_len),
        .sram_wstrb_1   (inst_sram_wstrb),
        .sram_wdata_1   (inst_sram_wdata),
        .sram_addr_ok_1 (inst_sram_addr_ok),
        .sram_data_ok_1 (inst_sram_data_ok),
        .sram_rdata_1   (inst_sram_rdata),

        .sram_req_2     (data_sram_req),
        .sram_wr_2      (data_sram_wr),
        .sram_size_2    (data_sram_size),
        .sram_addr_2    (data_sram_paddr),
        .sram_len_2     (data_sram_len),
        .sram_wstrb_2   (data_sram_wstrb),
        .sram_wdata_2   (data_sram_wdata),
        .sram_last_2    (data_sram_wr_last),
        .sram_data_valid_2(data_sram_wr_data_valid),
        .sram_addr_ok_2 (data_sram_addr_ok),
        .sram_data_ok_2 (data_sram_data_ok),
        .sram_rdata_2   (data_sram_rdata),

        .arid           (arid),
        .araddr         (araddr),
        .arlen          (arlen),
        .arsize         (arsize),
        .arburst        (arburst),
        .arlock         (arlock),
        .arcache        (arcache),
        .arprot         (arprot),
        .arvalid        (arvalid),
        .arready        (arready),

        .rid            (rid),
        .rdata          (rdata),
        .rresp          (rresp),
        .rlast          (rlast),
        .rvalid         (rvalid),
        .rready         (rready),

        .awid           (awid),
        .awaddr         (awaddr),
        .awlen          (awlen),
        .awsize         (awsize),
        .awburst        (awburst),
        .awlock         (awlock),
        .awcache        (awcache),
        .awprot         (awprot),
        .awvalid        (awvalid),
        .awready        (awready),

        .wid            (wid),
        .wdata          (wdata),
        .wstrb          (wstrb),
        .wlast          (wlast),
        .wvalid         (wvalid),
        .wready         (wready),

        .bid            (bid),
        .bresp          (bresp),
        .bvalid         (bvalid),
        .bready         (bready)
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

    wire [1:0] discard;

    wire IF_out_valid;
    wire IF_discard;

    wire IW_in_ready;
    wire IW_out_valid;
    wire [31: 0] IW_PC;
    wire [31: 0] IW_inst;
    wire IW_inst_valid;
    wire IW_has_exception;
    wire [5: 0] IW_ecode;
    wire [8: 0] IW_esubcode;
    wire IW_inst_valid_out;
    wire [31:0] IW_exception_maddr;
    

    wire ID_in_ready;
    wire ID_out_valid;
    wire [31: 0] ID_PC;
    wire [31: 0] ID_inst;
    wire ID_this_flush;
    wire ID_has_exception;
    wire [5: 0] ID_ecode;
    wire [8: 0] ID_esubcode;
    wire [31:0] ID_exception_maddr;

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
    wire EX_br_stall;
    wire EX_mem_inst;
    wire [31:0] EX_exception_maddr;

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
    wire [31: 0] MEM_rj_value;
    wire [31: 0] MEM_rkd_value;
    wire [31: 0] MEM_result_bypass;
    wire MEM_this_flush;
    wire MEM_has_exception;
    wire [5: 0] MEM_ecode;
    wire [8: 0] MEM_esubcode;
    wire [31: 0] MEM_exception_maddr;
    wire MEM_ertn;
    wire MEM_rdcntid;
    wire MEM_mem_inst;


    wire RDW_in_ready;
    wire RDW_out_valid;
    wire RDW_data_valid;
    //wire RDW_discard;
    wire [31:0] RDW_PC;
    wire [31:0] RDW_data;
    wire [31:0] RDW_csr_result;
    wire [31:0] RDW_alu_result;
    wire [31:0] RDW_mul_result;
    wire [31:0] RDW_div_result;
    wire [7:0] RDW_mem_op;
    wire RDW_res_from_mul;
	wire RDW_res_from_div;
    wire RDW_res_from_mem;
    wire RDW_res_from_csr;
    wire RDW_gr_we;
    wire RDW_mem_we;
    wire [4:0] RDW_dest;
    wire [31:0] RDW_result_bypass;
    wire RDW_this_flush;
    wire RDW_has_exception;
    wire [5:0] RDW_ecode;
    wire [8:0] RDW_esubcode;
    wire [31:0] RDW_exception_maddr;
    wire RDW_ertn;
    wire RDW_rdcntid;
    wire RDW_data_valid_out;
    
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
    wire [31:0] WB_data;


    // // temporary
    // wire inst_wr;
    // wire [1:0] inst_size;
    // wire [3:0] inst_wstrb;
    // wire inst_addr_ok = 1'b1;
    // reg inst_data_ok;
    // assign inst_sram_we = {4{inst_wr}};
    // always @(posedge clk) begin
    //     if(reset) begin
    //         inst_data_ok <= 1'b0;
    //     end
    //     else begin
    //         inst_data_ok <= inst_sram_en;
    //     end
    // end

    IF IF_unit(
        .clk(clk),
        .rst(reset),
        .out_valid(IF_out_valid),
        .out_ready(IW_in_ready),
        .ex_flush(exception_submit),
        .ex_tlbr(ex_tlbr_submit),
        .ertn_flush(ertn_submit),
        .ex_entry(ex_entry),
        .ex_tlbr_entry(ex_tlbr_entry),
        .ertn_entry(ertn_entry),
        .br_taken(EX_br_taken),
        .br_target(EX_br_target),
        .br_stall(EX_br_stall),
        .ID_in_valid(IW_out_valid),
        .discard(discard),
        .IW_inst_valid(IW_inst_valid_out),

        .req(inst_sram_req),
        .wr(inst_sram_wr),
        .size(inst_sram_size),
        .addr(inst_sram_vaddr),
        .wstrb(inst_sram_wstrb),
        .wdata(inst_sram_wdata),
        .addr_ok(inst_sram_addr_ok),
        .data_ok(inst_sram_data_ok),
        .rdata(inst_sram_rdata),

        .PC_out(IW_PC),
        .inst_out(IW_inst),
        .inst_valid_out(IW_inst_valid),
        .has_exception_out(IW_has_exception),
        .ecode_out(IW_ecode),
        .esubcode_out(IW_esubcode),

        .discard_out_wire(IF_discard),

        .tlb_flush(tlb_submit),
        .tlb_flush_entry(tlb_flush_entry),

        .mmu_ecode_i(mmu_ecode_i),
        .mmu_esubcode_i(mmu_esubcode_i),

        .csr_flush(csr_flush_submit),
        .csr_flush_target(csr_flush_target_submit),

        .exception_maddr_out(IW_exception_maddr)
    );

    IW IW_unit(
        .clk(clk),
        .rst(reset),

        .in_valid(IF_out_valid),
        .out_ready(ID_in_ready),
        .in_ready(IW_in_ready),
        .out_valid(IW_out_valid),

        .PC_from_IF(IW_PC),
        .inst_from_IF(IW_inst),
        .inst_valid_from_IF(IW_inst_valid),
        .discard_from_IF(IF_discard),

        .br_taken(EX_br_taken),

        .data_ok(inst_sram_data_ok),
        .rdata(inst_sram_rdata),

        .inst_out(ID_inst),
        .PC_out(ID_PC),
        .discard(discard),
        .inst_valid(IW_inst_valid_out),

        .ex_flush(exception_submit),
        .ertn_flush(ertn_submit),
        .ID_flush(ID_this_flush),
        .EX_flush(EX_this_flush),
        .MEM_flush(MEM_this_flush),
        .RDW_flush(RDW_this_flush),
        .WB_flush(WB_this_flush),

        .has_exception(IW_has_exception),
        .ecode(IW_ecode),
        .esubcode(IW_esubcode),
        .has_exception_out(ID_has_exception),
        .ecode_out(ID_ecode),
        .esubcode_out(ID_esubcode),

        .ID_this_tlb_refetch(ID_this_tlb_refetch),
        .EX_this_tlb_refetch(EX_this_tlb_refetch),
        .MEM_this_tlb_refetch(MEM_this_tlb_refetch),
        .RDW_this_tlb_refetch(RDW_this_tlb_refetch),

        .tlb_flush(tlb_submit),

        .ID_this_csr_refetch(ID_this_csr_refetch),
        .EX_this_csr_refetch(EX_this_csr_refetch),
        .csr_flush(csr_flush_submit),

        .exception_maddr(IW_exception_maddr),
        .exception_maddr_out(ID_exception_maddr)
    );

    ID ID_unit(
        .clk(clk),
        .rst(reset),

        .in_valid(IW_out_valid),
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

        .RDW_valid(MEM_out_valid),
        .RDW_gr_we(RDW_gr_we),
        .RDW_dest(RDW_dest),
        .RDW_res_from_mul(RDW_res_from_mul),
        .RDW_res_from_div(RDW_res_from_div),
        .RDW_res_from_mem(RDW_res_from_mem),
        .RDW_result_bypass(RDW_result_bypass),
        .RDW_rdcntid(RDW_rdcntid),
        
        .WB_valid(RDW_out_valid),
        .WB_gr_we(WB_gr_we),
        .WB_res_from_mul(WB_res_from_mul),
        .WB_res_from_div(WB_res_from_div),
        .WB_dest(WB_dest),
        .WB_result_bypass(WB_result_bypass),
        .WB_rdcntid(WB_rdcntid),
        
        .inst(ID_inst),
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
        .this_flush(ID_this_flush),
        .EX_flush(EX_this_flush),
        .MEM_flush(MEM_this_flush),
        .RDW_flush(RDW_this_flush),
        .WB_flush(WB_this_flush),
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
        .rdcntvh_w_out(EX_rdcntvh_w),

        .tlbsrch_out(EX_tlbsrch),
        .tlbrd_out(EX_tlbrd),
        .tlbwr_out(EX_tlbwr),
        .tlbfill_out(EX_tlbfill),
        .invtlb_out(EX_invtlb),
        .invtlb_op_out(EX_invtlb_op),

        .this_tlb_refetch(ID_this_tlb_refetch),
        .EX_this_tlb_refetch(EX_this_tlb_refetch),
        .MEM_this_tlb_refetch(MEM_this_tlb_refetch),
        .RDW_this_tlb_refetch(RDW_this_tlb_refetch),

        .tlb_flush(tlb_submit),
        
        // .csr_flush_out_wire(csr_flush),
        // .csr_flush_target_out_wire(csr_flush_target),

        .this_csr_refetch(ID_this_csr_refetch),
        // .csr_flush_target(csr_flush_target),

        .csr_flush_out(EX_csr_flush),

        .EX_this_csr_refetch(EX_this_csr_refetch),
        .csr_flush(csr_flush_submit),

        .br_stall(EX_br_stall),

        .EX_mem_inst(EX_mem_inst),
        .MEM_mem_inst(MEM_mem_inst),

        .exception_maddr(ID_exception_maddr),
        .exception_maddr_out(EX_exception_maddr)
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
        .rj_value_out(MEM_rj_value),
        .rkd_value_out(MEM_rkd_value),
        .this_flush(EX_this_flush),
        .MEM_flush(MEM_this_flush),
        .RDW_flush(RDW_this_flush),
        .WB_flush(WB_this_flush),
        .has_exception(EX_has_exception),
        .ecode(EX_ecode),
        .esubcode(EX_esubcode),
        .exception_maddr(EX_exception_maddr),
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
        .count(count),

        .tlbsrch(EX_tlbsrch),
        .tlbrd(EX_tlbrd),
        .tlbwr(EX_tlbwr),
        .tlbfill(EX_tlbfill),
        .invtlb(EX_invtlb),
        .invtlb_op(EX_invtlb_op),

        .tlbsrch_out(MEM_tlbsrch),
        .tlbrd_out(MEM_tlbrd),
        .tlbwr_out(MEM_tlbwr),
        .tlbfill_out(MEM_tlbfill),
        .invtlb_out(MEM_invtlb),
        .invtlb_op_out(MEM_invtlb_op),

        .this_tlb_refetch(EX_this_tlb_refetch),
        .MEM_this_tlb_refetch(MEM_this_tlb_refetch),
        .RDW_this_tlb_refetch(RDW_this_tlb_refetch),

        .csr_flush_input(EX_csr_flush),
        .this_csr_refetch(EX_this_csr_refetch),
        .csr_flush_submit(csr_flush_submit),
        .csr_flush_target_submit(csr_flush_target_submit),

        .tlb_flush(tlb_submit),

        .mem_inst(EX_mem_inst)
    );



    // // temporary
    // wire data_req;
    // wire data_wr;
    // wire [1:0] data_size;
    // wire [3:0] data_wstrb;
    // wire data_addr_ok = 1'b1;
    // reg data_data_ok;
    // assign data_sram_en = data_req;
    // assign data_sram_we = {4{data_req}} & data_wstrb;
    // always @(posedge clk) begin
    //     if(reset) begin
    //         data_data_ok <= 1'b0;
    //     end
    //     else begin
    //         data_data_ok <= data_req;
    //     end
    // end

    MEM MEM_unit(
        .clk(clk),
        .rst(reset),

        .in_valid(EX_out_valid),
        .out_ready(RDW_in_ready),
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
        // .rj_value(MEM_rj_value),
        .rkd_value(MEM_rkd_value),
        .RDW_data_valid(RDW_data_valid_out),

        .req(data_sram_req),
        .wr(data_sram_wr),
        .size(data_sram_size),
        .addr(data_sram_vaddr),
        .wstrb(data_sram_wstrb),
        .wdata(data_sram_wdata),
        .addr_ok(data_sram_addr_ok),
        .data_ok(data_sram_data_ok),
        .rdata(data_sram_rdata),

        .result_bypass(MEM_result_bypass),
        .csr_result_out(RDW_csr_result),
        .alu_result_out(RDW_alu_result),
        .mul_result_out(RDW_mul_result),
        .div_result_out(RDW_div_result),
        .PC_out(RDW_PC),
        .mem_op_out(RDW_mem_op),
        .res_from_mul_out(RDW_res_from_mul),
        .res_from_div_out(RDW_res_from_div),
        .res_from_mem_out(RDW_res_from_mem),
        .res_from_csr_out(RDW_res_from_csr),
        .gr_we_out(RDW_gr_we),
        .mem_we_out(RDW_mem_we),
        .dest_out(RDW_dest),
        .data_valid_out(RDW_data_valid),
        .data_out(RDW_data),
        .this_flush(MEM_this_flush),
        .RDW_flush(RDW_this_flush),
        .WB_flush(WB_this_flush),
        .has_exception(MEM_has_exception),
        .ecode(MEM_ecode),
        .esubcode(MEM_esubcode),
        .exception_maddr(MEM_exception_maddr),
        .ertn(MEM_ertn),
        .has_exception_out(RDW_has_exception),
        .ecode_out(RDW_ecode),
        .esubcode_out(RDW_esubcode),
        .exception_maddr_out(RDW_exception_maddr),
        .ertn_out(RDW_ertn),
        .rdcntid(MEM_rdcntid),
        .rdcntid_out(RDW_rdcntid),

        .tlbsrch(MEM_tlbsrch),
        .tlbrd(MEM_tlbrd),
        .tlbwr(MEM_tlbwr),
        .tlbfill(MEM_tlbfill),
        .invtlb(MEM_invtlb),
        .invtlb_op(MEM_invtlb_op),
        
        .tlbsrch_to_csr(MEM_tlbsrch_to_csr),
        .tlbrd_to_csr(MEM_tlbrd_to_csr),
        .tlbwr_to_csr(MEM_tlbwr_to_csr),
        .tlbfill_to_csr(MEM_tlbfill_to_csr),
        .invtlb_to_csr(MEM_invtlb_to_csr),
        .invtlb_op_to_csr(MEM_invtlb_op_to_csr),

        .this_tlb_refetch(MEM_this_tlb_refetch),
        .RDW_this_tlb_refetch(RDW_this_tlb_refetch),

        .tlb_out(RDW_tlb),
        .tlb_flush(tlb_submit),

        .mmu_ecode_d(mmu_ecode_d),
        .mmu_esubcode_d(mmu_esubcode_d),

        .mem_inst(MEM_mem_inst)
    );

    RDW RDW_unit(
        .clk(clk),
        .rst(reset),
        
        // pipeline control signals
        .in_valid(MEM_out_valid),
        .out_ready(WB_in_ready),
        .in_ready(RDW_in_ready),
        .out_valid(RDW_out_valid),

        .ex_flush(exception_submit),
        .ertn_flush(ertn_submit),

        // input from MEM
        .data_from_MEM(RDW_data),
        .data_valid_from_MEM(RDW_data_valid),
        //.discard_from_MEM(RDW_discard),

        .csr_result(RDW_csr_result),
        .alu_result(RDW_alu_result),
        .mul_result(RDW_mul_result),
        .div_result(RDW_div_result),
        .PC(RDW_PC),
        .mem_op(RDW_mem_op),
        .res_from_mul(RDW_res_from_mul),
        .res_from_div(RDW_res_from_div),
        .res_from_mem(RDW_res_from_mem),
        .res_from_csr(RDW_res_from_csr),
        .gr_we(RDW_gr_we),
        .mem_we(RDW_mem_we),
        .dest(RDW_dest),
        .result_bypass(RDW_result_bypass),

        // sram-like interface
        .data_ok(data_sram_data_ok),
        .rdata(data_sram_rdata),

        // output regs
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
        .data_out(WB_data),
        .data_valid(RDW_data_valid_out),

        // exception handle
        .this_flush(RDW_this_flush),
        .WB_flush(WB_this_flush),

        .has_exception(RDW_has_exception),
        .ecode(RDW_ecode),
        .esubcode(RDW_esubcode),
        .exception_maddr(RDW_exception_maddr),
        .ertn(RDW_ertn),
        .has_exception_out(WB_has_exception),
        .ecode_out(WB_ecode),
        .esubcode_out(WB_esubcode),
        .exception_maddr_out(WB_exception_maddr),
        .ertn_out(WB_ertn),

        .rdcntid(RDW_rdcntid),
        .rdcntid_out(WB_rdcntid),

        .this_tlb_refetch(RDW_this_tlb_refetch),

        .tlb(RDW_tlb),
        .tlb_submit(tlb_submit),
        .tlb_flush_entry(tlb_flush_entry)
    );

    WB WB_unit(
        .clk(clk),
		.rst(reset),
		.in_valid(RDW_out_valid),
        .in_ready(WB_in_ready),
        .valid(valid),

        .data_from_RDW(WB_data),
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
        .ex_tlbr_submit(ex_tlbr_submit),
        .ertn_submit(ertn_submit),
        .csr_tid(csr_tid),
        .rdcntid(WB_rdcntid)
    );
endmodule
