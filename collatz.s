# Collatz conjecture: starting from N, repeatedly apply
#   if even: n = n / 2
#   if odd:  n = 3n + 1
# until n == 1.
#
# Registers:
#   x1 = n (current value)
#   x2 = step count
#   x3 = scratch

    # Setup Palette 0 (White/Red)
    addi x4, x0, 1024       # 0x400
    lui  x5, 0x00F01
    addi x5, x5, -1         # 0x00F00FFF
    sw   x5, 0(x4)

    # Setup Palette 1 (Green/Blue)
    lui  x5, 0x0000F
    addi x5, x5, 240        # 0x0000F0F0
    sw   x5, 4(x4)

    # Setup Sprite 0 (tile=1, x=100, y=100, palette=0)
    addi x4, x0, 512        # 0x200
    lui  x5, 0x00099
    addi x5, x5, 100        # 0x00099064
    sw   x5, 0(x4)

    # Setup Sprite 1 (tile=2, x=200, y=100, palette=1)
    lui  x5, 0x04119
    addi x5, x5, 200        # 0x041190C8
    sw   x5, 4(x4)

    addi x1, x0, 27      # n = 27 (takes 111 steps)
    addi x2, x0, 0       # steps = 0

loop:
    addi x3, x0, 1
    beq  x1, x3, done    # if n == 1, stop

    addi x2, x2, 1       # steps++

    andi x3, x1, 1       # x3 = n & 1
    bne  x3, x0, odd     # if odd, branch

    # even: n = n >> 1
    srai x1, x1, 1
    jal  x0, loop

odd:
    # n = 3n + 1
    add  x3, x1, x1      # x3 = 2n
    add  x1, x3, x1      # x1 = 3n
    addi x1, x1, 1       # x1 = 3n + 1
    jal  x0, loop

done:
    jal  x0, done         # spin
