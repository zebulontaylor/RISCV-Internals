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
    output reg [31:0] data_out,

    input [31:0] oam_addr,
    input [31:0] palette_addr,
    output [31:0] oam_data,
    output [35:0] palette_data
    
);

    (* ram_style = "block" *) reg [31:0] mem [0:1023];
    (* ram_style = "block" *) reg [31:0] oam_mem [0:127];
    (* ram_style = "block" *) reg [35:0] palette_mem [0:15];

    wire is_oam_addr = (address >= 32'h200) && (address <= 32'h3FF);
    wire is_palette_addr = (address >= 32'h400) && (address <= 32'h43F);


    always_ff @(posedge clk) begin
        if(rst)
            data_out <= 32'b0;
        else if(read_en) begin
            if(is_oam_addr)
                data_out <= oam_mem[address[8:2]];
            else if(is_palette_addr)
                data_out <= palette_mem[address[5:2]];
            else
                data_out <= mem[address[11:2]];
        end
    end

    assign oam_data = oam_mem[oam_addr[6:0]];
    assign palette_data = palette_mem[palette_addr[3:0]];

    always_ff @(posedge clk) begin
        if(write_en) begin
            if(is_oam_addr)
                oam_mem[address[8:2]] <= data_in;
            else if(is_palette_addr)
                palette_mem[address[5:2]] <= data_in;
            else
                mem[address[11:2]] <= data_in;
        end
    end
endmodule
