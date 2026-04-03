`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2026 09:10:57 PM
// Design Name: 
// Module Name: mem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Unified von Neumann memory.
//   Byte address map:
//     0x000000 - 0x003FFF : unified code+data RAM (4096 x 32-bit words)
//     0x400000+           : palette (bit 22 set, bit 23 clear) - 16 entries x 36-bit
//     0x800000+           : OAM     (bit 23 set)               - 128 entries x 32-bit
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mem(
    input clk,
    input rst,
    input write_en,
    input read_en,
    input [31:0] address,
    input [31:0] data_in,
    output reg [31:0] data_out,

    // Instruction fetch port (combinational, word-addressed by PC)
    input [31:0] pc,
    output [31:0] instruction,

    input [31:0] oam_addr,
    input [31:0] palette_addr,
    output [31:0] oam_data,
    output [35:0] palette_data
    
);
    localparam RAM_WORDS = 4096;

    (* ram_style = "block" *) reg [31:0] ram [0:RAM_WORDS-1];
    (* ram_style = "block" *) reg [31:0] oam_mem [0:127];
    (* ram_style = "block" *) reg [35:0] palette_mem [0:15];

    initial $readmemh("mem/prog.mem", ram);

    // Address decode: high bits determine region
    wire is_oam_addr     = address[23];
    wire is_palette_addr = address[22] & ~address[23];

    // Synchronous data read
    always_ff @(posedge clk) begin
        if (rst)
            data_out <= 32'b0;
        else if (read_en) begin
            if (is_oam_addr)
                data_out <= oam_mem[address[8:2]];
            else if (is_palette_addr)
                data_out <= palette_mem[address[5:2]];
            else
                data_out <= ram[address[13:2]];
        end
    end

    // Instruction fetch: combinational read from RAM (PC word-addressed)
    assign instruction = ram[pc[13:2]];

    // OAM and palette display read ports
    assign oam_data     = oam_mem[oam_addr[6:0]];
    assign palette_data = palette_mem[palette_addr[3:0]];

    // Synchronous write
    always_ff @(posedge clk) begin
        if (write_en) begin
            if (is_oam_addr)
                oam_mem[address[8:2]] <= data_in;
            else if (is_palette_addr)
                palette_mem[address[5:2]] <= data_in;
            else
                ram[address[13:2]] <= data_in;
        end
    end
endmodule
