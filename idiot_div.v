module idiot_div (
    input [31: 0] x,
    input [31: 0] y,
    input [3: 0] div_op,
    output reg [31: 0] result
);
    always @(*) begin
        if (div_op[0]) begin
            result = $signed(x) / $signed(y);
        end
        else if (div_op[1]) begin
            result = x / y;
        end
        else if (div_op[2]) begin
            result = $signed(x) % $signed(y);
        end
        else if (div_op[3]) begin
            result = x % y;
        end
        else begin
            result = 32'b0;
        end
    end
endmodule
