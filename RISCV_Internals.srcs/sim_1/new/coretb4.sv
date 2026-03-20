`timescale 1ns / 1ps

// Replicates FPGA enable pattern: enable is high for exactly 1 clock
// cycle per "frame" (every FRAME_CLOCKS cycles).
module coretb4();

    logic clk;
    logic rst;

    internal_signals dbg_if();

    // Simulate frame-based enable (1 cycle per FRAME_CLOCKS)
    localparam FRAME_CLOCKS = 5;  // much shorter than real 1650*750, but same pattern
    int cycle_count;
    wire enable = (cycle_count == 0);

    core core_inst(
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .dbg(dbg_if)
    );

    always #5 clk = ~clk;

    always_ff @(posedge clk) begin
        if (rst)
            cycle_count <= 0;
        else
            cycle_count <= (cycle_count == FRAME_CLOCKS - 1) ? 0 : cycle_count + 1;
    end

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;

        // Give it enough frames for Collatz(27) = 111 steps + stall overhead
        // Each step needs ~5 enable cycles (instruction + stalls), so ~600 frames
        // At FRAME_CLOCKS=100, that's 60000 cycles
        repeat(100000) @(posedge clk);

        $display("========================================");
        $display("  coretb4: Collatz with intermittent enable");
        $display("  (enable pattern: 1 cycle per %0d)", FRAME_CLOCKS);
        $display("========================================");
        $display("  x1 = %0d (0x%08X)", core_inst.regfile[1], core_inst.regfile[1]);
        $display("  x2 = %0d (0x%08X)", core_inst.regfile[2], core_inst.regfile[2]);
        $display("  x3 = %0d (0x%08X)", core_inst.regfile[3], core_inst.regfile[3]);
        $display("  PC = 0x%08X", core_inst.fetch_stage_pc);
        $display("========================================");

        if (core_inst.regfile[1] === 32'd1)
            $display("[PASS] x1 reached 1");
        else
            $display("[FAIL] x1 = %0d, expected 1", core_inst.regfile[1]);

        if (core_inst.regfile[2] === 32'd111)
            $display("[PASS] x2 = 111 steps");
        else
            $display("[FAIL] x2 = %0d, expected 111 steps", core_inst.regfile[2]);

        $display("========================================");
        $finish;
    end
endmodule
