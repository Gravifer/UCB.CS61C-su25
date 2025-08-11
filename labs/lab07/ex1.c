#include <time.h>
#include <stdio.h>
#include <x86intrin.h>
#include "ex1.h"

long long int sum(int vals[NUM_ELEMS]) {
    clock_t start = clock();

    long long int sum = 0;
    for(unsigned int w = 0; w < OUTER_ITERATIONS; w++) {
        for(unsigned int i = 0; i < NUM_ELEMS; i++) {
            if(vals[i] >= 128) {
                sum += vals[i];
            }
        }
    }
    clock_t end = clock();
    printf("Time taken: %Lf s\n", (long double)(end - start) / CLOCKS_PER_SEC);
    return sum;
}

long long int sum_unrolled(int vals[NUM_ELEMS]) {
    clock_t start = clock();
    long long int sum = 0;

    for(unsigned int w = 0; w < OUTER_ITERATIONS; w++) {
        for(unsigned int i = 0; i < NUM_ELEMS / 4 * 4; i += 4) {
            if(vals[i] >= 128) sum += vals[i];
            if(vals[i + 1] >= 128) sum += vals[i + 1];
            if(vals[i + 2] >= 128) sum += vals[i + 2];
            if(vals[i + 3] >= 128) sum += vals[i + 3];
        }

        // TAIL CASE, for when NUM_ELEMS isn't a multiple of 4
        // NUM_ELEMS / 4 * 4 is the largest multiple of 4 less than NUM_ELEMS
        // Order is important, since (NUM_ELEMS / 4) effectively rounds down first
        for(unsigned int i = NUM_ELEMS / 4 * 4; i < NUM_ELEMS; i++) {
            if (vals[i] >= 128) {
                sum += vals[i];
            }
        }
    }
    clock_t end = clock();
    printf("Time taken: %Lf s\n", (long double)(end - start) / CLOCKS_PER_SEC);
    return sum;
}

long long int sum_simd(int vals[NUM_ELEMS]) {
    clock_t start = clock();
    __m128i _127 = _mm_set1_epi32(127); // This is a vector with 127s in it... Why might you need this?
    long long int result = 0; // This is where you should put your final result!
    /* DO NOT MODIFY ANYTHING ABOVE THIS LINE (in this function) */
    __m128i sum_vec, addend, mask;
    int tmp_arr[4] = {0, 0, 0, 0}; // Temporary array to store the result of the SIMD operation

    for(unsigned int w = 0; w < OUTER_ITERATIONS; w++) {
        // //* YOUR CODE GOES HERE */
        sum_vec = _mm_setzero_si128(); // Initialize sum vector to {0, 0, 0, 0} for each outer iteration
        for(unsigned int i = 0; i < NUM_ELEMS / 4 * 4; i += 4) {
            addend  = _mm_loadu_si128((__m128i *) &vals[i]);
            mask    = _mm_cmpgt_epi32(addend, _127);
            addend  = _mm_and_si128(addend, mask);  // bitwise; zeroes out values that are less than 128
            sum_vec = _mm_add_epi32(sum_vec, addend);
        }
        _mm_storeu_si128((__m128i *) tmp_arr, sum_vec);
        result += tmp_arr[0] + tmp_arr[1] + tmp_arr[2] + tmp_arr[3];

        // //* Hint: you'll need a tail case. */
        for(unsigned int i = NUM_ELEMS / 4 * 4; i < NUM_ELEMS; i++) {
            if (vals[i] >= 128) {
                result += vals[i];
            }
        }
    }

    /* DO NOT MODIFY ANYTHING BELOW THIS LINE (in this function) */
    clock_t end = clock();
    printf("Time taken: %Lf s\n", (long double)(end - start) / CLOCKS_PER_SEC);
    return result;
}

long long int sum_simd_unrolled(int vals[NUM_ELEMS]) {
    clock_t start = clock();
    __m128i _127 = _mm_set1_epi32(127);
    long long int result = 0;
    /* DO NOT MODIFY ANYTHING ABOVE THIS LINE (in this function) */
    __m128i sum_vec, addend, mask;
    int tmp_arr[4] = {0, 0, 0, 0}; // Temporary array to store the result of the SIMD operation

    for(unsigned int w = 0; w < OUTER_ITERATIONS; w++) { // * see https://en.wikipedia.org/wiki/Duff%27s_device but don't use it
        // //* YOUR CODE GOES HERE */
        sum_vec = _mm_setzero_si128(); // Initialize sum vector to {0, 0, 0, 0} for each outer iteration
        /* Copy your sum_simd() implementation here, and unroll it */

        // Macro to process a SIMD block at a given offset
        #ifdef ex1_SIMD_BLOCK  // somehow clashed; abort compilation
            #error "ex1_SIMD_BLOCK macro is already defined! Name collision detected."
        #endif
        #define ex1_SIMD_BLOCK(offset) \
            addend  = _mm_loadu_si128((__m128i *)&vals[i + 4 * (offset)]); \
            mask    = _mm_cmpgt_epi32(addend, _127); \
            addend  = _mm_and_si128(addend, mask); \
            sum_vec = _mm_add_epi32(sum_vec, addend);
        
        // Configurable unrolling using recursive macros (compile-time "for loop")
        #define UNROLL_FACTOR 16  // Change this to 4, 8, 16, etc.
            
        // Recursive macro expansion for compile-time "for loop"
        #define REPEAT_0(macro, arg)
        #define REPEAT_1(macro, arg) macro(arg)
        #define REPEAT_2(macro, arg) REPEAT_1(macro, arg) macro(arg+1)
        #define REPEAT_4(macro, arg) REPEAT_2(macro, arg) REPEAT_2(macro, arg+2)
        #define REPEAT_8(macro, arg) REPEAT_4(macro, arg) REPEAT_4(macro, arg+4)
        #define REPEAT_16(macro, arg) REPEAT_8(macro, arg) REPEAT_8(macro, arg+8)
        
        // Select the appropriate repeat macro based on UNROLL_FACTOR
        #define CONCAT(a, b) a##b
        #define REPEAT(n, macro, arg) CONCAT(REPEAT_, n)(macro, arg)
        
        // Main unrolled loop with configurable stride
        for (unsigned int i = 0; i < NUM_ELEMS / (UNROLL_FACTOR * 4) * (UNROLL_FACTOR * 4); i += (UNROLL_FACTOR * 4)) {
            REPEAT(UNROLL_FACTOR, ex1_SIMD_BLOCK, 0)
        }

        /* Hint: you'll need 1 or maybe 2 tail cases here. */
        for (unsigned int i = NUM_ELEMS / (UNROLL_FACTOR * 4) * (UNROLL_FACTOR * 4); i < NUM_ELEMS / 4 * 4; i += 4) {
            ex1_SIMD_BLOCK(0);
        }
        
        #undef REPEAT
        #undef CONCAT
        #undef REPEAT_16
        #undef REPEAT_8
        #undef REPEAT_4
        #undef REPEAT_2
        #undef REPEAT_1
        #undef REPEAT_0
        #undef ex1_SIMD_BLOCK
        #undef UNROLL_FACTOR

        _mm_storeu_si128((__m128i *) tmp_arr, sum_vec);
        result += tmp_arr[0] + tmp_arr[1] + tmp_arr[2] + tmp_arr[3];

        for(unsigned int i = NUM_ELEMS / 4 * 4; i < NUM_ELEMS; i++) {
            if (vals[i] >= 128) {
             result += vals[i];
            }
        }
    }

    /* DO NOT MODIFY ANYTHING BELOW THIS LINE (in this function) */
    clock_t end = clock();
    printf("Time taken: %Lf s\n", (long double)(end - start) / CLOCKS_PER_SEC);
    return result;
}
