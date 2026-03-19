`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2026 09:40:40 PM
// Design Name: 
// Module Name: alu
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

enum logic [3:0] {
    ADD = 4'b0000,
    SUB = 4'b1000,
    SLL = 4'b0001,
    SLT = 4'b0010,
    SLTU = 4'b0011,
    XOR = 4'b0100,
    SRL = 4'b0101,
    SRA = 4'b1101,
    OR = 4'b0110,
    AND = 4'b0111
} op;

enum logic [2:0] {
    BEQ = 3'b000,
    BNE = 3'b001,
    BLT = 3'b100,
    BGE = 3'b101,
    BLTU = 3'b110,
    BGEU = 3'b111
} branch_op;

module alu(
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,
    input logic [3:0] funct,
    input logic is_branch,
    output logic [31:0] result
);

    always_comb begin
        if (is_branch) begin
            case(funct[2:0])
                BEQ: begin // BEQ
                    result = operand_a == operand_b ? 32'd1 : 32'd0;
                end
                BNE: begin // BNE
                    result = operand_a != operand_b ? 32'd1 : 32'd0;
                end
                BLT: begin // BLT
                    result = signed'(operand_a) < signed'(operand_b) ? 32'd1 : 32'd0;
                end
                BGE: begin // BGE
                    result = signed'(operand_a) >= signed'(operand_b) ? 32'd1 : 32'd0;
                end
                BLTU: begin // BLTU
                    result = operand_a < operand_b ? 32'd1 : 32'd0;
                end
                BGEU: begin // BGEU
                    result = operand_a >= operand_b ? 32'd1 : 32'd0;
                end
                default: begin
                    result = 32'b0;
                end
            endcase
        end else begin
            case(funct)
                ADD: begin // ADD
                    result = operand_a + operand_b;
                end
                SUB: begin // SUB
                    result = operand_a - operand_b;
                end
                SLL: begin // SLL
                    result = operand_a << operand_b[4:0];
                end
                SLT: begin // SLT
                    result = signed'(operand_a) < signed'(operand_b) ? 32'd1 : 32'd0;
                end
                SLTU: begin // SLTU
                    result = operand_a < operand_b ? 32'd1 : 32'd0;
                end
                XOR: begin // XOR
                    result = operand_a ^ operand_b;
                end
                SRL: begin // SRL
                    result = operand_a >> operand_b[4:0];
                end
                SRA: begin // SRA
                    result = signed'(operand_a) >>> operand_b[4:0];
                end
                OR: begin // OR
                    result = operand_a | operand_b;
                end
                AND: begin // AND
                    result = operand_a & operand_b;
                end
                default: begin
                    result = 32'b0;
                end
            endcase
        end
    end
endmodule
