.globl classify

.text
# =====================================
# COMMAND LINE ARGUMENTS
# =====================================
# Args:
#   a0 (int)        argc
#   a1 (char**)     argv
#   a1[1] (char*)   pointer to the filepath string of m0
#   a1[2] (char*)   pointer to the filepath string of m1
#   a1[3] (char*)   pointer to the filepath string of input matrix
#   a1[4] (char*)   pointer to the filepath string of output file
#   a2 (int)        silent mode, if this is 1, you should not print
#                   anything. Otherwise, you should print the
#                   classification and a newline.
# Returns:
#   a0 (int)        Classification
# Exceptions:
#   - If there are an incorrect number of command line args,
#     this function terminates the program with exit code 31
#   - If malloc fails, this function terminates the program with exit code 26
#
# Usage:
#   main.s <M0_PATH> <M1_PATH> <INPUT_PATH> <OUTPUT_PATH>
classify:
    # Prologue
    # Check number of arguments
    li t0, 5 # expect 5 arguments (<progname>, m0, m1, input, output)
    bne a0, t0, classify_err_argc # !crash if argc is not 5

    addi sp, sp, -52  # 48 for registers + 4 for silent mode
    sw ra, 48(sp) # save return address
    # backup caller state (now including s10 for dimensions)
    sw s0, 44(sp)
    sw s1, 40(sp)
    sw s2, 36(sp)
    sw s3, 32(sp)
    sw s4, 28(sp)
    sw s5, 24(sp)
    sw s6, 20(sp)
    sw s7, 16(sp)
    sw s8, 12(sp)
    sw s9,  8(sp)
    sw s10, 4(sp)
    sw a2,  0(sp) # save silent mode flag on stack
    # backup arguments
    lw s1,  4(a1) # s1 = argv[1] = m0 filepath >== pointer
    lw s2,  8(a1) # s2 = argv[2] = m1 filepath >== pointer
    lw s3, 12(a1) # s3 = argv[3] = input filepath >== pointer
    lw s4, 16(a1) # s4 = argv[4] = output filepath

    addi sp, sp, -24 # make room for dimensions
    # Read pretrained m0
    mv a0, s1 # a0 = m0 filepath
    addi a1, sp,  0 # a1 = pointer to (int*) # of rows
    addi a2, sp,  4 # a2 = pointer to (int*) # of cols
    jal read_matrix # [stateful] return -> a0 = pointer to m0 matrix in memory
    mv s1, a0 # s5 = pointer to m0


    # Read pretrained m1
    mv a0, s2 # a0 = m1 filepath
    addi a1, sp,  8 # a1 = pointer to (int*) # of rows
    addi a2, sp, 12 # a2 = pointer to (int*) # of cols
    jal read_matrix # [stateful] return -> a0 = pointer to m1 matrix in memory
    mv s2, a0 # s5 = pointer to m1


    # Read input matrix
    mv a0, s3 # a0 = input filepath
    addi a1, sp, 16 # a1 = pointer to (int*) # of rows
    addi a2, sp, 20 # a2 = pointer to (int*) # of cols
    jal read_matrix # [stateful] return -> a0 = pointer to input matrix
    mv s3, a0 # s5 = pointer to input matrix

    # Load all dimensions sequentially for cache efficiency
    lw s5,  0(sp) # s5 = m0 rows
    lw s6,  4(sp) # s6 = m0 cols
    lw s7,  8(sp) # s7 = m1 rows
    lw s8, 12(sp) # s8 = m1 cols
    lw s9, 16(sp) # s9 = input rows
    lw s10, 20(sp) # s10 = input cols

    # Compute h = matmul(m0, input)
    # malloc for result matrix h
    mul a0, s5, s10 # a0 = # of elements in h (m0_rows * input_cols)
    slli a0, a0, 2 # a0 = # of bytes in h
    jal malloc # [stateful] return -> a0 = pointer to h matrix
    beq a0, zero, malloc_failed # !malloc failed
    mv s0, a0 # s0 = pointer to h matrix (use s0 since silent mode is on stack)
    # call matmul
    mv a0, s1 # a0 = pointer to m0
    mv a1, s5 # a1 = # of rows of m0
    mv a2, s6 # a2 = # of cols of m0
    mv a3, s3 # a3 = pointer to input matrix
    mv a4, s9 # a4 = # of rows of input matrix
    mv a5, s10 # a5 = # of cols of input matrix
    mv a6, s0 # a6 = pointer to h matrix
    jal matmul # [in-place] a6 now contains h matrix
    # Free m0 and input (they're no longer needed)
    mv a0, s1 # a0 = pointer to m0 matrix
    jal free
    mv a0, s3 # a0 = pointer to input matrix
    jal free
    # s0 now contains h pointer


    # Compute h = relu(h)
    mv a0, s0 # a0 = pointer to h matrix
    mul a1, s5, s10 # a1 = # of elems of h (m0_rows * input_cols)
    jal relu # [in-place]


    # Compute o = matmul(m1, h)
    # malloc for result matrix o
    mul a0, s7, s10 # a0 = # of elements in o (m1_rows * input_cols)
    slli a0, a0, 2 # a0 = # of bytes in o
    jal malloc # [stateful] return -> a0 = pointer to o matrix
    beq a0, zero, malloc_failed # !malloc failed
    mv s1, a0 # s1 = pointer to o matrix (reuse s1 since m0 is freed)
    # call matmul
    mv a0, s2 # a0 = pointer to m1 matrix
    mv a1, s7 # a1 = # of rows of m1
    mv a2, s8 # a2 = # of cols of m1
    mv a3, s0 # a3 = pointer to h matrix
    mv a4, s5 # a4 = # of rows of h matrix (m0_rows)
    mv a5, s10 # a5 = # of cols of h matrix (input_cols)
    mv a6, s1 # a6 = pointer to o matrix
    jal matmul # [in-place] a6 now contains o matrix
    # Free m1 and h
    mv a0, s2 # a0 = pointer to m1 matrix
    jal free
    mv a0, s0 # a0 = pointer to h matrix
    jal free
    # Now s1 contains o pointer
    addi sp, sp, +24 # discard dimensions


    # Write output matrix o
    mv a0, s4 # a0 = output filepath
    mv a1, s1 # a1 = pointer to o matrix
    mv a2, s7 # a2 = # of rows of o matrix (m1_rows)
    mv a3, s10 # a3 = # of cols of o matrix (input_cols)
    jal write_matrix # [stateful] writes o matrix to file


    # Compute and return argmax(o)
    mv a0, s1 # a0 = pointer to o matrix
    mul a1, s7, s10 # a1 = # of elements in o (m1_rows * input_cols)
    jal argmax # [stateful] return -> a0 = index of max element in o
    mv s2, a0 # s2 = index of max element in o (reuse s2)

    # free o matrix to avoid memory leak
    mv a0, s1 # a0 = pointer to o matrix
    jal free

    # If enabled, print argmax(o) and newline
    lw t0, 0(sp) # load silent mode flag from stack
    bnez t0, classify_end
    mv a0, s2 # a0 = index of max element in o
    jal print_int
    li a0, '\n' # a0 = newline
    jal print_char # print newline


classify_end:
    mv a0, s2 # a0 = index of max element in o
    # Epilogue: restore saved registers and stack pointer
    lw ra, 48(sp)
    lw s0, 44(sp)
    lw s1, 40(sp)
    lw s2, 36(sp)
    lw s3, 32(sp)
    lw s4, 28(sp)
    lw s5, 24(sp)
    lw s6, 20(sp)
    lw s7, 16(sp)
    lw s8, 12(sp)
    lw s9,  8(sp)
    lw s10, 4(sp)
    addi sp, sp, 52
    jr ra


# !exceptions!

malloc_failed:
    li a0, 26
    # // la a1, msg_malloc_failed
    j exit
classify_err_argc:
    li a0, 31
    j exit
