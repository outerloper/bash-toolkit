#!/bin/bash

STDOUT=/tmp/unittest-out
STDERR=/tmp/unittest-err

function assertResult() {
   local result=$?
   if (( $# > 1 ))
   then
      assertEquals "Wrong result: $1." "$2" ${result}
   else
      assertEquals "Wrong result." "$1" ${result}
   fi
}
export -f assertResult

function assertOk() {
   local result=$?
   if (( $# > 0 ))
   then
      assertEquals "Expected success but was failure: $1." 0 ${result}
   else
      assertEquals "Expected success but was failure." 0 ${result}
   fi
}
export -f assertOk

function assertNotOk() {
   local result=$?
   if (( $# > 0 ))
   then
      assertNotEquals "Expected failure but was success: $1." 0 ${result}
   else
      assertNotEquals "Expected failure but was success." 0 ${result}
   fi
}
export -f assertNotOk

function assertStdOut() {
   if (( $# > 1 ))
   then
      assertEquals "Difference on STDOUT: $1." "$2" "$(cat <${STDOUT})"
   else
      assertEquals "Difference on STDOUT." "$1" "$(cat <${STDOUT})"
   fi
}
export -f assertStdOut

function assertStdErr() {
   if (( $# > 1 ))
   then
      assertEquals "Difference on STDERR: $1." "$2" "$(cat <${STDERR})"
   else
      assertEquals "Difference on STDERR." "$1" "$(cat <${STDERR})"
   fi
}
export -f assertStdErr


function assertOutput() {
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

function assertPwd() {
   if (( $# > 1 ))
   then
      assertEquals "Unexpected PWD: ${1}." "${PWD}" "${2}"
   else
      assertEquals "Unexpected PWD." "${PWD}" "${1}"
   fi
}
export -f assertPwd
