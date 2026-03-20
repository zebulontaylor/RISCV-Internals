#!/usr/bin/env python3
"""Minimal RV32I assembler → Vivado .mem file.

Supports the instruction subset implemented by core.sv:
  R-type:  add sub sll slt sltu xor srl sra or and
  I-type:  addi slti sltiu xori ori andi slli srli srai
  Load:    lw
  Store:   sw
  Branch:  beq bne blt bge bltu bgeu
  Jump:    jal jalr
  Upper:   lui auipc
  Pseudo:  nop li mv not neg j ret
           beqz bnez blez bgez bltz bgtz

Labels: 'name:' on its own or prefixing an instruction.
Comments: # or // to end of line.

Usage: python3 asm2mem.py prog.s [out.mem]
"""

import re
import sys

# ── register aliases ──────────────────────────────────────────────
REG_ALIASES = {f"x{i}": i for i in range(32)}
REG_ALIASES.update({
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
    "t0": 5, "t1": 6, "t2": 7,
    "s0": 8, "fp": 8, "s1": 9,
    **{f"a{i}": 10 + i for i in range(8)},
    **{f"s{i}": 16 + i for i in range(2, 12)},
    **{f"t{i}": 25 + i for i in range(3, 7)},
})

def reg(s):
    s = s.strip().lower()
    r = REG_ALIASES.get(s)
    if r is None:
        raise ValueError(f"bad register: {s}")
    return r

def imm(s, labels, pc, bits, signed=True):
    """Parse an immediate value or label reference."""
    s = s.strip()
    if s in labels:
        return labels[s] - pc  # PC-relative
    val = int(s, 0)
    lo = -(1 << (bits - 1)) if signed else 0
    hi = (1 << (bits - 1)) - 1 if signed else (1 << bits) - 1
    if val < lo or val > hi:
        raise ValueError(f"immediate {val} out of range [{lo}, {hi}]")
    return val & ((1 << bits) - 1)

def uimm(s, labels, pc, bits):
    return imm(s, labels, pc, bits, signed=False)

# ── encoding helpers ──────────────────────────────────────────────
def r_type(funct7, rs2, rs1, funct3, rd):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x33

def i_type(immv, rs1, funct3, rd, opcode=0x13):
    return ((immv & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def s_type(immv, rs2, rs1, funct3=0x2):
    immv &= 0xFFF
    return ((immv >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((immv & 0x1F) << 7) | 0x23

def b_type(immv, rs2, rs1, funct3):
    immv &= 0x1FFF
    return (((immv >> 12) & 1) << 31) | (((immv >> 5) & 0x3F) << 25) | \
           (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | \
           (((immv >> 1) & 0xF) << 8) | (((immv >> 11) & 1) << 7) | 0x63

def j_type(immv, rd):
    immv &= 0x1FFFFF
    return (((immv >> 20) & 1) << 31) | (((immv >> 1) & 0x3FF) << 21) | \
           (((immv >> 11) & 1) << 20) | (((immv >> 12) & 0xFF) << 12) | \
           (rd << 7) | 0x6F

def u_type(immv, rd, opcode):
    return ((immv & 0xFFFFF) << 12) | (rd << 7) | opcode

# ── R-type table: mnemonic → (funct7, funct3) ────────────────────
R_OPS = {
    "add": (0x00, 0), "sub": (0x20, 0), "sll": (0x00, 1),
    "slt": (0x00, 2), "sltu": (0x00, 3), "xor": (0x00, 4),
    "srl": (0x00, 5), "sra": (0x20, 5), "or": (0x00, 6), "and": (0x00, 7),
}

# ── I-type ALU table: mnemonic → funct3 ──────────────────────────
I_OPS = {
    "addi": 0, "slti": 2, "sltiu": 3, "xori": 4, "ori": 6, "andi": 7,
}
I_SHIFT = {"slli": (0, 1), "srli": (0, 5), "srai": (0x20, 5)}

# ── Branch table: mnemonic → funct3 ──────────────────────────────
B_OPS = {
    "beq": 0, "bne": 1, "blt": 4, "bge": 5, "bltu": 6, "bgeu": 7,
}

# ── offset(reg) parser for lw/sw ─────────────────────────────────
OFFSET_RE = re.compile(r"(-?\w+)\((\w+)\)")

def parse_offset_reg(arg, labels, pc):
    m = OFFSET_RE.match(arg.strip())
    if m:
        return imm(m.group(1), labels, pc, 12), reg(m.group(2))
    raise ValueError(f"expected offset(reg), got: {arg}")

# ── two-pass assembler ────────────────────────────────────────────
COMMENT_RE = re.compile(r"(#|//).*")
LABEL_RE = re.compile(r"^(\w+):\s*")

def tokenize(src):
    """Return list of (label_or_None, mnemonic, args_string) per instruction."""
    lines = []
    for raw in src.splitlines():
        line = COMMENT_RE.sub("", raw).strip()
        if not line:
            continue
        label = None
        m = LABEL_RE.match(line)
        if m:
            label = m.group(1)
            line = line[m.end():].strip()
        if not line:
            lines.append((label, None, None))
        else:
            parts = line.split(None, 1)
            mn = parts[0].lower()
            args = parts[1] if len(parts) > 1 else ""
            lines.append((label, mn, args))
    return lines


def expand_pseudo(mn, args):
    """Expand pseudo-instructions into real instructions.
    Returns list of (mnemonic, args_string)."""
    a = [x.strip() for x in args.split(",") if x.strip()] if args else []
    if mn == "nop":
        return [("addi", "x0, x0, 0")]
    if mn == "li":
        return [("addi", f"{a[0]}, x0, {a[1]}")]
    if mn == "mv":
        return [("addi", f"{a[0]}, {a[1]}, 0")]
    if mn == "not":
        return [("xori", f"{a[0]}, {a[1]}, -1")]
    if mn == "neg":
        return [("sub", f"{a[0]}, x0, {a[1]}")]
    if mn == "j":
        return [("jal", f"x0, {a[0]}")]
    if mn == "ret":
        return [("jalr", "x0, x1, 0")]
    if mn == "beqz":
        return [("beq", f"{a[0]}, x0, {a[1]}")]
    if mn == "bnez":
        return [("bne", f"{a[0]}, x0, {a[1]}")]
    if mn == "blez":
        return [("bge", f"x0, {a[0]}, {a[1]}")]
    if mn == "bgez":
        return [("bge", f"{a[0]}, x0, {a[1]}")]
    if mn == "bltz":
        return [("blt", f"{a[0]}, x0, {a[1]}")]
    if mn == "bgtz":
        return [("blt", f"x0, {a[0]}, {a[1]}")]
    return [(mn, args)]


def assemble(src):
    toks = tokenize(src)

    # Pass 1: assign addresses, collect labels
    labels = {}
    expanded = []  # (pc, mnemonic, args)
    pc = 0
    for label, mn, args in toks:
        if label:
            labels[label] = pc
        if mn is None:
            continue
        for emn, eargs in expand_pseudo(mn, args):
            expanded.append((pc, emn, eargs))
            pc += 4

    # Pass 2: encode
    words = []
    for pc, mn, args in expanded:
        a = [x.strip() for x in args.split(",") if x.strip()] if args else []
        try:
            word = encode(mn, a, labels, pc)
        except Exception as e:
            raise ValueError(f"pc={pc:#x}: {mn} {args} — {e}") from e
        words.append(word)
    return words


def encode(mn, a, labels, pc):
    if mn in R_OPS:
        f7, f3 = R_OPS[mn]
        return r_type(f7, reg(a[2]), reg(a[1]), f3, reg(a[0]))
    if mn in I_OPS:
        return i_type(imm(a[2], labels, pc, 12), reg(a[1]), I_OPS[mn], reg(a[0]))
    if mn in I_SHIFT:
        f7, f3 = I_SHIFT[mn]
        shamt = uimm(a[2], labels, pc, 5)
        return i_type((f7 << 5) | shamt, reg(a[1]), f3, reg(a[0]))
    if mn == "lw":
        off, rs1 = parse_offset_reg(a[1], labels, pc)
        return i_type(off, rs1, 0x2, reg(a[0]), opcode=0x03)
    if mn == "sw":
        off, rs1 = parse_offset_reg(a[1], labels, pc)
        return s_type(off, reg(a[0]), rs1)
    if mn in B_OPS:
        return b_type(imm(a[2], labels, pc, 13), reg(a[1]), reg(a[0]), B_OPS[mn])
    if mn == "jal":
        if len(a) == 1:  # jal label (rd=ra implicit)
            return j_type(imm(a[0], labels, pc, 21), 1)
        return j_type(imm(a[1], labels, pc, 21), reg(a[0]))
    if mn == "jalr":
        if len(a) == 3:
            return i_type(imm(a[2], labels, pc, 12), reg(a[1]), 0, reg(a[0]), opcode=0x67)
        # jalr rd, offset(rs1)
        off, rs1 = parse_offset_reg(a[1], labels, pc)
        return i_type(off, rs1, 0, reg(a[0]), opcode=0x67)
    if mn == "lui":
        return u_type(imm(a[1], labels, pc, 20, signed=False), reg(a[0]), 0x37)
    if mn == "auipc":
        return u_type(imm(a[1], labels, pc, 20, signed=False), reg(a[0]), 0x17)
    raise ValueError(f"unknown mnemonic: {mn}")


def main():
    src_path = sys.argv[1] if len(sys.argv) > 1 else "-"
    out_path = sys.argv[2] if len(sys.argv) > 2 else "prog.mem"

    if src_path == "-":
        text = sys.stdin.read()
    else:
        with open(src_path) as f:
            text = f.read()

    words = assemble(text)
    with open(out_path, "w") as f:
        for w in words:
            f.write(f"{w:08X}\n")

    print(f"Assembled {len(words)} instructions to {out_path}")


if __name__ == "__main__":
    main()
