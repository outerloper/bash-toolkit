#!/bin/bash

source ../src/utils.sh
source ../../core/src/test-utils.sh

function testIsNumReturnsTrueForNaturalNumbers() {
   isNum 0
   assertOk
   isNum 4
   assertOk
   isNum 45665644
   assertOk
}

function testIsNumReturnsTrueForNotNaturalNumbersAndEmptyValue() {
   isNum xxx
   assertNotOk
   isNum 61x
   assertNotOk
   isNum x45
   assertNotOk
   isNum 666g666
   assertNotOk
   isNum ''
   assertNotOk
}

function testIsIntReturnsTrueForIntegerNumbers() {
   isInt 0
   assertOk
   isInt 4
   assertOk
   isInt 45665644
   assertOk
   isInt -4
   assertOk
   isInt -45665644
   assertOk
}

function testIsIntReturnsTrueForNotIntegerNumbersAndEmptyValue() {
   isInt xxx
   assertNotOk xxx
   isInt 61x
   assertNotOk 61x
   isInt x45
   assertNotOk x45
   isInt 666g666
   assertNotOk 666g666
   isInt -xxx
   assertNotOk -xxx
   isInt -61x
   assertNotOk -61x
   isInt -x45
   assertNotOk -x45
   isInt -666g666
   assertNotOk -666g666
   isInt 3-
   assertNotOk 3-
   isInt -
   assertNotOk -
   isInt ''
   assertNotOk 'empty string'
}

function testIsUtfReturnsOk() {
   local LANG="pl_PL.UTF-8"
   isUtf
   assertOk
}

function testIsUtfReturnsNotOk() {
   local LANG="en_US.ISO-8859-1"
   isUtf
   assertNotOk
}

function testRealpath() {
   realpath /tmp >"${STDOUT}"
   assertStdOut /tmp

   cd /tmp
   realpath >"${STDOUT}"
   assertStdOut /tmp
}

source ../../core/lib/shunit/src/shunit2
