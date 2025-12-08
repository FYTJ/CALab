module mmu(
    input [31: 0] inst_sram_vaddr,
    input inst_sram_wr,
    input [31: 0] data_sram_vaddr,
    input data_sram_wr,
    input [1: 0] crmd_plv_value,
    input crmd_da_value,
    input crmd_pg_value,
    input dmw0_plv0_value,
    input dmw0_plv1_value,
    input dmw0_plv2_value,
    input dmw0_plv3_value,
    input [1: 0] dmw0_mat_value,
    input [2: 0] dmw0_pseg_value,
    input [2: 0] dmw0_vseg_value,
    input dmw1_plv0_value,
    input dmw1_plv1_value,
    input dmw1_plv2_value,
    input dmw1_plv3_value,
    input [1: 0] dmw1_mat_value,
    input [2: 0] dmw1_pseg_value,
    input [2: 0] dmw1_vseg_value,

    input tlb_s0_found,
    input [19:0] tlb_s0_ppn,
    input [ 1:0] tlb_s0_plv,
    input [ 1:0] tlb_s0_mat,
    input tlb_s0_v,
    output [18: 0] tlb_s0_vppn,
    output tlb_s0_va_bit12,
    input tlb_s1_found,
    input [19:0] tlb_s1_ppn,
    input [ 1:0] tlb_s1_plv,
    input [ 1:0] tlb_s1_mat,
    input tlb_s1_d,
    input tlb_s1_v,
    output tlb_s1_va_bit12,

    output [31: 0] inst_sram_paddr,
    output [31: 0] data_sram_paddr,

    // exceptions
    output [5: 0] ecode,
    output [8: 0] esubcode
);
    wire dmw0_plv_cond = (crmd_plv_value == 2'd3 && dmw0_plv3_value) || (crmd_plv_value == 2'd2 && dmw0_plv2_value) || (crmd_plv_value == 2'd1 && dmw0_plv1_value) || (crmd_plv_value == 2'd0 && dmw0_plv0_value);
    wire dmw1_plv_cond = (crmd_plv_value == 2'd3 && dmw1_plv3_value) || (crmd_plv_value == 2'd2 && dmw1_plv2_value) || (crmd_plv_value == 2'd1 && dmw1_plv1_value) || (crmd_plv_value == 2'd0 && dmw1_plv0_value);

    assign inst_sram_paddr = (crmd_da_value && !crmd_pg_value) ? inst_sram_vaddr : 
        (inst_sram_vaddr[31: 29] == dmw0_vseg_value && dmw0_plv_cond) ? {dmw0_pseg_value, inst_sram_vaddr[28: 0]} :
        (inst_sram_vaddr[31: 29] == dmw1_vseg_value && dmw1_plv_cond) ? {dmw1_pseg_value, inst_sram_vaddr[28: 0]} :
        {tlb_s0_ppn, inst_sram_vaddr[11: 0]};
    assign tlb_s0_vppn = inst_sram_vaddr[31: 13];
    assign tlb_s0_va_bit12 = inst_sram_vaddr[12];


    assign data_sram_paddr = (crmd_da_value && !crmd_pg_value) ? data_sram_vaddr : 
        (data_sram_vaddr[31: 29] == dmw0_vseg_value && dmw0_plv_cond) ? {dmw0_pseg_value, data_sram_vaddr[28: 0]} :
        (data_sram_vaddr[31: 29] == dmw1_vseg_value && dmw1_plv_cond) ? {dmw1_pseg_value, data_sram_vaddr[28: 0]} :
        {tlb_s1_ppn, data_sram_vaddr[11: 0]};
    assign tlb_s1_va_bit12 = data_sram_vaddr[12];

    wire use_tlb_i = !(crmd_da_value && !crmd_pg_value) &&
        !(inst_sram_vaddr[31: 29] == dmw0_vseg_value && dmw0_plv_cond) &&
        !(inst_sram_vaddr[31: 29] == dmw1_vseg_value && dmw1_plv_cond);
    wire use_tlb_d = !(crmd_da_value && !crmd_pg_value) &&
        !(data_sram_vaddr[31: 29] == dmw0_vseg_value && dmw0_plv_cond) &&
        !(data_sram_vaddr[31: 29] == dmw1_vseg_value && dmw1_plv_cond);

    wire pil = use_tlb_d && tlb_s1_found && !tlb_s1_v && !data_sram_wr;
    wire pis = use_tlb_d && tlb_s1_found && !tlb_s1_v && data_sram_wr;
    wire pif = use_tlb_i && tlb_s0_found && !tlb_s0_v;
    wire pmm = use_tlb_d && tlb_s1_found && tlb_s1_v && (crmd_plv_value <= tlb_s1_plv) && data_sram_wr && !tlb_s1_d;
    wire ppi = (use_tlb_i && tlb_s0_found && tlb_s0_v && (crmd_plv_value > tlb_s0_plv)) || 
        (use_tlb_d && tlb_s1_found && tlb_s1_v && (crmd_plv_value > tlb_s1_plv));

    assign ecode = pil ? 6'h1 :
        pis ? 6'h2 :
        pif ? 6'h3 :
        pmm ? 6'h4 :
        ppi ? 6'h5 :
        6'h0;

    assign esubcode = 9'h0;
endmodule
