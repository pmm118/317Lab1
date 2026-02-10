// Test Bench
`timescale 1ns / 1ps
 
 module tb_unpipelined;
 
 // setting clock parameter
 parameter CLK_PERIOD = 10; //10ns clock period
 
 //TB signals (regs)
 reg tb_clk; // Inputs to DUT are regs in testbench
 reg tb_rst;

 reg tb_in_valid;
 reg tb_in_ready;

 reg signed [15:0] tb_a;
 reg signed [15:0] tb_b;
 reg signed [15:0] tb_c;
 reg signed [15:0] tb_d;
 reg signed [15:0] tb_e;

 wire tb_out_valid; // Output from DUT is a wire in testbench
 reg tb_out_ready;
 wire signed [31:0] tb_y;
 
 // Instantiating DUT
  unpipelined dut (
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
    
    //Set up clock
    initial begin
        tb_clk = 1'b0; // Initialize clock
        forever #(CLK_PERIOD/2) tb_clk = ~tb_clk; // Toggle every half period
    end
    
    //Set up reset
    intial begin
    //left off here
end

endmodule
 
