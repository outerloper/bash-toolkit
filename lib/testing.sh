#!/bin/bash

# TODO fix tests

# Self-check - executes tests. Takes 2 optional params which narrow range of test files to execute. $1 is module name and $2 - pattern to match to a test file.
run-tests() {
    local path=${HOME}/.bash-toolkit
    if [[ -n ${1} ]]
    then
        path=${path}/${1}
    else
        path=${path}/**
    fi

    for dir in ${path}/test
    do
       if [ -d "${dir}" ]
       then
          pushd "${dir}" >/dev/null
          echo "======= suite $(readlink -f ${dir}) ========="
          for test in test.*.sh
          do
             if ! [[ -f "${test}" ]] ; then continue ; fi
             if [[ -n "${2}" ]] && ! [[ "${test}" =~ ${2} ]] ; then continue ; fi
             _run-test "${test}"
          done
          popd >/dev/null
          echo
       fi
    done
}

_run-test() {
    local VISIBLE_SPACE="\xb7"
    local ERROR_COLOR="\x1b[31m"
    local NO_COLOR="\x1b[0m"
    #if [[ "$LANG" =~ .*UTF-8 ]]
    #then
    #   VISIBLE_SPACE="\xe2\x80\xa2"
    #fi
    echo -e "\nExecuting $test\n----------------------------------"
    "./${1}" | sed \
        -e 's/\(ASSERT:expected:\)</'"${ERROR_COLOR}"'\1\n<'"${NO_COLOR}"'/' \
        -e 's/> \(but was:\)</'"${ERROR_COLOR}"'>\n\1\n<'"${NO_COLOR}"'/' \
        -e 's/ /'"${VISIBLE_SPACE}"'/g'
}

STDOUT=/tmp/unittest-out
STDERR=/tmp/unittest-err

assertResult() {
   local result=$?
   if (( $# > 1 ))
   then
      assertEquals "Wrong result: $1." "$2" ${result}
   else
      assertEquals "Wrong result." "$1" ${result}
   fi
}
export -f assertResult

assertOk() {
   local result=$?
   if (( $# > 0 ))
   then
      assertEquals "Expected success but was failure: $1." 0 ${result}
   else
      assertEquals "Expected success but was failure." 0 ${result}
   fi
}
export -f assertOk

assertNotOk() {
   local result=$?
   if (( $# > 0 ))
   then
      assertNotEquals "Expected failure but was success: $1." 0 ${result}
   else
      assertNotEquals "Expected failure but was success." 0 ${result}
   fi
}
export -f assertNotOk

assertStdOut() {
   if (( $# > 1 ))
   then
      assertEquals "Difference on STDOUT: $1." "$2" "$(cat <${STDOUT})"
   else
      assertEquals "Difference on STDOUT." "$1" "$(cat <${STDOUT})"
   fi
}
export -f assertStdOut

assertStdErr() {
   if (( $# > 1 ))
   then
      assertEquals "Difference on STDERR: $1." "$2" "$(cat <${STDERR})"
   else
      assertEquals "Difference on STDERR." "$1" "$(cat <${STDERR})"
   fi
}
export -f assertStdErr


assertOutput() {
   if (( $# > 2 ))
   then
      assertEquals "Difference in STDOUT: $1." "$2" "$(cat <${STDOUT})"
      assertEquals "Difference in STDERR: $1." "$3" "$(cat <${STDERR})"
   else
      assertEquals "Difference in STDOUT." "$1" "$(cat <${STDOUT})"
      assertEquals "Difference in STDERR." "$2" "$(cat <${STDERR})"
   fi
}
export -f assertOutput

assertPwd() {
   if (( $# > 1 ))
   then
      assertEquals "Unexpected PWD: ${1}." "${2}" "${PWD}"
   else
      assertEquals "Unexpected PWD." "${1}" "${PWD}"
   fi
}
export -f assertPwd
