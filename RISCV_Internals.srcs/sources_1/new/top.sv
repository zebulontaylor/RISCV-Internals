`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2026 09:06:24 PM
// Design Name: 
// Module Name: top
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


module top(
    input[15:0] sw,
    output reg[15:0] led,
    input clk,
    input btnU,
    input btnC,
    input btnL,
    input btnR,
    input btnD,
    output reg[3:0] vgaRed,
    output reg[3:0] vgaGreen,
    output reg[3:0] vgaBlue,
    output reg Hsync,
    output reg Vsync,
    output TxD
);
    wire rst = btnC;
    wire pix_clk;
    
    clk_wiz_0 instance_name (
        // Clock out ports
        .clk_out1(pix_clk),     // output clk_out1
        // Status and control signals
        .reset(rst), // input reset
        // Clock in ports
        .clk_in1(clk)      // input clk_in1
    );

    localparam H_RES = 1280;
    localparam V_RES = 720;
    localparam H_FRONT_PORCH = 110;
    localparam H_SYNC_PULSE = 40;
    localparam H_BACK_PORCH = 220;
    localparam V_FRONT_PORCH = 5;
    localparam V_SYNC_PULSE = 5;
    localparam V_BACK_PORCH = 20;
    localparam H_TOTAL = H_RES + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;
    localparam V_TOTAL = V_RES + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;
    localparam H_CHARS = 213;
    localparam V_CHARS = 90;

    reg [11:0] h_count = 12'd0;
    reg [10:0] h_char_addr = 11'd0;
    reg [2:0] h_pixel_cnt = 3'd0;
    reg [11:0] v_count = 12'd0;
    reg [14:0] text_row_offset = 15'b0;
    wire display_en = (h_char_addr < H_CHARS) && (v_count >> 3 < V_CHARS);
    assign Hsync = ~(h_count >= H_RES + H_FRONT_PORCH && 
                   h_count <  H_RES + H_FRONT_PORCH + H_SYNC_PULSE);
    assign Vsync = ~(v_count >= V_RES + V_FRONT_PORCH && 
                   v_count <  V_RES + V_FRONT_PORCH + V_SYNC_PULSE);

    always_ff @(posedge pix_clk) begin
        if (rst) begin
            h_count <= 12'd0;
            h_char_addr <= 11'd0;
            h_pixel_cnt <= 3'd0;
        end
        else begin
            h_count <= (h_count == H_TOTAL - 1) ? 12'd0 : h_count + 1'b1;
            h_pixel_cnt <= (h_pixel_cnt == 0) ? 3'd5 : h_pixel_cnt - 1'b1;
            if (h_pixel_cnt == 0) begin
                h_char_addr <= h_char_addr + 1'b1;
            end
        end
        if (rst)
            v_count <= 12'd0;
        else if (h_count == H_TOTAL - 1'b1) begin
            h_pixel_cnt <= 3'd5;
            h_char_addr <= 11'd0;
            v_count <= (v_count == V_TOTAL - 1) ? 12'd0 : v_count + 1'b1;
            if (v_count == V_TOTAL - 1)
                text_row_offset <= 15'd0;
            else if (v_count[2:0] == 3'b111)
                text_row_offset <= text_row_offset + H_CHARS;
        end
    end
    
    (* rom_style = "block" *) reg [5:0] font_rom [2047:0];
    // 8 rows per char; 6 bits per scanline
    initial $readmemh("font.mem", font_rom);

    (* ram_style = "block" *) reg [6:0] text_buffer [19169:0];  // 213*90
    initial $readmemh("text_buffer.mem", text_buffer);
    
    wire color_bit = font_rom[{text_buffer[text_row_offset + h_char_addr], v_count[2:0]}][h_pixel_cnt];
    
    always_ff @(posedge pix_clk) begin
        if (rst)
            vgaRed <= 4'b0;
        else
            vgaRed <= display_en ? {4{color_bit}} : 4'h0;
            vgaGreen <= display_en ? {4{color_bit}} : 4'h0;
            vgaBlue <= display_en ? {4{color_bit}} : 4'h0;
    end
    
endmodule
