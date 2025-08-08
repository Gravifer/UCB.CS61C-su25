.globl relu

.text
# ==============================================================================
# FUNCTION: Performs an inplace element-wise ReLU on an array of ints
# Arguments:
#   a0 (int*) is the pointer to the array
#   a1 (int)  is the # of elements in the array
# Returns:
#   None
# Exceptions:
#   - If the length of the array is less than 1,
#     this function terminates the program with error code 36
# ==============================================================================
relu:
    # Prologue
    ble a1, x0, malformed # ! length of array less than 1

loop_start:
    lw t0, 0(a0)      # Load current element
    bge t0, zero, loop_continue # If element >= 0, skip negation
    sw x0, 0(a0)      # Set the element to 0

loop_continue:
    addi a0, a0, 4    # Move to the next element
    addi a1, a1, -1    # Decrement the element count
    bnez a1, loop_start # If more elements, repeat
    j loop_end         # Jump to the end of the loop
    
loop_end:


    # Epilogue


    jr ra

malformed: # ! length of array less than 1
    li a0 36
    j exit
