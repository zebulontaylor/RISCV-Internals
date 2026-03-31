#!/bin/bash
set -e
clang --target=riscv32 -march=rv32i -mabi=ilp32 -mno-relax -O3 -c crt0.s -o crt0.o
clang --target=riscv32 -march=rv32i -mabi=ilp32 -mno-relax -O3 -c program.c -o program.o
ld.lld -T link.ld crt0.o program.o -o program.elf
llvm-objcopy -O binary program.elf program.bin
python3 bin2mem.py program.bin prog.mem

if [[ ! " $* " == *" --debug "* ]]; then
  rm -f crt0.o program.o program.elf program.bin
fi