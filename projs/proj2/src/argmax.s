.globl argmax

.text
# =================================================================
# FUNCTION: Given a int array, return the index of the largest
#   element. If there are multiple, return the one
#   with the smallest index.
# Arguments:
#   a0 (int*) is the pointer to the start of the array
#   a1 (int)  is the # of elements in the array
# Returns:
#   a0 (int)  is the first index of the largest element
# Exceptions:
#   - If the length of the array is less than 1,
#     this function terminates the program with error code 36
# =================================================================
argmax:
    # Prologue
    ble a1, x0, malformed # ! length of array less than 1

    # Initialize the index of the largest element
    mv t0, a0         # t0 points to current element
    mv t1, a1         # t0 holds array length
    mv a0, zero       # max_index = 0
    lw a1, 0(t0)      # max_value = a0[0] # can be accessed by caller if needed

    li t2, 0          # index = 0
loop_start:
    lw t3, 0(t0)      # Load current element
    bge a1, t3, loop_continue # If element > max_value, update max
    mv a0, t2         # max_index = current index
    mv a1, t3         # max_value = current element


loop_continue:
    addi t0, t0, 4    # Move to the next element
    addi t2, t2, 1    # Increment the index
    blt t2, t1, loop_start # If more elements, repeat
    j loop_end        # Jump to the end of the loop


loop_end:
    # Epilogue

    jr ra

malformed: # ! length of array less than 1
    li a0 36
    j exit
