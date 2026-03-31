`timescale 1ns / 1ps

module coretb2();

    logic clk;
    logic rst;

    internal_signals dbg_if();

    // core instance with all ports
    core core_inst(
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .oam_addr(32'b0),
        .palette_addr(32'b0),
        .oam_data(),
        .palette_data(),
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
        input [6:0] opcode, input [4:0] rd, input [4:0] rs1,
        input [2:0] funct3, input [11:0] imm
    );
        return {imm, rs1, funct3, rd, opcode};
    endfunction

    function automatic [31:0] s_type(
        input [4:0] rs1, input [4:0] rs2,
        input [2:0] funct3, input [11:0] imm
    );
        return {imm[11:5], rs2, rs1, funct3, imm[4:0], 7'b0100011};
    endfunction

    // Convenience aliases
    function automatic [31:0] i_add(input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return i_type(7'b0010011, rd, rs1, 3'b000, imm);
    endfunction

    function automatic [31:0] i_lw(input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return i_type(7'b0000011, rd, rs1, 3'b010, imm);
    endfunction

    function automatic [31:0] s_sw(input [4:0] rs1, input [4:0] rs2, input [11:0] imm);
        return s_type(rs1, rs2, 3'b010, imm);
    endfunction

    function automatic [31:0] nop();
        return i_add(5'd0, 5'd0, 12'd0);
    endfunction

    // ---------------------------------------------------------------
    // Test execution
    // ---------------------------------------------------------------
    initial begin
        clk = 1'b0;
        rst = 1'b1;

        // Clear memory
        for (int i = 0; i < 4096; i++) core_inst.mem_inst.ram[i] = 32'b0;

        // --- TEST PROGRAM ---
        // 0x00: addi sp, x0, 0x3FFC   (Set SP to top word)
        // 0x04: addi x1, x0, 0x123    (Value to store)
        // 0x08: sw   x1, 0(sp)         (Store x1 to stack[0])
        // 0x0C: lw   x2, 0(sp)         (Load back to x2)
        // 0x10: addi x1, x1, 1         (x1 = 0x124)
        // 0x14: sw   x1, -4(sp)        (Store 0x124 to next slot)
        // 0x18: lw   x3, -4(sp)        (Load back to x3)
        // 0x1C: addi sp, sp, -4        (Update SP)
        // 0x20: lw   x4, 0(sp)         (Load from updated SP)
        // 0x24: addi x5, x0, 0xAAA     (New data)
        // 0x28: sw   x5, 0(sp)         (Overwrite stack[1])
        // 0x2C: lw   x6, 0(sp)         (Immediate reload)
        
        core_inst.mem_inst.ram[0] = i_add(5'd2, 5'd0, 12'hFFC); // sp (x2) = 0xFFC
        // Wait, sp is at 0x4000. 0x3FFC is bit 13..2 = 14'h0FFC >> 2 = 1023.
        // Actually sp is USUALLY at the very top.
        // Let's use 0x4000 as base.
        core_inst.mem_inst.ram[0] = i_add(5'd2, 5'd0, 12'h800); // sp = 0x800
        core_inst.mem_inst.ram[1] = i_add(5'd2, 5'd2, 12'h800); // sp = 0x1000 (scaled up)
        // Wait, addi imm is signed. 0x800 is negative in 12-bit? No, 0x800 is 1000_0000_0000.
        // In 12-bit 2's complement, 0x800 is -2048.
        // Let's build it safely.
        core_inst.mem_inst.ram[0] = i_add(5'd2, 5'd0, 12'h400); // 1024
        core_inst.mem_inst.ram[1] = i_add(5'd2, 5'd2, 12'h400); // 2048
        core_inst.mem_inst.ram[2] = i_add(5'd2, 5'd2, 12'h400); // 3072
        core_inst.mem_inst.ram[3] = i_add(5'd2, 5'd2, 12'h400); // 4096 (0x1000)
        // Okay, x2 = 0x1000. (4096 bytes)
        
        core_inst.mem_inst.ram[4] = i_add(5'd1, 5'd0, 12'h123); // x1 = 0x123
        core_inst.mem_inst.ram[5] = s_sw(5'd2, 5'd1, -12'd4);  // sw x1, -4(x2)  -> address 0x0FFC
        core_inst.mem_inst.ram[6] = i_lw(5'd10, 5'd2, -12'd4); // lw x10, -4(x2) -> load back
        
        core_inst.mem_inst.ram[7] = i_add(5'd1, 5'd1, 12'd1);  // x1 = 0x124 (RAW on x1)
        core_inst.mem_inst.ram[8] = s_sw(5'd2, 5'd1, -12'd8);  // sw x1, -8(x2)  -> address 0x0FF8
        core_inst.mem_inst.ram[9] = i_lw(5'd11, 5'd2, -12'd8); // lw x11, -8(x2)
        
        core_inst.mem_inst.ram[10] = i_add(5'd2, 5'd2, -12'd8); // x2 = x2 - 8 = 0x0FF8 (Update SP)
        core_inst.mem_inst.ram[11] = i_lw(5'd12, 5'd2, 12'd0);  // lw x12, 0(x2)  (RAW on x2)
        
        core_inst.mem_inst.ram[12] = i_add(5'd5, 5'd0, 12'hAAA);
        core_inst.mem_inst.ram[13] = s_sw(5'd2, 5'd5, 12'd4);   // sw x5, 4(x2)  -> back to 0x0FFC
        core_inst.mem_inst.ram[14] = i_lw(5'd13, 5'd2, 12'd4);  // lw x13, 4(x2) (Immediate reload)
        
        core_inst.mem_inst.ram[15] = i_add(5'd31, 5'd0, 12'hDED); // Marker

        repeat(5) @(posedge clk);
        rst = 1'b0;

        // Run until marker
        repeat(200) @(posedge clk);

        $display("========================================");
        $display("  RISC-V Core Memory Debug Test");
        $display("========================================");
        
        $display("Test 1: sw followed by lw (Store-to-Load RAW)");
        if (core_inst.regfile[10] === 32'h123) 
            $display("[PASS] x10 = 0x123");
        else 
            $display("[FAIL] x10 = 0x%08x (Expected 0x00000123)", core_inst.regfile[10]);

        $display("Test 2: Data-to-Store RAW (addi x1, x1, 1 then sw x1)");
        if (core_inst.regfile[11] === 32'h124) 
            $display("[PASS] x11 = 0x124");
        else 
            $display("[FAIL] x11 = 0x%08x (Expected 0x00000124)", core_inst.regfile[11]);

        $display("Test 3: SP update RAW (addi x2 then lw 0(x2))");
        if (core_inst.regfile[12] === 32'h124)
            $display("[PASS] x12 = 0x124");
        else
            $display("[FAIL] x12 = 0x%08x (Expected 0x00000124)", core_inst.regfile[12]);

        $display("Test 4: Immediate reload (sw then lw same addr)");
        if (core_inst.regfile[13] === 32'hFFFFFAAA)
            $display("[PASS] x13 = 0xAAA (sign-extended to 0xFFFFFAAA)");
        else
            $display("[FAIL] x13 = 0x%08x (Expected 0xFFFFFAAA)", core_inst.regfile[13]);

        if (core_inst.regfile[31] === 32'hDED)
            $display("\n[RESULT] Test Completed Successfully.");
        else
            $display("\n[RESULT] Test did not reach completion marker (x31=0xDED).");

        $display("========================================");

        $finish;
    end

endmodule

