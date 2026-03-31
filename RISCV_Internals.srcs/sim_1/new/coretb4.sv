`timescale 1ns / 1ps

// Minimal testbench: exercises soft_mul / soft_div / soft_mod only.
// Loads test_math.mem, waits for the sentinel word (results[15] == 0xDEAD),
// then checks the 8 expected results written into the results[] array.
//
// results[] base: byte 0x3FC  ->  word index 0xFF (255)
// results[n]    : word index 255 + n
// sentinel      : results[15] = word index 270

module coretb4();

    logic clk;
    logic rst;

    internal_signals dbg_if();

    // Tie off OAM/palette ports (not needed for this test)
    wire [31:0] oam_data_nc;
    wire [35:0] pal_data_nc;

    localparam FRAME_CLOCKS = 5;
    int cycle_count;
    wire enable = (cycle_count == 0);

    core core_inst(
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .dbg(dbg_if),
        .oam_addr(32'b0),
        .palette_addr(32'b0),
        .oam_data(oam_data_nc),
        .palette_data(pal_data_nc)
    );

    always #5 clk = ~clk;

    always_ff @(posedge clk) begin
        if (rst)
            cycle_count <= 0;
        else
            cycle_count <= (cycle_count == FRAME_CLOCKS - 1) ? 0 : cycle_count + 1;
    end

    // -----------------------------------------------------------------------
    // Expected results (must match test_math.c)
    // -----------------------------------------------------------------------
    // -----------------------------------------------------------------------
    // Expected results (must match test_math.c)
    // -----------------------------------------------------------------------
    localparam int EXPECTED [0:13] = '{
        42,       // 0: soft_mul(6, 7)
        -45,      // 1: soft_mul(-5, 9)
        25,       // 2: soft_div(100, 4)
        -33,      // 3: soft_div(-99, 3)
        2,        // 4: soft_mod(17, 5)
        2,        // 5: soft_mod(100, 7)
        3329050,  // 6: soft_mul(1664525, 2)
        9,        // 7: soft_div(99, 10)
        3,        // 8: arr[0]
        206,      // 9: arr[29]
        7,        // 10: arr[14] - arr[13]
        100,      // 11: sum (100)
        100,      // 12: load-use (100)
        999       // 13: cell (999)
    };

    localparam RESULTS_WORD_BASE = 301; // 0x4B4 >> 2
    localparam SENTINEL_WORD     = 332; // 301 + 31
    localparam SENTINEL_VAL      = 32'h0000DEAD;

    // -----------------------------------------------------------------------
    // Declare all variables at top for SV tool compatibility
    int pass, fail, got, expected;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        pass = 0; fail = 0;

        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;

        // Poll for sentinel (results[31] == 0xDEAD), timeout after 5M cycles.
        begin
            int timeout_cnt;
            timeout_cnt = 0;
            while (core_inst.mem_inst.ram[SENTINEL_WORD] !== SENTINEL_VAL) begin
                @(posedge clk);
                timeout_cnt = timeout_cnt + 1;
                if (timeout_cnt >= 5_000_000) begin
                    $display("[TIMEOUT] Sentinel never appeared after %0d cycles. PC=0x%08X",
                             timeout_cnt, core_inst.fetch_stage_pc);
                    $finish;
                end
            end
        end

        // --- Report ---
        $display("========================================");
        $display("  coretb4: Detailed Math & Memory Test");
        $display("========================================");

        for (int i = 0; i < 14; i++) begin
            got      = $signed(core_inst.mem_inst.ram[RESULTS_WORD_BASE + i]);
            expected = EXPECTED[i];
            if (got === expected) begin
                $display("  [PASS] results[%2d] = %6d", i, got);
                pass++;
            end else begin
                $display("  [FAIL] results[%2d] = %6d, expected %6d", i, got, expected);
                fail++;
            end
        end

        $display("----------------------------------------");
        $display("  %0d passed, %0d failed", pass, fail);
        $display("========================================");
        $finish;
    end
endmodule
