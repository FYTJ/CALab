module AW (
    input clk,
    input resetn,

    input [1: 0] id,
    input [31: 0] addr,
    input [1: 0] size,
    input [3: 0] strb,
    input [31: 0] data,
    output addr_ok,

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

    output [3: 0] wid,
    output [31: 0] wdata,
    output [3: 0] wstrb,
    output wlast,
    output wvalid,
    input wready
);
    localparam IDLE = 2'b01;
    localparam BUSY = 2'b10;

    assign awid = 4'b1;
    assign awlen = 8'b0;
    assign awburst = 2'b01;
    assign awlock = 2'b0;
    assign awcache = 4'b0;
    assign awprot = 3'b0;
    assign wid = 4'b1;
    assign wlast = 1'b1;

    reg [1: 0] current_state;
    reg [1: 0] next_state;
    reg aw_fire;
    reg w_fire;

    reg [31: 0] addr_reg;
    reg [1: 0] size_reg;
    reg [3: 0] strb_reg;
    reg [31: 0] data_reg;

    assign awaddr = addr_reg;
    assign awsize = {1'b0, size_reg};
    assign awvalid = current_state == BUSY;
    assign wdata = data_reg;
    assign wstrb = strb_reg;
    assign wvalid = current_state == BUSY;

    assign addr_ok = current_state == IDLE;

    always @(posedge clk) begin
        if (!resetn) begin
            addr_reg <= 32'b0;
            size_reg <= 2'b0;
            strb_reg <= 4'b0;
            data_reg <= 32'b0;
        end
        else if (current_state == IDLE) begin
            addr_reg <= addr;
            size_reg <= size;
            strb_reg <= strb;
            data_reg <= data;
        end
    end

    // 注意此处逻辑的顺序，地址和数据握手均成功时应该还原fire寄存器
    always @(posedge clk) begin
        if (!resetn) begin
            aw_fire <= 1'b0;
        end
        else if ((awready && awvalid || aw_fire) && (wready && wvalid || w_fire)) begin
            aw_fire <= 1'b0;
        end
        else if (awready && awvalid) begin
            aw_fire <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            w_fire <= 1'b0;
        end
        else if ((awready && awvalid || aw_fire) && (wready && wvalid || w_fire)) begin
            w_fire <= 1'b0;
        end
        else if (wready && wvalid) begin
            w_fire <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        if (!resetn) begin
            next_state = IDLE;
        end
        else begin
            case (current_state)
                IDLE: begin
                    if (id == 2'b01 || id == 2'b10) begin
                        // 此处使用wire而非reg的目的是立即响应cpu的请求
                        next_state = BUSY;
                    end
                    else begin
                        next_state = IDLE;
                    end
                end
                BUSY: begin
                    if ((awready && awvalid || aw_fire) && (wready && wvalid || w_fire)) begin
                        // 需要考虑AW和W握手同时满足和不同时满足的情况(aw_fire和w_fire不会同时为1)
                        next_state = IDLE;
                    end
                    else begin
                        next_state = BUSY;
                    end
                end
                default: begin
                    next_state = IDLE;
                end
            endcase
        end
    end
endmodule
