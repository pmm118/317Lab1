
`timescale 1ns / 1ps
`define NUM_VECTORS 200
`define SEED 12345

module tb_pipelined;

    parameter CLK_PERIOD = 10;

    reg tb_clk;
    reg tb_rst;
    reg tb_in_valid;
    wire tb_in_ready;
    reg signed [15:0] tb_a, tb_b, tb_c, tb_d, tb_e;
    wire tb_out_valid;
    reg tb_out_ready;

    // --- NEW: Variables for Self-Checking --
    integer errors = 0;
    reg signed [31:0] expected_q [0:`NUM_VECTORS-1];
    integer in_idx = 0;
    integer out_idx = 0;
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
    
    
    //Comparing out vs. actual
       always@( posedge tb_clk) begin
            if(!tb_rst && tb_out_valid && tb_out_ready) begin
            
                if(tb_y !== expected_q[out_idx]) begin
                $display("ERROR Output %0d: Expected %0d, Got %0d", 
                        out_idx, expected_q[out_idx], tb_y);
                errors = errors +1;
            end
            out_idx = out_idx + 1;
            end
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

            // --- Calculate Expected Result Immediately ---
            // We do the math here in the testbench to verify the DUT later
            expected_q[in_idx] = ($signed(tb_a) * $signed(tb_b))  + ($signed(tb_c) * $signed(tb_d)) + $signed(tb_e);
            in_idx = in_idx +1;
            
            // ------------------------------------------------

            // 3. Drive Inputs
            tb_in_valid = 1'b1;
            @(posedge tb_clk);
            tb_in_valid = 1'b0;
        end
        
        while(out_idx < `NUM_VECTORS) @(posedge tb_clk);

        // --- Final Report ---
        if (errors == 0)
            $display("SUCCESS: All %0d pipelined tests passed!", `NUM_VECTORS);
        else
            $display("FAILURE: %0d mismatches found.", errors);

        $finish;
    end

endmodule

