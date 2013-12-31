#!/bin/bash

for test in *.test.sh
do
   echo -e "\nExecuting $test\n----------------------------------"
   "./${test}"
done
