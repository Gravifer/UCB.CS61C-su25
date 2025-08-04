.globl f # this allows other files to find the function f

# f takes in two arguments:
# a0 is the value we want to evaluate f at
# a1 is the address of the "output" array (read the lab spec for more information).
# The return value should be stored in a0
f:
    # Your code here
   
    addi t0, a0, 3 # convert the inputs [-3, 3] to indices [0, 6]
    slli t0, t0, 2 # t0 *= 4; now the offset in bytes
    add  t0, t0, a1 # add the base address of the output array to the offset
    lw a0, 0(t0) # load the value at the offset into a0
    # now a0 contains the value of f at the input value
    # we can return from the function

    # This is how you return from a function. You'll learn more about this later.
    # This should be the last line in your program.
    jr ra
