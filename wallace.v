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

    // second layer
    wire [3:0] S2;
    wire [11:0] in2;
    assign in2 = {S1, in[1:0], Cin[4:0]};
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

    // register for pipeline
    reg [13:0] Cin_reg;
    reg [ 1:0] S3_reg;
    always @(posedge mul_clk) begin
        if(!resetn) begin
            Cin_reg <= 14'd0;
            S3_reg <= 2'd0;
        end 
        else begin
            Cin_reg <= Cin;
            S3_reg <= S3;
        end
    end

    // fourth layer
    wire [1:0] S4;
    wire [5:0] in4;
    assign in4 = {S3_reg, Cin_reg[10:7]};
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