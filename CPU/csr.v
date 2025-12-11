module csr #(
    parameter TLBNUM = 16
) (
    input  wire        clk,
    input  wire        csr_re,
    input  wire [13:0] csr_num,
    output wire [31:0] csr_rvalue,
    input  wire        csr_we,
    input  wire [31:0] csr_wmask,
    input  wire [31:0] csr_wvalue,

    input  wire        rst,
    input  wire        wb_ex,
    input  wire [ 5:0] wb_ecode,
    input  wire [ 8:0] wb_esubcode,
    input  wire [31:0] wb_pc,
    input  wire [31:0] wb_vaddr,
    input  wire        ertn_flush,
    output wire [31:0] ex_entry,
    output wire [31:0] ex_tlbr_entry,
    output wire        has_int,
    output wire [31:0] ertn_entry,

    output wire [31:0] tid,
    output reg  [63:0] count,

    output wire [9:0]  asid_asid_value,
    output wire [1: 0] crmd_plv_value,
    output wire        crmd_da_value,
    output wire        crmd_pg_value,
    output wire [18:0] tlbehi_vppn_value,
    output wire        dmw0_plv0_value,
    output wire        dmw0_plv1_value,
    output wire        dmw0_plv2_value,
    output wire        dmw0_plv3_value,
    output wire [1: 0] dmw0_mat_value,
    output wire [2: 0] dmw0_pseg_value,
    output wire [2: 0] dmw0_vseg_value,
    output wire        dmw1_plv0_value,
    output wire        dmw1_plv1_value,
    output wire        dmw1_plv2_value,
    output wire        dmw1_plv3_value,
    output wire [1: 0] dmw1_mat_value,
    output wire [2: 0] dmw1_pseg_value,
    output wire [2: 0] dmw1_vseg_value,

    /* TLB */
    input tlbsrch,
    input tlbrd,
    input tlbwr,
    input tlbfill,
    input invtlb,
    input [4: 0] invtlb_op,

    input tlb_s1_found,
    input [$clog2(TLBNUM)-1:0] tlb_s1_index,

    output tlb_we,
    output [$clog2(TLBNUM)-1:0] tlb_w_index,
    output tlb_w_e,
    output [18:0] tlb_w_vppn,
    output [ 5:0] tlb_w_ps,
    output [ 9:0] tlb_w_asid,
    output tlb_w_g,
    output [19:0] tlb_w_ppn0,
    output [ 1:0] tlb_w_plv0,
    output [ 1:0] tlb_w_mat0,
    output tlb_w_d0,
    output tlb_w_v0,
    output [19:0] tlb_w_ppn1,
    output [ 1:0] tlb_w_plv1,
    output [ 1:0] tlb_w_mat1,
    output tlb_w_d1,
    output tlb_w_v1,

    output [$clog2(TLBNUM)-1:0] tlb_r_index,
    input tlb_r_e,
    input [18:0] tlb_r_vppn,
    input [ 5:0] tlb_r_ps,
    input [ 9:0] tlb_r_asid,
    input tlb_r_g,
    input [19:0] tlb_r_ppn0,
    input [ 1:0] tlb_r_plv0,
    input [ 1:0] tlb_r_mat0,
    input tlb_r_d0,
    input tlb_r_v0,
    input [19:0] tlb_r_ppn1,
    input [ 1:0] tlb_r_plv1,
    input [ 1:0] tlb_r_mat1,
    input tlb_r_d1,
    input tlb_r_v1,

    output  tlb_invtlb_valid,
    output  [4: 0] tlb_invtlb_op
);
    //TICLR
    `define CSR_TICLR_CLR 0
    `define CSR_TICLR     14'h44

    // CRMD
    `define CSR_CRMD      14'h0
    `define CSR_CRMD_IE 2
    `define CSR_CRMD_DA 3
    `define CSR_CRMD_PG 4
    `define CSR_CRMD_PLV  1:0

    // PRMD
    `define CSR_PRMD      14'h1
    `define CSR_PRMD_PIE  2
    `define CSR_PRMD_PPLV 1:0

    // ECFG
    `define CSR_ECFG     14'h4
    `define CSR_ECFG_LIE 12:0

    // ESTAT
    `define CSR_ESTAT      14'h5
    `define CSR_ESTAT_IS10 1:0

    //ERA
    `define CSR_ERA    14'h6
    `define CSR_ERA_PC 31:0

    // BADV
    `define CSR_BADV      14'h7 
    `define ECODE_ADE     6'h8
    `define ECODE_ALE     6'h9
    `define ESUBCODE_ADEF 0

    // EENTRY
    `define CSR_EENTRY      14'hC
    `define CSR_EENTRY_VA   31:6

    // TLBIDX
    `define CSR_TLBIDX 14'h10
    `define CSR_TLBIDX_INDEX $clog2(TLBNUM)-1: 0
    `define CSR_TLBIDX_PS 29: 24
    `define CSR_TLBIDX_NE 31

    // TLBEHI
    `define CSR_TLBEHI 14'h11
    `define CSR_TLBEHI_VPPN 31: 13

    // TLBELO
    `define CSR_TLBELO0 14'h12
    `define CSR_TLBELO1 14'h13
    `define CSR_TLBELO_V 0
    `define CSR_TLBELO_D 1
    `define CSR_TLBELO_PLV 3: 2
    `define CSR_TLBELO_MAT 5: 4
    `define CSR_TLBELO_G 6
    `define CSR_TLBELO_PPN 27: 8

    // ASID
    `define CSR_ASID 14'h18
    `define CSR_ASID_ASID 9: 0
    `define CSR_ASID_ASIDBITS 23: 16

    // SAVE
    `define CSR_SAVE0      14'h30
    `define CSR_SAVE1      14'h31
    `define CSR_SAVE2      14'h32
    `define CSR_SAVE3      14'h33
    `define CSR_SAVE_DATA  31:0

    // TID
    `define CSR_TID        14'h40
    `define CSR_TID_TID    31:0

    // TCFG
    `define CSR_TCFG       14'h41
    `define CSR_TCFG_EN        0
    `define CSR_TCFG_PERIOD    1
    `define CSR_TCFG_INITV  31:2

    // TVAL
    `define CSR_TVAL       14'h42

    // TLBRENTRY
    `define CSR_TLBRENTRY 14'h88
    `define CSR_TLBRENTRY_PPN 31: 12
    `define ECODE_TLBR 6'h3F
    `define ECODE_PIL 6'h1
    `define ECODE_PIS 6'h2
    `define ECODE_PIF 6'h3
    `define ECODE_PME 6'h4
    `define ECODE_PPI 6'h7

    // DMW
    `define CSR_DMW0 14'h180
    `define CSR_DMW1 14'h181
    `define CSR_DMW2 14'h182
    `define CSR_DMW3 14'h183
    `define CSR_DMW_PLV0 0
    `define CSR_DMW_PLV1 1
    `define CSR_DMW_PLV2 2
    `define CSR_DMW_PLV3 3
    `define CSR_DMW_MAT 5: 4
    `define CSR_DMW_PSEG 27: 25
    `define CSR_DMW_VSEG 31: 29

    // CRMD
    reg  [ 1: 0] csr_crmd_plv;
    reg          csr_crmd_ie;
    reg          csr_crmd_da;
    reg          csr_crmd_pg;
    wire [ 1: 0] csr_crmd_datf;
    wire [ 1: 0] csr_crmd_datm;

    wire [31: 0] csr_crmd_rvalue;

    always @(posedge clk) begin
        if (rst) begin
            csr_crmd_plv <= 2'b0;
            csr_crmd_ie  <= 1'b0;
            csr_crmd_da  <= 1'b1;
            csr_crmd_pg  <= 1'b0;
        end
        else if (wb_ex) begin
            csr_crmd_plv <= 2'b0;
            csr_crmd_ie  <= 1'b0;
        end
        else if (ertn_flush) begin
            csr_crmd_plv <= csr_prmd_pplv;
            csr_crmd_ie  <= csr_prmd_pie;
        end
        else if (csr_we && csr_num==`CSR_CRMD) begin
            csr_crmd_plv <= csr_wmask[`CSR_CRMD_PLV] & csr_wvalue[`CSR_CRMD_PLV] 
                         | ~csr_wmask[`CSR_CRMD_PLV] & csr_crmd_plv;
            csr_crmd_ie  <= csr_wmask[`CSR_CRMD_IE] & csr_wvalue[`CSR_CRMD_IE]
                         | ~csr_wmask[`CSR_CRMD_IE] & csr_crmd_ie;
            csr_crmd_da  <= csr_wmask[`CSR_CRMD_DA] & csr_wvalue[`CSR_CRMD_DA]
                         | ~csr_wmask[`CSR_CRMD_DA] & csr_crmd_da;
            csr_crmd_pg  <= csr_wmask[`CSR_CRMD_PG] & csr_wvalue[`CSR_CRMD_PG]
                         | ~csr_wmask[`CSR_CRMD_PG] & csr_crmd_pg;
        end
    end

    assign csr_crmd_datf = 2'b00; 
    assign csr_crmd_datm = 2'b00;
    assign crmd_plv_value = csr_crmd_plv;
    assign crmd_da_value = csr_crmd_da;
    assign crmd_pg_value = csr_crmd_pg;

    assign csr_crmd_rvalue = {23'b0, csr_crmd_datm, csr_crmd_datf, csr_crmd_pg, csr_crmd_da, csr_crmd_ie, csr_crmd_plv};

    // PRMD
    reg  [ 1: 0] csr_prmd_pplv;
    reg          csr_prmd_pie;

    wire [31: 0] csr_prmd_rvalue;

    always @(posedge clk) begin
        if (wb_ex) begin
            csr_prmd_pplv <= csr_crmd_plv;
            csr_prmd_pie <= csr_crmd_ie;
        end
        else if (csr_we && csr_num==`CSR_PRMD) begin
            csr_prmd_pplv <= csr_wmask[`CSR_PRMD_PPLV] & csr_wvalue[`CSR_PRMD_PPLV]
                          | ~csr_wmask[`CSR_PRMD_PPLV] & csr_prmd_pplv;
            csr_prmd_pie  <= csr_wmask[`CSR_PRMD_PIE]  & csr_wvalue[`CSR_PRMD_PIE]
                          | ~csr_wmask[`CSR_PRMD_PIE]  & csr_prmd_pie;
        end
    end

    assign csr_prmd_rvalue = {29'b0, csr_prmd_pie, csr_prmd_pplv};

    // ECFG
    reg  [12: 0] csr_ecfg_lie;

    wire [31: 0] csr_ecfg_rvalue;

    always @(posedge clk) begin
        if (rst)
            csr_ecfg_lie <= 13'b0;
        else if (csr_we && csr_num==`CSR_ECFG)
            csr_ecfg_lie <= csr_wmask[`CSR_ECFG_LIE] & 13'h1bff & csr_wvalue[`CSR_ECFG_LIE]
                         | ~csr_wmask[`CSR_ECFG_LIE] & 13'h1bff & csr_ecfg_lie;
    end

    assign csr_ecfg_rvalue = {19'b0, csr_ecfg_lie[12:11], 1'b0, csr_ecfg_lie[9:0]};

    // ESTAT
    reg  [12: 0] csr_estat_is;
    reg  [ 5: 0] csr_estat_ecode;
    reg  [ 8: 0] csr_estat_esubcode;

    wire [31: 0] csr_estat_rvalue;

    always @(posedge clk) begin
        if (rst)
            csr_estat_is[1:0] <= 2'b0;
        else if (csr_we && csr_num==`CSR_ESTAT)
            csr_estat_is[1:0] <= csr_wmask[`CSR_ESTAT_IS10] & csr_wvalue[`CSR_ESTAT_IS10]
                              | ~csr_wmask[`CSR_ESTAT_IS10] & csr_estat_is[1:0];

//////////////////////注意注意注意, 此信号现在悬空!
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
        // csr_estat_is[9:2] <= hw_int_in[7:0];
        csr_estat_is[9:2] <= 8'b0;
        //此处应为"采样处理器核中断输入引脚"
///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
        csr_estat_is[ 10] <= 1'b0;

        if (timer_cnt[31:0]==32'b0)
            csr_estat_is[11] <= 1'b1;
        else if (csr_we && csr_num==`CSR_TICLR && csr_wmask[`CSR_TICLR_CLR] && csr_wvalue[`CSR_TICLR_CLR])
            csr_estat_is[11] <= 1'b0;

//////////////////////注意注意注意, 此信号现在悬空!
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
        // csr_estat_is[12] <= ipi_int_in;
        csr_estat_is[12] <= 1'b0;
        //应该为"采样处理器核的核间中断"
///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
    end

    always @(posedge clk) begin
        if (wb_ex) begin
            csr_estat_ecode    <= wb_ecode;
            csr_estat_esubcode <= wb_esubcode;
        end
    end

    assign csr_estat_rvalue = {1'b0, csr_estat_esubcode, csr_estat_ecode, 3'b0, csr_estat_is[12:11], 1'b0, csr_estat_is[9:0]};

    //ERA
    reg  [31: 0] csr_era_pc;

    wire [31: 0] csr_era_rvalue;
    always @(posedge clk) begin
        if (wb_ex)
            csr_era_pc <= wb_pc;
        else if (csr_we && csr_num==`CSR_ERA)
            csr_era_pc <= csr_wmask[`CSR_ERA_PC] & csr_wvalue[`CSR_ERA_PC]
                       | ~csr_wmask[`CSR_ERA_PC] & csr_era_pc;
    end

    assign csr_era_rvalue = csr_era_pc;

    // BADV
    wire         wb_ex_addr_err;
    reg  [31: 0] csr_badv_vaddr;

    wire [31: 0] csr_badv_rvalue;
    assign wb_ex_addr_err = wb_ecode==`ECODE_ADE || wb_ecode==`ECODE_ALE || 
                            wb_ecode==`ECODE_TLBR || wb_ecode==`ECODE_PIL ||
                            wb_ecode==`ECODE_PIS || wb_ecode==`ECODE_PIF ||
                            wb_ecode==`ECODE_PME || wb_ecode==`ECODE_PPI;
    always @(posedge clk) begin
        if (wb_ex && wb_ex_addr_err)
            csr_badv_vaddr <= (wb_ecode==`ECODE_ADE && wb_esubcode==`ESUBCODE_ADEF) ? wb_pc : wb_vaddr;
    end

    assign csr_badv_rvalue = csr_badv_vaddr;

    // EENTRY
    reg  [25: 0] csr_eentry_va;

    wire [31: 0] csr_eentry_rvalue;
    always @(posedge clk) begin
        if (csr_we && csr_num==`CSR_EENTRY)
            csr_eentry_va <= csr_wmask[`CSR_EENTRY_VA] & csr_wvalue[`CSR_EENTRY_VA]
                          | ~csr_wmask[`CSR_EENTRY_VA] & csr_eentry_va;
    end

    assign csr_eentry_rvalue = {csr_eentry_va, 6'b0};

    // SAVE
    reg  [31: 0] csr_save0_data;
    reg  [31: 0] csr_save1_data;
    reg  [31: 0] csr_save2_data;
    reg  [31: 0] csr_save3_data;

    wire [31:0] csr_save0_rvalue;
    wire [31:0] csr_save1_rvalue;
    wire [31:0] csr_save2_rvalue;
    wire [31:0] csr_save3_rvalue;
    always @(posedge clk) begin
        if (csr_we && csr_num==`CSR_SAVE0)
            csr_save0_data <= csr_wmask[`CSR_SAVE_DATA] & csr_wvalue[`CSR_SAVE_DATA]
                           | ~csr_wmask[`CSR_SAVE_DATA] & csr_save0_data;
        if (csr_we && csr_num==`CSR_SAVE1)
            csr_save1_data <= csr_wmask[`CSR_SAVE_DATA] & csr_wvalue[`CSR_SAVE_DATA]
                           | ~csr_wmask[`CSR_SAVE_DATA] & csr_save1_data;
        if (csr_we && csr_num==`CSR_SAVE2)
            csr_save2_data <= csr_wmask[`CSR_SAVE_DATA] & csr_wvalue[`CSR_SAVE_DATA]
                           | ~csr_wmask[`CSR_SAVE_DATA] & csr_save2_data;
        if (csr_we && csr_num==`CSR_SAVE3)
            csr_save3_data <= csr_wmask[`CSR_SAVE_DATA] & csr_wvalue[`CSR_SAVE_DATA]
                           | ~csr_wmask[`CSR_SAVE_DATA] & csr_save3_data;
    end

    assign csr_save0_rvalue = csr_save0_data;
    assign csr_save1_rvalue = csr_save1_data;
    assign csr_save2_rvalue = csr_save2_data;
    assign csr_save3_rvalue = csr_save3_data;

    // TID
    reg  [31: 0] csr_tid_tid;

    wire [31: 0] csr_tid_rvalue;
    always @(posedge clk) begin
        if (rst)
///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////悬着！
//手册:定时器编号。软件可配置。处理器核复位期间，硬件可以将其复位成与CSR.CPUID中CoreID相同的值。
            // csr_tid_tid <= coreid_in;
            csr_tid_tid <= 32'b0;
///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
        else if (csr_we && csr_num==`CSR_TID)
            csr_tid_tid <= csr_wmask[`CSR_TID_TID] & csr_wvalue[`CSR_TID_TID]
                        | ~csr_wmask[`CSR_TID_TID] & csr_tid_tid;
    end

    assign csr_tid_rvalue = csr_tid_tid;

    // TCFG
    reg          csr_tcfg_en;
    reg          csr_tcfg_periodic;
    reg  [29: 0] csr_tcfg_initval;

    wire [31: 0] csr_tcfg_rvalue;
    always @(posedge clk) begin
        if (rst)
            csr_tcfg_en <= 1'b0;
        else if (csr_we && csr_num==`CSR_TCFG)
            csr_tcfg_en <= csr_wmask[`CSR_TCFG_EN] & csr_wvalue[`CSR_TCFG_EN]
                        | ~csr_wmask[`CSR_TCFG_EN] & csr_tcfg_en;

        if (csr_we && csr_num==`CSR_TCFG) begin
            csr_tcfg_periodic <= csr_wmask[`CSR_TCFG_PERIOD] & csr_wvalue[`CSR_TCFG_PERIOD]
                              | ~csr_wmask[`CSR_TCFG_PERIOD] & csr_tcfg_periodic;
            csr_tcfg_initval  <= csr_wmask[`CSR_TCFG_INITV] & csr_wvalue[`CSR_TCFG_INITV]
                              | ~csr_wmask[`CSR_TCFG_INITV] & csr_tcfg_initval;
        end
    end

    assign csr_tcfg_rvalue = {csr_tcfg_initval, csr_tcfg_periodic, csr_tcfg_en};

    // TVAL
    wire [31:0] tcfg_next_value;
    wire [31:0] csr_tval;
    wire [31:0] csr_tval_rvalue;
    reg  [31:0] timer_cnt;
    //下面这个宏跟CSR_TCFG_INITV一样
    `define CSR_TCFG_INITVAL 31:2 
    assign tcfg_next_value =  csr_wmask[31:0] & csr_wvalue[31:0]
                           | ~csr_wmask[31:0] & {csr_tcfg_initval, csr_tcfg_periodic, csr_tcfg_en};
    
    always @(posedge clk) begin
        if (rst)
            timer_cnt <= 32'hffffffff;
        else if (csr_we && csr_num==`CSR_TCFG && tcfg_next_value[`CSR_TCFG_EN])
            timer_cnt <= {tcfg_next_value[`CSR_TCFG_INITVAL], 2'b0};
        else if (csr_tcfg_en && timer_cnt!=32'hffffffff) begin
            if (timer_cnt[31:0]==32'b0 && csr_tcfg_periodic)
                timer_cnt <= {csr_tcfg_initval, 2'b0};
            else
                timer_cnt <= timer_cnt - 1'b1;
        end
    end
    assign csr_tval = timer_cnt[31:0];
    assign csr_tval_rvalue = csr_tval;

    //TICLR
    wire        csr_ticlr_clr;
    wire [31:0] csr_ticlr_rvalue;
    assign csr_ticlr_clr = 1'b0;

    assign csr_ticlr_rvalue = {31'b0, csr_ticlr_clr};

    // TLBIDX
    reg [$clog2(TLBNUM)-1: 0] csr_tlbidx_index;
    reg [5: 0] csr_tlbidx_ps;
    reg csr_tlbidx_ne;
    wire [31:0] csr_tlbidx_rvalue = {csr_tlbidx_ne, 1'b0, csr_tlbidx_ps,  {{(32-1-1-6-($clog2(TLBNUM))){1'b0}}}, csr_tlbidx_index};

    // TLBEHI
    reg [18: 0] csr_tlbehi_vppn;
    wire [31:0] csr_tlbehi_rvalue = {csr_tlbehi_vppn, 13'b0};
    assign tlbehi_vppn_value = csr_tlbehi_vppn;

    // TLBELO
    reg csr_tlbelo0_v;
    reg csr_tlbelo0_d;
    reg [1: 0] csr_tlbelo0_plv;
    reg [1: 0] csr_tlbelo0_mat;
    reg csr_tlbelo0_g;
    reg [19: 0] csr_tlbelo0_ppn;
    reg csr_tlbelo1_v;
    reg csr_tlbelo1_d;
    reg [1: 0] csr_tlbelo1_plv;
    reg [1: 0] csr_tlbelo1_mat;
    reg csr_tlbelo1_g;
    reg [19: 0] csr_tlbelo1_ppn;
    wire [31:0] csr_tlbelo0_rvalue = {4'b0, csr_tlbelo0_ppn, 1'b0, csr_tlbelo0_g, csr_tlbelo0_mat, csr_tlbelo0_plv, csr_tlbelo0_d, csr_tlbelo0_v};
    wire [31:0] csr_tlbelo1_rvalue = {4'b0, csr_tlbelo1_ppn, 1'b0, csr_tlbelo1_g, csr_tlbelo1_mat, csr_tlbelo1_plv, csr_tlbelo1_d, csr_tlbelo1_v};

    // ASID
    reg [9: 0] csr_asid_asid;

    assign asid_asid_value = csr_asid_asid;
    wire [31:0] csr_asid_rvalue = {8'b0, 8'd10, 6'b0, csr_asid_asid};

    // TLBRENTRY
    reg [19: 0] csr_tlbrentry_ppn;
    wire [31:0] csr_tlbrentry_rvalue = {csr_tlbrentry_ppn, 12'b0};

    always @(posedge clk) begin
        if (tlbsrch) begin
            csr_tlbidx_ne <= !tlb_s1_found;
            if (tlb_s1_found) begin
                csr_tlbidx_index <= tlb_s1_index;
            end
        end
        else if (tlbrd) begin
            if (tlb_r_e) begin
                csr_tlbidx_ne <= 1'b0;
                csr_tlbehi_vppn <= tlb_r_vppn;
                csr_tlbidx_ps <= tlb_r_ps;
                csr_asid_asid <= tlb_r_asid;
                csr_tlbelo0_g <= tlb_r_g;
                csr_tlbelo1_g <= tlb_r_g;
                csr_tlbelo0_ppn <= tlb_r_ppn0;
                csr_tlbelo0_plv <= tlb_r_plv0;
                csr_tlbelo0_mat <= tlb_r_mat0;
                csr_tlbelo0_d <= tlb_r_d0;
                csr_tlbelo0_v <= tlb_r_v0;
                csr_tlbelo1_ppn <= tlb_r_ppn1;
                csr_tlbelo1_plv <= tlb_r_plv1;
                csr_tlbelo1_mat <= tlb_r_mat1;
                csr_tlbelo1_d <= tlb_r_d1;
                csr_tlbelo1_v <= tlb_r_v1;
            end
            else begin
                csr_tlbidx_ne <= 1'b1;
                csr_tlbidx_ps <= 6'b0;
                csr_asid_asid <= 10'b0;
                csr_tlbehi_vppn <= 19'b0;
                csr_tlbelo0_g <= 1'b0;
                csr_tlbelo1_g <= 1'b0;
                csr_tlbelo0_ppn <= 20'b0;
                csr_tlbelo0_plv <= 2'b0;
                csr_tlbelo0_mat <= 2'b0;
                csr_tlbelo0_d <= 1'b0;
                csr_tlbelo0_v <= 1'b0;
                csr_tlbelo1_ppn <= 20'b0;
                csr_tlbelo1_plv <= 2'b0;
                csr_tlbelo1_mat <= 2'b0;
                csr_tlbelo1_d <= 1'b0;
                csr_tlbelo1_v <= 1'b0;
            end
        end

        else if (csr_we) begin
            if (csr_num==`CSR_TLBRENTRY) begin
                csr_tlbrentry_ppn <= csr_wmask[`CSR_TLBRENTRY_PPN] & csr_wvalue[`CSR_TLBRENTRY_PPN] 
                                 | ~csr_wmask[`CSR_TLBRENTRY_PPN] & csr_tlbrentry_ppn;
            end
            else if (csr_num==`CSR_TLBIDX) begin
                csr_tlbidx_ne    <= csr_wmask[`CSR_TLBIDX_NE]    & csr_wvalue[`CSR_TLBIDX_NE]
                                 | ~csr_wmask[`CSR_TLBIDX_NE]    & csr_tlbidx_ne;
                csr_tlbidx_index <= csr_wmask[`CSR_TLBIDX_INDEX] & csr_wvalue[`CSR_TLBIDX_INDEX]
                                 | ~csr_wmask[`CSR_TLBIDX_INDEX] & csr_tlbidx_index;
                csr_tlbidx_ps    <= csr_wmask[`CSR_TLBIDX_PS]    & csr_wvalue[`CSR_TLBIDX_PS]
                                 | ~csr_wmask[`CSR_TLBIDX_PS]    & csr_tlbidx_ps;
            end
            else if (csr_num==`CSR_TLBEHI) begin
                csr_tlbehi_vppn  <= csr_wmask[`CSR_TLBEHI_VPPN]  & csr_wvalue[`CSR_TLBEHI_VPPN]
                                 | ~csr_wmask[`CSR_TLBEHI_VPPN]  & csr_tlbehi_vppn;
            end
            else if (csr_num==`CSR_TLBELO0) begin
                csr_tlbelo0_v    <= csr_wmask[`CSR_TLBELO_V]     & csr_wvalue[`CSR_TLBELO_V]
                                 | ~csr_wmask[`CSR_TLBELO_V]     & csr_tlbelo0_v;
                csr_tlbelo0_d    <= csr_wmask[`CSR_TLBELO_D]     & csr_wvalue[`CSR_TLBELO_D]
                                 | ~csr_wmask[`CSR_TLBELO_D]     & csr_tlbelo0_d;
                csr_tlbelo0_plv  <= csr_wmask[`CSR_TLBELO_PLV]   & csr_wvalue[`CSR_TLBELO_PLV]
                                 | ~csr_wmask[`CSR_TLBELO_PLV]   & csr_tlbelo0_plv;
                csr_tlbelo0_mat  <= csr_wmask[`CSR_TLBELO_MAT]   & csr_wvalue[`CSR_TLBELO_MAT]
                                 | ~csr_wmask[`CSR_TLBELO_MAT]   & csr_tlbelo0_mat;
                csr_tlbelo0_g    <= csr_wmask[`CSR_TLBELO_G]     & csr_wvalue[`CSR_TLBELO_G]
                                 | ~csr_wmask[`CSR_TLBELO_G]     & csr_tlbelo0_g;
                csr_tlbelo0_ppn  <= csr_wmask[`CSR_TLBELO_PPN]   & csr_wvalue[`CSR_TLBELO_PPN]
                                 | ~csr_wmask[`CSR_TLBELO_PPN]   & csr_tlbelo0_ppn;
            end
            else if (csr_num==`CSR_TLBELO1) begin
                csr_tlbelo1_v    <= csr_wmask[`CSR_TLBELO_V]     & csr_wvalue[`CSR_TLBELO_V]
                                 | ~csr_wmask[`CSR_TLBELO_V]     & csr_tlbelo1_v;
                csr_tlbelo1_d    <= csr_wmask[`CSR_TLBELO_D]     & csr_wvalue[`CSR_TLBELO_D]
                                 | ~csr_wmask[`CSR_TLBELO_D]     & csr_tlbelo1_d;
                csr_tlbelo1_plv  <= csr_wmask[`CSR_TLBELO_PLV]   & csr_wvalue[`CSR_TLBELO_PLV]
                                 | ~csr_wmask[`CSR_TLBELO_PLV]   & csr_tlbelo1_plv;
                csr_tlbelo1_mat  <= csr_wmask[`CSR_TLBELO_MAT]   & csr_wvalue[`CSR_TLBELO_MAT]
                                 | ~csr_wmask[`CSR_TLBELO_MAT]   & csr_tlbelo1_mat;
                csr_tlbelo1_g    <= csr_wmask[`CSR_TLBELO_G]     & csr_wvalue[`CSR_TLBELO_G]
                                 | ~csr_wmask[`CSR_TLBELO_G]     & csr_tlbelo1_g;
                csr_tlbelo1_ppn  <= csr_wmask[`CSR_TLBELO_PPN]   & csr_wvalue[`CSR_TLBELO_PPN]
                                 | ~csr_wmask[`CSR_TLBELO_PPN]   & csr_tlbelo1_ppn;
            end
            else if (csr_num==`CSR_ASID) begin
                csr_asid_asid    <= csr_wmask[`CSR_ASID_ASID]    & csr_wvalue[`CSR_ASID_ASID]
                                 | ~csr_wmask[`CSR_ASID_ASID]    & csr_asid_asid;
            end
        end
    end

    assign tlb_we = tlbwr || tlbfill;
    assign tlb_w_index = csr_tlbidx_index;
    assign tlb_w_e = !csr_tlbidx_ne || (csr_estat_ecode == `ECODE_TLBR);
    assign tlb_w_vppn = csr_tlbehi_vppn;
    assign tlb_w_ps = csr_tlbidx_ps;
    assign tlb_w_asid = csr_asid_asid;
    assign tlb_w_g = csr_tlbelo0_g && csr_tlbelo1_g;
    assign tlb_w_ppn0 = csr_tlbelo0_ppn;
    assign tlb_w_plv0 = csr_tlbelo0_plv;
    assign tlb_w_mat0 = csr_tlbelo0_mat;
    assign tlb_w_d0 = csr_tlbelo0_d;
    assign tlb_w_v0 = csr_tlbelo0_v;
    assign tlb_w_ppn1 = csr_tlbelo1_ppn;
    assign tlb_w_plv1 = csr_tlbelo1_plv;
    assign tlb_w_mat1 = csr_tlbelo1_mat;
    assign tlb_w_d1 = csr_tlbelo1_d;
    assign tlb_w_v1 = csr_tlbelo1_v;

    assign tlb_r_index = csr_tlbidx_index;

    assign tlb_invtlb_valid = invtlb;
    assign tlb_invtlb_op = invtlb_op;

    // always @(posedge clk) begin

    //     // if(rst) begin

    //     // end



    //     if (tlbsrch) begin
    //         csr_tlbidx_ne <= !tlb_s1_found;
    //         if (tlb_s1_found) begin
    //             csr_tlbidx_index <= tlb_s1_index;
    //         end
    //     end
    //     else if (tlbrd) begin
    //         if (tlb_r_e) begin
    //             csr_tlbidx_ne <= 1'b0;
    //             csr_tlbehi_vppn <= tlb_r_vppn;
    //             csr_tlbidx_ps <= tlb_r_ps;
    //             csr_asid_asid <= tlb_r_asid;
    //             csr_tlbelo0_g <= tlb_r_g;
    //             csr_tlbelo1_g <= tlb_r_g;
    //             csr_tlbelo0_ppn <= tlb_r_ppn0;
    //             csr_tlbelo0_plv <= tlb_r_plv0;
    //             csr_tlbelo0_mat <= tlb_r_mat0;
    //             csr_tlbelo0_d <= tlb_r_d0;
    //             csr_tlbelo0_v <= tlb_r_v0;
    //             csr_tlbelo1_ppn <= tlb_r_ppn1;
    //             csr_tlbelo1_plv <= tlb_r_plv1;
    //             csr_tlbelo1_mat <= tlb_r_mat1;
    //             csr_tlbelo1_d <= tlb_r_d1;
    //             csr_tlbelo1_v <= tlb_r_v1;
    //         end
    //         else begin
    //             csr_tlbidx_ne <= 1'b1;
    //             csr_tlbidx_ps <= 6'b0;
    //             csr_asid_asid <= 10'b0;
    //             csr_tlbehi_vppn <= 19'b0;
    //             csr_tlbelo0_g <= 1'b0;
    //             csr_tlbelo1_g <= 1'b0;
    //             csr_tlbelo0_ppn <= 20'b0;
    //             csr_tlbelo0_plv <= 2'b0;
    //             csr_tlbelo0_mat <= 2'b0;
    //             csr_tlbelo0_d <= 1'b0;
    //             csr_tlbelo0_v <= 1'b0;
    //             csr_tlbelo1_ppn <= 20'b0;
    //             csr_tlbelo1_plv <= 2'b0;
    //             csr_tlbelo1_mat <= 2'b0;
    //             csr_tlbelo1_d <= 1'b0;
    //             csr_tlbelo1_v <= 1'b0;
    //         end
    //     end
    // end

    // DMW
    reg csr_dmw0_plv0;
    reg csr_dmw0_plv1;
    reg csr_dmw0_plv2;
    reg csr_dmw0_plv3;
    reg [1: 0] csr_dmw0_mat;
    reg [2: 0] csr_dmw0_pseg;
    reg [2: 0] csr_dmw0_vseg;
    reg csr_dmw1_plv0;
    reg csr_dmw1_plv1;
    reg csr_dmw1_plv2;
    reg csr_dmw1_plv3;
    reg [1: 0] csr_dmw1_mat;
    reg [2: 0] csr_dmw1_pseg;
    reg [2: 0] csr_dmw1_vseg;
    wire [31: 0] csr_dmw0_rvalue = {csr_dmw0_vseg, 1'b0, csr_dmw0_pseg, 19'b0, csr_dmw0_mat, csr_dmw0_plv3, csr_dmw0_plv2, csr_dmw0_plv1, csr_dmw0_plv0};
    wire [31: 0] csr_dmw1_rvalue = {csr_dmw1_vseg, 1'b0, csr_dmw1_pseg, 19'b0, csr_dmw1_mat, csr_dmw1_plv3, csr_dmw1_plv2, csr_dmw1_plv1, csr_dmw1_plv0};


    assign dmw0_plv0_value = csr_dmw0_plv0;
    assign dmw0_plv1_value = csr_dmw0_plv1;
    assign dmw0_plv2_value = csr_dmw0_plv2;
    assign dmw0_plv3_value = csr_dmw0_plv3;
    assign dmw0_mat_value = csr_dmw0_mat;
    assign dmw0_pseg_value = csr_dmw0_pseg;
    assign dmw0_vseg_value = csr_dmw0_vseg;
    assign dmw1_plv0_value = csr_dmw1_plv0;
    assign dmw1_plv1_value = csr_dmw1_plv1;
    assign dmw1_plv2_value = csr_dmw1_plv2;
    assign dmw1_plv3_value = csr_dmw1_plv3;
    assign dmw1_mat_value = csr_dmw1_mat;
    assign dmw1_pseg_value = csr_dmw1_pseg;
    assign dmw1_vseg_value = csr_dmw1_vseg;

    always @(posedge clk) begin
        if (rst) begin
            csr_dmw0_plv0 <= 1'b0;
            csr_dmw0_plv1 <= 1'b0;
            csr_dmw0_plv2 <= 1'b0;
            csr_dmw0_plv3 <= 1'b0;
            csr_dmw0_mat <= 2'b0;
            csr_dmw0_pseg <= 3'b0;
            csr_dmw0_vseg <= 3'b0;
            csr_dmw1_plv0 <= 1'b0;
            csr_dmw1_plv1 <= 1'b0;
            csr_dmw1_plv2 <= 1'b0;
            csr_dmw1_plv3 <= 1'b0;
            csr_dmw1_mat <= 2'b0;
            csr_dmw1_pseg <= 3'b0;
            csr_dmw1_vseg <= 3'b0;
        end
        else if (csr_we) begin
            if (csr_num==`CSR_DMW0) begin
                csr_dmw0_plv0 <= csr_wmask[`CSR_DMW_PLV0] & csr_wvalue[`CSR_DMW_PLV0] | ~csr_wmask[`CSR_DMW_PLV0] & csr_dmw0_plv0;
                csr_dmw0_plv1 <= csr_wmask[`CSR_DMW_PLV1] & csr_wvalue[`CSR_DMW_PLV1] | ~csr_wmask[`CSR_DMW_PLV1] & csr_dmw0_plv1;
                csr_dmw0_plv2 <= csr_wmask[`CSR_DMW_PLV2] & csr_wvalue[`CSR_DMW_PLV2] | ~csr_wmask[`CSR_DMW_PLV2] & csr_dmw0_plv2;
                csr_dmw0_plv3 <= csr_wmask[`CSR_DMW_PLV3] & csr_wvalue[`CSR_DMW_PLV3] | ~csr_wmask[`CSR_DMW_PLV3] & csr_dmw0_plv3;
                csr_dmw0_mat <= csr_wmask[`CSR_DMW_MAT] & csr_wvalue[`CSR_DMW_MAT] | ~csr_wmask[`CSR_DMW_MAT] & csr_dmw0_mat;
                csr_dmw0_pseg <= csr_wmask[`CSR_DMW_PSEG] & csr_wvalue[`CSR_DMW_PSEG] | ~csr_wmask[`CSR_DMW_PSEG] & csr_dmw0_pseg;
                csr_dmw0_vseg <= csr_wmask[`CSR_DMW_VSEG] & csr_wvalue[`CSR_DMW_VSEG] | ~csr_wmask[`CSR_DMW_VSEG] & csr_dmw0_vseg;
            end
            else if (csr_num==`CSR_DMW1) begin
                csr_dmw1_plv0 <= csr_wmask[`CSR_DMW_PLV0] & csr_wvalue[`CSR_DMW_PLV0] | ~csr_wmask[`CSR_DMW_PLV0] & csr_dmw1_plv0;
                csr_dmw1_plv1 <= csr_wmask[`CSR_DMW_PLV1] & csr_wvalue[`CSR_DMW_PLV1] | ~csr_wmask[`CSR_DMW_PLV1] & csr_dmw1_plv1;
                csr_dmw1_plv2 <= csr_wmask[`CSR_DMW_PLV2] & csr_wvalue[`CSR_DMW_PLV2] | ~csr_wmask[`CSR_DMW_PLV2] & csr_dmw1_plv2;
                csr_dmw1_plv3 <= csr_wmask[`CSR_DMW_PLV3] & csr_wvalue[`CSR_DMW_PLV3] | ~csr_wmask[`CSR_DMW_PLV3] & csr_dmw1_plv3;
                csr_dmw1_mat <= csr_wmask[`CSR_DMW_MAT] & csr_wvalue[`CSR_DMW_MAT] | ~csr_wmask[`CSR_DMW_MAT] & csr_dmw1_mat;
                csr_dmw1_pseg <= csr_wmask[`CSR_DMW_PSEG] & csr_wvalue[`CSR_DMW_PSEG] | ~csr_wmask[`CSR_DMW_PSEG] & csr_dmw1_pseg;
                csr_dmw1_vseg <= csr_wmask[`CSR_DMW_VSEG] & csr_wvalue[`CSR_DMW_VSEG] | ~csr_wmask[`CSR_DMW_VSEG] & csr_dmw1_vseg;
            end
        end
    end


    // rvalue mux (CSR read)
    assign csr_rvalue = (csr_num==`CSR_CRMD)    ? csr_crmd_rvalue    :
                        (csr_num==`CSR_PRMD)    ? csr_prmd_rvalue    :
                        (csr_num==`CSR_ECFG)    ? csr_ecfg_rvalue    :
                        (csr_num==`CSR_ESTAT)   ? csr_estat_rvalue   :
                        (csr_num==`CSR_ERA)     ? csr_era_rvalue     :
                        (csr_num==`CSR_EENTRY)  ? csr_eentry_rvalue  :
                        (csr_num==`CSR_BADV)    ? csr_badv_rvalue    :
                        (csr_num==`CSR_SAVE0)   ? csr_save0_rvalue   :
                        (csr_num==`CSR_SAVE1)   ? csr_save1_rvalue   :
                        (csr_num==`CSR_SAVE2)   ? csr_save2_rvalue   :
                        (csr_num==`CSR_SAVE3)   ? csr_save3_rvalue   :
                        (csr_num==`CSR_TID)     ? csr_tid_rvalue     :
                        (csr_num==`CSR_TCFG)    ? csr_tcfg_rvalue    :
                        (csr_num==`CSR_TVAL)    ? csr_tval_rvalue    :
                        (csr_num==`CSR_TICLR)   ? csr_ticlr_rvalue   :
                        (csr_num==`CSR_TLBIDX)  ? csr_tlbidx_rvalue  :
                        (csr_num==`CSR_TLBEHI)  ? csr_tlbehi_rvalue  :
                        (csr_num==`CSR_TLBELO0) ? csr_tlbelo0_rvalue :
                        (csr_num==`CSR_TLBELO1) ? csr_tlbelo1_rvalue :
                        (csr_num==`CSR_ASID)    ? csr_asid_rvalue    :
                        (csr_num==`CSR_TLBRENTRY)? csr_tlbrentry_rvalue : 
                        (csr_num==`CSR_DMW0)    ? csr_dmw0_rvalue    : 
                        (csr_num==`CSR_DMW1)    ? csr_dmw1_rvalue    : 
                        32'b0;

// special:
    // to pre-IF
    assign ex_entry   = csr_eentry_rvalue;
    assign ex_tlbr_entry = csr_tlbrentry_rvalue;
    assign ertn_entry = csr_era_rvalue;

    // to ID
    assign has_int = ((csr_estat_is[12:0] & csr_ecfg_lie[12:0]) != 13'b0) && (csr_crmd_ie == 1'b1);

    // for rdcntid instruction
    assign tid = csr_tid_rvalue;

    // independent stable counter
    always @(posedge clk) begin
        if(rst) begin
            count <= 64'd0;
        end else begin
            count <= count + 1;
        end
    end

endmodule
