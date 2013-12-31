#!/bin/bash

. ../src/arglist.sh
. ../../common/src/test-utils.sh

function testIsTrueFunctionReturnsTrue() {
   isTrue yes
   assertResult 0
   isTrue YES
   assertResult 0
   isTrue Yes
   assertResult 0
   isTrue 1
   assertResult 0
   isTrue y
   assertResult 0
   isTrue Y
   assertResult 0
   isTrue true
   assertResult 0
   isTrue TRUE
   assertResult 0
   isTrue True
   assertResult 0
}

function testIsTrueFunctionReturnsFalse() {
   isTrue no
   assertResult 1
   isTrue NO
   assertResult 1
   isTrue No
   assertResult 1
   isTrue 0
   assertResult 1
   isTrue
   assertResult 1
   isTrue n
   assertResult 1
   isTrue N
   assertResult 1
   isTrue false
   assertResult 1
   isTrue FALSE
   assertResult 1
   isTrue False
   assertResult 1
}

function testIsTrueFunctionReturnsFalseButProducesWarning() {
   isTrue invalidValue 2>/dev/null
   assertResult 1
   assertEquals "Warning: Invalid boolean value. False assumed." "$(isTrue invalidValue 2>&1)"
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

. ../../common/lib/shunit/src/shunit2
