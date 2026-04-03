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
    initial $readmemh("mem/font.mem", font_rom);

    (* ram_style = "block" *) reg [10:0] text_buffer [19169:0];  // 213*90, 11-bit
    initial $readmemh("mem/text_buffer.mem", text_buffer);
    
    reg btnU_prev;
    wire rising_btnU = btnU && ~btnU_prev;
    
    always @(posedge pix_clk)
        if (h_count == 0 && v_count == 0)
            btnU_prev <= btnU;

    internal_signals signals();
    internal_signals signals_reg();
    
    always_ff @(posedge pix_clk) begin
        signals_reg.stall <= signals.stall;
        signals_reg.regfile <= signals.regfile;
        signals_reg.fetch_stage_pc <= signals.fetch_stage_pc;
        signals_reg.if_id_instr <= signals.if_id_instr;
        signals_reg.if_id_pc <= signals.if_id_pc;
        signals_reg.id_operand_a <= signals.id_operand_a;
        signals_reg.id_operand_b <= signals.id_operand_b;
        signals_reg.id_read_rs1 <= signals.id_read_rs1;
        signals_reg.id_read_rs2 <= signals.id_read_rs2;
        signals_reg.id_write_en <= signals.id_write_en;
        signals_reg.id_rd_src <= signals.id_rd_src;
        signals_reg.id_jump <= signals.id_jump;
        signals_reg.id_cjump <= signals.id_cjump;
        signals_reg.id_mem_read <= signals.id_mem_read;
        signals_reg.id_mem_write <= signals.id_mem_write;
        signals_reg.id_pc_out <= signals.id_pc_out;
        signals_reg.id_c_next_pc <= signals.id_c_next_pc;
        signals_reg.id_instr <= signals.id_instr;
        signals_reg.alu_result <= signals.alu_result;
        signals_reg.funct <= signals.funct;
        signals_reg.branch_taken <= signals.branch_taken;
        signals_reg.flush_delay <= signals.flush_delay;
        signals_reg.rs1_addr <= signals.rs1_addr;
        signals_reg.rs2_addr <= signals.rs2_addr;
        signals_reg.rd_addr <= signals.rd_addr;
        signals_reg.rs1_val <= signals.rs1_val;
        signals_reg.rs2_val <= signals.rs2_val;
        signals_reg.ex_rd_addr <= signals.ex_rd_addr;
        signals_reg.ex_instr <= signals.ex_instr;
        signals_reg.ex_operand_a <= signals.ex_operand_a;
        signals_reg.ex_operand_b <= signals.ex_operand_b;
        signals_reg.ex_funct <= signals.ex_funct;
        signals_reg.ex_branch_taken <= signals.ex_branch_taken;
        signals_reg.ex_cjump <= signals.ex_cjump;
        signals_reg.ex_c_next_pc <= signals.ex_c_next_pc;
        signals_reg.ex_mem_read <= signals.ex_mem_read;
        signals_reg.ex_mem_write <= signals.ex_mem_write;
        signals_reg.ex_write_en <= signals.ex_write_en;
        signals_reg.ex_rd_src <= signals.ex_rd_src;
        signals_reg.ex_mem_wb_val <= signals.ex_mem_wb_val;
        signals_reg.ex_mem_mem_data <= signals.ex_mem_mem_data;
        signals_reg.ex_mem_address <= signals.ex_mem_address;
        signals_reg.ex_mem_rd_addr <= signals.ex_mem_rd_addr;
        signals_reg.wb_rd_addr <= signals.wb_rd_addr;
        signals_reg.wb_en <= signals.wb_en;
        signals_reg.wb_val <= signals.wb_val;
        signals_reg.mem_wb_val <= signals.mem_wb_val;
    end

    reg [6:0] oam_sprite_index = 7'b0;
    wire [31:0] oam_sprite_data;
    wire [35:0] palette_data;
    wire [9:0] sprite_h_pos = oam_sprite_data[9:0];
    wire [8:0] sprite_v_pos = oam_sprite_data[18:10];
    wire [6:0] sprite_tile_idx = oam_sprite_data[25:19];
    wire [1:0] sprite_palette = oam_sprite_data[27:26];

    core core_inst(
        .clk(pix_clk),
        .rst(rst),
        .enable((h_count == 0 && v_count == 0 && (btnR || rising_btnU)) || btnD || sw[15]),
        .dbg(signals),
        .oam_addr(oam_sprite_index),
        .oam_data(oam_sprite_data),
        .palette_addr(sprite_palette),
        .palette_data(palette_data)
    );

    always @(posedge pix_clk)
        led <= signals.regfile[1][15:0];

    // TEXT
    wire [10:0] char_full = text_buffer[text_row_offset + h_char_addr];
    wire is_template = char_full[10];
    wire [6:0] tmpl_id = char_full[9:3];
    wire [2:0] tmpl_nib = char_full[2:0];
    wire [31:0] signal_value;
    id_case id_case_inst(.signals(signals_reg), .id(tmpl_id), .value(signal_value));
    wire [3:0] nibble = signal_value[tmpl_nib*4 +: 4];
    wire [7:0] hex_ascii = (nibble < 4'd10) ? (8'h30 + {4'b0, nibble})
                                             : (8'h37 + {4'b0, nibble});
    wire [7:0] char_idx = is_template ? hex_ascii : char_full[7:0];
    wire text_color_bit = font_rom[{char_idx, v_count[2:0]}][h_pixel_cnt];

    // OAM
    (* rom_style = "block" *) reg [1:0] sprite_rom [127:0][15:0][15:0];
    initial begin
        for (int i = 0; i < 128; i++) begin
            for (int j = 0; j < 16; j++) begin
                for (int k = 0; k < 16; k++) begin
                    sprite_rom[i][j][k] = (i == 1) ? 2'd1 : (i == 2) ? 2'd2 : 2'b0;
                end
            end
        end
    end
    wire in_oam_space = (h_count >= 32'd1280 - 32'd640) && (h_count < 32'd1280) && (v_count >= 32'd0) && (v_count < 32'd480);

    // double buffer
    (* ram_style = "block" *) reg [11:0] oam_line_buffer [1:0][639:0];
    reg [1:0][639:0] valid_bits;
    reg scanning_sprite = 1'b0;
    reg scanning_sprite_prev = 1'b0;
    reg [3:0] scanning_progress = 4'b0;
    reg active_frame = 1'b0;  // which one is being WRITTEN to; not displayed
    reg [5:0] prev_pixel_color = 6'b0;
    wire [9:0] oam_h_count = h_count - 12'd640;

    wire is_sprite_active = (v_count+1 >= sprite_v_pos) && (v_count+1 < sprite_v_pos + 8'd16) && (sprite_tile_idx != 7'b0);

    wire [1:0] comb_pixel = sprite_rom[sprite_tile_idx][v_count+1 - sprite_v_pos][scanning_progress];
    
    // buffer writing logic
    always_ff @(posedge pix_clk) begin
        if (h_count == H_TOTAL-1) begin
            active_frame <= ~active_frame;
            valid_bits[~active_frame] <= 640'b0;
            oam_sprite_index <= 7'b0;
            scanning_sprite <= 1'b0;
            scanning_progress <= 4'd0;
        end
        else begin
            if (!scanning_sprite && is_sprite_active) begin
                scanning_sprite <= 1'b1;
                scanning_progress <= 4'd0;
            end
            else if (scanning_sprite) begin
                if (scanning_progress == 4'd15) begin
                    scanning_sprite <= 1'b0;
                    if (oam_sprite_index < 7'd127)
                        oam_sprite_index <= oam_sprite_index + 1'b1;
                end else begin
                    scanning_progress <= scanning_progress + 1'b1;
                end
            end
            else if (oam_sprite_index < 7'd127) begin
                oam_sprite_index <= oam_sprite_index + 1'b1;
            end

            if (scanning_sprite) begin
                if (comb_pixel != 2'b0 && (sprite_h_pos + scanning_progress) < 10'd640) begin
                    valid_bits[active_frame][sprite_h_pos + scanning_progress] <= 1'b1;
                    case (comb_pixel)
                        2'd1: oam_line_buffer[active_frame][sprite_h_pos + scanning_progress] <= palette_data[11:0];
                        2'd2: oam_line_buffer[active_frame][sprite_h_pos + scanning_progress] <= palette_data[23:12];
                        2'd3: oam_line_buffer[active_frame][sprite_h_pos + scanning_progress] <= palette_data[35:24];
                    endcase
                end
            end
        end
    end

    // buffer reading logic
    wire [11:0] oam_line_buffer_out = valid_bits[~active_frame][oam_h_count] ? oam_line_buffer[~active_frame][oam_h_count] : 12'b0;

    // VGA OUTPUT

    wire [3:0] color_r = in_oam_space ? oam_line_buffer_out[11:8] : {4{text_color_bit}};
    wire [3:0] color_g = in_oam_space ? oam_line_buffer_out[7:4] : {4{text_color_bit}};
    wire [3:0] color_b = in_oam_space ? oam_line_buffer_out[3:0] : {4{text_color_bit}};
    
    always_ff @(posedge pix_clk) begin
        if (rst)
            vgaRed <= 4'b0;
        else begin
            vgaRed <= display_en ? color_r : 4'h0;
            vgaGreen <= display_en ? color_g : 4'h0;
            vgaBlue <= display_en ? color_b : 4'h0;
        end
    end
    
endmodule
