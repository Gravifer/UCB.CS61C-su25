import sys
from collections.abc import Callable
import unittest
from framework import AssemblyTest, print_coverage, _venus_default_args
from tools.check_hashes import check_hashes

"""
Coverage tests for project 2 is meant to make sure you understand
how to test RISC-V code based on function descriptions.
Before you attempt to write these tests, it might be helpful to read
unittests.py and framework.py.
Like project 1, you can see your coverage score by submitting to gradescope.
The coverage will be determined by how many lines of code your tests run,
so remember to test for the exceptions!
"""

"""
abs_loss
# =======================================================
# FUNCTION: Get the absolute difference of 2 int arrays,
#   store in the result array and compute the sum
# Arguments:
#   a0 (int*) is the pointer to the start of arr0
#   a1 (int*) is the pointer to the start of arr1
#   a2 (int)  is the length of the arrays
#   a3 (int*) is the pointer to the start of the result array

# Returns:
#   a0 (int)  is the sum of the absolute loss
# Exceptions:
# - If the length of the array is less than 1,
#   this function terminates the program with error code 36.
# =======================================================
"""


class TestAbsLoss(unittest.TestCase):
    def test_simple(self):
        # load the test for abs_loss.s
        t = AssemblyTest(self, "../coverage-src/abs_loss.s")

        # //raise NotImplementedError("TODO")

        # create array0 in the data section
        lst0 = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        arr0 = t.array(lst0) # DONE
        # load address of `array0` into register a0       
        t.input_array("a0", arr0) # DONE
        # create array1 in the data section
        lst1 = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        arr1 = t.array(lst1) # DONE
        # load address of `array1` into register a1
        t.input_array("a1", arr1) # DONE
        # set a2 to the length of the array
        l = min(len(lst0), len(lst1))
        t.input_scalar("a2", l) # DONE
        # create a result array in the data section (fill values with -1)
        losses = [abs(lst0[i] - lst1[i]) for i in range(l)]
        result = t.array([-1] * l) # DONE
        # load address of `array2` into register a3
        t.input_array("a3", result) # DONE
        # call the `abs_loss` function
        t.call("abs_loss") # DONE
        # check that the result array contains the correct output
        t.check_array(result, losses) # DONE
        # check that the register a0 contains the correct output
        t.check_scalar("a0", sum(losses)) # DONE
        # generate the `assembly/TestAbsLoss_test_simple.s` file and run it through venus
        t.execute()

    # Add other test cases if necessary
    def doAbsLoss(self, lst0, lst1, n = None, losses = None, code=0):
        if n is None:
            n = min(len(lst0), len(lst1))
        else:
            assert (n <= min(len(lst0), len(lst1))), "n must be less than or equal to the length of the input arrays"
        if losses is None:
            losses = lambda x, y: abs(x - y)
        else:
            assert (len(losses) >= n) , "losses must be at least as long as n"
        t = AssemblyTest(self, "../coverage-src/abs_loss.s")
        doLoss_(t, "abs_loss", lst0, lst1, n, losses, code)

    def test_abs_loss_bad_len(self):
        self.doAbsLoss([1, 2, 3], [4, 5, 6], n=-1, losses=[3, 3, 3], code=36)

    def test_reverse(self):
        self.doAbsLoss([4, 5, 6], [1, 2, 3], n=3, losses=[3, 3, 3])

    @classmethod
    def tearDownClass(cls):
        print_coverage("abs_loss.s", verbose=False)


"""
squared_loss
# =======================================================
# FUNCTION: Get the squared difference of 2 int arrays,
#   store in the result array and compute the sum
# Arguments:
#   a0 (int*) is the pointer to the start of arr0
#   a1 (int*) is the pointer to the start of arr1
#   a2 (int)  is the length of the arrays
#   a3 (int*) is the pointer to the start of the result array

# Returns:
#   a0 (int)  is the sum of the squared loss
# Exceptions:
# - If the length of the array is less than 1,
#   this function terminates the program with error code 36.
# =======================================================
"""


class TestSquaredLoss(unittest.TestCase):
    def test_simple(self):
        self.doSquaredLoss([1, 2, 3, 4, 5, 6, 7, 8, 9], [1, 2, 3, 4, 5, 6, 7, 8, 9], n=9)
        return
        # load the test for squared_loss.s
        t = AssemblyTest(self, "../coverage-src/squared_loss.s")

        raise NotImplementedError("TODO")

        # TODO
        # create input arrays in the data section
        # TODO
        # load array addresses into argument registers
        # TODO
        # load array length into argument register
        # TODO
        # create a result array in the data section (fill values with -1)
        # TODO
        # load result array address into argument register
        # TODO
        # call the `squared_loss` function
        # TODO
        # check that the result array contains the correct output
        # TODO
        # check that the register a0 contains the correct output
        # TODO
        # generate the `assembly/TestSquaredLoss_test_simple.s` file and run it through venus
        # TODO

    # Add other test cases if neccesary
    def doSquaredLoss(self, lst0, lst1, n = None, losses = None, code=0):
        if n is None:
            n = min(len(lst0), len(lst1))
        else:
            assert (n <= min(len(lst0), len(lst1))), "n must be less than or equal to the length of the input arrays"
        if losses is None:
            losses = lambda x, y: (x - y)**2
        else:
            assert (len(losses) >= n), "losses must be at least as long as n"
        t = AssemblyTest(self, "../coverage-src/squared_loss.s")
        doLoss_(t, "squared_loss", lst0, lst1, n, losses, code)

    def test_squared_loss_bad_len(self):
        self.doSquaredLoss([1, 2, 3], [4, 5, 6], n=0, losses=[3, 3, 3], code=36)
    def test_reverse(self):
        self.doSquaredLoss([4, 5, 6], [1, 2, 3], n=3, losses=[9, 9, 9])

    @classmethod
    def tearDownClass(cls):
        print_coverage("squared_loss.s", verbose=False)


"""
zero_one_loss
# =======================================================
# FUNCTION: Generates a 0-1 classifer array inplace in the result array,
#  where result[i] = (arr0[i] == arr1[i])
# Arguments:
#   a0 (int*) is the pointer to the start of arr0
#   a1 (int*) is the pointer to the start of arr1
#   a2 (int)  is the length of the arrays
#   a3 (int*) is the pointer to the start of the result array

# Returns:
#   NONE
# Exceptions:
# - If the length of the array is less than 1,
#   this function terminates the program with error code 36.
# =======================================================
"""


class TestZeroOneLoss(unittest.TestCase):
    def test_simple(self):
        self.doZeroOneLoss([1, 2, 3, 4, 5, 6, 7, 8, 9], [1, 2, 3, 4, 5, 6, 7, 8, 9], n=9)
        return
        # load the test for zero_one_loss.s
        t = AssemblyTest(self, "../coverage-src/zero_one_loss.s")

        raise NotImplementedError("TODO")

        # create input arrays in the data section
        # TODO
        # load array addresses into argument registers
        # TODO
        # load array length into argument register
        # TODO
        # create a result array in the data section (fill values with -1)
        # TODO
        # load result array address into argument register
        # TODO
        # call the `zero_one_loss` function
        # TODO
        # check that the result array contains the correct output
        # TODO
        # generate the `assembly/TestZeroOneLoss_test_simple.s` file and run it through venus
        # TODO

    # Add other test cases if neccesary
    def doZeroOneLoss(self, lst0, lst1, n = None, losses = None, code=0):
        if n is None:
            n = min(len(lst0), len(lst1))
        else:
            assert (n <= min(len(lst0), len(lst1))), "n must be less than or equal to the length of the input arrays"
        if losses is None:
            losses = lambda x, y: 1 if x == y else 0
        else:
            assert (len(losses) >= n), "losses must be at least as long as n"
        t = AssemblyTest(self, "../coverage-src/zero_one_loss.s")
        doLoss_(t, "zero_one_loss", lst0, lst1, n, losses, code)

    def test_zero_one_loss_bad_len(self):
        self.doZeroOneLoss([1, 2, 3], [4, 5, 6], n=0, losses=[0, 0, 0], code=36)
    def test_reverse(self):
        self.doZeroOneLoss([4, 5, 6], [1, 2, 3], n=3, losses=[0, 0, 0])

    @classmethod
    def tearDownClass(cls):
        print_coverage("zero_one_loss.s", verbose=False)


"""
initialize_zero
# =======================================================
# FUNCTION: Initialize a zero array with the given length
# Arguments:
#   a0 (int) size of the array

# Returns:
#   a0 (int*)  is the pointer to the zero array
# Exceptions:
# - If the length of the array is less than 1,
#   this function terminates the program with error code 36.
# - If malloc fails, this function terminates the program with exit code 26.
# =======================================================
"""


class TestInitializeZero(unittest.TestCase):
    def test_simple(self):
        t = AssemblyTest(self, "../coverage-src/initialize_zero.s")

        # //raise NotImplementedError("TODO")
        l = 3
        # input the length of the desired array
        t.input_scalar("a0", l) # DONE
        # call the `initialize_zero` function
        t.call("initialize_zero") # DONE
        # check that the register a0 contains the correct array (hint: look at the check_array_pointer function in framework.py)
        t.check_array_pointer("a0", [0] * l) # DONE
        t.execute()

    # Add other test cases if neccesary
    def test_empty(self):
        t = AssemblyTest(self, "../coverage-src/initialize_zero.s")
        l = 0
        # input the length of the desired array
        t.input_scalar("a0", l)
        # call the `initialize_zero` function
        t.call("initialize_zero")
        t.execute(code=36)
    def test_malloc_fail(self):
        t = AssemblyTest(self, "../coverage-src/initialize_zero.s")
        # ! set length to a large value to trigger malloc failure
        l = 2**31 - 1  # This is a large value that will likely cause malloc to fail
        # input the length of the desired array
        t.input_scalar("a0", l)
        # call the `initialize_zero` function
        t.call("initialize_zero")
        t.execute(code=26)

    @classmethod
    def tearDownClass(cls):
        print_coverage("initialize_zero.s", verbose=False)



def doLoss_(t:AssemblyTest, fn:str, lst0:list[int], lst1:list[int], n:int, losses:list[int]|Callable[[int, int], int], code:int = 0):
    # load addresses of input arrays
    t.input_array("a0", t.array(lst0))
    t.input_array("a1", t.array(lst1))
    # set a2 to the length of the array
    assert (n <= min(len(lst0), len(lst1))), "n must be less than or equal to the length of the input arrays"
    t.input_scalar("a2", n)
    # create a result array in the data section (fill values with -1)
    # load address into register a3
    if callable(losses):
        losses = [losses(lst0[i], lst1[i]) for i in range(n)]
    else:
        assert (len(losses) >= n), f"losses {losses} must be at least as long as n"
        losses = losses[:n]
    arr2 = t.array([-1] * n)
    t.input_array("a3", arr2)
    # call the `abs_loss` function
    t.call(fn)
    # check that the result array contains the correct output
    if n > 0:
        t.check_array(arr2, losses)
    # check that the register a0 contains the correct output
    if fn != "zero_one_loss":
        # for zero_one_loss, we don't check the sum
        t.check_scalar("a0", sum(losses))
    # generate the `assembly/TestAbsLoss_test_simple.s` file and run it through venus
    t.execute(code=code)
unittest.TestCase.TestLoss_doLoss_ = doLoss_ # type: ignore

if __name__ == "__main__":
    split_idx = sys.argv.index("--")
    for arg in sys.argv[split_idx + 1 :]:
        _venus_default_args.append(arg)

    check_hashes()

    unittest.main(argv=sys.argv[:split_idx])
