#!/bin/bash

source ../src/utils.sh
source ../../core/src/test-utils.sh

function ret() {
   return $1
}

function testAssertResult() {
   ret 0
   assertResult 0
   ret 1
   assertResult 1
   ret 2
   assertResult 2
}

function testAssertOk() {
   ret 0
   assertOk
   ret 1
   assertNotOk
   ret 2
   assertNotOk
}

function testAssertOutput() {
   echo "xx" >"$STDOUT"
   assertStdOut "xx"

   echo "yy" >"$STDERR"
   assertStdErr "yy"

   echo "ooo" >"$STDOUT"
   echo "eee" >"$STDERR"
   assertOutput "ooo" "eee"
}

source ../../core/lib/shunit/src/shunit2
