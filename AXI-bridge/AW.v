module AW (
    input clk,
    input resetn,

    input [1: 0] id,
    input [31: 0] addr,
    input [1: 0] size,
    input [7: 0] len,
    input [3: 0] strb,
    input [31: 0] data,
    input last,
    input data_valid,
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
    localparam IDLE = 4'b0001;
    localparam BUSY = 4'b0010;
    localparam AW_FIRE = 4'b0100;
    localparam W_FIRE = 4'b1000;

    assign awid = 4'b1;
    assign awlen = 8'b0;
    assign awburst = 2'b01;
    assign awlock = 2'b0;
    assign awcache = 4'b0;
    assign awprot = 3'b0;
    assign wid = 4'b1;
    assign wlast = 1'b1;

    reg [3: 0] current_state;
    reg [3: 0] next_state;

    reg [31: 0] addr_reg;
    reg [1: 0] size_reg;
    reg [7: 0] len_reg;
    reg [3: 0] strb_reg;
    reg [31: 0] data_reg;

    assign awaddr = addr_reg;
    assign awsize = {1'b0, size_reg};
    assign awlen = len_reg;
    assign awvalid = current_state == BUSY || current_state == W_FIRE;
    assign wdata = data_reg;
    assign wstrb = strb_reg;
    assign wvalid = (current_state == BUSY || current_state == AW_FIRE) && data_valid;

    assign addr_ok = current_state == IDLE;

    always @(posedge clk) begin
        if (!resetn) begin
            addr_reg <= 32'b0;
            size_reg <= 2'b0;
            len_reg <= 8'b0;
            strb_reg <= 4'b0;
            data_reg <= 32'b0;
        end
        else if (current_state == IDLE) begin
            addr_reg <= addr;
            size_reg <= size;
            len_reg <= len;
            strb_reg <= strb;
            data_reg <= data;
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
                    if (awready && awvalid && wready && wvalid && last) begin
                        next_state = IDLE;
                    end
                    else if (awready && awready) begin
                        next_state = AW_FIRE;
                    end
                    else if (wready && wvalid && last) begin
                        next_state = W_FIRE;
                    end
                    else begin
                        next_state = BUSY;
                    end
                end
                AW_FIRE: begin
                    if (wready && wvalid && last) begin
                        next_state = IDLE;
                    end
                    else begin
                        next_state = AW_FIRE;
                    end
                end
                W_FIRE: begin
                    if (awready && awvalid) begin
                        next_state = IDLE;
                    end
                    else begin
                        next_state = W_FIRE;
                    end
                end
                default: begin
                    next_state = IDLE;
                end
            endcase
        end
    end
endmodule
