`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2026 09:10:57 PM
// Design Name: 
// Module Name: id
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


module id(
    input logic clk,
    input logic rst,
    input logic [31:0] instruction,
    input logic [31:0] rs1_val,
    input logic [31:0] rs2_val,
    input logic [31:0] pc_in,
    input logic bubble,

    output logic [31:0] operand_a,
    output logic [31:0] operand_b,
    output logic read_rs1,
    output logic read_rs2,
    output logic write_en,
    output logic rd_src,
    output logic [3:0] funct,
    output logic jump,
    output logic [31:0] pc_out,
    output logic cjump,
    output logic [31:0] c_next_pc,
    output logic mem_read,
    output logic mem_write
);
    wire is_enabled = ~rst & ~bubble;
    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];

    wire [31:0] immI = {{20{instruction[31]}}, instruction[31:20]};
    wire [31:0] immS = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    wire [31:0] immB = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    wire [31:0] immU = {instruction[31:12], 12'b0};
    wire [31:0] immJ = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};

    always @(*) begin
        read_rs1 <= 1'b0;
        read_rs2 <= 1'b0;
        operand_a <= 32'b0;
        operand_b <= 32'b0;
        write_en <= 1'b0;
        rd_src <= 1'b0;
        jump <= 1'b0;
        cjump <= 1'b0;
        mem_read <= 1'b0;
        mem_write <= 1'b0;
        rd_src <= 1'b0; // alu by default
        funct <= {instruction[30], instruction[14:12]};
        pc_out <= 32'b0;
        c_next_pc <= 32'b0;

        case(opcode)
            7'b00110011: begin // r-type
                operand_a <= rs1_val;
                operand_b <= rs2_val;
                read_rs1 <= 1'b1;
                read_rs2 <= 1'b1;
                write_en <= is_enabled;
            end
            // I TYPES
            7'b0010011: begin // ALU imm
                operand_a <= rs1_val;
                operand_b <= immI;
                read_rs1 <= 1'b1;
                write_en <= is_enabled;
                funct <= {instruction[14:12] == 3'b101 ? instruction[30] : 1'b0, instruction[14:12]};
            end
            7'b0000011: begin // LOAD
                operand_a <= rs1_val;
                operand_b <= immI;
                read_rs1 <= 1'b1;
                mem_read <= 1'b1;
                write_en <= is_enabled;
                rd_src <= 1'b1;  // rd src 1 -> mem
                funct <= 3'b0;
            end
            7'b1100111: begin // JALR
                operand_a <= pc_in;  // write pc+4 to rd
                operand_b <= 32'd4;
                read_rs1 <= 1'b1;
                write_en <= is_enabled;
                pc_out <= rs1_val + immI; // jump to rs1+immI
                jump <= is_enabled;
                funct <= 3'b0;
            end
            // end of I types
            7'b0100011: begin // STORE
                operand_a <= rs1_val;
                operand_b <= immS;
                read_rs1 <= 1'b1;
                read_rs2 <= 1'b1;
                mem_write <= is_enabled;
                funct <= 3'b0;
            end
            7'b1100011: begin // BRANCH
                operand_a <= rs1_val;
                operand_b <= rs2_val;
                read_rs1 <= 1'b1;
                read_rs2 <= 1'b1;
                cjump <= is_enabled;
                c_next_pc <= pc_in + immB;
            end
            7'b1101111: begin // JAL
                operand_a <= pc_in;
                operand_b <= 32'd4;
                write_en <= is_enabled;
                jump <= is_enabled;
                pc_out <= pc_in + immJ;
                funct <= 4'b0;
            end
            7'b0110111: begin // LUI
                operand_a <= immU;
                operand_b <= 32'd0;
                write_en <= is_enabled;
                funct <= 3'b0;
            end
            7'b0010111: begin // AUIPC
                operand_a <= pc_in;
                operand_b <= immU;
                write_en <= is_enabled;
                funct <= 3'b0;
            end
        endcase
    end

endmodule
