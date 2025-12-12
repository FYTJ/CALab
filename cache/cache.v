module cache (
    input clk,
    input resetn,

    // CPU - cache
    input valid,
    input op,  // 0: read, 1: write
    input [7: 0] index,
    input [19: 0] tag,
    input [3: 0] offset,
    input [3: 0] wstrb,
    input [31: 0] wdata,
    output addr_ok,
    output data_ok,
    output [31: 0] rdata,

    // AXI - cache
    output rd_req,
    output [2: 0] rd_type,
    output [31: 0] rd_addr,
    input rd_rdy,
    input ret_valid,
    input ret_last,
    input [31: 0] ret_data,
    output wr_req,
    output [2: 0] wr_type,
    output [31: 0] wr_addr,
    output [3: 0] wr_wstrb,
    output [127: 0] wr_data,
    input wr_rdy
);
    wire rst = !resetn;

    // FSM
    localparam M_IDLE = 5'b00001;
    localparam M_LOOKUP = 5'b00010;
    localparam M_MISS = 5'b00100;
    localparam M_REPLACE = 5'b01000;
    localparam M_REFILL = 5'b10000;
    localparam W_IDLE = 2'b01;
    localparam W_WRITE = 2'b10;

    reg [4: 0] m_current_state;
    reg [4: 0] m_next_state;
    reg [1: 0] w_current_state;
    reg [1: 0] w_next_state;

    always @(posedge clk) begin
        if (rst) begin
            m_current_state <= M_IDLE;
            w_current_state <= W_IDLE;
        end
        else begin
            m_current_state <= m_next_state;
            w_current_state <= w_next_state;
        end
    end

    // TagV
    wire tagv0_en = 1'b1;
    wire [7: 0] tagv0_addr;
    wire [20: 0] tagv0_rdata;
    wire tagv0_we;
    wire [20: 0] tagv0_wdata;
    wire tagv1_en = 1'b1;
    wire [7: 0] tagv1_addr;
    wire [20: 0] tagv1_rdata;
    wire tagv1_we;
    wire [20: 0] tagv1_wdata;

    tagv_ram u_tagv0 (
        .clka (clk),
        .ena (tagv0_en),
        .wea (tagv0_we),
        .addra (tagv0_addr),
        .dina (tagv0_wdata),
        .douta (tagv0_rdata)
    );

    tagv_ram u_tagv1 (
        .clka (clk),
        .ena (tagv1_en),
        .wea (tagv1_we),
        .addra (tagv1_addr),
        .dina (tagv1_wdata),
        .douta (tagv1_rdata)
    );

    // D
    wire [7: 0] d0_addr;
    wire d0_rdata;
    wire d0_we;
    wire d0_wdata;
    wire [7: 0] d1_addr;
    wire d1_rdata;
    wire d1_we;
    wire d1_wdata;
    
    D u_d0(
        .clk(clk),
        .rst(rst),
        .addr(d0_addr),
        .rdata(d0_rdata),
        .we(d0_we),
        .wdata(d0_wdata)
    );

    D u_d1(
        .clk(clk),
        .rst(rst),
        .addr(d1_addr),
        .rdata(d1_rdata),
        .we(d1_we),
        .wdata(d1_wdata)
    );

    // Data
    wire data0_en = 1'b1;
    wire [7: 0] data0_raddr;
    wire [31: 0] data0_bank0_rdata;
    wire [31: 0] data0_bank1_rdata;
    wire [31: 0] data0_bank2_rdata;
    wire [31: 0] data0_bank3_rdata;
    wire [3: 0] data0_wbank_sel;
    wire [3: 0] data0_bank0_we;
    wire [3: 0] data0_bank1_we;
    wire [3: 0] data0_bank2_we;
    wire [3: 0] data0_bank3_we;
    wire [7: 0] data0_waddr;
    wire [31: 0] data0_wdata;
    wire data1_en = 1'b1;
    wire [7: 0] data1_raddr;
    wire [31: 0] data1_bank0_rdata;
    wire [31: 0] data1_bank1_rdata;
    wire [31: 0] data1_bank2_rdata;
    wire [31: 0] data1_bank3_rdata;
    wire [3: 0] data1_wbank_sel;
    wire [3: 0] data1_bank0_we;
    wire [3: 0] data1_bank1_we;
    wire [3: 0] data1_bank2_we;
    wire [3: 0] data1_bank3_we;
    wire [7: 0] data1_waddr;
    wire [31: 0] data1_wdata;

    wire [127: 0] data0_rdata = {data0_bank3_rdata, data0_bank2_rdata, data0_bank1_rdata, data0_bank0_rdata};
    wire [127: 0] data1_rdata = {data1_bank3_rdata, data1_bank2_rdata, data1_bank1_rdata, data1_bank0_rdata};

    data_ram u_data0_bank0 (
        .clka (clk),
        .ena (data0_en),
        .wea (data0_bank0_we),
        .addra (data0_waddr),
        .dina (data0_wdata),
        .clkb (clk),
        .enb (data0_en),
        .addrb (data0_raddr),
        .doutb (data0_bank0_rdata)
    );

    data_ram u_data0_bank1 (
        .clka (clk),
        .ena (data0_en),
        .wea (data0_bank1_we),
        .addra (data0_waddr),
        .dina (data0_wdata),
        .clkb (clk),
        .enb (data0_en),
        .addrb (data0_raddr),
        .doutb (data0_bank1_rdata)
    );

    data_ram u_data0_bank2 (
        .clka (clk),
        .ena (data0_en),
        .wea (data0_bank2_we),
        .addra (data0_waddr),
        .dina (data0_wdata),
        .clkb (clk),
        .enb (data0_en),
        .addrb (data0_raddr),
        .doutb (data0_bank2_rdata)
    );

    data_ram u_data0_bank3 (
        .clka (clk),
        .ena (data0_en),
        .wea (data0_bank3_we),
        .addra (data0_waddr),
        .dina (data0_wdata),
        .clkb (clk),
        .enb (data0_en),
        .addrb (data0_raddr),
        .doutb (data0_bank3_rdata)
    );
    data_ram u_data1_bank0 (
        .clka (clk),
        .ena (data1_en),
        .wea (data1_bank0_we),
        .addra (data1_waddr),
        .dina (data1_wdata),
        .clkb (clk),
        .enb (data1_en),
        .addrb (data1_raddr),
        .doutb (data1_bank0_rdata)
    );

    data_ram u_data1_bank1 (
        .clka (clk),
        .ena (data1_en),
        .wea (data1_bank1_we),
        .addra (data1_waddr),
        .dina (data1_wdata),
        .clkb (clk),
        .enb (data1_en),
        .addrb (data1_raddr),
        .doutb (data1_bank1_rdata)
    );

    data_ram u_data1_bank2 (
        .clka (clk),
        .ena (data1_en),
        .wea (data1_bank2_we),
        .addra (data1_waddr),
        .dina (data1_wdata),
        .clkb (clk),
        .enb (data1_en),
        .addrb (data1_raddr),
        .doutb (data1_bank2_rdata)
    );

    data_ram u_data1_bank3 (
        .clka (clk),
        .ena (data1_en),
        .wea (data1_bank3_we),
        .addra (data1_waddr),
        .dina (data1_wdata),
        .clkb (clk),
        .enb (data1_en),
        .addrb (data1_raddr),
        .doutb (data1_bank3_rdata)
    );

    // LFSR
    wire rand_way;

    LSFR u_LSFR(
        .clk(clk),
        .rand_way(rand_way)
    );

    // M_IDLE
    reg op_reg;
    reg [19: 0] tag_reg;
    reg [7: 0] index_reg;
    reg [3: 0] offset_reg;
    reg [3: 0] wstrb_reg;
    reg [31: 0] wdata_reg;
    always @(posedge clk) begin
        if (rst) begin
            op_reg <= 1'b0;
            tag_reg <= 20'b0;
            index_reg <= 8'b0;
            offset_reg <= 4'b0;
            wstrb_reg <= 4'b0;
            wdata_reg <= 32'b0;
        end
        else if (((m_current_state == M_IDLE) && valid && !stall) || ((m_current_state == M_LOOKUP) && hit && valid && !stall)) begin
            op_reg <= op;
            tag_reg <= tag;
            index_reg <= index;
            offset_reg <= offset;
            wstrb_reg <= wstrb;
            wdata_reg <= wdata;
        end
    end

    assign data0_raddr = (m_current_state == M_IDLE) ? index : index_reg;
    assign data1_raddr = (m_current_state == M_IDLE) ? index : index_reg;

    // M_LOOKUP
    wire hit_way_0 = tagv0_rdata[20: 1] == tag_reg && tagv0_rdata[0];
    wire hit_way_1 = tagv1_rdata[20: 1] == tag_reg && tagv1_rdata[0];
    wire hit = (hit_way_0) || (hit_way_1);

    // M_MISS
    reg replace_way;

    always @(posedge clk) begin
        if (rst) begin
            replace_way <= 1'b0;
        end
        else if ((m_current_state == M_MISS) && wr_rdy) begin
            replace_way <= rand_way;
        end
    end

    // M_REPLACE
    reg wr_req_reg;
    always @(posedge clk) begin
        if (rst) begin
            wr_req_reg <= 1'b0;
        end
        else if ((m_current_state == M_MISS) && wr_rdy) begin
            wr_req_reg <= 1'b1;
        end
        else if ((m_current_state == M_REPLACE) && wr_rdy) begin
            wr_req_reg <= 1'b0;
        end
    end

    assign tagv0_we = (replace_way == 1'b0) && ret_last;
    assign tagv0_wdata = {tag_reg, 1'b1};
    assign tagv1_we = (replace_way == 1'b1) && ret_last;
    assign tagv1_wdata = {tag_reg, 1'b1};

    assign d0_we = (replace_way == 1'b0) && ret_last;
    assign d0_addr = index_reg;
    assign d0_wdata = op_reg;
    assign d1_we = (replace_way == 1'b1) && ret_last;
    assign d1_addr = index_reg;
    assign d1_wdata = op_reg;

    assign rd_req = (m_current_state == M_REPLACE);
    assign rd_type = 3'b100;
    assign rd_addr = {tag_reg, index_reg, 4'b0};

    assign wr_req = wr_req_reg && (((replace_way == 1'b0) && tagv0_rdata[0] && d0_rdata) || ((replace_way == 1'b1) && tagv1_rdata[0] && d1_rdata));
    assign wr_type = 3'b100;
    assign wr_addr = (replace_way == 1'b0) ? {tagv0_rdata[20: 1], index_reg, 4'b0} : {tagv1_rdata[20: 1], index_reg, 4'b0};
    assign wr_wstrb = 4'b1111;
    assign wr_data = (replace_way == 1'b0) ? data0_rdata : data1_rdata;

    // M_REFILL
    reg [1: 0] read_cnt;
    always @(posedge clk) begin
        if (rst) begin
            read_cnt <= 2'b0;
        end
        else if (ret_last == 1'b1) begin
            read_cnt <= 2'b0;
        end
        else if (ret_valid) begin
            read_cnt <= read_cnt + 2'b1;
        end
    end

    wire [31: 0] refill_mask = {{8{wstrb_reg[3]}}, {8{wstrb_reg[2]}}, {8{wstrb_reg[1]}}, {8{wstrb_reg[0]}}};
    wire [31: 0] refill_wdata = (ret_data & ~refill_mask) | (wdata_reg & refill_mask);

    // W_IDLE
    reg [19: 0] w_tag_reg;
    reg [7: 0] w_index_reg;
    reg [3: 0] w_offset_reg;
    reg w_way_reg;
    reg w_we_reg;
    reg [3: 0] w_wstrb_reg;
    reg [31: 0] w_wdata_reg;
    reg [31: 0] w_prev_data;  // 保存写之前data的值，用于hit_wdata

    always @(posedge clk) begin
        if (rst) begin
            w_tag_reg <= 20'b0;
            w_index_reg <= 8'b0;
            w_offset_reg <= 4'b0;
            w_way_reg <= 1'b0;
            w_we_reg <= 1'b0;
            w_wstrb_reg <= 4'b0;
            w_wdata_reg <= 32'b0;
            w_prev_data <= 32'b0;
        end
        else if ((m_current_state == M_LOOKUP) && hit && (op_reg == 1'b1)) begin
            w_tag_reg <= tag_reg;
            w_index_reg <= index_reg;
            w_offset_reg <= offset_reg;
            w_way_reg <= hit_way_1;
            w_we_reg <= op_reg;
            w_wstrb_reg <= wstrb_reg;
            w_wdata_reg <= wdata_reg;
            w_prev_data <= hit_way_0 ? data0_rdata[offset_reg[3: 2] * 32 +: 32] : data1_rdata[offset_reg[3: 2] * 32 +: 32];
        end
    end

    // W_WRITE
    wire [31: 0] hit_mask = {{8{w_wstrb_reg[3]}}, {8{w_wstrb_reg[2]}}, {8{w_wstrb_reg[1]}}, {8{w_wstrb_reg[0]}}};
    wire [31: 0] hit_wdata = (w_wdata_reg & hit_mask) | (w_prev_data & ~hit_mask);

    // share
    wire stall = 
        (m_current_state == M_LOOKUP) && hit && (op_reg == 1'b1) && valid && (op == 1'b0) && ({tag, index, offset[3: 2]} == {tag_reg, index_reg, offset_reg[3: 2]}) ||
        (w_current_state == W_WRITE) && valid && (op == 1'b0) && (tag == w_tag_reg) && (index == w_index_reg) && (offset[3: 2] == w_offset_reg[3: 2]);

    assign addr_ok = (m_current_state == M_IDLE) || ((m_current_state == M_LOOKUP) && hit && valid && !stall);

    assign data_ok = ((m_current_state == M_LOOKUP) && hit) ||
        ((m_current_state == M_LOOKUP) && (op_reg == 1'b1)) ||
        ((m_current_state == M_REFILL) && (op_reg == 1'b0) && ret_valid && (read_cnt == offset_reg[3: 2]));

    assign tagv0_addr = (m_current_state == M_IDLE) ? index : index_reg;
    assign tagv1_addr = (m_current_state == M_IDLE) ? index : index_reg;

    wire data0_we = ((m_current_state == M_REFILL) && (replace_way == 1'b0) && ret_valid) || ((w_current_state == W_WRITE) && (w_way_reg == 1'b0) && w_we_reg);
    assign data0_wbank_sel = (m_current_state == M_REFILL) ? (4'b1 << read_cnt) : (4'b1 << w_offset_reg[3: 2]);
    assign data0_bank0_we = ((data0_wbank_sel == 4'h1) && data0_we) ? 4'b1111 : 4'b0;
    assign data0_bank1_we = ((data0_wbank_sel == 4'h2) && data0_we) ? 4'b1111 : 4'b0;
    assign data0_bank2_we = ((data0_wbank_sel == 4'h4) && data0_we) ? 4'b1111 : 4'b0;
    assign data0_bank3_we = ((data0_wbank_sel == 4'h8) && data0_we) ? 4'b1111 : 4'b0;
    assign data0_waddr = index_reg;
    assign data0_wdata = (w_current_state == W_WRITE) ? hit_wdata : !op_reg ? ret_data : (read_cnt == offset_reg[3: 2]) ? refill_wdata : ret_data;

    wire data1_we = ((m_current_state == M_REFILL) && (replace_way == 1'b1) && ret_valid) || ((w_current_state == W_WRITE) && (w_way_reg == 1'b1) && w_we_reg);
    assign data1_wbank_sel = (m_current_state == M_REFILL) ? (4'b1 << read_cnt) : (4'b1 << w_offset_reg[3: 2]);
    assign data1_bank0_we = ((data1_wbank_sel == 4'h1) && data1_we) ? 4'b1111 : 4'b0;
    assign data1_bank1_we = ((data1_wbank_sel == 4'h2) && data1_we) ? 4'b1111 : 4'b0;
    assign data1_bank2_we = ((data1_wbank_sel == 4'h4) && data1_we) ? 4'b1111 : 4'b0;
    assign data1_bank3_we = ((data1_wbank_sel == 4'h8) && data1_we) ? 4'b1111 : 4'b0;
    assign data1_waddr = index_reg;
    assign data1_wdata = (w_current_state == W_WRITE) ? hit_wdata : !op_reg ? ret_data : (read_cnt == offset_reg[3: 2]) ? refill_wdata : ret_data;

    assign rdata = hit_way_0 ? data0_rdata[offset_reg[3: 2] * 32 +: 32] :
        hit_way_1 ? data1_rdata[offset_reg[3: 2] * 32 +: 32] :
        ret_data;


    // FSM
    always @(*) begin
        if (rst) begin
            m_next_state = M_IDLE;
        end
        else begin
            case (m_current_state)
                M_IDLE: begin
                    if (valid && !stall) begin
                        m_next_state = M_LOOKUP;
                    end
                    else begin
                        m_next_state = M_IDLE;
                    end
                end
                M_LOOKUP: begin
                    if (hit && (!valid || stall)) begin
                        m_next_state = M_IDLE;
                    end
                    else if (hit && valid) begin
                        m_next_state = M_LOOKUP;
                    end
                    else begin
                        m_next_state = M_MISS;
                    end
                end
                M_MISS: begin
                    if (!wr_rdy) begin
                        m_next_state = M_MISS;
                    end
                    else begin
                        m_next_state = M_REPLACE;
                    end
                end
                M_REPLACE: begin
                    if (!rd_rdy) begin
                        m_next_state = M_REPLACE;
                    end
                    else begin
                        m_next_state = M_REFILL;
                    end
                end
                M_REFILL: begin
                    if (!(ret_valid && ret_last == 1'b1)) begin
                        m_next_state = M_REFILL;
                    end
                    else begin
                        m_next_state = M_IDLE;
                    end
                end
                default begin
                    m_next_state = M_IDLE;
                end
            endcase
        end
    end

    always @(*) begin
        if (rst) begin
            w_next_state = W_IDLE;
        end
        else begin
            case (w_current_state)
                W_IDLE: begin
                    if ((m_current_state == M_LOOKUP) && hit && (op_reg == 1'b1)) begin
                        w_next_state = W_WRITE;
                    end
                    else begin
                        w_next_state = W_IDLE;
                    end
                end 
                W_WRITE: begin
                    if ((m_current_state == M_LOOKUP) && hit && (op_reg == 1'b1)) begin
                        w_next_state = W_WRITE;
                    end
                    else begin
                        w_next_state = W_IDLE;
                    end
                end
                default: begin
                    w_next_state = W_IDLE;
                end
            endcase
        end
    end
endmodule
