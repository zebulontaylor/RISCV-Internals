#!/usr/bin/env python3
"""Convert text/markdown input with {{signal}} templates into a Vivado .mem file
for a 213x90 x 11-bit text buffer, and generate id_case.sv."""

import json
import math
import os
import re
import sys
import xml.etree.ElementTree as ET
from rich.console import Console
from rich.markdown import Markdown
from rich.layout import Layout
from rich.panel import Panel

COLS = 213
ROWS = 90
FILL = 0x20  # space

# Unicode Private Use Area (PUA) blocks we use to smuggle signal lengths through rich's layout
PUA_START = 0xE000
PUA_CONTINUE = 0xE800

TEMPLATE_RE = re.compile(r"\{\{\s*(\w+)\s*\}\}")

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

# Map standard Unicode box-drawing to your VGA Font codes (approximate fallback mappings)
BOX_MAP = {
    ord('┌'): 0x18,
    ord('┏'): 0x18,
    ord('─'): 0x17,
    ord('━'): 0x17,
    ord('│'): 0x16,
    ord('┃'): 0x16,
    ord('└'): 0x1A,
    ord('┗'): 0x1A,
    ord('┐'): 0x19,  
    ord('┓'): 0x19,  
    ord('┘'): 0x1B,  
    ord('┛'): 0x1B,  
    ord('├'): 0x14,
    ord('┣'): 0x14,
    ord('┤'): 0x13,
    ord('┫'): 0x13,
    ord('┬'): 0x12,
    ord('┴'): 0x11,
    ord('┼'): 0x15,
    ord('╭'): 0x18,
    ord('╮'): 0x19,
    ord('╰'): 0x1A,
    ord('╯'): 0x1B,
}

def load_signals(json_path):
    with open(json_path) as f:
        return json.load(f)

def render_layout(text, signals):
    """Pass 1 & 2: Substitute templates with exactly sized dummy characters, then render layout with rich."""
    def substitute(match):
        name = match.group(1)
        sig = signals.get(name)
        if not sig:
            raise ValueError(f"Unknown signal '{name}' — not in src2id.json")
        sid = sig["id"]
        nibbles = math.ceil(sig["size"] / 4)
        
        # Output exactly `nibbles` string length: First character is the signal ID, rest is stuffing.
        return chr(PUA_START + sid) + chr(PUA_CONTINUE) * (nibbles - 1)

    processed_text = TEMPLATE_RE.sub(substitute, text)
    
    def build_layout(node):
        ratio = int(node.attrib.get('ratio', 1))
        size = node.attrib.get('size')
        if size is not None:
            size = int(size)
            
        name = node.attrib.get('name', node.tag)
        
        if node.tag.lower() == 'panel':
            content = "".join(node.itertext()).strip()
            renderable = Markdown(content) if ("#" in content or "|" in content) else content
            
            title = node.attrib.get('title')
            if title:
                renderable = Panel(renderable, title=title, expand=True)
                
            return Layout(renderable, name=name, ratio=ratio, size=size)
            
        layout = Layout(name=name, ratio=ratio, size=size)
        children_layouts = [build_layout(child) for child in node]
        
        if node.tag.lower() == 'row':
            layout.split_row(*children_layouts)
        else:
            layout.split_column(*children_layouts)
            
        return layout

    # Render with rich using explicit width AND height so Layouts expand perfectly
    console = Console(width=COLS, height=ROWS, color_system=None, force_terminal=False, force_jupyter=False)
    with console.capture() as capture:
        if "<Row>" in processed_text or "<Column>" in processed_text or "<Layout>" in processed_text:
            try:
                root = ET.fromstring(f"<Root>{processed_text}</Root>")
                if len(root) == 1:
                    main_layout = build_layout(root[0])
                else:
                    main_layout = Layout()
                    main_layout.split_column(*[build_layout(child) for child in root])
                console.print(main_layout)
            except ET.ParseError as e:
                import sys
                sys.stderr.write(f"XML Parse Error in input markdown: {e}\n")
                sys.exit(1)
        elif "=== COLUMN ===" in processed_text:
            parts = [p.strip() for p in processed_text.split("=== COLUMN ===")]
            renderables = []
            for p in parts:
                if p.startswith("#") or "|" in p:
                    renderables.append(Markdown(p))
                else:
                    renderables.append(p)
            console.print(Columns(renderables, expand=True))
        elif text.strip().startswith("#") or "|" in text:
            console.print(Markdown(processed_text))
        else:
            console.print(processed_text)
    
    print(capture.get())
    return capture.get()

def expand_templates(rendered_text, signals):
    """Pass 3: Scan string for smuggler characters and map standard box-drawing characters."""
    signals_by_id = {s["id"]: s for s in signals.values()}
    used_ids = set()
    result = []
    
    for line in rendered_text.split('\n'):
        row = []
        skip = 0
        for ch in line:
            if skip > 0:
                skip -= 1
                continue
                
            c = ord(ch)
            
            # Did we hit our start signal chunk?
            if PUA_START <= c < PUA_CONTINUE:
                sid = c - PUA_START
                sig = signals_by_id[sid]
                nibbles = math.ceil(sig["size"] / 4)
                used_ids.add(sid)
                
                # MSN first (nibble_offset = nibbles-1 down to 0)
                for nib in range(nibbles - 1, -1, -1):
                    row.append((1 << 10) | (sid << 3) | nib)
                skip = nibbles - 1
                
            # Hardware box-drawing mapping
            elif c in BOX_MAP:
                row.append(BOX_MAP[c])
                
            # Maintain backward compatibility with explicit Control Codes / block indices
            elif 0x2400 <= c <= 0x241F:
                row.append(c - 0x2400)
            elif 0x257F <= c <= 0x25A0:
                row.append((c - 0x257F) + 127)
                
            # Standard ASCII handling
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
    src = sys.argv[1] if len(sys.argv) > 1 else "data/input.md"
    mem_out = sys.argv[2] if len(sys.argv) > 2 else "mem/text_buffer.mem"
    sv_out = sys.argv[3] if len(sys.argv) > 3 else os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        "RISCV_Internals.srcs", "sources_1", "new", "id_case.sv")
    id_json = sys.argv[4] if len(sys.argv) > 4 else os.path.join(
        os.path.dirname(os.path.dirname(__file__)), "data", "src2id.json")

    signals = load_signals(id_json)

    if src == "-":
        text = sys.stdin.read()
    else:
        # Fall back to input.txt if input.md doesn't exist but the user hasn't supplied an arg
        if not os.path.exists(src) and src == "input.md" and os.path.exists("input.txt"):
            src = "input.txt"
        with open(src) as f:
            text = f.read()

    rendered = render_layout(text, signals)
    rows, used_ids = expand_templates(rendered, signals)

    # Truncate / pad to grid
    rows = rows[:ROWS]

    with open(mem_out, "w") as f:
        for r in range(ROWS):
            row = rows[r] if r < len(rows) else []
            for c in range(COLS):
                val = row[c] if c < len(row) else FILL
                # Hard mask the top-right text to pure spaces (0x20) for the 480p CPU area!
                # Since 107 cols x 60 rows perfectly overlays 640x480 hardware pixels.
                if r < 60 and c >= 106:
                    val = 0x20
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