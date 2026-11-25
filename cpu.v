module cpu(input clk, reset, output reg [7:0] out_port);
    reg [7:0] pc, acc, ir, ram [0:255];
    reg state;
    initial $readmemh("program.mem", ram);
    always @(posedge clk or posedge reset)
        if (reset) {pc, acc, out_port, state} <= 0;
        else begin
            state <= ~state;
            if (!state) begin ir <= ram[pc]; pc <= pc + 1; end // FETCH
            else case (ir[7:4])                                 // EXECUTE
                1: acc <= ram[ir[3:0]];        // LOAD
                2: acc <= acc + ram[ir[3:0]];  // ADD
                3: out_port <= acc;            // OUT
                4: pc <= pc - 1;               // HALT
                5: ram[ir[3:0]] <= acc;        // STORE
                6: pc <= ir[3:0];              // JMP
            endcase
        end
endmodule
