module booth (
    input [4:0] exponent,
    input [2:0] y_2_0,
    input [63:0] x_ext, neg_x_ext, x_ext_mult2, neg_x_ext_mult2,

    output [63:0] partial_product
);

    assign partial_product = ({64{~y_2_0[2] & ~y_2_0[1] & ~y_2_0[0]}} & 64'd0 |
                              {64{~y_2_0[2] & ~y_2_0[1] & y_2_0[0]}}  & x_ext |
                              {64{~y_2_0[2] & y_2_0[1] & ~y_2_0[0]}}  & x_ext |
                              {64{~y_2_0[2] & y_2_0[1] & y_2_0[0]}}   & x_ext_mult2 |
                              {64{y_2_0[2] & ~y_2_0[1] & ~y_2_0[0]}}  & neg_x_ext_mult2 |
                              {64{y_2_0[2] & ~y_2_0[1] & y_2_0[0]}}   & neg_x_ext |
                              {64{y_2_0[2] & y_2_0[1] & ~y_2_0[0]}}   & neg_x_ext |
                              {64{y_2_0[2] & y_2_0[1] & y_2_0[0]}}    & 64'd0)
                              << exponent;

endmodule