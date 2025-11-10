module AR (
    input clk,
    input resetn,

    input [1: 0] id,
    input [31: 0] addr,
    input [1: 0] size,
    output addr_ok,

    input writing,

    output [3: 0] arid,
    output [31: 0] araddr,
    output [7: 0] arlen,
    output [2: 0] arsize,
    output [1: 0] arburst,
    output [1: 0] arlock,
    output [3: 0] arcache,
    output [2: 0] arprot,
    output arvalid,
    input arready
);
    localparam IDLE = 2'b01;
    localparam BUSY = 2'b10;

    assign arlen = 8'b0;
    assign arburst = 2'b01;
    assign arlock = 2'b0;
    assign arcache = 4'b0;
    assign arprot = 3'b0;

    reg [1: 0] current_state;
    reg [1: 0] next_state;

    reg [1: 0] id_reg;
    reg [31: 0] addr_reg;
    reg [1: 0] size_reg;

    assign arid = {3'b0, id_reg[1]};
    assign araddr = addr_reg;
    assign arsize = {1'b0, size_reg};
    assign arvalid = current_state == BUSY;

    assign addr_ok = current_state == IDLE;
    
    always @(posedge clk) begin
        if (!resetn) begin
            id_reg <= 2'b0;
            addr_reg <= 32'b0;
            size_reg <= 2'b0;
        end
        else if (current_state == IDLE) begin
            id_reg <= id;
            addr_reg <= addr;
            size_reg <= size;
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
                    if (id == 2'b01 || id == 2'b10 && !writing) begin
                        // 此处使用wire而非reg的目的是立即响应cpu的请求
                        next_state = BUSY;
                    end
                    else begin
                        next_state = IDLE;
                    end
                end
                BUSY: begin
                    if (arready && arvalid) begin
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
