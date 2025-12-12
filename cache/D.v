module D(
    input wire clk,
    input wire [7: 0] addr,
    output wire rdata,
    input wire we,
    input wire wdata
);
reg d[255: 0];

always @(posedge clk) begin
    if (we) d[addr] <= wdata;
end

assign rdata = d[addr];
endmodule
