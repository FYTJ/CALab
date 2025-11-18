`include "AR.v"
`include "R.v"
`include "AW.v"
`include "B.v"

module AXI_bridge (
    input clk,
    input resetn,

    // SRAM side
    // Inst-RAM
    input sram_req_1,
    input sram_wr_1,
    input [1: 0] sram_size_1,
    input [31: 0] sram_addr_1,
    input [3: 0] sram_wstrb_1,
    input [31: 0] sram_wdata_1,
    output sram_addr_ok_1,
    output sram_data_ok_1,
    output [31: 0] sram_rdata_1,

    // Data-Ram
    input sram_req_2,
    input sram_wr_2,
    input [1: 0] sram_size_2,
    input [31: 0] sram_addr_2,
    input [3: 0] sram_wstrb_2,
    input [31: 0] sram_wdata_2,
    output sram_addr_ok_2,
    output sram_data_ok_2,
    output [31: 0] sram_rdata_2,

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
    output bready
);
    wire [1: 0] ar_id;
    wire [1: 0] aw_id;
    wire [1: 0] ar_size;
    wire [1: 0] aw_size;
    wire [31: 0] ar_addr;
    wire [31: 0] aw_addr;
    wire [3: 0] strb;
    wire [31: 0] write_data;
    wire ar_addr_ok;
    wire aw_addr_ok;
    wire r_data_ok;
    wire b_data_ok;
    wire [31: 0] read_data;
    wire [1: 0] r_id;
    wire [1: 0] b_id;
    reg  [4: 0] writing;

    // 注意此处顺序：data-req优先级大于inst-req
    assign ar_id = (~sram_wr_2 && sram_req_2) ? 2'b10 : (~sram_wr_1 && sram_req_1) ? 2'b01 : 2'b00;
    assign aw_id = (sram_wr_2 && sram_req_2) ? 2'b10 : 2'b00;
    assign ar_size = ~sram_wr_2 && sram_req_2 ? sram_size_2 : sram_size_1;
    assign aw_size = sram_size_2;
    assign ar_addr = ~sram_wr_2 && sram_req_2 ? sram_addr_2 : sram_addr_1;
    assign aw_addr = sram_addr_2;
    assign strb = sram_wstrb_2;
    assign write_data = sram_wdata_2;
    assign sram_rdata_1 = read_data;
    assign sram_rdata_2 = read_data;
    // 如果同时存在读内存和取指请求，优先选择了MEM，则此时addr_ok_1不能拉高
    assign sram_addr_ok_1 = ar_id[0] ? ar_addr_ok : 1'b0;
    // WARNING: MEM的addr_ok是否应该依赖wr？
    // RAW阻塞：当内存写忙时，禁止接收内存读请求
    assign sram_addr_ok_2 = sram_wr_2 ? aw_addr_ok : (writing != 0) ? 1'b0 : ar_id[1] ? ar_addr_ok : 1'b0;
    assign sram_data_ok_1 = r_id[0] && r_data_ok;
    assign sram_data_ok_2 = r_id[1] && r_data_ok || b_data_ok;

    always @(posedge clk) begin
        if (!resetn) begin
            writing <= 5'b0;
        end
        else if (sram_wr_2 && aw_addr_ok && sram_req_2 && b_data_ok) begin
            writing <= writing;
        end
        else if (sram_wr_2 && aw_addr_ok && sram_req_2) begin
            writing <= writing + 1;
        end
        else if (b_data_ok) begin
            writing <= writing - 1;
        end
    end

    AR AR_Channel(
        .clk(clk),
        .resetn(resetn),
        .id(ar_id),
        .addr(ar_addr),
        .size(ar_size),
        .addr_ok(ar_addr_ok),

        .writing(writing),

        .arid(arid),
        .araddr(araddr),
        .arlen(arlen),
        .arsize(arsize),
        .arburst(arburst),
        .arlock(arlock),
        .arcache(arcache),
        .arprot(arprot),
        .arvalid(arvalid),
        .arready(arready)
    );

    R R_Channel(
        .clk(clk),
        .resetn(resetn),

        .id(r_id),
        .data_ok(r_data_ok),
        .data(read_data),

        .rid(rid),
        .rdata(rdata),
        .rresp(rresp),
        .rlast(rlast),
        .rvalid(rvalid),
        .rready(rready)
    );

    AW W_Channel(
        .clk(clk),
        .resetn(resetn),

        .id(aw_id),
        .addr(aw_addr),
        .size(aw_size),
        .strb(strb),
        .data(write_data),
        .addr_ok(aw_addr_ok),

        .awid(awid),
        .awaddr(awaddr),
        .awlen(awlen),
        .awsize(awsize),
        .awburst(awburst),
        .awlock(awlock),
        .awcache(awcache),
        .awprot(awprot),
        .awvalid(awvalid),
        .awready(awready),

        .wid(wid),
        .wdata(wdata),
        .wstrb(wstrb),
        .wlast(wlast),
        .wvalid(wvalid),
        .wready(wready)
    );

    B B_Channel(
        .clk(clk),
        .resetn(resetn),

        .id(b_id),
        .data_ok(b_data_ok),

        .bid(bid),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready)
    );
endmodule
