
// Test benches for unpipelined and pipelined modules
`timescale 1ns / 1ps

// Basic seeded-random testbench generator parameters
`define NUM_VECTORS 200
`define SEED 12345

module tb_unpipelined;

parameter CLK_PERIOD = 10; // 10ns clock

reg tb_clk;
reg tb_rst;

reg tb_in_valid;
wire tb_in_ready;

reg signed [15:0] tb_a;
reg signed [15:0] tb_b;
reg signed [15:0] tb_c;
reg signed [15:0] tb_d;
reg signed [15:0] tb_e;

wire tb_out_valid;
reg tb_out_ready;
wire signed [31:0] tb_y;

// hold correct math result
reg signed [31:0] expected_y;
integer errors = 0;

// Instantiate DUT
unpipelined dut_unp (
    .clk(tb_clk),
    .rst(tb_rst),
    .in_valid(tb_in_valid),
    .in_ready(tb_in_ready),
    .a(tb_a),
    .b(tb_b),
    .c(tb_c),
    .d(tb_d),
    .e(tb_e),
    .out_valid(tb_out_valid),
    .out_ready(tb_out_ready),
    .y(tb_y)
);

// Clock
initial begin
    tb_clk = 0;
    forever #(CLK_PERIOD/2) tb_clk = ~tb_clk;
end

// Reset
initial begin
    tb_rst = 1'b1;
    #(CLK_PERIOD*2);
    tb_rst = 1'b0;
end

// Stimulus: generate `NUM_VECTORS` random vectors with seed using $random(seed)
integer i;
integer seed;
initial begin
    seed = `SEED;
    tb_out_ready = 1'b1; // always ready to accept output
    tb_in_valid = 1'b0;
    tb_a = 0; tb_b = 0; tb_c = 0; tb_d = 0; tb_e = 0;

    // wait for reset deassert
    @(negedge tb_rst);

    for (i = 0; i < `NUM_VECTORS; i = i + 1) begin
        // wait until DUT is ready to accept inputs
        @(posedge tb_clk);
        while (!tb_in_ready) @(posedge tb_clk);

        // drive inputs and assert valid for one cycle
        tb_a = $random(seed);
        tb_b = $random(seed);
        tb_c = $random(seed);
        tb_d = $random(seed);
        tb_e = $random(seed);

        // calculate expected
        expected_y = (tb_a * tb_b) + (tb_c * tb_d) + tb_e;

        // drive inputs
        tb_in_valid = 1'b1;
        @(posedge tb_clk);
        tb_in_valid = 1'b0;

        // wait for output valid
        while (!tb_out_valid) @(posedge tb_clk);
        // 3. COMPARE ACTUAL vs EXPECTED
            if (tb_y !== expected_y) begin
                $display("ERROR Test %0d: Inputs: %0d,%0d,%0d,%0d,%0d", i, tb_a, tb_b, tb_c, tb_d, tb_e);
                $display("      Expected: %0d | Got: %0d", expected_y, tb_y);
                errors = errors + 1;
            end else begin
                $display("PASS Test %0d: %0d == %0d", i, tb_y, expected_y);
            end
        @(posedge tb_clk);
    end

        if (errors == 0)
            $display("UNPIPELINED TEST PASSED: All %0d vectors match.", `NUM_VECTORS);
        else
            $display("UNPIPELINED TEST FAILED: %0d errors found.", errors);

        $finish;
end

endmodule

module tb_pipelined;

    parameter CLK_PERIOD = 10;

    reg tb_clk;
    reg tb_rst;
    reg tb_in_valid;
    wire tb_in_ready;
    reg signed [15:0] tb_a, tb_b, tb_c, tb_d, tb_e;
    wire tb_out_valid;
    reg tb_out_ready;
    wire signed [31:0] tb_y;

    // --- NEW: Variables for Self-Checking ---
    reg signed [31:0] expected_y;
    integer errors = 0;
    // ----------------------------------------

    // Instantiate DUT
    pipelined dut_pipe (
        .clk(tb_clk), .rst(tb_rst),
        .in_valid(tb_in_valid), .in_ready(tb_in_ready),
        .a(tb_a), .b(tb_b), .c(tb_c), .d(tb_d), .e(tb_e),
        .out_valid(tb_out_valid), .out_ready(tb_out_ready), .y(tb_y)
    );

    // Clock
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD/2) tb_clk = ~tb_clk;
    end

    // Reset
    initial begin
        tb_rst = 1'b1;
        #(CLK_PERIOD*2);
        tb_rst = 1'b0;
    end

    integer j;
    integer seed2;

    initial begin
        seed2 = `SEED;
        tb_out_ready = 1'b1;
        tb_in_valid = 1'b0;
        tb_a = 0; tb_b = 0; tb_c = 0; tb_d = 0; tb_e = 0;

        // Wait for reset
        @(negedge tb_rst);

        for (j = 0; j < `NUM_VECTORS; j = j + 1) begin
            // 1. Wait for Ready
            @(posedge tb_clk);
            while (!tb_in_ready) @(posedge tb_clk);

            // 2. Generate Inputs
            tb_a = $random(seed2);
            tb_b = $random(seed2);
            tb_c = $random(seed2);
            tb_d = $random(seed2);
            tb_e = $random(seed2);

            // --- NEW: Calculate Expected Result Immediately ---
            // We do the math here in the testbench to verify the DUT later
            expected_y = (tb_a * tb_b) + (tb_c * tb_d) + tb_e;
            // ------------------------------------------------

            // 3. Drive Inputs
            tb_in_valid = 1'b1;
            @(posedge tb_clk);
            tb_in_valid = 1'b0;

            // 4. Wait for Output
            while (!tb_out_valid) @(posedge tb_clk);

            // --- NEW: Compare Actual vs Expected ---
            if (tb_y !== expected_y) begin
                $display("ERROR Test %0d: Inputs: a=%0d b=%0d c=%0d d=%0d e=%0d", j, tb_a, tb_b, tb_c, tb_d, tb_e);
                $display("      Expected: %0d | Got: %0d", expected_y, tb_y);
                errors = errors + 1;
            end else begin
                // Optional: Print pass message (can be spammy for 200 tests)
                // $display("PASS Test %0d: %0d == %0d", j, tb_y, expected_y);
            end
            // ---------------------------------------

            @(posedge tb_clk);
        end

        // --- NEW: Final Report ---
        if (errors == 0)
            $display("SUCCESS: All %0d pipelined tests passed!", `NUM_VECTORS);
        else
            $display("FAILURE: %0d mismatches found.", errors);

        $finish;
    end

endmodule

//  y <= (a * b) + (c * d) + e;
module MathEquation (
    input  wire a, b, c, d, e
    output wire out
);
    // Golden approach: Use continuous assignment (assign)
    // synthesizes directly to gates (AND, XOR, OR)
    assign out = (a & b) | (c ^ d) | e; 
endmodule

