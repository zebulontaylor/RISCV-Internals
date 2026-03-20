`timescale 1ns / 1ps

module id_case (
    internal_signals signals,
    input [6:0] id,
    output reg [31:0] value
);
    always_comb begin
        case(id)
            7'd1: value = signals.regfile[0];
            7'd2: value = signals.regfile[1];
            7'd3: value = signals.regfile[2];
            7'd4: value = signals.regfile[3];
            7'd5: value = signals.regfile[4];
            7'd6: value = signals.regfile[5];
            7'd7: value = signals.regfile[6];
            7'd8: value = signals.regfile[7];
            7'd9: value = signals.regfile[8];
            7'd10: value = signals.regfile[9];
            7'd11: value = signals.regfile[10];
            7'd12: value = signals.regfile[11];
            7'd13: value = signals.regfile[12];
            7'd14: value = signals.regfile[13];
            7'd15: value = signals.regfile[14];
            7'd16: value = signals.regfile[15];
            7'd17: value = signals.regfile[16];
            7'd18: value = signals.regfile[17];
            7'd19: value = signals.regfile[18];
            7'd20: value = signals.regfile[19];
            7'd21: value = signals.regfile[20];
            7'd22: value = signals.regfile[21];
            7'd23: value = signals.regfile[22];
            7'd24: value = signals.regfile[23];
            7'd25: value = signals.regfile[24];
            7'd26: value = signals.regfile[25];
            7'd27: value = signals.regfile[26];
            7'd28: value = signals.regfile[27];
            7'd29: value = signals.regfile[28];
            7'd30: value = signals.regfile[29];
            7'd31: value = signals.regfile[30];
            7'd32: value = signals.regfile[31];
            7'd33: value = signals.stall;
            7'd34: value = signals.fetch_stage_pc;
            7'd35: value = signals.if_id_instr;
            7'd36: value = signals.if_id_pc;
            7'd37: value = signals.id_operand_a;
            7'd38: value = signals.id_operand_b;
            7'd39: value = signals.id_read_rs1;
            7'd40: value = signals.id_read_rs2;
            7'd41: value = signals.id_write_en;
            7'd42: value = signals.id_rd_src;
            7'd43: value = signals.id_jump;
            7'd44: value = signals.id_cjump;
            7'd45: value = signals.id_mem_read;
            7'd46: value = signals.id_mem_write;
            7'd47: value = signals.id_pc_out;
            7'd48: value = signals.id_c_next_pc;
            7'd49: value = signals.id_instr;
            7'd50: value = signals.alu_result;
            7'd51: value = signals.funct;
            7'd52: value = signals.branch_taken;
            7'd53: value = signals.flush_delay;
            7'd54: value = signals.rs1_addr;
            7'd55: value = signals.rs2_addr;
            7'd56: value = signals.rd_addr;
            7'd57: value = signals.rs1_val;
            7'd58: value = signals.rs2_val;
            7'd59: value = signals.ex_rd_addr;
            7'd60: value = signals.ex_instr;
            7'd61: value = signals.ex_operand_a;
            7'd62: value = signals.ex_operand_b;
            7'd63: value = signals.ex_funct;
            7'd64: value = signals.ex_branch_taken;
            7'd65: value = signals.ex_cjump;
            7'd66: value = signals.ex_mem_read;
            7'd67: value = signals.ex_mem_write;
            7'd68: value = signals.ex_write_en;
            7'd69: value = signals.ex_rd_src;
            7'd70: value = signals.ex_c_next_pc;
            7'd71: value = signals.ex_mem_wb_val;
            7'd72: value = signals.ex_mem_mem_data;
            7'd73: value = signals.ex_mem_address;
            7'd74: value = signals.ex_mem_rd_addr;
            7'd75: value = signals.wb_rd_addr;
            7'd76: value = signals.wb_en;
            7'd77: value = signals.wb_val;
            7'd78: value = signals.mem_wb_val;
            default: value = 32'd0;
        endcase
    end
endmodule
