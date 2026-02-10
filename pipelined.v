// Pipelined
    module pipelined (
    input wire clk,
    input wire rst,

    input wire  in_valid,
    output wire in_ready,

    input wire signed [15:0] a,
    input wire signed [15:0] b,
    input wire signed [15:0] c,
    input wire signed [15:0] d,
    input wire signed [15:0] e,

    output reg out_valid,
    input wire  out_ready,
    output reg signed [31:0] y
);

    assign in_ready = (~out_valid) || (out_valid && out_ready); // handshake

    // stage 1: p1 = a x b and p2 = c x d
    // stage 2: s = p1 + p2
    // stage 3: y = s + e

    reg signed [31:0] p1;
    reg signed [31:0] p2;
    reg signed [31:0] s;

    always @(posedge clk) begin
         if (rst) begin
            out_valid <= 1'b0;
            y <= 32'sd0;
         end 
         else if (in_ready) begin
            out_valid <= in_valid;
            if (in_valid) begin
                p1 <= a * b;
                p2 <= c * d;
                s <= p1 + p2;
                y <= s + e;
            end
        end
    end

endmodule
