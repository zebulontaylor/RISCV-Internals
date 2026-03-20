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
            7'd33: value = signals.stall;
            7'd34: value = signals.fetch_stage_pc;
            7'd35: value = signals.if_id_instr;
            7'd36: value = signals.if_id_pc;
            7'd37: value = signals.id_operand_a;
            7'd38: value = signals.id_operand_b;
            default: value = 32'd0;
        endcase
    end
endmodule
