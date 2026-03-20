<Layout>
    <Panel title="Header" ratio="1">
        # RISC-V Pipeline Dashboard
    </Panel>
    <Row ratio="15">
        <!-- Left Panel: Registers -->
        <Panel title="Registers" ratio="3">
| Reg | Value   | Reg | Value   | Reg | Value   | Reg | Value   |
|-----|---------|-----|---------|-----|---------|-----|---------|
| r0  | {{r0}}  | r8  | {{r8}}  | r16 | {{r16}} | r24 | {{r24}} |
| r1  | {{r1}}  | r9  | {{r9}}  | r17 | {{r17}} | r25 | {{r25}} |
| r2  | {{r2}}  | r10 | {{r10}} | r18 | {{r18}} | r26 | {{r26}} |
| r3  | {{r3}}  | r11 | {{r11}} | r19 | {{r19}} | r27 | {{r27}} |
| r4  | {{r4}}  | r12 | {{r12}} | r20 | {{r20}} | r28 | {{r28}} |
| r5  | {{r5}}  | r13 | {{r13}} | r21 | {{r21}} | r29 | {{r29}} |
| r6  | {{r6}}  | r14 | {{r14}} | r22 | {{r22}} | r30 | {{r30}} |
| r7  | {{r7}}  | r15 | {{r15}} | r23 | {{r23}} | r31 | {{r31}} |
        </Panel>

        <!-- Main Pipeline Display -->
        <Column ratio="7">
            
            <!-- Top Section of Pipeline: Fetch & Writeback -->
            <Row ratio="1">
                <Panel title="Fetch (IF)" ratio="1">
| Signal | Value | Signal | Value |
|--------|-------|--------|-------|
| Stall        | {{stall}}          | Flush Delay | {{flush_delay}}   |
| IF PC        | {{fetch_stage_pc}} | IF/ID PC    | {{if_id_pc}}      |
|              |                    | IF/ID Instr | {{if_id_instr}}   |
                </Panel>
                <Panel title="Writeback (WB)" ratio="1">
| Signal | Value | Signal | Value |
|--------|-------|--------|-------|
| WB En  | {{wb_en}}  | WB Rd Addr | {{wb_rd_addr}} |
| WB Val | {{wb_val}} | Mem/WB Val | {{mem_wb_val}} |
                </Panel>
            </Row>

            <!-- Bottom Section of Pipeline: Decode, Execute, Memory -->
            <Row ratio="3">
                
                <Panel title="Decode (ID)" ratio="1">
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
                
                <Panel title="Execute (EX)" ratio="1">
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

                <Panel title="Memory (MEM)" ratio="1">
| Signal | Value |
|--------|-------|
| Address | {{ex_mem_address}} |
| Mem Data| {{ex_mem_mem_data}} |
| WB Val  | {{ex_mem_wb_val}} |
| RD Addr | {{ex_mem_rd_addr}} |
                </Panel>

            </Row>
        </Column>
    </Row>
</Layout>
