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

    // Pipeline registers for three stages
    reg signed [31:0] p1_s1; // stage1 outputs
    reg signed [31:0] p2_s1;
    reg signed [31:0] s_s2;  // stage2 output
    reg signed [31:0] e_s1;  // pass-through for e
    reg signed [31:0] e_s2;
    reg signed [31:0] y_s3;  // final result register

    // Valid signals for each pipeline stage
    reg v_s1, v_s2, v_s3;

    // Keep the same simple input-ready policy but rely on v_s3 for out_valid
    assign in_ready = (~out_valid) || (out_valid && out_ready);

    always @(posedge clk) begin
        if (rst) begin
            // clear registers
            p1_s1 <= 32'sd0;
            p2_s1 <= 32'sd0;
            s_s2  <= 32'sd0;
            e_s1  <= 32'sd0;
            e_s2  <= 32'sd0;
            y_s3  <= 32'sd0;
            v_s1  <= 1'b0;
            v_s2  <= 1'b0;
            v_s3  <= 1'b0;
            out_valid <= 1'b0;
            y <= 32'sd0;
        end else begin
            // Stage 1: capture multiplies when input is accepted
            if (in_ready) begin
                v_s1 <= in_valid;
                if (in_valid) begin
                    p1_s1 <= a * b;
                    p2_s1 <= c * d;
                    e_s1  <= e;
                end
            end else begin
                v_s1 <= 1'b0;
            end

            // Stage 2: compute sum of products and pass e forward
            v_s2 <= v_s1;
            s_s2 <= p1_s1 + p2_s1;
            e_s2 <= e_s1;

            // Stage 3: final accumulation
            v_s3 <= v_s2;
            y_s3 <= s_s2 + e_s2;

            // Output registers reflect stage 3
            out_valid <= v_s3;
            y <= y_s3;
        end
    end

    // always @(posedge clk) begin
    //     p1 <= a * b;
    // end

    // always @(posedge clk) begin
    //     p2 <= c * d;
    // end

    // always @(posedge clk) begin
    //     s <= p1 + p2;
    // end

    // always @(posedge clk) begin
    //     y <= s + e;
    // end

endmodule
