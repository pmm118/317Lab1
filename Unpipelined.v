module unpipelined (
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


    always @(posedge clk) begin
         if (rst) begin // if rst is 1, valid outputs 0 and wipes y
            out_valid <= 1'b0;
            y <= 32'sd0; // same as {32{1'b0}}
         end else if (in_ready) begin
            out_valid <= in_valid;
            if (in_valid) begin
                y <= (a * b) + (c * d) + e;
            end
        end
    end
    
 endmodule

