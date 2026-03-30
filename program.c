// Collatz + Sprite Animation for Baremetal RISC-V Custom Core
// Compile with:
// clang --target=riscv32 -march=rv32i -mabi=ilp32 -mno-relax -O3 -c program.c -o program.o
// ld.lld -T link.ld program.o -o program.elf
// llvm-objcopy -O binary program.elf program.bin
// python3 bin2mem.py program.bin prog.mem

#include <stdint.h>

// Define memory mapped I/O addresses
#define OAM_PALETTE_BASE ((volatile uint32_t*)0x400)
#define OAM_SPRITE_BASE  ((volatile uint32_t*)0x200)

// Helper to prevent the compiler from optimizing away the delay loop
static inline void delay(uint32_t count) {
    for (volatile uint32_t i = 0; i < count; i++) {
        // Do nothing
    }
}

// Baremetal entry point
void _start() {
    // 1. Collatz calculation
    uint32_t n = 27;
    uint32_t steps = 0;

    while (n != 1) {
        steps++;
        if (n & 1) {
            // odd
            n = (n + n + n) + 1; // 3n + 1 (Avoid multiplication just in case)
        } else {
            // even
            n = n >> 1;
        }
    }

    // 2. Setup Palettes
    // Palette 0: White/Red
    OAM_PALETTE_BASE[0] = 0x00F00FFF;
    // Palette 1: Green/Blue
    OAM_PALETTE_BASE[1] = 0x0000F0F0;

    // 3. Sprite Initialization
    int32_t s0_x = 100, s0_y = 100;
    int32_t s0_dx = 1,  s0_dy = 1;

    int32_t s1_x = 200, s1_y = 100;
    int32_t s1_dx = -1, s1_dy = 1;

    const int32_t max_x = 624; // 640 - 16
    const int32_t max_y = 464; // 480 - 16

    // 4. Animation Loop
    while (1) {
        // --- Update Sprite 0 ---
        s0_x += s0_dx;
        if (s0_x <= 0) {
            s0_x = 0;
            s0_dx = 1;
        } else if (s0_x >= max_x) {
            s0_x = max_x;
            s0_dx = -1;
        }

        s0_y += s0_dy;
        if (s0_y <= 0) {
            s0_y = 0;
            s0_dy = 1;
        } else if (s0_y >= max_y) {
            s0_y = max_y;
            s0_dy = -1;
        }

        // Pack and write Sprite 0
        // palette=0, tile=1 => 1 << 19 = 0x00080000
        uint32_t s0_data = 0x00080000 | (s0_y << 10) | s0_x;
        OAM_SPRITE_BASE[0] = s0_data;

        // --- Update Sprite 1 ---
        s1_x += s1_dx;
        if (s1_x <= 0) {
            s1_x = 0;
            s1_dx = 1;
        } else if (s1_x >= max_x) {
            s1_x = max_x;
            s1_dx = -1;
        }

        s1_y += s1_dy;
        if (s1_y <= 0) {
            s1_y = 0;
            s1_dy = 1;
        } else if (s1_y >= max_y) {
            s1_y = max_y;
            s1_dy = -1;
        }

        // Pack and write Sprite 1
        // palette=1, tile=2 => (1 << 26) | (2 << 19) = 0x04100000
        uint32_t s1_data = 0x04100000 | (s1_y << 10) | s1_x;
        OAM_SPRITE_BASE[1] = s1_data;

        // --- Delay ---
        delay(0x00020000);
    }
}
