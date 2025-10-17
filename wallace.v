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
                .resetn(resetn),
                .mul_clk(mul_clk),
                .Cout(cin_cout[i+1]),
                .S(S[i]),
                .C(C[i])
            );
        end
    endgenerate

    assign result = {C[62:0], 1'b0} + S;


endmodule

module wallace (
    input [16:0] in,    // 17-bit
    input [13:0] Cin,
    input resetn,
    input mul_clk,
    output [13:0] Cout,
    output S,
    output C
);
    // first layer
    wire [4:0] S1;
    genvar i;
    generate
        for(i = 0; i < 5; i = i + 1) begin : layer1
            full_adder full_adder_layer_1 (
                .A(in[3*i+4]),
                .B(in[3*i+3]),
                .Cin(in[3*i+2]),
                .S(S1[i]),
                .Cout(Cout[i])
            );
        end
    endgenerate

    // register for pipeline
    reg [13:0] Cin_reg;
    reg [ 4:0] S1_reg;
    reg [16:0] in_reg;
    always @(posedge mul_clk) begin
        if(!resetn) begin
            Cin_reg <= 14'd0;
            S1_reg <= 5'd0;
            in_reg <= 17'd0;
        end 
        else begin
            Cin_reg <= Cin;
            S1_reg <= S1;
            in_reg <= in;
        end
    end

    // second layer
    wire [3:0] S2;
    wire [11:0] in2;
    assign in2 = {S1_reg, in_reg[1:0], Cin_reg[4:0]};
    generate
        for(i = 0; i < 4; i = i + 1) begin : layer2
            full_adder full_adder_layer_2 (
                .A(in2[3*i+2]),
                .B(in2[3*i+1]),
                .Cin(in2[3*i]),
                .S(S2[i]),
                .Cout(Cout[i+5])
            );
        end
    endgenerate

    // third layer
    wire [1:0] S3;
    wire [5:0] in3;
    assign in3 = {S2, Cin[6:5]};
    generate
        for(i = 0; i < 2; i = i + 1) begin : layer3
            full_adder full_adder_layer_3 (
                .A(in3[3*i+2]),
                .B(in3[3*i+1]),
                .Cin(in3[3*i]),
                .S(S3[i]),
                .Cout(Cout[i+9])
            );
        end
    endgenerate

    // fourth layer
    wire [1:0] S4;
    wire [5:0] in4;
    assign in4 = {S3, Cin[10:7]};
    generate
        for(i = 0; i < 2; i = i + 1) begin : layer4
            full_adder full_adder_layer_4 (
                .A(in4[3*i+2]),
                .B(in4[3*i+1]),
                .Cin(in4[3*i]),
                .S(S4[i]),
                .Cout(Cout[i+11])
            );
        end
    endgenerate

    // fifth layer
    wire S5;
    full_adder full_adder_layer_5 (
        .A(S4[1]),
        .B(S4[0]),
        .Cin(Cin[11]),
        .S(S5),
        .Cout(Cout[13])
    );

    // sixth layer
    full_adder full_adder_layer_6 (
        .A(S5),
        .B(Cin[13]),
        .Cin(Cin[12]),
        .S(S),
        .Cout(C)
    );

endmodule