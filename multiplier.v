module multiplier (
    input mul_clk,
    input resetn,
    input mul_signed,
    input [31:0] x,
    input [31:0] y,
    output [63:0] result
);
    wire [63:0] x_ext, neg_x_ext, x_ext_mult2, neg_x_ext_mult2;
    wire [34:0] y_shift1;
    wire [63:0] partial_product [16:0];
    wire [16:0] wallace_input [63:0];
    wire [13:0] cin_cout [64:0];
    wire [63:0] S, C;
    
    assign x_ext = {{32{x[31] & mul_signed}}, x};
    assign neg_x_ext = ~x_ext + 1;
    assign x_ext_mult2 = x_ext << 1;
    assign neg_x_ext_mult2 = neg_x_ext << 1;
    assign y_shift1 = {{2{y[31] & mul_signed}}, y, 1'b0};
    
    genvar i, j;
    // booth
    generate
        for(i = 0; i < 17; i = i + 1) begin
            booth booth_uint(
                .exponent(i[5:0] << 1),
                .y_2_0(y_shift1[2*i+2:2*i]),
                .x_ext(x_ext),
                .neg_x_ext(neg_x_ext),
                .x_ext_mult2(x_ext_mult2),
                .neg_x_ext_mult2(neg_x_ext_mult2),

                .partial_product(partial_product[i])
            );
        end
    endgenerate

    // transpose
    generate
        for (i = 0; i < 64; i = i + 1) begin
            for (j = 0; j < 17; j = j + 1) begin
                assign wallace_input[i][j] = partial_product[j][i];
            end
        end
    endgenerate

    // wallace
    assign cin_cout[0] = 14'd0;
    generate
        for(i = 0; i < 64; i = i + 1) begin
            wallace wallace_uint(
                .in(wallace_input[i]),
                .Cin(cin_cout[i]),

                .Cout(cin_cout[i+1]),
                .S(S[i]),
                .C(C[i])
            );
        end
    endgenerate

    // register for pipeline
    reg [63:0] S_reg, C_reg;
    always @(posedge mul_clk) begin
        if(!resetn) begin
            S_reg <= 64'd0;
            C_reg <= 64'd0;
        end
        else begin
            S_reg <= S;
            C_reg <= C;
        end
    end

    assign result = {C_reg[62:0], 1'b0} + S_reg;


endmodule