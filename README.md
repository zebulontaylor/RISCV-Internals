# RISCV Visualization

This project is an FPGA implementation of a RISCV processor that visualizes its internal state on a VGA display.

## AI Usage Disclosure

I used AI for the generation of testbenches (`*tb.sv`) and for most of the files in `tools/` or `sw/`. I did not use AI for the generation of the core or top level modules.

## Setup

Starter `.mem` files are already generated in the `mem/` directory. To generate new ones, use the following commands:

```bash
./tools/c2mem.sh
./tools/text2mem.py
./tools/png2mem.py
```

Set up Vivado for your FPGA and add the appropriate sources from `RISCV_Internals.srcs`.

## Demo

![Boids Demo](media/boidsdemo.gif)

## Breakdown

### `top.sv`

Handles VGA rendering. Reads from `mem/text_buffer.mem` and `mem/font.mem` to display text, filling in templates from the text buffer with values from the processor's internal state. It also handles the Object Attribute Memory (OAM) rendering.

### `core.sv`

Implements the RISCV processor. It is a 5-stage pipelined processor with support for the RV32I instruction set.

### `tools/bin2mem.py`

Converts a (compiled C) binary to a `.mem` file for the memory. Since the memory is von Neumann, it includes both instructions and data.

### `tools/text2mem.py`

Converts `data/input.md` (which is actually an XML file) to a `.mem` template for the text buffer. It uses `rich` to format the text while looking pretty and to handle the layout.

### `tools/png2mem.py`

Converts a PNG image to a `.mem` file for the font. You should not have to run this unless you change the font.

### `tools/c2mem.sh`

Runs `clang` to compile `sw/program.c` and `sw/crt0.s` to a binary (with the entry point at the start of the binary), then uses `bin2mem.py` to convert it to a `.mem` file for the memory.

### `tools/sim.py`

Can use a compiled binary of `program.c` to visualize the output without needing to resynthesize the FPGA. 