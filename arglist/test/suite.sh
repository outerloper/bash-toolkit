#!/bin/bash

for test in test.*.sh
do
   echo -e "\nExecuting $test\n----------------------------------"
   "./${test}" | sed -e 's/\(ASSERT:expected:\)</\x1b[31m\1\n<\x1b[0m/' -e 's/> \(but was:\)</\x1b[31m>\n\1\n<\x1b[0m/' -e 's/ /\xb7/g'
done
