module LSFR (
    input clk,
    input rst,
    output rand_way
);
    reg [7: 0] lfsr_index;
    always @(posedge clk) begin
        if (rst) begin
            lfsr_index <= 8'h1;
        end
        else begin
            lfsr_index <= {lfsr_index[6: 0], feedback_index};
        end
    end
    wire feedback_index = lfsr_index[7] ^ lfsr_index[5] ^ lfsr_index[4] ^ lfsr_index[3];

    assign rand_way = lfsr_index[0];
endmodule
