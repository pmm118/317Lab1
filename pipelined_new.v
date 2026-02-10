module pipelined_new (
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

    // ==========================================
    // STAGE 1: Multiplication (p1, p2)
    // ==========================================
    reg signed [31:0] s1_p1;
    reg signed [31:0] s1_p2;
    reg signed [15:0] s1_e; // 'e' delayed by 1 cycle
    reg s1_valid;

    // Stage 1 is ready if it's empty OR if Stage 2 is ready to take data
    wire s1_ready_in = (~s1_valid) || (s1_valid && s2_ready_in);
    assign in_ready = s1_ready_in;

    always @(posedge clk) begin
        if (rst) begin
            s1_valid <= 1'b0;
            s1_p1    <= 32'sd0;
            s1_p2    <= 32'sd0;
            s1_e     <= 16'sd0;
        end else if (s1_ready_in) begin
            s1_valid <= in_valid;
            if (in_valid) begin
                s1_p1 <= a * b;
                s1_p2 <= c * d;
                s1_e  <= e; // Capture e
            end
        end
    end

    // ==========================================
    // STAGE 2: Intermediate Sum (s = p1 + p2)
    // ==========================================
    reg signed [31:0] s2_s;
    reg signed [15:0] s2_e; // 'e' delayed by 2 cycles
    reg s2_valid;

    // Stage 2 is ready if it's empty OR if Stage 3 (output) is ready
    wire s2_ready_in = (~s2_valid) || (s2_valid && s3_ready_in);

    always @(posedge clk) begin
        if (rst) begin
            s2_valid <= 1'b0;
            s2_s     <= 32'sd0;
            s2_e     <= 16'sd0;
        end else if (s2_ready_in) begin
            s2_valid <= s1_valid;
            if (s1_valid) begin
                s2_s <= s1_p1 + s1_p2;
                s2_e <= s1_e; // Pass e along again!
            end
        end
    end

    // ==========================================
    // STAGE 3: Final Addition (y = s + e)
    // ==========================================
    // This stage writes directly to the module outputs (out_valid, y)
    
    // Stage 3 (Output) is ready if it's empty OR if the consumer is ready
    wire s3_ready_in = (~out_valid) || (out_valid && out_ready);

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            y         <= 32'sd0;
        end else if (s3_ready_in) begin
            out_valid <= s2_valid;
            if (s2_valid) begin
                y <= s2_s + s2_e; // Finally use e
            end
        end
    end

endmodule