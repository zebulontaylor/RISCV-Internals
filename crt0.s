.section .text.init
.global _start
_start:
    lui  sp, 4          # sp = 0x4000 (top of 16KB unified RAM)
    j main
