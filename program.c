// Boids Simulation for Baremetal RISC-V Custom Core
// Compile with:
// clang --target=riscv32 -march=rv32i -mabi=ilp32 -mno-relax -O3 -c program.c -o program.o
// ld.lld -T link.ld program.o -o program.elf
// llvm-objcopy -O binary program.elf program.bin
// python3 bin2mem.py program.bin prog.mem

#include <stdint.h>

#ifdef PC_TEST
#include <stdio.h>
uint32_t mock_oam[2048];
#define OAM_PALETTE_BASE (&mock_oam[0x400 / 4])
#define OAM_SPRITE_BASE  (&mock_oam[0x200 / 4])
static inline void delay(uint32_t count) {}
#else
// Define memory mapped I/O addresses
#define OAM_PALETTE_BASE ((volatile uint32_t*)0x400000)
#define OAM_SPRITE_BASE  ((volatile uint32_t*)0x800000)

// Helper to prevent the compiler from optimizing away the delay loop without using stack/RAM
static inline void delay(uint32_t count) {
    __asm__ volatile (
        "1:\n\t"
        "addi %0, %0, -1\n\t"
        "bnez %0, 1b\n\t"
        : "+r" (count)
    );
}
#endif

// Software implementation of multiplication
int32_t soft_mul(int32_t a, int32_t b) {
    int32_t res = 0;
    int32_t sign = 1;
    if (a < 0) { a = -a; sign = -sign; }
    if (b < 0) { b = -b; sign = -sign; }
    uint32_t ua = a, ub = b;
    while (ub) {
        __asm__ volatile ("" : "+r"(ua), "+r"(ub));
        
        if (ub & 1) res += ua;
        ua <<= 1;
        ub >>= 1;
    }
    return (sign > 0) ? res : -res;
}

// Software implementation of division
int32_t soft_div(int32_t num, int32_t den) {
    if (den == 0) return 0;
    int32_t sign = 1;
    if (num < 0) { num = -num; sign = -sign; }
    if (den < 0) { den = -den; sign = -sign; }
    
    uint32_t n = num;
    uint32_t d = den;
    uint32_t res = 0;
    
    uint32_t current = 1;
    while (d <= n && d < (1U<<31)) {
        d <<= 1;
        current <<= 1;
    }
    if (d > n && current > 1) {
        d >>= 1;
        current >>= 1;
    }
    
    while (current != 0) {
        if (n >= d) {
            n -= d;
            res |= current;
        }
        current >>= 1;
        d >>= 1;
    }
    return (sign > 0) ? (int32_t)res : -(int32_t)res;
}

uint32_t soft_mod(uint32_t a, uint32_t b) {
    if (b == 0) return 0;
    int32_t q = soft_div(a & 0x7FFFFFFF, b);
    return a - soft_mul(q, b);
}

uint32_t seed = 0x12345678;
uint32_t my_rand() {
    seed = soft_mul(seed, 1664525) + 1013904223;
    return seed;
}

#define NUM_BOIDS 18

// Main program entry point
int main() {
    // 1. Setup Palettes
    OAM_PALETTE_BASE[0] = 0x00FFFFFF; // White
    OAM_PALETTE_BASE[1] = 0x00FFFF00; // Cyan
    OAM_PALETTE_BASE[2] = 0x00FF00FF; // Magenta

    // 2. Boids Initialization
    const int32_t FRACTION_BITS = 8;
    const int32_t ONE = 1 << FRACTION_BITS;
    
    int32_t boid_x[NUM_BOIDS];
    int32_t boid_y[NUM_BOIDS];
    int32_t boid_vx[NUM_BOIDS];
    int32_t boid_vy[NUM_BOIDS];
    
    for (int i = 0; i < NUM_BOIDS; i++) {
        boid_x[i] = ((soft_mod(my_rand(), 600)) + 20) << FRACTION_BITS;
        boid_y[i] = ((soft_mod(my_rand(), 440)) + 20) << FRACTION_BITS;
        boid_vx[i] = ((soft_mod(my_rand(), 4)) - 2) * ONE;
        boid_vy[i] = ((soft_mod(my_rand(), 4)) - 2) * ONE;
        if (boid_vx[i] == 0) boid_vx[i] = ONE;
        if (boid_vy[i] == 0) boid_vy[i] = ONE;
    }

    const int32_t max_x_bounds = 624 << FRACTION_BITS; // 640 - 16
    const int32_t max_y_bounds = 464 << FRACTION_BITS; // 480 - 16
    const int32_t MAX_V = 3 * ONE;
    const int32_t MIN_V = 1 * ONE;

    #define CLAMP_V(v) do { \
        if ((v) > MAX_V) (v) = MAX_V; \
        else if ((v) < -MAX_V) (v) = -MAX_V; \
    } while(0)

    // 3. Application Loop
    while (1) {
        int32_t next_vx[NUM_BOIDS];
        int32_t next_vy[NUM_BOIDS];
        
        for (int i = 0; i < NUM_BOIDS; i++) {
            int32_t sep_vx = 0, sep_vy = 0;
            int32_t align_vx = 0, align_vy = 0;
            int32_t align_count = 0;
            int32_t coh_x = 0, coh_y = 0;
            int32_t coh_count = 0;
            
            for (int j = 0; j < NUM_BOIDS; j++) {
                if (i == j) continue;
                int32_t dx = boid_x[i] - boid_x[j];
                int32_t dy = boid_y[i] - boid_y[j];
                int32_t abs_dx = (dx < 0) ? -dx : dx;
                int32_t abs_dy = (dy < 0) ? -dy : dy;
                // Cornell Separation: 20 pixels protected range (Manhattan distance for diamond shape instead of square grid)
                if (abs_dx + abs_dy < (20 * ONE)) {
                    sep_vx += dx >> 1;
                    sep_vy += dy >> 1;
                }
                
                // Cornell Sight: 40 pixels visible range (visualRange in cornell is 20-40 usually. We'll use 40 to get good flocking)
                if (abs_dx < (20 * ONE) && abs_dy < (20 * ONE)) {
                    align_vx += boid_vx[j];
                    align_vy += boid_vy[j];
                    align_count++;
                    coh_x += boid_x[j];
                    coh_y += boid_y[j];
                    coh_count++;
                }
            }
            
            int32_t n_vx = boid_vx[i];
            int32_t n_vy = boid_vy[i];
            
            // 1. Separation
            // avoidfactor: 0.05. 0.05 is ~1/20. We can do >> 4 or divide by 20.
            n_vx += soft_div(soft_mul(sep_vx, 8), 100);
            n_vy += soft_div(soft_mul(sep_vy, 8), 100);
            
            // 2. Alignment
            if (align_count > 0) {
                align_vx = soft_div(align_vx, align_count);
                align_vy = soft_div(align_vy, align_count);
                // matchingfactor: 0.05 => * 5 / 100
                n_vx += soft_div(soft_mul(align_vx - boid_vx[i], 5), 100);
                n_vy += soft_div(soft_mul(align_vy - boid_vy[i], 5), 100);
            }
            
            // 3. Cohesion
            if (coh_count > 0) {
                coh_x = soft_div(coh_x, coh_count);
                coh_y = soft_div(coh_y, coh_count);
                // centeringfactor: 0.0005 => * 1 / 10000
                n_vx += soft_div(coh_x - boid_x[i], 10000);
                n_vy += soft_div(coh_y - boid_y[i], 10000);
            }
            
            // 4. Cornell Screen Edges
            int32_t margin = 50 * ONE;
            int32_t turnfactor = (ONE * 2) / 10; // 0.2
            
            if (boid_x[i] < margin) n_vx += turnfactor;
            if (boid_x[i] > max_x_bounds - margin) n_vx -= turnfactor;
            if (boid_y[i] < margin) n_vy += turnfactor;
            if (boid_y[i] > max_y_bounds - margin) n_vy -= turnfactor;

            int32_t center_x = 320 << FRACTION_BITS;
            int32_t center_y = 240 << FRACTION_BITS;
            int32_t dir_cx = center_x - boid_x[i];
            int32_t dir_cy = center_y - boid_y[i];

            n_vx += dir_cx >> 13;
            n_vy += dir_cy >> 13;
            
            // 4.5 Organic wander (noise) to prevent grid lock
            int32_t rx = (int32_t)(my_rand() & 31) - 16;
            int32_t ry = (int32_t)(my_rand() & 31) - 16;
            n_vx += rx;
            n_vy += ry;
            
            // 5. Speed limits (Cornell Euclidean approximation)
            int32_t speed = (n_vx < 0 ? -n_vx : n_vx) + (n_vy < 0 ? -n_vy : n_vy);
            if (speed > MAX_V) {
                n_vx = soft_div(soft_mul(n_vx, MAX_V), speed);
                n_vy = soft_div(soft_mul(n_vy, MAX_V), speed);
            } else if (speed < MIN_V && speed > 0) {
                n_vx = soft_div(soft_mul(n_vx, MIN_V), speed);
                n_vy = soft_div(soft_mul(n_vy, MIN_V), speed);
            } else if (speed == 0) {
                n_vx = MIN_V;
            }

            next_vx[i] = n_vx;
            next_vy[i] = n_vy;
        }
        
        for (int i = 0; i < NUM_BOIDS; i++) {
            boid_vx[i] = next_vx[i];
            boid_vy[i] = next_vy[i];
            boid_x[i] += boid_vx[i];
            boid_y[i] += boid_vy[i];
            
            // Hard bounds bounce
            if (boid_x[i] < 0) { boid_x[i] = 0; boid_vx[i] = -boid_vx[i]; }
            if (boid_x[i] > max_x_bounds) { boid_x[i] = max_x_bounds; boid_vx[i] = -boid_vx[i]; }
            if (boid_y[i] < 0) { boid_y[i] = 0; boid_vy[i] = -boid_vy[i]; }
            if (boid_y[i] > max_y_bounds) { boid_y[i] = max_y_bounds; boid_vy[i] = -boid_vy[i]; }
            
            uint32_t raw_x = boid_x[i] >> FRACTION_BITS;
            uint32_t raw_y = boid_y[i] >> FRACTION_BITS;
            
            // Write to OAM
            uint32_t pal = soft_mod(i, 3);
            uint32_t tile = 1; // Used for generic shape, from collatz maybe
            uint32_t sprite_attr = (pal << 26) | (tile << 19);
            OAM_SPRITE_BASE[i] = sprite_attr | (raw_y << 10) | raw_x;
            
            #ifdef PC_TEST
            printf("%d %d ", raw_x, raw_y);
            #endif
        }
        #ifdef PC_TEST
        printf("\n");
        #else
        //delay(0x00020000);
        #endif
    }
}
