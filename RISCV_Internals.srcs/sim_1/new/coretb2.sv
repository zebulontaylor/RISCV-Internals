`timescale 1ns / 1ps

module coretb2();

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

    function automatic [31:0] branch(
        input [4:0] rs1, input [4:0] rs2,
        input [2:0] funct3, input [13:0] imm
    );
        return {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], 7'b1100011};
    endfunction

    function automatic [31:0] jal(input [4:0] rd, input [20:0] imm);
        return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'b1101111};
    endfunction

    // Convenience aliases
    function automatic [31:0] i_add(input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return i_type(rd, rs1, 3'b000, imm);
    endfunction

    function automatic [31:0] i_andi(input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return i_type(rd, rs1, 3'b111, imm);
    endfunction

    function automatic [31:0] i_slli(input [4:0] rd, input [4:0] rs1, input [4:0] shamt);
        return i_type(rd, rs1, 3'b001, {7'b0000000, shamt});
    endfunction

    function automatic [31:0] i_srli(input [4:0] rd, input [4:0] rs1, input [4:0] shamt);
        return i_type(rd, rs1, 3'b101, {7'b0000000, shamt});
    endfunction

    function automatic [31:0] r_add(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return r_type(rd, rs1, rs2, 3'b000, 7'b0000000);
    endfunction

    function automatic [31:0] nop();
        return i_add(5'd0, 5'd0, 12'd0);
    endfunction

    // ---------------------------------------------------------------
    // Test execution
    // ---------------------------------------------------------------
    initial begin
        clk = 1'b0;

        // Load Collatz sequence program into instruction memory
        // Starting value in x1=6, step count in x2=0, constants x3=1
        // Collatz on x1:
        // if x1 == x3 (1) -> end
        // if (x1 & 1 != 0) -> odd
        // even: x1 = x1 >> 1; goto next_iter
        // odd: x1 = (x1 << 1) + x1 + 1 (i.e., x1 * 3 + 1)
        // next_iter: x2 = x2 + 1; goto loop
        // end: nop

        // Addresses are byte-addressed, but mapped to word index in hardware.
        // Current core has a fetch bug and will repeat pc=0, but we load the whole 
        // sequence anyway as if it worked.
        core_inst.ifs_inst.mem[0]  = branch(5'd1, 5'd3, 3'b000, 14'd40); // 0:  BEQ x1, x3, 40    -> goto end
        core_inst.ifs_inst.mem[1]  = i_andi(5'd4, 5'd1, 12'd1);          // 4:  ANDI x4, x1, 1    -> get odd bit
        core_inst.ifs_inst.mem[2]  = branch(5'd4, 5'd0, 3'b001, 14'd12); // 8:  BNE x4, x0, 12    -> goto odd (PC+12=0x14)
        core_inst.ifs_inst.mem[3]  = i_srli(5'd1, 5'd1, 5'd1);           // C:  SRLI x1, x1, 1    -> even step: x1 /= 2
        core_inst.ifs_inst.mem[4]  = jal(5'd0, 21'd16);                  // 10: JAL x0, 16        -> goto next_iter (PC+16=0x20)
        core_inst.ifs_inst.mem[5]  = i_slli(5'd5, 5'd1, 5'd1);           // 14: SLLI x5, x1, 1    -> odd step: x5 = x1*2
        core_inst.ifs_inst.mem[6]  = r_add(5'd1, 5'd1, 5'd5);            // 18: ADD x1, x1, x5    -> x1 = x1*3
        core_inst.ifs_inst.mem[7]  = i_add(5'd1, 5'd1, 12'd1);           // 1C: ADDI x1, x1, 1    -> x1 = x1*3+1
        core_inst.ifs_inst.mem[8]  = i_add(5'd2, 5'd2, 12'd1);           // 20: ADDI x2, x2, 1    -> next_iter: steps++
        core_inst.ifs_inst.mem[9]  = jal(5'd0, -21'd36);                 // 24: JAL x0, -36       -> loop back to PC=0
        for (int i = 10; i < 1024; i++) begin
            core_inst.ifs_inst.mem[i] = nop();
        end

        // Reset the core
        rst = 1'b1;
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;

        // Give the loop variables their initial values right after reset disables
        core_inst.regfile[1] = 32'd6; // Initial number to evaluate Collatz for
        core_inst.regfile[2] = 32'd0; // Steps counter
        core_inst.regfile[3] = 32'd1; // Constant value 1 for BEQ comparison

        // Give it 500 cycles to run Collatz (Sequence for 6 = 8 steps)
        repeat(500) @(posedge clk);

        $display("========================================");
        $display("  RISC-V Core Collatz Test");
        $display("========================================");
        // Expect x1 = 1 (complete) and x2 = 8 (amount of steps for 6)
        if (core_inst.regfile[1] === 32'd1 && core_inst.regfile[2] === 32'd8) begin
            $display("[PASS] Collatz completed. Value reached 1 in 8 steps.");
        end else begin
            $display("[FAIL] Collatz failed. Expected x1=1, x2=8. Got x1=%0d, x2=%0d", 
                      core_inst.regfile[1], core_inst.regfile[2]);
            $display("       (This is likely due to the PC fetch bug preventing the loop from advancing)");
        end
        $display("========================================");

        $finish;
    end
endmodule
