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
    beq  x1, x3, collatz_done    # if n == 1, stop

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

collatz_done:
    # Setup Palette 0 (White/Red) at 0x400000
    lui  x4, 0x400       # x4 = 0x400000
    lui  x5, 0x00F01
    addi x5, x5, -1      # 0x00F00FFF
    sw   x5, 0(x4)

    # Setup Palette 1 (Green/Blue) at 0x400004
    lui  x5, 0x0000F
    addi x5, x5, 240     # 0x0000F0F0
    sw   x5, 4(x4)

    # Sprite state initialization
    addi x10, x0, 100  # s0_x = 100
    addi x11, x0, 100  # s0_y = 100
    addi x12, x0, 1    # s0_dx = 1
    addi x13, x0, 1    # s0_dy = 1

    addi x14, x0, 200  # s1_x = 200
    addi x15, x0, 100  # s1_y = 100
    addi x16, x0, -1   # s1_dx = -1
    addi x17, x0, 1    # s1_dy = 1

    addi x28, x0, 624  # max_x (640 - 16)
    addi x29, x0, 464  # max_y (480 - 16)

    # x18 = OAM base = 0x800000
    lui  x18, 0x800

anim_loop:
    # Update s0_x
    add x10, x10, x12
    # Bounce x
    beq x10, x0,  s0_bounce_x_left
    beq x10, x28, s0_bounce_x_right
    jal x0, s0_x_done
s0_bounce_x_left:
    addi x12, x0, 1
    jal x0, s0_x_done
s0_bounce_x_right:
    addi x12, x0, -1
s0_x_done:

    # Update s0_y
    add x11, x11, x13
    # Bounce y
    beq x11, x0,  s0_bounce_y_top
    beq x11, x29, s0_bounce_y_bottom
    jal x0, s0_y_done
s0_bounce_y_top:
    addi x13, x0, 1
    jal x0, s0_y_done
s0_bounce_y_bottom:
    addi x13, x0, -1
s0_y_done:

    # Pack and write Sprite 0 to OAM[0] at 0x800000
    # oam_sprite_data = (palette << 26) | (tile << 19) | (v_pos << 10) | h_pos
    # palette=0, tile=1 => 1 << 19 = 0x80000
    lui x5, 0x00080      # 0x00080000
    slli x6, x11, 10
    add x5, x5, x6
    add x5, x5, x10
    sw x5, 0(x18)        # OAM[0]

    # Update s1_x
    add x14, x14, x16
    # Bounce x
    beq x14, x0,  s1_bounce_x_left
    beq x14, x28, s1_bounce_x_right
    jal x0, s1_x_done
s1_bounce_x_left:
    addi x16, x0, 1
    jal x0, s1_x_done
s1_bounce_x_right:
    addi x16, x0, -1
s1_x_done:

    # Update s1_y
    add x15, x15, x17
    # Bounce y
    beq x15, x0,  s1_bounce_y_top
    beq x15, x29, s1_bounce_y_bottom
    jal x0, s1_y_done
s1_bounce_y_top:
    addi x17, x0, 1
    jal x0, s1_y_done
s1_bounce_y_bottom:
    addi x17, x0, -1
s1_y_done:

    # Pack and write Sprite 1 to OAM[1] at 0x800004
    # palette=1, tile=2 => (1 << 26) | (2 << 19) = 0x04000000 | 0x00100000 = 0x04100000
    lui x5, 0x04100      # 0x04100000
    slli x6, x15, 10
    add x5, x5, x6
    add x5, x5, x14
    sw x5, 4(x18)        # OAM[1]

    # Delay loop to slow down animation
    lui x6, 0x00020      # adjust as needed
    addi x7, x0, 0
delay_loop:
    addi x7, x7, 1
    bne x7, x6, delay_loop

    jal x0, anim_loop
