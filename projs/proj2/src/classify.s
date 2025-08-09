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

    addi sp, sp, -52
    sw ra, 48(sp) # save return address
    # backup caller state
    sw s0, 44(sp)
    sw s1, 40(sp)
    sw s2, 36(sp)
    sw s3, 32(sp)
    sw s4, 28(sp)
    sw s5, 24(sp) # reserve for h pointer
    sw s6, 20(sp) # reserve for o pointer
    sw s7, 16(sp) # reserve for m0, h height
    sw s8, 12(sp) # reserve for input, h width
    sw s9,  8(sp) # reserve for m1, o height
    sw s10, 4(sp) # reserve for h, o width
    sw s11, 0(sp) # reserve for argmax index
    # backup arguments
    mv s0, a2 # s0 = silent mode (1 if silent, 0 if not)
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


    # Compute h = matmul(m0, input)
    lw s7,  0(sp) # s7 = (int) # of rows of m0
    lw s8, 20(sp) # s8 = (int) # of cols of input matrix
    # malloc for result matrix h
    mul a0, s7, s8 # a0 = (int) # of elements in h
    slli a0, a0, 2 # a0 = (int) # of bytes in h
    jal malloc # [stateful] return -> a0 = pointer to h matrix
    beq a0, zero, malloc_failed # !malloc failed
    mv s5, a0 # s5 = a0 = pointer to h matrix
    # call matmul
    mv a0, s1 # a0 = pointer to m0
    mv a1, s7 # a1 = (int) # of rows of m0
    lw a2,  4(sp) # a2 = (int) # of cols of m0
    mv a3, s3 # a3 = pointer to input matrix
    lw a4, 16(sp) # a4 = (int) # of rows of input matrix
    mv a5, s8 # a5 = (int) # of cols of input matrix
    mv a6, s5 # a6 = s5 = pointer to h matrix
    jal matmul # [in-place] a6 now contains h matrix
    # free m0, input
    mv a0, s1 # a0 = pointer to m0 matrix
    jal free
    mv a0, s3 # a0 = pointer to input matrix
    jal free
    # liberated store registers: s1, s3


    # Compute h = relu(h)
    mv a0, s5 # a0 = pointer to h matrix
    mul a1, s7, s8 # a1 = (int) # of elems of h
    jal relu # [in-place]


    # Compute o = matmul(m1, h)
    lw s9,  8(sp) # s9 = (int) # of rows of m1
    # malloc for result matrix o
    mul a0, s9, s8 # a0 = (int) # of elements in o
    slli a0, a0, 2 # a0 = (int) # of bytes in o
    jal malloc # [stateful] return -> a0 = pointer to o matrix
    beq a0, zero, malloc_failed # !malloc failed
    mv s6, a0 # s6 = a0 = pointer to o matrix
    # call matmul
    mv a0, s2 # a0 = pointer to m1 matrix
    mv a1, s9 # a1 = (int) # of rows of m1
    lw a2, 12(sp) # a2 = (int) # of cols of m1
    mv a3, s5 # a3 = pointer to h matrix
    mv a4, s7 # a4 = (int) # of rows of h matrix
    mv a5, s8 # a5 = (int) # of cols of h matrix
    mv a6, s6 # a6 = s6 = pointer to o matrix
    jal matmul # [in-place] a6 now contains o matrix
    # free m1, h
    mv a0, s2 # a0 = pointer to m1 matrix
    jal free
    mv a0, s5 # a0 = pointer to h matrix
    jal free
    # liberated store registers: s2, s5
    addi sp, sp, +24 # discard dimensions


    # Write output matrix o
    mv a0, s4 # a0 = output filepath
    mv a1, s6 # a1 = pointer to o matrix
    mv a2, s9 # a2 = (int) # of rows of o matrix
    mv a3, s8 # a3 = (int) # of cols of o matrix
    jal write_matrix # [stateful] writes o matrix to file


    # Compute and return argmax(o)
    mv a0, s6 # a0 = pointer to o matrix
    mul a1, s9, s8 # a1 = (int) # of elements in o
    jal argmax # [stateful] return -> a0 = index of max element in o
    mv s11, a0 # s11 = index of max element in o

    # free o matrix to avoid memory leak
    mv a0, s6 # a0 = pointer to o matrix
    jal free

    # If enabled, print argmax(o) and newline
    bnez s0, classify_end
    mv a0, s11 # a0 = index of max element in o
    jal print_int
    li a0, '\n' # a0 = newline
    jal print_char # print newline


classify_end:
    mv a0, s11 # a0 = index of max element in o
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
    lw s9, 8(sp)
    lw s10, 4(sp)
    lw s11, 0(sp)
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
