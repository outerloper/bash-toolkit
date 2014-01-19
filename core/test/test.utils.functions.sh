#!/bin/bash

source ../src/utils.functions.sh
source ../src/utils.tests.sh

function setUp() {
   function _testFunction() {
      echo 'Hello world'
   }
}

function testIsFunction() {
   is-function _testFunction || fail 'is-function should return true when function exists'

   unset -f _testFunction
   is-function _testFunction && fail 'is-function should return false when function does not exist'
}

function testRenameFunction() {
   is-function _renamedFunction && unset -f _renamedFunction
   is-function _renamedFunction && fail '_renamedFunction should not exist'
   is-function _testFunction || fail '_testFunction should exist'

   rename-function _testFunction _renamedFunction
   is-function _testFunction && fail '_testFunction should not exist'
   is-function _renamedFunction || fail '_renamedFunction should exist'
}

function testEchoFunctionBody() {
   echo-function-body _testFunction >"${STDOUT}"
   assertStdOut "    echo 'Hello world'"
}

source ../../core/lib/shunit/src/shunit2
