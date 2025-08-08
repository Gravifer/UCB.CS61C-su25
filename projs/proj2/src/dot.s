.globl dot

.text
# =======================================================
# FUNCTION: Dot product of 2 int arrays
# Arguments:
#   a0 (int*) is the pointer to the start of arr0
#   a1 (int*) is the pointer to the start of arr1
#   a2 (int)  is the number of elements to use
#   a3 (int)  is the stride of arr0
#   a4 (int)  is the stride of arr1
# Returns:
#   a0 (int)  is the dot product of arr0 and arr1
# Exceptions:
#   - If the number of elements to use is less than 1,
#     this function terminates the program with error code 36
#   - If the stride of either array is less than 1,
#     this function terminates the program with error code 37
# =======================================================
dot:

    # Prologue
    ble a2, x0, malform_ne # ! length of array less than 1
    slti t3, a3, 1   # ! stride of arr0 less than 1
    slti t4, a4, 1   # ! stride of arr1 less than 1
    or   t0, t3, t4  # ! either is an error
    bnez t0, malform_st # ! stride malformed

    mv t0, a0        # t0 points to element of arr0
    mv t1, a1        # t1 points to element of arr1
    mv t2, a2        # t2 holds the number of elements
    slli t3, a3, 2   # t3 holds the byte-stride of arr0
    slli t4, a4, 2   # t4 holds the byte-stride of arr1
    mv a0, zero      # a0 will hold the dot product result

loop_start:
    lw a2, 0(t0)     # Load current element of arr0
    lw a3, 0(t1)     # Load current element of arr1
    mul a1, a2, a3   # Multiply the elements
    add a0, a0, a1   # Add to the dot product result

    add t0, t0, t3   # Move to the next element in arr0
    add t1, t1, t4   # Move to the next element in arr1
    addi t2, t2, -1  # Decrement the element count
    bnez t2, loop_start # If more elements, repeat

loop_end:


    # Epilogue


    jr ra

malform_ne: # ! length of array less than 1
    li a0 36
    j exit
malform_st: # ! stride of array less than 1
    li a0 37
    j exit
