#!/bin/bash

source utils.functions.sh
source ../src/utils.tests.sh

function setUp() {
   function _testFunction() {
      echo 'Hello world'
   }
}

function testIsFunction() {
   -fun _testFunction || fail '-fun should return true when function exists'

   unset -f _testFunction
   -fun _testFunction && fail '-fun should return false when function does not exist'
}

function testRenameFunction() {
   -fun _renamedFunction && unset -f _renamedFunction
   -fun _renamedFunction && fail '_renamedFunction should not exist'
   -fun _testFunction || fail '_testFunction should exist'

   rename-function _testFunction _renamedFunction
   -fun _testFunction && fail '_testFunction should not exist'
   -fun _renamedFunction || fail '_renamedFunction should exist'
}

function testEchoFunctionBody() {
   echo-function-body _testFunction >"${STDOUT}"
   assertStdOut "    echo 'Hello world'"
}

source ../lib/shunit/src/shunit2
