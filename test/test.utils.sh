#!/bin/bash

source ../src/utils.sh
source ../src/testing.sh

function testIsTrueFunctionReturnsTrue() {
   is yes
   assertResult 0
   is YES
   assertResult 0
   is Yes
   assertResult 0
   is 1
   assertResult 0
   is y
   assertResult 0
   is Y
   assertResult 0
   is true
   assertResult 0
   is TRUE
   assertResult 0
   is True
   assertResult 0
}

function testIsTrueFunctionReturnsFalse() {
   is no
   assertResult 1
   is NO
   assertResult 1
   is No
   assertResult 1
   is 0
   assertResult 1
   is
   assertResult 1
   is n
   assertResult 1
   is N
   assertResult 1
   is false
   assertResult 1
   is FALSE
   assertResult 1
   is False
   assertResult 1
}

function testIsTrueReturnsFalseButProducesWarningOnInvalidValue() {
   is invalidValue 2>/dev/null
   assertResult 1
   assertEquals "Warning: Invalid boolean value. False assumed." "$(is invalidValue 2>&1)"
}

function testIs() {
   -z ""
   assertResult 0
   -z "x"
   assertResult 1
}

function testNo() {
   -n ""
   assertResult 1
   -n "x"
   assertResult 0
}

function testIsUtfReturnsOk() {
   local LANG="pl_PL.UTF-8"
   is-encoding UTF-8
   assertOk
}

function testIsUtfReturnsNotOk() {
   local LANG="en_US.ISO-8859-1"
   is-encoding UTF-8
   assertNotOk
}

function testIsDirEmpty() {
   dir="/tmp/testIsDirEmpty"
   rm -rf "$dir"
   mkdir "$dir"
   -E "$dir"
   assertOk 'New dir is empty'

   touch "$dir/f"
   -E "$dir"
   assertNotOk 'Dir with file is not empty'

   rm "$dir/f"
   -E "$dir"
   assertOk 'Dir with only file deleted is empty'

   mkdir "$dir/d"
   -E "$dir"
   assertNotOk 'Dir with subdir is not empty'

   rm -rf "$dir"
}

function testDebugArray() {
   a=()
   print-var a > "$STDOUT"
   assertStdOut "a=( )"

   a=(2 4 5 6 10)
   print-var a > "$STDOUT"
   assertStdOut "a=( [0]=2 [1]=4 [2]=5 [3]=6 [4]=10 )"

   declare -A assoc
   assoc=( [bar]=qux [foo]=12 )
   print-var assoc > "$STDOUT"
   assertStdOut "assoc=( [bar]=qux [foo]=12 )"
}

source ../../core/lib/shunit/src/shunit2
