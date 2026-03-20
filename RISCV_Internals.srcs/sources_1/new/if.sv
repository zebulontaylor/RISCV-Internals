`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2026 09:10:57 PM
// Design Name: 
// Module Name: ifs
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


module ifs(
    input logic clk,
    input logic rst,
    input logic stall,
    input logic [31:0] pc_in,
    output logic [31:0] pc_out,
    output logic [31:0] instruction
    );

    (* rom_style = "block" *) logic [31:0] mem [0:1023];
    initial $readmemh("prog.mem", mem);
    
    always_ff @(posedge clk) begin
        if(rst)
            pc_out <= 32'b0;
        else if(~stall)
            pc_out <= pc_in;
    end

    assign instruction = mem[pc_out[11:2]];
endmodule
