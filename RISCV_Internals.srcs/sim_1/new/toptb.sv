`timescale 1ns / 1ps
module toptb;

    reg clk    = 0;
    reg rst    = 1;
    reg enable = 0;

    always #5 clk = ~clk;  // 100 MHz

    wire [31:0] oam_data;
    wire [35:0] palette_data;

    internal_signals dbg();

    core dut (
        .clk         (clk),
        .rst         (rst),
        .enable      (enable),
        .oam_addr    (32'b0),
        .palette_addr(32'b0),
        .oam_data    (oam_data),
        .palette_data(palette_data),
        .dbg         (dbg)
    );

    // ------------------------------------------------------------------
    // Periodic PC dump to diagnose stalls / infinite loops
    // ------------------------------------------------------------------
    integer cycle = 0;
    always @(posedge clk) if (enable && !rst) begin
        cycle = cycle + 1;
        if (cycle % 500_000 == 0)
            $display("[cycle %0d] PC=0x%08x  ra=0x%08x  sp=0x%08x",
                     cycle,
                     dbg.fetch_stage_pc,
                     dbg.regfile[1],
                     dbg.regfile[2]);
    end

    // ------------------------------------------------------------------
    // OAM write monitor
    // ------------------------------------------------------------------
    integer frame_count = 0;
    localparam MAX_FRAMES = 10;

    always @(posedge clk) begin
        if (enable && !rst && dbg.ex_mem_write) begin
            if (dbg.ex_mem_wb_val >= 32'h200 &&
                dbg.ex_mem_wb_val <= 32'h3FF) begin
                automatic integer idx = (dbg.ex_mem_wb_val - 32'h200) >> 2;
                automatic integer px  = dbg.ex_mem_mem_data[9:0];
                automatic integer py  = dbg.ex_mem_mem_data[18:10];
                $display("  OAM[%02d] x=%3d y=%3d  raw=0x%08x",
                         idx, px, py, dbg.ex_mem_mem_data);
                if (idx == 17) begin
                    frame_count = frame_count + 1;
                    $display("=== Frame %0d done ===\n", frame_count);
                    if (frame_count >= MAX_FRAMES) begin
                        $display("Done."); $finish;
                    end
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // Init: load IMEM, pre-seed DMEM so soft_mul doesn't get X operands
    //   seed is at linker VA 0x14D4 -> DMEM[0x14D4[11:2]] = DMEM[0x535]
    //   0x535 > 1023 wraps: 0x535 & 0x3FF = 0x135 = 309
    //   On real hardware BRAM powers up 0 which also works fine.
    // ------------------------------------------------------------------
    initial begin
        $readmemh("/home/zeb/Desktop/RISCV_Internals/prog.mem",
                  dut.mem_inst.ram);

        $display("Boids OAM testbench starting...\n");
        rst    = 1;
        enable = 0;
        repeat(8) @(posedge clk);
        @(negedge clk);
        rst    = 0;
        enable = 1;

        repeat(100_000_000) @(posedge clk);
        $display("Timeout."); $finish;
    end

endmodule
