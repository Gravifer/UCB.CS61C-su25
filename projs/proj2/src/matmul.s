.globl matmul

.data
BLOCK_SIZE: .word 32 # todo: do block-by-block multiplication
# //malformed_mat: .asciz "Error: Malformed matrix dimensions.\n"
# //incompat_dims: .asciz "Error: Incompatible matrix dimensions.\n"

.text
# =======================================================
# FUNCTION: Matrix Multiplication of 2 integer matrices
#   d = matmul(m0, m1)
# Arguments:
#   a0 (int*)  is the pointer to the start of m0
#   a1 (int)   is the # of rows (height) of m0
#   a2 (int)   is the # of columns (width) of m0
#   a3 (int*)  is the pointer to the start of m1
#   a4 (int)   is the # of rows (height) of m1
#   a5 (int)   is the # of columns (width) of m1
#   a6 (int*)  is the pointer to the the start of d
# Returns:
#   None (void), sets d = matmul(m0, m1)
# Exceptions:
#   Make sure to check in top to bottom order!
#   - If the dimensions of m0 do not make sense,
#     this function terminates the program with exit code 38
#   - If the dimensions of m1 do not make sense,
#     this function terminates the program with exit code 38
#   - If the dimensions of m0 and m1 don't match,
#     this function terminates the program with exit code 38
# =======================================================
matmul:

    # Error checks
    # Check if m0 is malformed
    ble a1, zero, malformed_mat # m0 height
    ble a2, zero, malformed_mat # m0 width
    # Check if m1 is malformed
    ble a4, zero, malformed_mat # m1 height
    ble a5, zero, malformed_mat # m1 width
    # Check if m0 and m1 are compatible
    bne a2, a4, incompat_dims # m0 width != m1 height


    # Prologue
    addi sp, sp, -32
    sw ra, 28(sp) # save return address
    # backup caller state
    sw s0, 24(sp)
    sw s1, 20(sp)
    sw s2, 16(sp)
    sw s3, 12(sp)
    sw s4,  8(sp)
    sw s5,  4(sp)
    sw s6,  0(sp)
    # backup arguments
    mv s0, a0 # s0 = pointer to m0 row
    mv s1, a1 # s1 = rows of d to do
    mv s2, a2 # s2 = compat dim - doesn't need to change!
    mv s3, a3 # s3 = pointer to m1 col
    # * a4 is also compat dim - doesn't need to save!
    mv s4, a5 # s4 = cols of d backup
    mv s5, a5 # s5 = cols of d to do
    mv s6, a6 # s6 = elem of d to write to

outer_loop_start: # Outer loop: iterate over rows of m0

inner_loop_start: # Inner loop: iterate over cols of m1

    # prepare a call to dot
    mv a0, s0 # a0 (int*) -  pointer to the row of m0
    mv a1, s3 # a1 (int*) -  pointer to the col of m1
    mv a2, s2 # a2 (int)  -  compat dim - doesn't need to change!
    li a3, 1  # a3 (int)  -  stride of row -- 1
    mv a4, s4 # a4 (int)  -  stride of col -- width of m1
    jal dot   # pseudoinstruction; links ra
    sw   a0, 0(s6)  # store the result in d

    addi s3, s3,  4 # move to the next col in m1
    addi s5, s5, -1 # decrement cols of d to do
    addi s6, s6,  4 # move to the next element in d
    bgt s5, zero, inner_loop_start # if s5 <= 0, exit inner loop

inner_loop_end:
    slli t2, s2,  2 # t2 = byte stride of width of m0
    add  s0, s0, t2 # move to the next row in m0
    addi s1, s1, -1 # decrm rows of d to do
    slli t5, s4,  2 # t5 = byte stride of width of m1
    sub  s3, s3, t5 # reset pointer to m1 col
    mv   s5, s4     # reset cols of d to do
    bgt s1, zero, outer_loop_start # if s1 <= 0, exit outer loop

outer_loop_end:


    # Epilogue
    lw ra, 28(sp) # restore return address
    # restore caller state
    lw s0, 24(sp)
    lw s1, 20(sp)
    lw s2, 16(sp)
    lw s3, 12(sp)
    lw s4,  8(sp)
    lw s5,  4(sp)
    lw s6,  0(sp)
    addi sp, sp, +32

    jr ra

malformed_mat: # ！The height or width of either matrix is less than 1
incompat_dims: # ！The number of columns (width) of the first matrix A is not
               # ！equal to the number of rows (height) of the second matrix B.
    li a0, 38
    j exit
