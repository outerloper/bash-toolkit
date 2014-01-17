#!/bin/bash

source ../src/arglist.sh
source ../../core/src/test-utils.sh

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

function testIsTrueFunctionReturnsFalseButProducesWarning() {
   is-true invalidValue 2>/dev/null
   assertResult 1
   assertEquals "Warning: Invalid boolean value. False assumed." "$(is-true invalidValue 2>&1)"
}

function testIsFunction() {
   no ""
   assertResult 0
   no "x"
   assertResult 1
}

function testNoFunction() {
   is ""
   assertResult 1
   is "x"
   assertResult 0
}

source ../../core/lib/shunit/src/shunit2
