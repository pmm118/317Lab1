
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
        tb_in_valid = 1'b1;
        @(posedge tb_clk);
        tb_in_valid = 1'b0;

        // wait for output valid and capture
        while (!tb_out_valid) @(posedge tb_clk);
        $display("UNPIPE Test %0d: a=%0d b=%0d c=%0d d=%0d e=%0d -> y=%0d", i, tb_a, tb_b, tb_c, tb_d, tb_e, tb_y);
        @(posedge tb_clk);
    end

    $display("UNPIPELINE TEST COMPLETE");
    $finish;
end

endmodule

module tb_pipelined;

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

// Instantiate DUT
pipelined dut_pipe (
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
integer j;
integer seed2;
initial begin
    seed2 = `SEED;
    tb_out_ready = 1'b1; // always ready to accept output
    tb_in_valid = 1'b0;
    tb_a = 0; tb_b = 0; tb_c = 0; tb_d = 0; tb_e = 0;

    // wait for reset deassert
    @(negedge tb_rst);

    for (j = 0; j < `NUM_VECTORS; j = j + 1) begin
        // wait until DUT is ready to accept inputs
        @(posedge tb_clk);
        while (!tb_in_ready) @(posedge tb_clk);

        // drive inputs and assert valid for one cycle
        tb_a = $random(seed2);
        tb_b = $random(seed2);
        tb_c = $random(seed2);
        tb_d = $random(seed2);
        tb_e = $random(seed2);
        tb_in_valid = 1'b1;
        @(posedge tb_clk);
        tb_in_valid = 1'b0;

        // wait for output valid and capture
        while (!tb_out_valid) @(posedge tb_clk);
        $display("PIPE Test %0d: a=%0d b=%0d c=%0d d=%0d e=%0d -> y=%0d", j, tb_a, tb_b, tb_c, tb_d, tb_e, tb_y);
        @(posedge tb_clk);
    end

    $display("PIPELINED TEST COMPLETE");
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

