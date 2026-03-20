# Collatz conjecture: starting from N, repeatedly apply
#   if even: n = n / 2
#   if odd:  n = 3n + 1
# until n == 1.
#
# Registers:
#   x1 = n (current value)
#   x2 = step count
#   x3 = scratch

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
