`timescale 1ns / 1ps

module coretb3();

    logic clk;
    logic rst;

    internal_signals dbg_if();

    core core_inst(
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .dbg(dbg_if)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;

        // prog.mem is loaded via $readmemh in if.sv — no manual overrides.

        rst = 1'b1;
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;

        repeat(2500) @(posedge clk);

        $display("========================================");
        $display("  coretb3: Collatz from prog.mem");
        $display("========================================");
        $display("  x1 = %0d (0x%08X)", core_inst.regfile[1], core_inst.regfile[1]);
        $display("  x2 = %0d (0x%08X)", core_inst.regfile[2], core_inst.regfile[2]);
        $display("  x3 = %0d (0x%08X)", core_inst.regfile[3], core_inst.regfile[3]);
        $display("  x4 = %0d (0x%08X)", core_inst.regfile[4], core_inst.regfile[4]);
        $display("  x5 = %0d (0x%08X)", core_inst.regfile[5], core_inst.regfile[5]);
        $display("  PC = 0x%08X", core_inst.fetch_stage_pc);
        $display("========================================");

        // Collatz(27) should reach 1 in 111 steps
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
