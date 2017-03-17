#!/bin/bash

echo
echo "New script should return to original execution directory"
echo "  Correct directory: $TEST_DIR"
echo "  Current directory: `pwd`"
echo
exit_on_fail $([ "$TEST_DIR" == "`pwd`" ]; echo "$?") "FAIL: The test directory is not equal to the present working directory!"
