#!/bin/bash

source ../src/utils.sh
source ../src/utils.tests.sh

function testIsTrueFunctionReturnsTrue() {
   is-true yes
   assertResult 0
   is-true YES
   assertResult 0
   is-true Yes
   assertResult 0
   is-true 1
   assertResult 0
   is-true y
   assertResult 0
   is-true Y
   assertResult 0
   is-true true
   assertResult 0
   is-true TRUE
   assertResult 0
   is-true True
   assertResult 0
}

function testIsTrueFunctionReturnsFalse() {
   is-true no
   assertResult 1
   is-true NO
   assertResult 1
   is-true No
   assertResult 1
   is-true 0
   assertResult 1
   is-true
   assertResult 1
   is-true n
   assertResult 1
   is-true N
   assertResult 1
   is-true false
   assertResult 1
   is-true FALSE
   assertResult 1
   is-true False
   assertResult 1
}

function testIsTrueReturnsFalseButProducesWarningOnInvalidValue() {
   is-true invalidValue 2>/dev/null
   assertResult 1
   assertEquals "Warning: Invalid boolean value. False assumed." "$(is-true invalidValue 2>&1)"
}

function testIs() {
   no ""
   assertResult 0
   no "x"
   assertResult 1
}

function testNo() {
   is ""
   assertResult 1
   is "x"
   assertResult 0
}

function testIsUtfReturnsOk() {
   local LANG="pl_PL.UTF-8"
   is-utf
   assertOk
}

function testIsUtfReturnsNotOk() {
   local LANG="en_US.ISO-8859-1"
   is-utf
   assertNotOk
}

function testIsDirEmpty() {
   dir="/tmp/testIsDirEmpty"
   rm -rf "${dir}"
   mkdir "${dir}"
   is-dir-empty "${dir}"
   assertOk 'New dir is empty'

   touch "${dir}/f"
   is-dir-empty "${dir}"
   assertNotOk 'Dir with file is not empty'

   rm "${dir}/f"
   is-dir-empty "${dir}"
   assertOk 'Dir with only file deleted is empty'

   mkdir "${dir}/d"
   is-dir-empty "${dir}"
   assertNotOk 'Dir with subdir is not empty'

   rm -rf "${dir}"
}

function testDebugArray() {
   a=()
   debug-array a > "${STDOUT}"
   assertStdOut "a=( )"

   a=(2 4 5 6 10)
   debug-array a > "${STDOUT}"
   assertStdOut "a=( [0]=2 [1]=4 [2]=5 [3]=6 [4]=10 )"

   declare -A assoc
   assoc=( [bar]=qux [foo]=12 )
   debug-array assoc > "${STDOUT}"
   assertStdOut "assoc=( [bar]=qux [foo]=12 )"
}

source ../../core/lib/shunit/src/shunit2
