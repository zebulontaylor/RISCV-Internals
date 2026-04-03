<Layout>
    <Row>
        <!-- Left Side: Dashboard (106 cols wide) -->
        <Column size="106">
            <!-- Header (Exact 3 rows high) -->
            <Panel size="3">
# RISC-V PIPELINE DASHBOARD
            </Panel>

            <!-- Main Content Area -->
            <Row>
                <!-- Registers (Exact 35 cols wide) -->
                <Panel title="Registers" size="35">
| Reg | Value   |
|-----|---------|
| r0  | {{r0}}  |
| r1  | {{r1}}  |
| r2  | {{r2}}  |
| r3  | {{r3}}  |
| r4  | {{r4}}  |
| r5  | {{r5}}  |
| r6  | {{r6}}  |
| r7  | {{r7}}  |
| r8  | {{r8}}  |
| r9  | {{r9}}  |
| r10 | {{r10}} |
| r11 | {{r11}} |
| r12 | {{r12}} |
| r13 | {{r13}} |
| r14 | {{r14}} |
| r15 | {{r15}} |
| r16 | {{r16}} |
| r17 | {{r17}} |
| r18 | {{r18}} |
| r19 | {{r19}} |
| r20 | {{r20}} |
| r21 | {{r21}} |
| r22 | {{r22}} |
| r23 | {{r23}} |
| r24 | {{r24}} |
| r25 | {{r25}} |
| r26 | {{r26}} |
| r27 | {{r27}} |
| r28 | {{r28}} |
| r29 | {{r29}} |
| r30 | {{r30}} |
| r31 | {{r31}} |
                </Panel>

                <!-- Pipeline Display (Remaining 71 cols wide) -->
                <Column>
                    <Panel title="Fetch (IF)" ratio="1">
| Signal | Value | Signal | Value |
|--------|-------|--------|-------|
| Stall        | {{stall}}          | Flush Delay | {{flush_delay}}   |
| IF PC        | {{fetch_stage_pc}} | IF/ID PC    | {{if_id_pc}}      |
|              |                    | IF/ID Instr | {{if_id_instr}}   |
                    </Panel>

                    <Panel title="Decode (ID)" ratio="2">
**Data**
| Signal | Value | Signal | Value |
|--------|-------|--------|-------|
| Instr    | {{id_instr}}     | PC Out   | {{id_pc_out}} |
| RS1 Addr | {{rs1_addr}}     | RS2 Addr | {{rs2_addr}}  |
| RS1 Val  | {{rs1_val}}      | RS2 Val  | {{rs2_val}}   |
| Op A     | {{id_operand_a}} | Op B     | {{id_operand_b}} |
| RD Addr  | {{rd_addr}}      | Funct    | {{funct}}     |
| C Next PC| {{id_c_next_pc}} |          |               |

**Control**
| Signal | Val | Signal | Val | Signal | Val |
|--------|-----|--------|-----|--------|-----|
| Read RS1 | {{id_read_rs1}} | Mem Read | {{id_mem_read}}  | Write En | {{id_write_en}} |
| Read RS2 | {{id_read_rs2}} | Mem Write| {{id_mem_write}} | RD Src   | {{id_rd_src}}   |
| Jump     | {{id_jump}}     | CJump    | {{id_cjump}}     |          |                 |
                    </Panel>
                    
                    <Panel title="Execute (EX)" ratio="2">
**Data**
| Signal | Value | Signal | Value |
|--------|-------|--------|-------|
| Instr    | {{ex_instr}}       | ALU Result | {{alu_result}} |
| Op A     | {{ex_operand_a}}   | Op B       | {{ex_operand_b}} |
| Funct    | {{ex_funct}}       | RD Addr    | {{ex_rd_addr}} |
| C Next PC| {{ex_c_next_pc}}   | Branch Tk  | {{branch_taken}} |

**Control**
| Signal | Val | Signal | Val | Signal | Val |
|--------|-----|--------|-----|--------|-----|
| Mem Read | {{ex_mem_read}}  | Write En  | {{ex_write_en}} | Branch Tk | {{ex_branch_taken}} |
| Mem Writ | {{ex_mem_write}} | RD Src    | {{ex_rd_src}}   | CJump     | {{ex_cjump}} |
                    </Panel>

                    <Row ratio="1">
                        <Panel title="Memory (MEM)">
| Signal | Value |
|--------|-------|
| Address | {{ex_mem_address}} |
| Data    | {{ex_mem_mem_data}} |
| WB Val  | {{ex_mem_wb_val}} |
| RD Addr | {{ex_mem_rd_addr}} |
                        </Panel>

                        <Panel title="Writeback (WB)">
| Signal | Value |
|--------|-------|
| WB En  | {{wb_en}}  |
| Rd Addr| {{wb_rd_addr}} |
| WB Val | {{wb_val}} |
| Mem/WB | {{mem_wb_val}} |
                        </Panel>
                    </Row>
                </Column>
            </Row>
        </Column>

        <!-- Right Side: 480p CPU Draw Area (107 cols remaining) -->
        <Column>
            
            <!-- CPU Draw Area: Exactly 60 rows high! -->
            <Row size="60">
                <!-- Keep empty for CPU drawing (640x480 resolution) -->
            </Row>

            <!-- Bottom Right Menu: remaining 30 rows -->
            <Row>
                <Panel title="RISC-V Quick Reference (RV32I)">
**Instruction Formats**
| Type | 31 .. 25 | 24 .. 20 | 19 .. 15 | 14 .. 12 | 11 .. 7 | 6 .. 0 |
|---|---|---|---|---|---|---|
| **R** | funct7       | rs2 | rs1 | funct3 | rd | opcode |
| **I** | imm[11:0]    |     | rs1 | funct3 | rd | opcode |
| **S** | imm[11:5]    | rs2 | rs1 | funct3 | imm[4:0] | opcode |
| **B** | imm[12\|10:5]| rs2 | rs1 | funct3 | imm[4:1\|11] | opcode |
| **U** | imm[31:12]   |     |     |        | rd | opcode |
| **J** | imm[20\|10:1\|11\|19:12] | | |        | rd | opcode |

**Common Opcodes**
| Opcode  | Type | Desc     | Opcode  | Type | Desc   | Opcode  | Type | Desc     |
|---------|------|----------|---------|------|--------|---------|------|----------|
| 0110011 | R    | ALU Ops  | 0000011 | I    | Loads  | 1100011 | B    | Branches |
| 0010011 | I    | ALU Imm  | 0100011 | S    | Stores | 1101111 | J    | JAL      |
| 0110111 | U    | LUI      | 0010111 | U    | AUIPC  | 1100111 | I    | JALR     |
                </Panel>
            </Row>

        </Column>
    </Row>
</Layout>
