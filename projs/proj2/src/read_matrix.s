.globl read_matrix

.data
msg_malloc_failed: .string "Error: Memory allocation failed.\n"
msg_fopen_failed:  .string "Error: Failed to open file.\n"
msg_fclose_failed: .string "Error: Failed to close file.\n"
msg_fread_failed:  .string "Error: Failed to read from file.\n"

.text
# ==============================================================================
# FUNCTION: Allocates memory and reads in a binary file as a matrix of integers
#
# FILE FORMAT:
#   The first 8 bytes are two 4 byte ints representing the # of rows and columns
#   in the matrix. Every 4 bytes afterwards is an element of the matrix in
#   row-major order.
# Arguments:
#   a0 (char*) is the pointer to string representing the filename
#   a1 (int*)  is a pointer to an integer, we will set it to the number of rows
#   a2 (int*)  is a pointer to an integer, we will set it to the number of columns
# Returns:
#   a0 (int*)  is the pointer to the matrix in memory
# Exceptions:
#   - If malloc returns an error,
#     this function terminates the program with error code 26
#   - If you receive an fopen error or eof,
#     this function terminates the program with error code 27
#   - If you receive an fclose error or eof,
#     this function terminates the program with error code 28
#   - If you receive an fread error or eof,
#     this function terminates the program with error code 29
# ==============================================================================
read_matrix:

    # Prologue
    addi sp, sp, -20
    sw ra, 16(sp)
    # backup caller state
    sw s0, 12(sp)
    sw s1,  8(sp)
    sw s2,  4(sp)
    sw s3,  0(sp) # pointer to elem to read

    mv s0, a0 # s0 = filename pointer
    mv s1, a1 # s1 = (int* >== int) # of rows >== allocated matrix pointer
    mv s2, a2 # s2 = (int* >== int) # of cols >== remaining bytes to read

read_matrix_fopen:
    li a1, 0 # read only
    jal fopen
    blt a0, zero, fopen_failed # allow zero, which is stdin
    mv s0, a0 # s0 = a0 = file descriptor

    mv a1, s1 # (int*) # of rows
    li a2, 4
    jal fread # [stateful] reads 4 bytes into s1
    li a2, 4  # restore a2
    bne a0, a2, fread_failed # !not a valid binary matrix file

    mv a0, s0 # restore file descriptor
    mv a1, s2 # (int*) # of cols
    jal fread # [stateful] reads the next 4 bytes into s2
    li a2,  4 # restore a2
    bne a0, a2, fread_failed # !not a valid binary matrix file

    lw s1, 0(s1) # [deref] s1 = (int) # of rows
    lw s2, 0(s2) # [deref] s2 = (int) # of cols
    mul s2, s1, s2 # a0 = total number of elems
    slli s2, s2, 2 # a0 = total number of bytes
    mv a0, s2  # a0 = total number of bytes
    jal malloc # allocate memory for the matrix
    beq a0, zero, malloc_failed # malloc failed
    mv s1, a0  # s1 = pointer to the matrix in memory

    # dumb read, without any unrolling
    li a2,  4 # read a word each time
    mv s3, s1 # s3 = pointer to the foremost element
read_matrix_read_elem: # *assert* remaining bytes is a multiple of 4
    mv a0, s0 # file descriptor
    mv a1, s3 # pointer to the element to read
    jal fread # [stateful] reads the next 4 bytes into the matrix
    li a2,  4 # restore a2
    bne a0, a2, fread_failed # !not a valid binary matrix file

    addi s3, s3,  4 # move to the next element in the matrix
    addi s2, s2, -4 # decr remaining bytes by 4
    bgtz s2, read_matrix_read_elem # if there are still bytes left to read

read_matrix_end:
    # attempt to close the file
    mv a0, s0 # file descriptor
    jal fclose
    bne a0, zero, fclose_failed

    # if we reach here, we successfully read the matrix and closed the file
    mv a0, s3 # a0 = pointer to the matrix

    # Epilogue
    lw ra, 16(sp) # restore return address
    # restore caller state
    lw s0, 12(sp)
    lw s1,  8(sp)
    lw s2,  4(sp)
    lw s3,  0(sp)
    addi sp, sp, 20 # restore stack pointer

    jr ra

# !exceptions!

malloc_failed:
    # attempt to close the file
    mv a0, s0 # file descriptor
    jal fclose
    bne a0, zero, fclose_failed

    li a0, 26
    # // la a1, msg_malloc_failed
    j exit

fopen_failed:
    li a0, 27
    # // la a1, msg_fopen_failed
    j exit
fclose_failed:
    li a0, 28
    # // la a1, msg_fclose_failed
    j exit
fread_failed:
    # attempt to close the file
    mv a0, s0 # file descriptor
    jal fclose
    bne a0, zero, fclose_failed

    li a0, 29
    # // la a1, msg_fread_failed
    j exit
