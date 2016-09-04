#!/bin/bash

source ../src/utils.sh
source ../src/testing.sh

function testIsTrueFunctionReturnsTrue() {
   -true yes
   assertResult 0
   -true YES
   assertResult 0
   -true Yes
   assertResult 0
   -true 1
   assertResult 0
   -true y
   assertResult 0
   -true Y
   assertResult 0
   -true true
   assertResult 0
   -true TRUE
   assertResult 0
   -true True
   assertResult 0
}

function testIsTrueFunctionReturnsFalse() {
   -true no
   assertResult 1
   -true NO
   assertResult 1
   -true No
   assertResult 1
   -true 0
   assertResult 1
   -true
   assertResult 1
   -true n
   assertResult 1
   -true N
   assertResult 1
   -true false
   assertResult 1
   -true FALSE
   assertResult 1
   -true False
   assertResult 1
}

function testIsTrueReturnsFalseButProducesWarningOnInvalidValue() {
   -true invalidValue 2>/dev/null
   assertResult 1
   assertEquals "Warning: Invalid boolean value. False assumed." "$(-true invalidValue 2>&1)"
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
   -utf
   assertOk
}

function testIsUtfReturnsNotOk() {
   local LANG="en_US.ISO-8859-1"
   -utf
   assertNotOk
}

function testIsDirEmpty() {
   dir="/tmp/testIsDirEmpty"
   rm -rf "$dir"
   mkdir "$dir"
   -ed "$dir"
   assertOk 'New dir is empty'

   touch "$dir/f"
   -ed "$dir"
   assertNotOk 'Dir with file is not empty'

   rm "$dir/f"
   -ed "$dir"
   assertOk 'Dir with only file deleted is empty'

   mkdir "$dir/d"
   -ed "$dir"
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
