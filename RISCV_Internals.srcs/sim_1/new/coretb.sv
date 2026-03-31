`timescale 1ns / 1ps

module coretb();

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

    // ---------------------------------------------------------------
    // Instruction builder functions (RV32I encoding)
    // ---------------------------------------------------------------

    function automatic [31:0] r_type(
        input [4:0] rd, input [4:0] rs1, input [4:0] rs2,
        input [2:0] funct3, input [6:0] funct7
    );
        return {funct7, rs2, rs1, funct3, rd, 7'b0110011};
    endfunction

    function automatic [31:0] i_type(
        input [4:0] rd, input [4:0] rs1,
        input [2:0] funct3, input [11:0] imm
    );
        return {imm, rs1, funct3, rd, 7'b0010011};
    endfunction

    function automatic [31:0] load_word(
        input [4:0] rd, input [4:0] rs1, input [11:0] imm
    );
        return {imm, rs1, 3'b010, rd, 7'b0000011};
    endfunction

    function automatic [31:0] store_word(
        input [4:0] rs1, input [4:0] rs2, input [11:0] imm
    );
        return {imm[11:5], rs2, rs1, 3'b010, imm[4:0], 7'b0100011};
    endfunction

    function automatic [31:0] branch(
        input [4:0] rs1, input [4:0] rs2,
        input [2:0] funct3, input [12:0] imm
    );
        return {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], 7'b1100011};
    endfunction

    function automatic [31:0] lui(input [4:0] rd, input [19:0] imm);
        return {imm, rd, 7'b0110111};
    endfunction

    function automatic [31:0] auipc(input [4:0] rd, input [19:0] imm);
        return {imm, rd, 7'b0010111};
    endfunction

    function automatic [31:0] jal(input [4:0] rd, input [20:0] imm);
        return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'b1101111};
    endfunction

    function automatic [31:0] jalr(
        input [4:0] rd, input [4:0] rs1, input [11:0] imm
    );
        return {imm, rs1, 3'b000, rd, 7'b1100111};
    endfunction

    // Convenience aliases for common ALU instructions
    function automatic [31:0] i_add(input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return i_type(rd, rs1, 3'b000, imm);
    endfunction

    function automatic [31:0] i_ori(input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return i_type(rd, rs1, 3'b110, imm);
    endfunction

    function automatic [31:0] i_andi(input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return i_type(rd, rs1, 3'b111, imm);
    endfunction

    function automatic [31:0] i_xori(input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return i_type(rd, rs1, 3'b100, imm);
    endfunction

    function automatic [31:0] i_slti(input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return i_type(rd, rs1, 3'b010, imm);
    endfunction

    function automatic [31:0] i_sltiu(input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return i_type(rd, rs1, 3'b011, imm);
    endfunction

    function automatic [31:0] i_slli(input [4:0] rd, input [4:0] rs1, input [4:0] shamt);
        return i_type(rd, rs1, 3'b001, {7'b0000000, shamt});
    endfunction

    function automatic [31:0] i_srli(input [4:0] rd, input [4:0] rs1, input [4:0] shamt);
        return i_type(rd, rs1, 3'b101, {7'b0000000, shamt});
    endfunction

    function automatic [31:0] i_srai(input [4:0] rd, input [4:0] rs1, input [4:0] shamt);
        return i_type(rd, rs1, 3'b101, {7'b0100000, shamt});
    endfunction

    function automatic [31:0] r_add(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return r_type(rd, rs1, rs2, 3'b000, 7'b0000000);
    endfunction

    function automatic [31:0] r_sub(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return r_type(rd, rs1, rs2, 3'b000, 7'b0100000);
    endfunction

    function automatic [31:0] r_sll(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return r_type(rd, rs1, rs2, 3'b001, 7'b0000000);
    endfunction

    function automatic [31:0] r_slt(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return r_type(rd, rs1, rs2, 3'b010, 7'b0000000);
    endfunction

    function automatic [31:0] r_sltu(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return r_type(rd, rs1, rs2, 3'b011, 7'b0000000);
    endfunction

    function automatic [31:0] r_xor(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return r_type(rd, rs1, rs2, 3'b100, 7'b0000000);
    endfunction

    function automatic [31:0] r_srl(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return r_type(rd, rs1, rs2, 3'b101, 7'b0000000);
    endfunction

    function automatic [31:0] r_sra(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return r_type(rd, rs1, rs2, 3'b101, 7'b0100000);
    endfunction

    function automatic [31:0] r_or(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return r_type(rd, rs1, rs2, 3'b110, 7'b0000000);
    endfunction

    function automatic [31:0] r_and(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return r_type(rd, rs1, rs2, 3'b111, 7'b0000000);
    endfunction

    function automatic [31:0] nop();
        return i_add(5'd0, 5'd0, 12'd0);
    endfunction

    // ---------------------------------------------------------------
    // Test infrastructure
    // ---------------------------------------------------------------

    int test_num     = 0;
    int pass_count   = 0;
    int fail_count   = 0;

    // Load a single instruction at imem[0] and reset the core.
    // After reset, run for `cycles` clock cycles.
    task automatic run_single(
        input [31:0] instr,
        input int    cycles
    );
        // Load instruction into fetch-stage instruction memory
        core_inst.mem_inst.ram[0] = instr;
        // Assert reset for two cycles
        rst = 1'b1;
        @(posedge clk); @(posedge clk);
        rst = 1'b0;
        repeat(cycles) @(posedge clk);
    endtask

    // Load a sequence of instructions starting at imem[0] and reset.
    // Because fetch_stage_pc is never incremented, only imem[0] will
    // actually execute — but we load others for documentation/future use.
    task automatic run_sequence(
        input [31:0] instrs[],
        input int    cycles
    );
        int i;
        for (i = 0; i < instrs.size(); i++)
            core_inst.mem_inst.ram[i] = instrs[i];
        rst = 1'b1;
        @(posedge clk); @(posedge clk);
        rst = 1'b0;
        repeat(cycles) @(posedge clk);
    endtask

    // Pre-set a regfile entry (for tests that need source register values).
    // Directly forces the regfile array.  Must be called AFTER reset deasserts.
    task automatic seed_reg(input [4:0] addr, input [31:0] val);
        core_inst.regfile[addr] = val;
    endtask

    // Run a single instruction with pre-seeded register values, then check rd.
    task automatic run_test(
        input string  name,
        input [31:0]  instr,
        input [4:0]   seeds_addr[], // registers to pre-seed
        input [31:0]  seeds_val[],  // values to pre-seed
        input [4:0]   check_rd,     // register to check
        input [31:0]  expected      // expected value
    );
        int i;
        logic [31:0] actual;
        test_num++;

        // Load instruction and reset
        core_inst.mem_inst.ram[0] = instr;
        rst = 1'b1;
        @(posedge clk); @(posedge clk);
        rst = 1'b0;

        // Seed registers on the first cycle after reset
        for (i = 0; i < seeds_addr.size(); i++)
            seed_reg(seeds_addr[i], seeds_val[i]);

        // Wait enough cycles for the instruction to retire through the pipeline.
        // Pipeline stages: Fetch -> Decode -> Execute -> Memory -> WB
        // The instruction at mem[0] is fetched on the first cycle after reset,
        // decoded next cycle, executed next, memory next, WB next = 5 cycles.
        // But because the same instruction re-executes every cycle, we give it
        // enough time and just check the final regfile state.
        repeat(5) @(posedge clk);

        actual = core_inst.regfile[check_rd];
        if (actual === expected) begin
            $display("  [PASS] Test %0d: %s  (x%0d = 0x%08h)", test_num, name, check_rd, actual);
            pass_count++;
        end else begin
            $display("  [FAIL] Test %0d: %s  (x%0d = 0x%08h, expected 0x%08h)",
                     test_num, name, check_rd, actual, expected);
            fail_count++;
        end
    endtask

    // ---------------------------------------------------------------
    // Stall-detection helper: checks whether the stall signal asserts
    // ---------------------------------------------------------------
    task automatic run_stall_test(
        input string  name,
        input [31:0]  instr,
        input [4:0]   seeds_addr[],
        input [31:0]  seeds_val[],
        input logic    expect_stall
    );
        logic stall_seen;
        int i;
        test_num++;

        core_inst.mem_inst.ram[0] = instr;
        rst = 1'b1;
        @(posedge clk); @(posedge clk);
        rst = 1'b0;

        for (i = 0; i < seeds_addr.size(); i++)
            seed_reg(seeds_addr[i], seeds_val[i]);

        stall_seen = 1'b0;
        repeat(8) begin
            @(posedge clk);
            if (core_inst.stall) stall_seen = 1'b1;
        end

        if (stall_seen === expect_stall) begin
            $display("  [PASS] Test %0d: %s  (stall_seen=%0b)", test_num, name, stall_seen);
            pass_count++;
        end else begin
            $display("  [FAIL] Test %0d: %s  (stall_seen=%0b, expected=%0b)",
                     test_num, name, stall_seen, expect_stall);
            fail_count++;
        end
    endtask

    // ---------------------------------------------------------------
    // Main test sequence
    // ---------------------------------------------------------------
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        @(posedge clk);

        $display("");
        $display("========================================");
        $display("  RISC-V Core Testbench");
        $display("========================================");

        // ===========================================================
        // I-TYPE ALU INSTRUCTIONS
        // ===========================================================
        $display("");
        $display("--- I-Type ALU ---");

        // ADDI x1, x0, 42 → x1 = 42
        run_test("ADDI x1, x0, 42",
            i_add(5'd1, 5'd0, 12'd42),
            '{}, '{},
            5'd1, 32'd42);

        // ADDI x2, x0, -1 → x2 = 0xFFFFFFFF
        run_test("ADDI x2, x0, -1",
            i_add(5'd2, 5'd0, 12'hFFF),
            '{}, '{},
            5'd2, 32'hFFFFFFFF);

        // ORI x3, x5, 0xF0  (x5 pre-seeded to 0x0F)
        run_test("ORI x3, x5, 0xF0",
            i_ori(5'd3, 5'd5, 12'hF0),
            '{5'd5}, '{32'h0F},
            5'd3, 32'hFF);

        // ANDI x4, x5, 0xFF  (x5 pre-seeded to 0x12345678)
        run_test("ANDI x4, x5, 0xFF",
            i_andi(5'd4, 5'd5, 12'hFF),
            '{5'd5}, '{32'h12345678},
            5'd4, 32'h78);

        // XORI x6, x5, 0xFF  (x5 = 0xAA)
        run_test("XORI x6, x5, 0xFF",
            i_xori(5'd6, 5'd5, 12'hFF),
            '{5'd5}, '{32'hAA},
            5'd6, 32'h55);

        // SLTI x7, x5, 10  (x5 = 5, signed: 5 < 10 → 1)
        run_test("SLTI x7, x5, 10 (5<10)",
            i_slti(5'd7, 5'd5, 12'd10),
            '{5'd5}, '{32'd5},
            5'd7, 32'd1);

        // SLTI x7, x5, 3  (x5 = 5, signed: 5 < 3 → 0)
        run_test("SLTI x7, x5, 3 (5<3)",
            i_slti(5'd7, 5'd5, 12'd3),
            '{5'd5}, '{32'd5},
            5'd7, 32'd0);

        // SLTIU x8, x5, 10  (x5 = 5, unsigned: 5 < 10 → 1)
        run_test("SLTIU x8, x5, 10 (5<10)",
            i_sltiu(5'd8, 5'd5, 12'd10),
            '{5'd5}, '{32'd5},
            5'd8, 32'd1);

        // SLLI x9, x5, 4  (x5 = 1 → 16)
        run_test("SLLI x9, x5, 4 (1<<4)",
            i_slli(5'd9, 5'd5, 5'd4),
            '{5'd5}, '{32'd1},
            5'd9, 32'd16);

        // SRLI x10, x5, 4  (x5 = 0x80 → 0x08)
        run_test("SRLI x10, x5, 4 (0x80>>4)",
            i_srli(5'd10, 5'd5, 5'd4),
            '{5'd5}, '{32'h80},
            5'd10, 32'h08);

        // SRAI x11, x5, 4  (x5 = 0xFFFFFFF0 → 0xFFFFFFFF)
        run_test("SRAI x11, x5, 4 (arith >>4)",
            i_srai(5'd11, 5'd5, 5'd4),
            '{5'd5}, '{32'hFFFFFFF0},
            5'd11, 32'hFFFFFFFF);

        // ADDI to x0 must not change x0 (hardwired zero)
        run_test("ADDI x0, x0, 99 (x0 stays 0)",
            i_add(5'd0, 5'd0, 12'd99),
            '{}, '{},
            5'd0, 32'd0);

        // ===========================================================
        // R-TYPE ALU INSTRUCTIONS
        // ===========================================================
        $display("");
        $display("--- R-Type ALU ---");

        // ADD x3, x1, x2 (x1=10, x2=20 → 30)
        run_test("ADD x3, x1, x2 (10+20)",
            r_add(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'd10, 32'd20},
            5'd3, 32'd30);

        // SUB x3, x1, x2 (x1=20, x2=7 → 13)
        run_test("SUB x3, x1, x2 (20-7)",
            r_sub(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'd20, 32'd7},
            5'd3, 32'd13);

        // SLL x3, x1, x2 (x1=1, x2=5 → 32)
        run_test("SLL x3, x1, x2 (1<<5)",
            r_sll(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'd1, 32'd5},
            5'd3, 32'd32);

        // SLT x3, x1, x2 (x1=-1(signed), x2=1 → 1)
        run_test("SLT x3, x1, x2 (-1<1)",
            r_slt(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'hFFFFFFFF, 32'd1},
            5'd3, 32'd1);

        // SLTU x3, x1, x2 (x1=1, x2=0xFFFFFFFF → 1)
        run_test("SLTU x3, x1, x2 (1<0xFFFFFFFF)",
            r_sltu(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'd1, 32'hFFFFFFFF},
            5'd3, 32'd1);

        // XOR x3, x1, x2 (x1=0xFF00, x2=0x0FF0 → 0xF0F0)
        run_test("XOR x3, x1, x2",
            r_xor(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'hFF00, 32'h0FF0},
            5'd3, 32'hF0F0);

        // SRL x3, x1, x2 (x1=0x80000000, x2=4 → 0x08000000)
        run_test("SRL x3, x1, x2 (logical >>4)",
            r_srl(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'h80000000, 32'd4},
            5'd3, 32'h08000000);

        // SRA x3, x1, x2 (x1=0x80000000, x2=4 → 0xF8000000)
        run_test("SRA x3, x1, x2 (arith >>4)",
            r_sra(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'h80000000, 32'd4},
            5'd3, 32'hF8000000);

        // OR x3, x1, x2 (x1=0xF0, x2=0x0F → 0xFF)
        run_test("OR x3, x1, x2",
            r_or(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'hF0, 32'h0F},
            5'd3, 32'hFF);

        // AND x3, x1, x2 (x1=0xFF, x2=0x0F → 0x0F)
        run_test("AND x3, x1, x2",
            r_and(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'hFF, 32'h0F},
            5'd3, 32'h0F);

        // ===========================================================
        // U-TYPE INSTRUCTIONS
        // ===========================================================
        $display("");
        $display("--- U-Type ---");

        // LUI x1, 0xDEADB → x1 = 0xDEADB000
        run_test("LUI x1, 0xDEADB",
            lui(5'd1, 20'hDEADB),
            '{}, '{},
            5'd1, 32'hDEADB000);

        // AUIPC x1, 0x00001 → x1 = PC + 0x1000
        // PC is 0 in this core, so x1 = 0x1000
        run_test("AUIPC x1, 0x00001 (PC=0)",
            auipc(5'd1, 20'h00001),
            '{}, '{},
            5'd1, 32'h00001000);

        // ===========================================================
        // LOAD / STORE
        // ===========================================================
        $display("");
        $display("--- Load/Store ---");

        // LW x1, 0(x0): Pre-load data memory at address 0 with 0xCAFEBABE
        begin
            test_num++;
            core_inst.mem_inst.ram[0] = load_word(5'd1, 5'd0, 12'd1);
            core_inst.mem_inst.ram[1] = 32'hCAFEBABE;
            rst = 1'b1;
            @(posedge clk); @(posedge clk);
            rst = 1'b0;
            repeat(10) @(posedge clk);
            if (core_inst.regfile[1] === 32'hCAFEBABE) begin
                $display("  [PASS] Test %0d: LW x1, 0(x0) = 0xCAFEBABE", test_num);
                pass_count++;
            end else begin
                $display("  [FAIL] Test %0d: LW x1, 0(x0) = 0x%08h, expected 0xCAFEBABE",
                         test_num, core_inst.regfile[1]);
                fail_count++;
            end
        end

        // SW x2, 0(x0) then LW x3, 0(x0): Store then load back
        begin
            test_num++;
            // We can only execute one instruction (the one at imem[0]).
            // So test SW alone: seed x2=0xBEEFBEEF, store to dmem[0], check dmem directly.
            core_inst.mem_inst.ram[0] = store_word(5'd0, 5'd2, 12'd0);
            rst = 1'b1;
            @(posedge clk); @(posedge clk);
            rst = 1'b0;
            seed_reg(5'd2, 32'hBEEFBEEF);
            repeat(10) @(posedge clk);
            if (core_inst.mem_inst.ram[0] === 32'hBEEFBEEF) begin
                $display("  [PASS] Test %0d: SW x2, 0(x0) → dmem[0] = 0xBEEFBEEF", test_num);
                pass_count++;
            end else begin
                $display("  [FAIL] Test %0d: SW x2, 0(x0) → dmem[0] = 0x%08h, expected 0xBEEFBEEF",
                         test_num, core_inst.mem_inst.ram[0]);
                fail_count++;
            end
        end

        // LW with offset: LW x1, 8(x0) → loads dmem[2]
        begin
            test_num++;
            core_inst.mem_inst.ram[0] = load_word(5'd1, 5'd0, 12'd8);
            core_inst.mem_inst.ram[2] = 32'h12345678;
            rst = 1'b1;
            @(posedge clk); @(posedge clk);
            rst = 1'b0;
            repeat(10) @(posedge clk);
            if (core_inst.regfile[1] === 32'h12345678) begin
                $display("  [PASS] Test %0d: LW x1, 8(x0) = 0x12345678", test_num);
                pass_count++;
            end else begin
                $display("  [FAIL] Test %0d: LW x1, 8(x0) = 0x%08h, expected 0x12345678",
                         test_num, core_inst.regfile[1]);
                fail_count++;
            end
        end

        // ===========================================================
        // STALL DETECTION
        // ===========================================================
        $display("");
        $display("--- Stall Detection ---");

        // An instruction that reads and writes the same register should
        // trigger a RAW stall because ex_rd_addr will match rs1_addr on
        // the next fetch of the same instruction.
        // ADDI x1, x1, 1 — reads x1, writes x1
        run_stall_test("ADDI x1,x1,1 (RAW self-hazard → stall expected)",
            i_add(5'd1, 5'd1, 12'd1),
            '{}, '{},
            1'b1);

        // An instruction with no register dependencies should not stall.
        // ADDI x1, x0, 1 — reads x0, writes x1. x0 is never written.
        // But because the same instruction re-executes, x1 will be the
        // *previous* iteration's rd, so ex_rd_addr=x1 vs rs1_addr=x0
        // should NOT stall (they differ).
        run_stall_test("ADDI x1,x0,1 (no hazard → no stall expected)",
            i_add(5'd1, 5'd0, 12'd1),
            '{}, '{},
            1'b0);

        // LW x1, 0(x0) → reads x0, writes x1. With the instruction
        // repeating, the second iteration will see ex_rd_addr=x1 but
        // it only reads x0, so no stall from EX hazard. However the
        // MEM hazard (load-use) check: ex_mem_mem_read && ex_mem_rd_addr==rs1?
        // rs1=x0, rd=x1 → no match. So no stall expected.
        run_stall_test("LW x1,0(x0) (load, rd!=rs1 → no stall expected)",
            load_word(5'd1, 5'd0, 12'd0),
            '{}, '{},
            1'b0);

        // ADD x1, x1, x2 — reads x1 and x2, writes x1.
        // Next iteration: ex_rd_addr=x1 matches rs1_addr=x1 → stall.
        run_stall_test("ADD x1,x1,x2 (RAW rd=rs1 → stall expected)",
            r_add(5'd1, 5'd1, 5'd2),
            '{5'd2}, '{32'd5},
            1'b1);

        // ADD x3, x1, x2 — reads x1 and x2, writes x3.
        // Next iteration: ex_rd_addr=x3 vs rs1=x1, rs2=x2 → no match.
        // But iteration after that: ex_rd_addr's previous value... actually
        // since the same instruction keeps executing, the pipeline fills up
        // with the same rd=x3. rs1=x1, rs2=x2 ≠ x3 → no stall.
        run_stall_test("ADD x3,x1,x2 (no hazard → no stall expected)",
            r_add(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'd10, 32'd20},
            1'b0);

        // ===========================================================
        // EDGE CASES
        // ===========================================================
        $display("");
        $display("--- Edge Cases ---");

        // ADDI with maximum positive immediate: x1 = 0 + 2047 = 2047
        run_test("ADDI x1, x0, 2047 (max pos imm)",
            i_add(5'd1, 5'd0, 12'd2047),
            '{}, '{},
            5'd1, 32'd2047);

        // ADDI with minimum negative immediate: x1 = 0 + (-2048) = -2048
        run_test("ADDI x1, x0, -2048 (min neg imm)",
            i_add(5'd1, 5'd0, 12'h800),
            '{}, '{},
            5'd1, 32'hFFFFF800);

        // ADD overflow: 0x7FFFFFFF + 1 = 0x80000000 (wraps)
        run_test("ADD overflow (0x7FFFFFFF + 1)",
            r_add(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'h7FFFFFFF, 32'd1},
            5'd3, 32'h80000000);

        // SUB producing negative: 0 - 1 = 0xFFFFFFFF
        run_test("SUB x3 = 0 - 1",
            r_sub(5'd3, 5'd1, 5'd2),
            '{5'd1, 5'd2}, '{32'd0, 32'd1},
            5'd3, 32'hFFFFFFFF);

        // NOP (ADDI x0, x0, 0) — should not change any register
        run_test("NOP (ADDI x0,x0,0)",
            nop(),
            '{}, '{},
            5'd0, 32'd0);

        // LUI x0, 0xFFFFF — should not change x0 (hardwired zero)
        run_test("LUI x0, 0xFFFFF (x0 stays 0)",
            lui(5'd0, 20'hFFFFF),
            '{}, '{},
            5'd0, 32'd0);

        // ===========================================================
        // LARGE VALUES
        // ===========================================================
        $display("");
        $display("--- Large Values ---");

        // LUI + ADDI combo (tested separately since PC doesn't advance):
        // LUI alone: x1 = 0x12345000
        run_test("LUI x1, 0x12345",
            lui(5'd1, 20'h12345),
            '{}, '{},
            5'd1, 32'h12345000);

        // OR with all-ones: x3 = x1 | 0xFFF (x1=0 → 0xFFFFFFFF sign-extended)
        // Actually, ORI sign-extends the 12-bit immediate, so 0xFFF → 0xFFFFFFFF
        run_test("ORI x3, x0, 0xFFF (sign-ext → -1)",
            i_ori(5'd3, 5'd0, 12'hFFF),
            '{}, '{},
            5'd3, 32'hFFFFFFFF);

        // ===========================================================
        // Summary
        // ===========================================================
        $display("");
        $display("========================================");
        $display("  Results: %0d passed, %0d failed out of %0d tests",
                 pass_count, fail_count, test_num);
        $display("========================================");
        $display("");

        $finish;
    end

endmodule
