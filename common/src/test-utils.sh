#!/bin/bash

STDOUT=/tmp/unittest-out
STDERR=/tmp/unittest-err

function assertResult() {
   local result=$?
   if (( $# > 1 ))
   then
      assertEquals "$1" "$2" ${result}
   else
      assertEquals "$1" ${result}
   fi
}

function assertStdOut() {
   if (( $# > 1 ))
   then
      assertEquals "$1" "$2" "$(cat <${STDOUT})"
   else
      assertEquals "$1" "$(cat <${STDOUT})"
   fi
}

function assertStdErr() {
   if (( $# > 1 ))
   then
      assertEquals "$1" "$2" "$(cat <${STDERR})"
   else
      assertEquals "$1" "$(cat <${STDERR})"
   fi
}


function assertOutput() {
   if (( $# > 2 ))
   then
      assertEquals "$1" "$2" "$(cat <${STDOUT})"
      assertEquals "$1" "$3" "$(cat <${STDERR})"
   else
      assertEquals "$1" "$(cat <${STDOUT})"
      assertEquals "$2" "$(cat <${STDERR})"
   fi
}
