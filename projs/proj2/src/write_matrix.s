.globl write_matrix

.data
msg_fopen_failed:  .string "Error: Failed to open file.\n"
msg_fclose_failed: .string "Error: Failed to close file.\n"
msg_fwrite_failed:  .string "Error: Failed to write to file.\n"

.text
# ==============================================================================
# FUNCTION: Writes a matrix of integers into a binary file
# FILE FORMAT:
#   The first 8 bytes of the file will be two 4 byte ints representing the
#   numbers of rows and columns respectively. Every 4 bytes thereafter is an
#   element of the matrix in row-major order.
# Arguments:
#   a0 (char*) is the pointer to string representing the filename
#   a1 (int*)  is the pointer to the start of the matrix in memory
#   a2 (int)   is the number of rows in the matrix
#   a3 (int)   is the number of columns in the matrix
# Returns:
#   None
# Exceptions:
#   - If you receive an fopen error or eof,
#     this function terminates the program with error code 27
#   - If you receive an fclose error or eof,
#     this function terminates the program with error code 28
#   - If you receive an fwrite error or eof,
#     this function terminates the program with error code 30
# ==============================================================================
write_matrix:

    # Prologue
    addi sp, sp, -20
    sw ra, 16(sp)
    # backup caller state
    sw s0, 12(sp)
    sw s1,  8(sp)
    sw s2,  4(sp)
    sw s3,  0(sp)
    # backup arguments
    mv s0, a0 # s0 = filename pointer >== descriptor
    mv s1, a1 # s1 = (int*) matrix in memory
    mv s2, a2 # s1 = (int) # of rows
    mv s3, a3 # s2 = (int) # of cols

write_matrix_fopen:
    li a1, 1  # write only
    jal fopen # return -> a0 = file descriptor
    blt a0, zero, fopen_failed # allow zero, which is stdin
    mv s0, a0 # s0 = a0 = file descriptor


    # write the dimensions to the file
    addi sp, sp, -8 # store dimmensions to stack
    sw s2, 0(sp) # store # of rows
    sw s3, 4(sp) # store # of cols

    # a0 is already prepared
    mv a1, sp  # points to dimensions
    li a2, 2   # 2 ints to write (8 bytes)
    li a3, 4   # size of each int
    jal fwrite # [stateful] return -> a0 = number of items actually written
    li a2, 2   # restore a2
    bne a0, a2, fwrite_failed # !failed to write dimensions
    addi sp, sp,  8 # discard dimensions from stack

    # write the matrix elements to the file
    mv a0, s0 # restore file descriptor
    mv a1, s1 # a1 = pointer to matrix in memory
    mul s1, s2, s3 # s1 = total number of elements
    mv a2, s1 # a2 = s1
    li a3, 4  # size of each int
    jal fwrite # [stateful] return -> a0 = number of items actually written
    bne a0, s1, fwrite_failed # !failed to write matrix

read_matrix_end:
    # attempt to close the file
    mv a0, s0 # file descriptor
    jal fclose
    bne a0, zero, fclose_failed

    # if we reach here, we successfully read the matrix and closed the file

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

fopen_failed:
    li a0, 27
    # // la a1, msg_fopen_failed
    j exit
fclose_failed:
    li a0, 28
    # // la a1, msg_fclose_failed
    j exit
fwrite_failed:
    # attempt to close the file
    mv a0, s0 # file descriptor
    jal fclose
    bne a0, zero, fclose_failed

    li a0, 30
    # // la a1, msg_fwrtie_failed
    j exit

