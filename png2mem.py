#!/usr/bin/env python3
"""Convert a 16x16 grid font bitmap (6px wide x 8px tall chars, 1px separators) to a Vivado .mem file."""
 
from PIL import Image
import sys
 
CHAR_W = 6
CHAR_H = 8
GRID_COLS = 16
GRID_ROWS = 16
SEP = 1  # 1px separator between cells
THRESHOLD = 128  # pixel > threshold = bright (1)
 
def main():
    src = sys.argv[1] if len(sys.argv) > 1 else "/mnt/user-data/uploads/1773712940706_image.png"
    out = sys.argv[2] if len(sys.argv) > 2 else "/home/claude/font.mem"
 
    img = Image.open(src).convert("L")
 
    with open(out, "w") as f:
        for row in range(GRID_ROWS):
            for col in range(GRID_COLS):
                char_idx = row * GRID_COLS + col
                x0 = col * (CHAR_W + SEP)
                y0 = row * (CHAR_H + SEP)
 
                f.write(f"@{char_idx * CHAR_H:03X}\n")
                for y in range(CHAR_H):
                    bits = 0
                    for x in range(CHAR_W):
                        px = img.getpixel((x0 + x, y0 + y))
                        if px > THRESHOLD:
                            bits |= 1 << (CHAR_W - 1 - x)
                    f.write(f"{bits:02X}\n")
 
    total = GRID_ROWS * GRID_COLS * CHAR_H
    print(f"Wrote {total} bytes ({GRID_ROWS * GRID_COLS} chars x {CHAR_H} rows) to {out}")
 
if __name__ == "__main__":
    main()
 