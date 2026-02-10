
module pipelined_new (
    input  wire              clk,
    input  wire              rst,

    input  wire              in_valid,
    output wire              in_ready,

    input  wire signed [15:0] a,
    input  wire signed [15:0] b,
    input  wire signed [15:0] c,
    input  wire signed [15:0] d,
    input  wire signed [15:0] e,

    output reg               out_valid,
    input  wire              out_ready,
    output reg signed [31:0]  y
);

    // --------------------------
    // Ready chain 
    // --------------------------
    wire s3_ready_in;
    wire s2_ready_in;
    wire s1_ready_in;

    assign s3_ready_in = (~out_valid) || (out_valid && out_ready);
    assign s2_ready_in = (~s2_valid)  || (s2_valid  && s3_ready_in);
    assign s1_ready_in = (~s1_valid)  || (s1_valid  && s2_ready_in);

    assign in_ready = s1_ready_in;
    wire in_send = in_valid && in_ready;

    // ==========================================
    // STAGE 1: p1 = a*b, p2 = c*d, set e
    // ==========================================
    reg signed [31:0] s1_p1;
    reg signed [31:0] s1_p2;
    reg signed [15:0] s1_e;
    reg               s1_valid;

    always @(posedge clk) begin
        if (rst) begin
            s1_valid <= 1'b0;
            s1_p1    <= 32'sd0;
            s1_p2    <= 32'sd0;
            s1_e     <= 16'sd0;
        end else if (s1_ready_in) begin
            s1_valid <= in_send;
            if (in_send) begin
                s1_p1 <= $signed(a) * $signed(b);
                s1_p2 <= $signed(c) * $signed(d);
                s1_e  <= e;
            end
        end
    end

    // ==========================================
    // STAGE 2: s = p1 + p2, pass e
    // ==========================================
    reg signed [31:0] s2_s;
    reg signed [15:0] s2_e;
    reg               s2_valid;

    always @(posedge clk) begin
        if (rst) begin
            s2_valid <= 1'b0;
            s2_s     <= 32'sd0;
            s2_e     <= 16'sd0;
        end else if (s2_ready_in) begin
            s2_valid <= s1_valid;
            if (s1_valid) begin
                s2_s <= s1_p1 + s1_p2;
                s2_e <= s1_e;
            end
        end
    end

    // ==========================================
    // STAGE 3: y = s + e (output stage)
    // ==========================================
    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            y         <= 32'sd0;
        end else if (s3_ready_in) begin
            out_valid <= s2_valid;
            if (s2_valid) begin
                y <= s2_s + $signed(s2_e);
            end
        end
    end

endmodule