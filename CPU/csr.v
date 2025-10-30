module csr(
    input  wire        clk,
    input  wire        csr_re,
    input  wire [13:0] csr_addr,
    output wire [31:0] csr_rvalue,
    input  wire        csr_we,
    input  wire [31:0] csr_wmask,
    input  wire [31:0] csr_wvalue
);
reg [31: 0] csrf[255: 0];
wire [7: 0] addr = csr_addr[7: 0];

always @(posedge clk) begin
    if (csr_we && (csr_addr[13: 8] == 6'b0)) begin
        csrf[addr] <= csrf[addr] & ~csr_wmask | csr_wvalue & csr_wmask;
    end
end

assign csr_rvalue = (csr_addr[11: 8] == 4'b0 && csr_re) ? csrf[addr]: 32'b0;
endmodule
