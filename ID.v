module ID (
    input clk,
	input rst,

    input in_valid,
    input out_ready,
    output in_ready,
    output reg out_valid,

    input [31: 0] result,
    input MEM_valid,
    input MEM_gr_we,
    input [4: 0] MEM_dest,
    input MEM_res_from_mem,
    input [31: 0] MEM_result,

    input WB_valid,
    input WB_gr_we,
    input WB_res_from_mem,
    input [4: 0] WB_dest,
    input [31: 0] WB_data_sram_rdata,
    input [31: 0] WB_result,

    input [31: 0] inst,
	input [31: 0] PC,
    output [ 4:0] rf_raddr1,
    output [ 4:0] rf_raddr2,
    input [31:0] rf_rdata1,
    input [31:0] rf_rdata2,
    output br_taken_out,
    output [31: 0] br_target_out,
    output reg [7: 0] load_op_out,
    output reg [11: 0] alu_op_out,
    output reg [2: 0] mul_op_out,
    output reg [3: 0] div_op_out,
    output reg src1_is_pc_out,
    output reg src2_is_imm_out,
    output reg res_from_mem_out,
    output reg gr_we_out,
    output reg mem_we_out,
    output reg [4: 0] dest_out,
    output reg [31:0] imm_out,
    output reg [31: 0] PC_out,
    output reg [31: 0] rj_value_out,
    output reg [31: 0] rkd_value_out
);

    wire ready_go;
    wire load_use_sign;
    assign ready_go = ~in_valid | ~load_use_sign;

    assign in_ready = ~rst & (~in_valid | ready_go & out_ready);

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end
        else if (out_ready) begin
            out_valid <= in_valid & ready_go & ~load_use_sign;
        end
    end

    wire rj_eq_rd;
    wire rj_lt_rd;
    wire rj_ltu_rd;

    wire        br_taken;
    wire [31:0] br_target;

    wire [11:0] alu_op;
    wire [7: 0] load_op;
    wire [2: 0] mul_op;
    wire [3: 0] div_op;
    wire        src1_is_pc;
    wire        src2_is_imm;
    wire        res_from_mem;
    wire        dst_is_r1;
    wire        gr_we;
    wire        mem_we;
    wire        src_reg_is_rd;
    wire [4: 0] dest;
    reg  [31:0] rj_value;
    reg  [31:0] rkd_value;
    wire [31:0] imm;
    wire [31:0] br_offs;
    wire [31:0] jirl_offs;

    wire [ 5:0] op_31_26;
    wire [ 3:0] op_25_22;
    wire [ 1:0] op_21_20;
    wire [ 4:0] op_19_15;
    wire [ 4:0] rd;
    wire [ 4:0] rj;
    wire [ 4:0] rk;
    wire [11:0] i12;
    wire [19:0] i20;
    wire [15:0] i16;
    wire [25:0] i26;

    wire [63:0] op_31_26_d;
    wire [15:0] op_25_22_d;
    wire [ 3:0] op_21_20_d;
    wire [31:0] op_19_15_d;

    wire        inst_add_w;
    wire        inst_sub_w;
    wire        inst_slt;
    wire        inst_slti;
    wire        inst_sltu;
    wire        inst_sltui;
    wire        inst_nor;
    wire        inst_and;
    wire        inst_or;
    wire        inst_xor;
    wire        inst_andi;
    wire        inst_ori;
    wire        inst_xori;
    wire        inst_sll_w;
    wire        inst_srl_w;
    wire        inst_sra_w;
    wire        inst_slli_w;
    wire        inst_srli_w;
    wire        inst_srai_w;
    wire        inst_addi_w;
    wire        inst_ld_b;
    wire        inst_ld_h;
    wire        inst_ld_w;
    wire        inst_st_b;
    wire        inst_st_h;
    wire        inst_st_w;
    wire        inst_ld_bu;
    wire        inst_ld_hu;
    wire        inst_jirl;
    wire        inst_b;
    wire        inst_bl;
    wire        inst_beq;
    wire        inst_bne;
    wire        inst_blt;
    wire        inst_bge;
    wire        inst_bltu;
    wire        inst_bgeu;
    wire        inst_lu12i_w;
    wire        inst_pcaddu12i;
    wire        inst_mul_w;
    wire        inst_mulh_w;
    wire        inst_mulh_wu;
    wire        inst_div_w;
    wire        inst_mod_w;
    wire        inst_div_wu;
    wire        inst_mod_wu;

    wire        need_ui5;
    wire        need_si12;
    wire        need_si16;
    wire        need_si20;
    wire        need_si26;
    wire        src2_is_4;

    assign op_31_26  = inst[31:26];
    assign op_25_22  = inst[25:22];
    assign op_21_20  = inst[21:20];
    assign op_19_15  = inst[19:15];

    assign rd   = inst[ 4: 0];
    assign rj   = inst[ 9: 5];
    assign rk   = inst[14:10];

    assign i12  = inst[21:10];
    assign i20  = inst[24: 5];
    assign i16  = inst[25:10];
    assign i26  = {inst[ 9: 0], inst[25:10]};

    decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
    decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
    decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
    decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

    assign inst_add_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
    assign inst_sub_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
    assign inst_slt       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
    assign inst_slti      = op_31_26_d[6'h00] & op_25_22_d[4'h8];
    assign inst_sltu      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
    assign inst_sltui     = op_31_26_d[6'h00] & op_25_22_d[4'h9];
    assign inst_nor       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
    assign inst_and       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
    assign inst_or        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
    assign inst_xor       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
    assign inst_sll_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];
    assign inst_srl_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
    assign inst_sra_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
    assign inst_slli_w    = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
    assign inst_srli_w    = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
    assign inst_srai_w    = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
    assign inst_addi_w    = op_31_26_d[6'h00] & op_25_22_d[4'ha];
    assign inst_ld_b      = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
    assign inst_ld_h      = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
    assign inst_ld_w      = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
    assign inst_st_b      = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
    assign inst_st_h      = op_31_26_d[6'h0a] & op_25_22_d[4'h5];
    assign inst_st_w      = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
    assign inst_ld_bu     = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
    assign inst_ld_hu     = op_31_26_d[6'h0a] & op_25_22_d[4'h9];
    assign inst_jirl      = op_31_26_d[6'h13];
    assign inst_b         = op_31_26_d[6'h14];
    assign inst_bl        = op_31_26_d[6'h15];
    assign inst_beq       = op_31_26_d[6'h16];
    assign inst_bne       = op_31_26_d[6'h17];
    assign inst_blt       = op_31_26_d[6'h18];
    assign inst_bge       = op_31_26_d[6'h19];
    assign inst_bltu      = op_31_26_d[6'h1a];
    assign inst_bgeu      = op_31_26_d[6'h1b];
    assign inst_lu12i_w   = op_31_26_d[6'h05] & ~inst[25];
    assign inst_andi      = op_31_26_d[6'h00] & op_25_22_d[4'hd];
    assign inst_ori       = op_31_26_d[6'h00] & op_25_22_d[4'he];
    assign inst_xori      = op_31_26_d[6'h00] & op_25_22_d[4'hf];
    assign inst_pcaddu12i = op_31_26_d[6'h07];
    assign inst_mul_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
    assign inst_mulh_w    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19];
    assign inst_mulh_wu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1a];
    assign inst_div_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h00];
    assign inst_mod_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h01];
    assign inst_div_wu    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h02];
    assign inst_mod_wu    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h03];

    assign load_op = {inst_st_w, inst_st_h, inst_st_b, inst_ld_hu, inst_ld_bu, inst_ld_w, inst_ld_h, inst_ld_b};

    assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w
                        | inst_jirl | inst_bl | inst_pcaddu12i;
    assign alu_op[ 1] = inst_sub_w;
    assign alu_op[ 2] = inst_slt | inst_slti;
    assign alu_op[ 3] = inst_sltu | inst_sltui;
    assign alu_op[ 4] = inst_and | inst_andi;
    assign alu_op[ 5] = inst_nor;
    assign alu_op[ 6] = inst_or | inst_ori;
    assign alu_op[ 7] = inst_xor | inst_xori;
    assign alu_op[ 8] = inst_slli_w | inst_sll_w;
    assign alu_op[ 9] = inst_srli_w | inst_srl_w;
    assign alu_op[10] = inst_srai_w | inst_sra_w;
    assign alu_op[11] = inst_lu12i_w;

    assign mul_op = {inst_mulh_wu, inst_mulh_w, inst_mul_w};
    assign div_op = {inst_mod_wu, inst_mod_w, inst_div_wu, inst_div_w};

    assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;
    assign need_si12  =  inst_addi_w | inst_andi | inst_ori | inst_xori | inst_ld_b | inst_ld_h | inst_ld_w | inst_st_b | inst_st_h | inst_st_w | inst_ld_bu | inst_ld_hu | inst_slti | inst_sltui;
    assign need_si16  =  inst_jirl | inst_beq | inst_bne;
    assign need_si20  =  inst_lu12i_w | inst_pcaddu12i;
    assign need_si26  =  inst_b | inst_bl;
    assign src2_is_4  =  inst_jirl | inst_bl;

    assign imm = src2_is_4      ? 32'h4                      :
                 need_si20      ? {i20[19:0], 12'b0}         :
    /*need_ui5 || need_si12*/     {{20{i12[11]}}, i12[11:0]} ;

    assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                                {{14{i16[15]}}, i16[15:0], 2'b0} ;

    assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

    assign src_reg_is_rd = inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu | inst_st_b | inst_st_h | inst_st_w;

    assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;

    assign src2_is_imm   = inst_slli_w   |
                           inst_srli_w   |
                           inst_srai_w   |
                           inst_addi_w   |
                           inst_andi     |
                           inst_ori      |
                           inst_xori     |
                           inst_slti     |
                           inst_sltui    |
                           inst_ld_b     |
                           inst_ld_h     |
                           inst_ld_w     |
                           inst_st_b     |
                           inst_st_h     |
                           inst_st_w     |
                           inst_ld_bu    |
                           inst_ld_hu    |
                           inst_lu12i_w  |
                           inst_jirl     |
                           inst_bl       |
                           inst_pcaddu12i;

    assign res_from_mem  = inst_ld_b | inst_ld_h | inst_ld_w | inst_ld_bu | inst_ld_hu;
    assign dst_is_r1     = inst_bl;

    assign gr_we         = ~inst_st_b & ~inst_st_h & ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b & ~inst_blt & ~inst_bge & ~inst_bltu & ~inst_bgeu;
    assign mem_we        = inst_st_b | inst_st_h | inst_st_w;
    assign dest          = dst_is_r1 ? 5'd1 : rd;

    assign rf_raddr1 = rj;
    assign rf_raddr2 = src_reg_is_rd ? rd :rk;

    always @(*) begin
		if (rst) begin
			rj_value = 32'b0;
		end
        else if (out_valid && gr_we_out && !res_from_mem_out && (rf_raddr1 == dest_out) && (dest_out != 5'b0)) begin
            rj_value = result;
        end
        else if (MEM_valid && MEM_gr_we && !MEM_res_from_mem && (rf_raddr1 == MEM_dest) && (MEM_dest != 5'b0)) begin
            rj_value = MEM_result;
        end
        else if (WB_valid && WB_gr_we && (rf_raddr1 == WB_dest) && (WB_dest != 5'b0)) begin
            rj_value = WB_res_from_mem ? WB_data_sram_rdata : WB_result;
        end
        else begin
            rj_value = rf_rdata1;
        end
	end

    always @(*) begin
		if (rst) begin
			rkd_value = 32'b0;
		end
        else if (out_valid && gr_we_out && !res_from_mem_out && (rf_raddr2 == dest_out) && (dest_out != 5'b0)) begin
            rkd_value = result;
        end
        else if (MEM_valid && MEM_gr_we && !MEM_res_from_mem && (rf_raddr2 == MEM_dest) && (MEM_dest != 5'b0)) begin
            rkd_value = MEM_result;
        end
        else if (WB_valid && WB_gr_we && (rf_raddr2 == WB_dest) && (WB_dest != 5'b0)) begin
            rkd_value = WB_res_from_mem ? WB_data_sram_rdata : WB_result;
        end
        else begin
            rkd_value = rf_rdata2;
        end
	end
    
    assign rj_eq_rd = (rj_value == rkd_value);
    assign rj_lt_rd = ($signed(rj_value) < $signed(rkd_value));
    assign rj_ltu_rd = (rj_value < rkd_value);
    assign br_taken = (   inst_beq  &&  rj_eq_rd
                    || inst_bne  && !rj_eq_rd
                    || inst_blt && rj_lt_rd
                    || inst_bltu && rj_ltu_rd
                    || inst_bge && !rj_lt_rd
                    || inst_bgeu && !rj_ltu_rd
                    || inst_jirl
                    || inst_bl
                    || inst_b
    ) && in_valid;
    assign br_target = (inst_beq || inst_bne || inst_bl || inst_b) ? (PC + br_offs) :
                                                   /*inst_jirl*/ (rj_value + jirl_offs);
    
    always @(posedge clk) begin
		if (rst) begin
			PC_out <= 32'h1c000000;
		end
		else if (in_valid & ready_go & out_ready) begin
			PC_out <= PC;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			rj_value_out <= 32'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			rj_value_out <= rj_value;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			rkd_value_out <= 32'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			rkd_value_out <= rkd_value;
		end
	end

    assign br_taken_out = (~rst) & in_valid & ready_go & out_ready & br_taken;
    assign br_target_out = {32{(~rst) & in_valid & ready_go & out_ready}} & br_target;

    always @(posedge clk) begin
        if (rst) begin
            load_op_out <= 8'b0;
        end
        else if (in_valid & ready_go & out_ready) begin
			load_op_out <= load_op;
		end
    end

    always @(posedge clk) begin
		if (rst) begin
			alu_op_out <= 12'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			alu_op_out <= alu_op;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			mul_op_out <= 3'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			mul_op_out <= mul_op;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			div_op_out <= 4'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			div_op_out <= div_op;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			src1_is_pc_out <= 1'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			src1_is_pc_out <= src1_is_pc;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			src2_is_imm_out <= 1'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			src2_is_imm_out <= src2_is_imm;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			res_from_mem_out <= 1'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			res_from_mem_out <= res_from_mem;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			gr_we_out <= 1'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			gr_we_out <= gr_we;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			mem_we_out <= 1'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			mem_we_out <= mem_we;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			dest_out <= 5'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			dest_out <= dest;
		end
	end

    always @(posedge clk) begin
		if (rst) begin
			imm_out <= 32'b0;
		end
		else if (in_valid & ready_go & out_ready) begin
			imm_out <= imm;
		end
	end

    assign load_use_sign = in_valid & (
		rf_raddr1 == dest_out & gr_we_out & res_from_mem_out & out_valid |
        rf_raddr2 == dest_out & gr_we_out & res_from_mem_out & out_valid |
        rf_raddr1 == MEM_dest & MEM_gr_we & MEM_res_from_mem & MEM_valid |
        rf_raddr2 == MEM_dest & MEM_gr_we & MEM_res_from_mem & MEM_valid
    );
endmodule
