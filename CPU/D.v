module D(
    input wire clk,
    input rst,
    input wire [7: 0] addr,
    output wire rdata,
    input wire we,
    input wire wdata
);
reg d[255: 0];
integer i;

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < 256; i = i + 1) begin
            d[i] <= 1'b0;
        end
    end else if (we) d[addr] <= wdata;
end

assign rdata = d[addr];
endmodule
