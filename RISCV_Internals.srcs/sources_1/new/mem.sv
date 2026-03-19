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
// Description: 
// 
// Dependencies: 
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
    
    output reg [31:0] data_out
);

    (* ram_style = "block" *) reg [31:0] mem [0:1023];

    always_ff @(posedge clk) begin
        if(rst)
            data_out <= 32'b0;
        else if(read_en)
            data_out <= mem[address[11:2]];
    end

    always_ff @(posedge clk) begin
        if(write_en)
            mem[address[11:2]] <= data_in;
    end
endmodule
