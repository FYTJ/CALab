module R (
    input clk,
    input resetn,
    
    output reg [1: 0] id,
    output reg data_ok,
    output reg [31: 0] data,
    output reg last,

    input [3: 0] rid,
    input [31: 0] rdata,
    input [1: 0] rresp,
    input rlast,
    input rvalid,
    output rready
);
    assign rready = resetn;

    always @(posedge clk) begin
        if (!resetn) begin
            id <= 2'b0;
            data_ok <= 1'b0;
            data <= 32'b0;
            last <= 1'b0;
        end
        else begin
            id <= {rid[0], ~rid[0]};
            data_ok <= rvalid && rready;
            data <= rdata;
            last <= rlast;
        end
    end
endmodule
