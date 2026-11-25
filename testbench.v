module testbench;
    reg clk = 0, reset = 1;
    wire [7:0] out_port;
    cpu uut (.clk(clk), .reset(reset), .out_port(out_port));
    always #5 clk = ~clk;
    always @(posedge clk) if (uut.state && uut.ir[7:4] == 3) $display("Time: %0t | OUT: %0d", $time, uut.acc);
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        #20 reset = 0;
        #940 $finish; // stops after 233, the largest Fibonacci number that fits in 8 bits
    end
endmodule
