#!/bin/bash

SPACE_MARKER="\xb7"
SED_ERR="\x1b[31m"
SED_NC="\x1b[0m"
if [[ "$LANG" =~ .*UTF-8 ]]
then
   SPACE_MARKER="\xe2\x80\xa2"
fi

for dir in ${1:-$(readlink -f .)/../../**/test}
do
   if [ -d "${dir}" ]
   then
      pushd "${dir}" >/dev/null
      echo "======= suite $(readlink -f ${dir}) ========="
      for test in test.*.sh
      do
         echo -e "\nExecuting $test\n----------------------------------"
         "./${test}" | sed -e 's/\(ASSERT:expected:\)</'"${SED_ERR}"'\1\n<'"${SED_NC}"'/' \
            -e 's/> \(but was:\)</'"${SED_ERR}"'>\n\1\n<'"${SED_NC}"'/' -e 's/ /'"${SPACE_MARKER}"'/g'
      done
      popd >/dev/null
      echo
   fi
done
