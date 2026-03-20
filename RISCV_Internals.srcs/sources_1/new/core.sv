`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/17/2026 11:48:23 AM
// Design Name: 
// Module Name: core
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

interface internal_signals;
    logic stall;
    logic [31:0] regfile [0:31];
    logic [31:0] fetch_stage_pc;
    logic [31:0] if_id_instr, if_id_pc;
    logic [31:0] id_operand_a, id_operand_b;
    logic id_read_rs1, id_read_rs2, id_write_en, id_rd_src;
    logic id_jump, id_cjump, id_mem_read, id_mem_write;
    logic [31:0] id_pc_out, id_c_next_pc, id_instr;
    logic [31:0] alu_result;
    logic [3:0] funct;
    logic branch_taken, flush_delay;
    logic [4:0] rs1_addr, rs2_addr, rd_addr;
    logic [31:0] rs1_val, rs2_val;
    logic [4:0] ex_rd_addr;
    logic [31:0] ex_instr, ex_operand_a, ex_operand_b;
    logic [3:0] ex_funct;
    logic ex_branch_taken, ex_cjump, ex_mem_read, ex_mem_write;
    logic ex_write_en, ex_rd_src;
    logic [31:0] ex_c_next_pc;
    logic [31:0] ex_mem_wb_val, ex_mem_mem_data, ex_mem_address;
    logic [4:0] ex_mem_rd_addr;
    logic [4:0] wb_rd_addr;
    logic wb_en;
    logic [31:0] wb_val, mem_wb_val;

    modport src (output stall, regfile, fetch_stage_pc,
        if_id_instr, if_id_pc, id_operand_a, id_operand_b,
        id_read_rs1, id_read_rs2, id_write_en, id_rd_src,
        id_jump, id_cjump, id_mem_read, id_mem_write,
        id_pc_out, id_c_next_pc, id_instr, alu_result, funct,
        branch_taken, flush_delay, rs1_addr, rs2_addr, rd_addr,
        rs1_val, rs2_val, ex_rd_addr, ex_instr, ex_operand_a,
        ex_operand_b, ex_funct, ex_branch_taken, ex_cjump,
        ex_c_next_pc, ex_mem_read, ex_mem_write, ex_write_en,
        ex_rd_src, ex_mem_wb_val, ex_mem_mem_data, ex_mem_address,
        ex_mem_rd_addr, wb_rd_addr, wb_en, wb_val, mem_wb_val);
endinterface


module core(
    input clk,
    input rst,
    input enable,
    internal_signals.src dbg
);
    wire stall;

    reg [31:0] regfile [0:31];

    // FETCH
    reg [31:0] fetch_stage_pc;
    initial fetch_stage_pc = 32'b0;

    wire [31:0] if_id_instr;
    wire [31:0] if_id_pc;

    ifs ifs_inst(
        .clk(clk),
        .rst(rst),
        .stall(stall || ~enable),
        .pc_in(fetch_stage_pc),
        .pc_out(if_id_pc),
        .instruction(if_id_instr)
    );

    // DECODE
    wire [31:0] id_operand_a;
    wire [31:0] id_operand_b;
    wire id_read_rs1;
    wire id_read_rs2;
    wire id_write_en;
    wire id_rd_src;
    wire id_jump;
    wire [31:0] id_pc_out;
    wire id_cjump;
    wire [31:0] id_c_next_pc;
    wire id_mem_read;
    wire id_mem_write;
    wire [31:0] alu_result;
    wire [3:0] funct;
    wire branch_taken = ex_cjump && alu_result;

    // Flush decode stage instr on branch/jump.
    reg flush_delay;
    always_ff @(posedge clk) begin
        if (rst)
            flush_delay <= 1'b0;
        else if (enable)
            flush_delay <= branch_taken || id_jump;
    end

    wire [31:0] id_instr = (branch_taken || flush_delay) ? 32'b0 : if_id_instr;

    wire [4:0] rs1_addr = if_id_instr[19:15];
    wire [4:0] rs2_addr = if_id_instr[24:20];
    wire [4:0] rd_addr = if_id_instr[11:7];
    
    // Regfile reads
    wire [31:0] rs1_val = regfile[rs1_addr];
    wire [31:0] rs2_val = regfile[rs2_addr];


    id id_inst(
        .clk(clk),
        .rst(rst),
        .instruction(id_instr),
        .rs1_val(rs1_val),
        .rs2_val(rs2_val),
        .pc_in(if_id_pc),
        .bubble(stall),
        .operand_a(id_operand_a),
        .operand_b(id_operand_b),
        .read_rs1(id_read_rs1),
        .read_rs2(id_read_rs2),
        .write_en(id_write_en),
        .rd_src(id_rd_src),
        .jump(id_jump),
        .pc_out(id_pc_out),
        .cjump(id_cjump),
        .c_next_pc(id_c_next_pc),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .funct(funct)
    );

    reg [4:0] ex_rd_addr;
    reg [31:0] ex_instr;

    always_ff @(posedge clk) begin
        if(rst) begin
            ex_rd_addr <= 5'b0;
            ex_instr <= 32'b0;
        end else if (enable) begin
            if (stall) begin
                ex_rd_addr <= 5'b0;
                ex_instr <= 32'b0;
            end else begin
                ex_rd_addr <= rd_addr;
                ex_instr <= id_instr;
            end
        end
    end

    reg [31:0] ex_operand_a;
    reg [31:0] ex_operand_b;
    reg [3:0] ex_funct;
    reg ex_branch_taken;
    reg ex_cjump;
    reg [31:0] ex_c_next_pc;
    reg ex_mem_read;
    reg ex_mem_write;
    reg ex_write_en;
    reg ex_rd_src;


    always @(posedge clk) begin
        if(rst) begin
            ex_operand_a <= 32'b0;
            ex_operand_b <= 32'b0;
            ex_funct <= 4'b0;
            ex_branch_taken <= 1'b0;
            ex_cjump <= 1'b0;
            ex_c_next_pc <= 32'b0;
            ex_mem_read <= 1'b0;
            ex_mem_write <= 1'b0;
        end else if (enable) begin
            ex_operand_a <= id_operand_a;
            ex_operand_b <= id_operand_b;
            ex_funct <= funct;
            ex_branch_taken <= branch_taken;
            ex_cjump <= id_cjump;
            ex_c_next_pc <= id_c_next_pc;
            ex_mem_read <= id_mem_read;
            ex_mem_write <= id_mem_write;
            ex_write_en <= id_write_en;
            ex_rd_src <= id_rd_src;
        end
    end

    // EXECUTE
    alu alu_inst(
        .operand_a(ex_operand_a),
        .operand_b(ex_operand_b),
        .funct(ex_funct),
        .is_branch(ex_cjump),
        .result(alu_result)
    );

    reg ex_mem_write_en;
    reg ex_mem_rd_src;
    reg [31:0] ex_mem_wb_val;
    reg ex_mem_mem_read;
    reg ex_mem_mem_write;
    reg [31:0] ex_mem_mem_data;
    reg [31:0] ex_mem_address;
    reg [4:0] ex_mem_rd_addr;

    always_ff @(posedge clk) begin
        if(rst) begin
            ex_mem_write_en <= 1'b0;
            ex_mem_rd_addr <= 5'b0;
        end else if (enable) begin
            ex_mem_write_en <= ex_write_en;
            ex_mem_rd_addr <= ex_rd_addr;
            ex_mem_rd_src <= ex_rd_src;
            ex_mem_wb_val <= alu_result;
            ex_mem_mem_data <= rs2_val;
            ex_mem_mem_read <= ex_mem_read;
            ex_mem_mem_write <= ex_mem_write;
        end
    end
    
    // MEMORY
    wire [31:0] mem_wb_val;
    mem mem_inst(
        .clk(clk),
        .rst(rst),
        .write_en(ex_mem_mem_write & enable),
        .read_en(ex_mem_mem_read & enable),
        .address(ex_mem_wb_val),
        .data_in(ex_mem_mem_data),
        .data_out(mem_wb_val)
    );

    reg [4:0] wb_rd_addr;
    reg wb_en;
    reg [31:0] wb_val;

    always_ff @(posedge clk) begin
        if(rst)
            wb_rd_addr <= 5'b0;
        else if (enable)
            wb_rd_addr <= ex_mem_rd_addr;
    end

    always_ff @(posedge clk) begin
        if(rst)
            wb_en <= 1'b0;
        else if (enable) begin
            wb_en <= ex_mem_write_en;
            wb_val <= ex_mem_rd_src ? mem_wb_val : ex_mem_wb_val;
        end
    end

    // WB
    always_ff @(posedge clk) begin
        if (enable) begin
            regfile[0] <= 32'b0;
            if(wb_en && wb_rd_addr != 5'b0)
                regfile[wb_rd_addr] <= wb_val;
        end
    end

    // STALLING
    assign stall = (ex_mem_rd_addr != 5'b0 && ex_mem_rd_addr == rs1_addr && id_read_rs1) || 
                   (ex_mem_rd_addr != 5'b0 && ex_mem_rd_addr == rs2_addr && id_read_rs2) ||
                   (ex_rd_addr != 5'b0 && ex_rd_addr == rs1_addr && id_read_rs1) || 
                   (ex_rd_addr != 5'b0 && ex_rd_addr == rs2_addr && id_read_rs2) ||
                   (wb_rd_addr != 5'b0 && wb_rd_addr == rs1_addr && id_read_rs1) || 
                   (wb_rd_addr != 5'b0 && wb_rd_addr == rs2_addr && id_read_rs2);
    
    // PC INCREMENTING
    always @(posedge clk) begin
        if(rst)
            fetch_stage_pc <= 32'b0;
        else if(enable) begin
            if(id_jump)
                fetch_stage_pc <= id_pc_out;
            else if(branch_taken)
                fetch_stage_pc <= ex_c_next_pc;
            else if (~stall)
                fetch_stage_pc <= fetch_stage_pc + 32'd4;
        end
    end

    // Drive debug interface
    generate
        for (genvar i = 0; i < 32; i++)
            assign dbg.regfile[i] = regfile[i];
    endgenerate
    assign dbg.stall = stall;
    assign dbg.fetch_stage_pc = fetch_stage_pc;
    assign dbg.if_id_instr = if_id_instr;
    assign dbg.if_id_pc = if_id_pc;
    assign dbg.id_operand_a = id_operand_a;
    assign dbg.id_operand_b = id_operand_b;
    assign dbg.id_read_rs1 = id_read_rs1;
    assign dbg.id_read_rs2 = id_read_rs2;
    assign dbg.id_write_en = id_write_en;
    assign dbg.id_rd_src = id_rd_src;
    assign dbg.id_jump = id_jump;
    assign dbg.id_cjump = id_cjump;
    assign dbg.id_mem_read = id_mem_read;
    assign dbg.id_mem_write = id_mem_write;
    assign dbg.id_pc_out = id_pc_out;
    assign dbg.id_c_next_pc = id_c_next_pc;
    assign dbg.id_instr = id_instr;
    assign dbg.alu_result = alu_result;
    assign dbg.funct = funct;
    assign dbg.branch_taken = branch_taken;
    assign dbg.flush_delay = flush_delay;
    assign dbg.rs1_addr = rs1_addr;
    assign dbg.rs2_addr = rs2_addr;
    assign dbg.rd_addr = rd_addr;
    assign dbg.rs1_val = rs1_val;
    assign dbg.rs2_val = rs2_val;
    assign dbg.ex_rd_addr = ex_rd_addr;
    assign dbg.ex_instr = ex_instr;
    assign dbg.ex_operand_a = ex_operand_a;
    assign dbg.ex_operand_b = ex_operand_b;
    assign dbg.ex_funct = ex_funct;
    assign dbg.ex_branch_taken = ex_branch_taken;
    assign dbg.ex_cjump = ex_cjump;
    assign dbg.ex_c_next_pc = ex_c_next_pc;
    assign dbg.ex_mem_read = ex_mem_read;
    assign dbg.ex_mem_write = ex_mem_write;
    assign dbg.ex_write_en = ex_write_en;
    assign dbg.ex_rd_src = ex_rd_src;
    assign dbg.ex_mem_wb_val = ex_mem_wb_val;
    assign dbg.ex_mem_mem_data = ex_mem_mem_data;
    assign dbg.ex_mem_address = ex_mem_address;
    assign dbg.ex_mem_rd_addr = ex_mem_rd_addr;
    assign dbg.wb_rd_addr = wb_rd_addr;
    assign dbg.wb_en = wb_en;
    assign dbg.wb_val = wb_val;
    assign dbg.mem_wb_val = mem_wb_val;
    
endmodule
