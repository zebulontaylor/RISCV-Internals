import json

with open("src2id.json", "r") as f:
    data = json.load(f)

current_id = max(v["id"] for v in data.values())

signals = [
    ("stall", 1),
    ("fetch_stage_pc", 32),
    ("if_id_instr", 32),
    ("if_id_pc", 32),
    ("id_operand_a", 32),
    ("id_operand_b", 32),
    ("id_read_rs1", 1),
    ("id_read_rs2", 1),
    ("id_write_en", 1),
    ("id_rd_src", 1),
    ("id_jump", 1),
    ("id_cjump", 1),
    ("id_mem_read", 1),
    ("id_mem_write", 1),
    ("id_pc_out", 32),
    ("id_c_next_pc", 32),
    ("id_instr", 32),
    ("alu_result", 32),
    ("funct", 4),
    ("branch_taken", 1),
    ("flush_delay", 1),
    ("rs1_addr", 5),
    ("rs2_addr", 5),
    ("rd_addr", 5),
    ("rs1_val", 32),
    ("rs2_val", 32),
    ("ex_rd_addr", 5),
    ("ex_instr", 32),
    ("ex_operand_a", 32),
    ("ex_operand_b", 32),
    ("ex_funct", 4),
    ("ex_branch_taken", 1),
    ("ex_cjump", 1),
    ("ex_mem_read", 1),
    ("ex_mem_write", 1),
    ("ex_write_en", 1),
    ("ex_rd_src", 1),
    ("ex_c_next_pc", 32),
    ("ex_mem_wb_val", 32),
    ("ex_mem_mem_data", 32),
    ("ex_mem_address", 32),
    ("ex_mem_rd_addr", 5),
    ("wb_rd_addr", 5),
    ("wb_en", 1),
    ("wb_val", 32),
    ("mem_wb_val", 32),
]

for i in range(16, 32):
    rname = f"r{i+1}"
    if rname not in data:
        current_id += 1
        data[rname] = {
            "id": current_id,
            "size": 32,
            "name": f"regfile[{i}]"
        }

for name, size in signals:
    if name not in data:
        current_id += 1
        data[name] = {
            "id": current_id,
            "size": size,
            "name": name
        }

with open("src2id.json", "w") as f:
    json.dump(data, f, indent=4)
