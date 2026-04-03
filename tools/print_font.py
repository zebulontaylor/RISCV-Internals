#!/usr/bin/env python3
import sys

def main():
    font_file = sys.argv[1] if len(sys.argv) > 1 else 'mem/font.mem'
    try:
        with open(font_file, 'r') as f:
            lines = []
            for l in f:
                l = l.strip()
                if l and not l.startswith('//') and not l.startswith('@'):
                    # if there are comments after the data, strip them out too
                    val = l.split()[0]
                    lines.append(val)
    except FileNotFoundError:
        print(f"Error: {font_file} not found.")
        sys.exit(1)

    # font.mem contains hex values, one per line
    font_data = [int(x, 16) for x in lines]
    
    if len(font_data) != 2048:
        print(f"Warning: Expected 2048 entries in {font_file}, found {len(font_data)}.")

    num_chars = len(font_data) // 8
    for i in range(num_chars):
        if i < 32:
            # Map 0-31 to Unicode Control Pictures (␀, ␁, ␂...)
            char = chr(0x2400 + i)
        elif 127 <= i <= 160:
            # Map unprintable 127-160 to Unicode Box Drawing and Block Elements for visualization
            char = chr(0x2500 + i)
        elif 32 <= i <= 126 or 161 <= i <= 255:
            char = chr(i)
        else:
            char = '?'
        print(f"--- Character {i} (0x{i:02X}) '{char}' ---")
        for r in range(8):
            val = font_data[i * 8 + r]
            row_str = ""
            for bit in range(5, -1, -1):
                if (val & (1 << bit)):
                    row_str += "█"
                else:
                    row_str += "."
            print(row_str)
        print()

if __name__ == '__main__':
    main()
