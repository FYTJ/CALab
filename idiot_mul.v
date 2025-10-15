module idiot_mul (
    input [31: 0] x,
    input [31: 0] y,
    input [2: 0] mul_op,
    output reg [31: 0] result
);
    wire [63: 0] mul_res;
    wire [63: 0] mul_res_u;
    assign mul_res = $signed(x) * $signed(y);
    assign mul_res_u = x * y;
    always @(*) begin
        if (mul_op[0]) begin
            result = mul_res[31: 0];
        end
        else if (mul_op[1]) begin
            result = mul_res[63: 32];
        end
        else if (mul_op[2]) begin
            result = mul_res_u[63: 32];
        end
        else begin
            result = 32'b0;
        end
    end
endmodule
