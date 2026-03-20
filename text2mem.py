#!/usr/bin/env python3
"""Convert text input with {{signal}} templates into a Vivado .mem file
for a 213x90 x 11-bit text buffer, and generate id_case.sv."""

import json
import math
import os
import re
import sys

COLS = 213
ROWS = 90
FILL = 0x20  # space

TEMPLATE_RE = re.compile(r"\{\{(\w+)\}\}")

SV_TEMPLATE = """\
`timescale 1ns / 1ps

module id_case (
    internal_signals signals,
    input [6:0] id,
    output reg [31:0] value
);
    always_comb begin
        case(id)
%s
            default: value = 32'd0;
        endcase
    end
endmodule
"""


def expand_templates(text, signals):
    """Replace {{name}} tokens with encoded 11-bit template bytes.

    Returns (list of int values per character, set of used signal ids).
    """
    used_ids = set()
    result = []

    for line in text.split("\n"):
        row = []
        pos = 0
        for m in TEMPLATE_RE.finditer(line):
            # Literal text before this match
            for ch in line[pos:m.start()]:
                c = ord(ch)
                if 0x2400 <= c <= 0x241F:
                    row.append(c - 0x2400)
                elif 0x257F <= c <= 0x25A0:
                    row.append((c - 0x257F) + 127)
                else:
                    row.append(c & 0xFF)
            name = m.group(1)
            sig = signals.get(name)
            if sig is None:
                raise ValueError(f"Unknown signal '{name}' — not in src2id.json")
            sid = sig["id"]
            nibbles = math.ceil(sig["size"] / 4)
            used_ids.add(sid)
            # MSN first (nibble_offset = nibbles-1 down to 0)
            for nib in range(nibbles - 1, -1, -1):
                row.append((1 << 10) | (sid << 3) | nib)
            pos = m.end()
        # Literal text after last match
        for ch in line[pos:]:
            c = ord(ch)
            if 0x2400 <= c <= 0x241F:
                row.append(c - 0x2400)
            elif 0x257F <= c <= 0x25A0:
                row.append((c - 0x257F) + 127)
            else:
                row.append(c & 0xFF)
        result.append(row)

    return result, used_ids


def generate_case_entries(signals, used_ids):
    """Generate SV case entries for each used signal."""
    entries = []
    for name, sig in sorted(signals.items(), key=lambda x: x[1]["id"]):
        if sig["id"] not in used_ids:
            continue
        entries.append(f"            7'd{sig['id']}: value = signals.{sig['name']};")
    return "\n".join(entries)


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else "-"
    mem_out = sys.argv[2] if len(sys.argv) > 2 else "text_buffer.mem"
    sv_out = sys.argv[3] if len(sys.argv) > 3 else os.path.join(
        os.path.dirname(__file__),
        "RISCV_Internals.srcs", "sources_1", "new", "id_case.sv")
    id_json = sys.argv[4] if len(sys.argv) > 4 else os.path.join(
        os.path.dirname(__file__), "src2id.json")

    with open(id_json) as f:
        signals = json.load(f)

    if src == "-":
        text = sys.stdin.read()
    else:
        with open(src) as f:
            text = f.read()

    rows, used_ids = expand_templates(text, signals)

    # Truncate / pad to grid
    rows = rows[:ROWS]

    with open(mem_out, "w") as f:
        for r in range(ROWS):
            row = rows[r] if r < len(rows) else []
            for c in range(COLS):
                val = row[c] if c < len(row) else FILL
                f.write(f"{val:03X}\n")

    total = ROWS * COLS
    print(f"Wrote {total} entries ({ROWS}r x {COLS}c, 11-bit) to {mem_out}")

    # Generate id_case.sv
    case_body = generate_case_entries(signals, used_ids)
    with open(sv_out, "w") as f:
        f.write(SV_TEMPLATE % case_body)
    print(f"Wrote {sv_out}")


if __name__ == "__main__":
    main()