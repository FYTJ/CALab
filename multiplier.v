module multiplier (
    input mul_clk,
    input reset,
    input [2: 0] mul_op,
    input [31:0] x,
    input [31:0] y,
    input  to_mul_req_valid,
    output from_mul_req_ready,
    input  to_mul_resp_ready,
    output from_mul_resp_valid,
    output [63:0] result
);
    wire mul_signed;
    wire [63:0] x_ext, neg_x_ext, x_ext_mult2, neg_x_ext_mult2;
    wire [34:0] y_shift1;
    wire [63:0] partial_product [16:0];
    wire [16:0] wallace_input [63:0];
    wire [13:0] cin_cout [64:0];
    wire [63:0] S, C;

    reg M1_out_valid;
    wire M1_out_ready;
    wire M1_ready_go;

    wire M2_in_valid;
    wire M2_in_ready;
    wire M2_ready_go;

    assign M1_out_ready = M2_in_ready;
    assign M1_ready_go = to_mul_req_valid & from_mul_req_ready;

    wire M1_out_valid_next = M1_ready_go & M1_out_ready;
    always @(posedge mul_clk) begin
        if(reset) begin
            M1_out_valid <= 1'b0;
        end else begin
            M1_out_valid <= M1_out_valid_next;
        end
    end

    assign M2_in_valid = M1_out_valid;
    assign M2_in_ready = !(M2_in_valid) || M2_ready_go;
    assign M2_ready_go = to_mul_resp_ready & from_mul_resp_valid;

    assign from_mul_req_ready = M1_out_ready;
    assign from_mul_resp_valid = M2_in_valid;


    assign mul_signed = mul_op[0] || mul_op[1];
    assign x_ext = {{32{x[31] & mul_signed}}, x};
    assign neg_x_ext = ~x_ext + 1;
    assign x_ext_mult2 = x_ext << 1;
    assign neg_x_ext_mult2 = neg_x_ext << 1;
    assign y_shift1 = {{2{y[31] & mul_signed}}, y, 1'b0};
    
    genvar i, j;
    // booth
    generate
        for(i = 0; i < 17; i = i + 1) begin
            booth booth_unit(
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
            wallace wallace_unit(
                .in(wallace_input[i]),
                .Cin(cin_cout[i]),
                .reset(reset),
                .mul_clk(mul_clk),
                .M1_ready_go(M1_ready_go),
                .M1_out_ready(M1_out_ready),
                .Cout(cin_cout[i+1]),
                .S(S[i]),
                .C(C[i])
            );
        end
    endgenerate

    assign result = {C[62:0], 1'b0} + S;


endmodule