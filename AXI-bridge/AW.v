module AW (
    input clk,
    input resetn,

    input [1: 0] id,
    input [31: 0] addr,
    input [1: 0] size,
    input [7: 0] len,
    input [3: 0] strb,
    input [127: 0] data,
    // input last,  // last应为AW内部信号
    // input data_valid,  // 也应为AW内部信号
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
    output [31: 0] wdata, // 注意这里位宽应该是32！！因为是输出给内存的
    output [3: 0] wstrb,
    output wlast,
    output wvalid,
    input wready
);
    localparam IDLE = 4'b0001;
    localparam BUSY = 4'b0010;
    localparam AW_FIRE = 4'b0100;
    localparam W_FIRE = 4'b1000;

    reg [3: 0] current_state;
    reg [3: 0] next_state;

    reg [31: 0] addr_reg;
    reg [1: 0] size_reg;
    reg [7: 0] len_reg;
    reg [3: 0] strb_reg;
    reg [127: 0] data_reg;
    reg [7: 0] counter;

    assign awid = 4'b1;
    assign awlen = len_reg;
    assign awburst = 2'b01;
    assign awlock = 2'b0;
    assign awcache = 4'b0;
    assign awprot = 3'b0;
    assign wid = 4'b1;
    assign wlast = (counter == len_reg);

    assign awaddr = addr_reg;
    assign awsize = {1'b0, size_reg};
    assign awlen = len_reg;
    assign awvalid = current_state == BUSY || current_state == W_FIRE;
    /////////////////////////////////////////////////////
    // 要改！！！！
    // assign wdata = data_reg;
    assign wdata = data_reg[counter * 32 +: 32];
    /////////////////////////////////////////////////////
    assign wstrb = strb_reg;
    assign wvalid = (current_state == BUSY) || (current_state == AW_FIRE);

    assign addr_ok = current_state == IDLE;

    always @(posedge clk) begin
        if (!resetn) begin
            addr_reg <= 32'b0;
            size_reg <= 2'b0;
            len_reg <= 8'b0;
            strb_reg <= 4'b0;
            data_reg <= 128'b0;
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

    always @(posedge clk) begin
        if (!resetn) begin
            counter <= 8'd0;
        end
        else if (wready && wvalid && wlast) begin
            counter <= 8'd0;
        end
        else if (wready && wvalid) begin
            counter <= counter + 8'd1;
        end
    end

    always @(*) begin
        if (!resetn) begin
            next_state = IDLE;
        end
        else begin
            case (current_state)
                IDLE: begin
                    if (id == 2'b01 || id == 2'b10) begin  // 实际上只可能是2'b10
                        // 此处使用wire而非reg的目的是立即响应cpu的请求
                        next_state = BUSY;
                    end
                    else begin
                        next_state = IDLE;
                    end
                end
                BUSY: begin
                    if (awready && awvalid && wready && wvalid && wlast) begin
                        next_state = IDLE;
                    end
                    else if (awready && awready) begin
                        next_state = AW_FIRE;
                    end
                    else if (wready && wvalid && wlast) begin
                        next_state = W_FIRE;
                    end
                    else begin
                        next_state = BUSY;
                    end
                end
                AW_FIRE: begin
                    if (wready && wvalid && wlast) begin
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
