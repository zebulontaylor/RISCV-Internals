// Minimal math test for baremetal RISC-V
// Exercises soft_mul, soft_div, soft_mod only.
// Results are written to a fixed memory array so the tb can check them.
#include <stdint.h>

// --- pure software math (copied verbatim from program.c) ---

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

int32_t soft_div(int32_t num, int32_t den) {
    if (den == 0) return 0;
    int32_t sign = 1;
    if (num < 0) { num = -num; sign = -sign; }
    if (den < 0) { den = -den; sign = -sign; }
    uint32_t n = num, d = den, res = 0, current = 1;
    while (d <= n && d < (1U<<31)) { d <<= 1; current <<= 1; }
    if (d > n && current > 1)     { d >>= 1; current >>= 1; }
    while (current != 0) {
        if (n >= d) { n -= d; res |= current; }
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

// Results stored here so the testbench can read them directly from memory.
// Place at a fixed address via linker; we just use a global array.
volatile int32_t results[32];

int main() {
    // Test 0: 6 * 7 = 42
    results[0] = soft_mul(6, 7);

    // Test 1: -5 * 9 = -45
    results[1] = soft_mul(-5, 9);

    // Test 2: 100 / 4 = 25
    results[2] = soft_div(100, 4);

    // Test 3: -99 / 3 = -33
    results[3] = soft_div(-99, 3);

    // Test 4: 17 mod 5 = 2
    results[4] = (int32_t)soft_mod(17, 5);

    // Test 5: 100 mod 7 = 2
    results[5] = (int32_t)soft_mod(100, 7);

    // Test 6: seed-style mul (from my_rand): 1664525 * 2 = 3329050
    results[6] = soft_mul(1664525, 2);

    // Test 7: soft_div(99, 10) = 9
    results[7] = soft_div(99, 10);

    // ---------------------------------------------------------------
    // Test 8-10: Stack-allocated array load/store
    // Tests lw/sw with large SP-relative negative offsets.
    // ---------------------------------------------------------------
    {
        int32_t arr[30];
        for (int i = 0; i < 30; i++)
            arr[i] = i * 7 + 3;

        results[8]  = arr[0];             // 3
        results[9]  = arr[29];            // 206
        results[10] = arr[14] - arr[13];  // 101 - 94 = 7  (adjacent element diff)
    }

    // ---------------------------------------------------------------
    // Test 11-13: Load-use hazard
    // Each lw result is used by the very next instruction.
    // volatile forces real memory loads so the compiler can't hoist.
    // ---------------------------------------------------------------
    {
        // 11: four consecutive load->add pairs, sum must be exact
        volatile int32_t latch[4];
        latch[0] = 10; latch[1] = 20; latch[2] = 30; latch[3] = 40;
        int32_t sum = 0;
        sum += latch[0];  // lw then add
        sum += latch[1];
        sum += latch[2];
        sum += latch[3];
        results[11] = sum;  // 100

        // 12: load -> sub -> load -> sub chain
        volatile int32_t va = 77, vb = 30;
        int32_t v1 = va;        // lw
        int32_t v2 = v1 - 7;   // sub uses v1 immediately
        int32_t v3 = vb;        // lw
        int32_t v4 = v3 + v2;  // add uses v3 immediately
        results[12] = v4;  // 30 + 70 = 100

        // 13: store then load from same address (write-then-read)
        volatile int32_t cell = 0;
        cell = 999;
        results[13] = cell;  // must see 999, not 0
    }

    // Signal done
    results[31] = 0xDEAD;

    while (1) {}  // halt
}
