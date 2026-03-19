#!/usr/bin/env python3
"""Convert text input into a Vivado .mem file for a 213x90 x 7-bit text buffer."""

import sys

COLS = 213
ROWS = 90
FILL = 0x20  # space

def main():
    src = sys.argv[1] if len(sys.argv) > 1 else "-"
    out = sys.argv[2] if len(sys.argv) > 2 else "text_buffer.mem"
    if src == "-":
        text = sys.stdin.read()
    else:
        with open(src) as f:
            text = f.read()
 
    # Wrap lines: split each input line into COLS-wide chunks
    rows = []
    for line in text.split("\n"):
        if not line:
            rows.append("")
        else:
            for i in range(0, len(line), COLS):
                rows.append(line[i:i + COLS])
        if len(rows) >= ROWS:
            break
    rows = rows[:ROWS]
 
    with open(out, "w") as f:
        for row in range(ROWS):
            line = rows[row] if row < len(rows) else ""
            for col in range(COLS):
                ch = ord(line[col]) & 0x7F if col < len(line) else FILL
                f.write(f"{ch:02X}\n")
 
    total = ROWS * COLS
    print(f"Wrote {total} entries ({ROWS} rows x {COLS} cols, 7-bit) to {out}")
 
if __name__ == "__main__":
    main()
 