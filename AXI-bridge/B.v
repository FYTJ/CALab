module B (
    input clk,
    input resetn,
    
    output reg [1: 0] id,
    output reg data_ok,

    input [3: 0] bid,
    input [1: 0] bresp,
    input bvalid,
    output bready
);
    assign bready = resetn;

    always @(posedge clk) begin
        if (!resetn) begin
            id <= 2'b0;
            data_ok <= 1'b0;
        end
        else begin
            id <= 2'b10;
            data_ok <= bvalid && bready;
        end
    end
endmodule
