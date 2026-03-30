---
description: Compile C to Vivado .mem
---
This workflow compiles `program.c` into raw machine code and converts it to `prog.mem`.

// turbo-all
1. Compile the C code to an ELF object file:
```bash
clang --target=riscv32 -march=rv32i -mabi=ilp32 -mno-relax -O3 -c program.c -o program.o
```

2. Link the object into a fully resolved ELF using the custom linker script:
```bash
ld.lld -T link.ld program.o -o program.elf
```

3. Extract the raw binary machine code:
```bash
llvm-objcopy -O binary program.elf program.bin
```

4. Convert the binary to the `prog.mem` file:
```bash
python3 bin2mem.py program.bin prog.mem
```
