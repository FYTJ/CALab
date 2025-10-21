module full_adder (
    input wire A,
    input wire B,
    input wire Cin,
    output wire S,
    output wire Cout
);
    assign S = A ^ B ^ Cin;
    assign Cout = A & B | (A | B) & Cin;
endmodule