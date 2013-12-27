#!/bin/bash

function testIsTrueFunctionReturnsTrue() {
   isTrue yes
   assertLastResultEquals 0
   isTrue YES
   assertLastResultEquals 0
   isTrue Yes
   assertLastResultEquals 0
   isTrue 1
   assertLastResultEquals 0
   isTrue y
   assertLastResultEquals 0
   isTrue Y
   assertLastResultEquals 0
   isTrue true
   assertLastResultEquals 0
   isTrue TRUE
   assertLastResultEquals 0
   isTrue True
   assertLastResultEquals 0
}

function testIsTrueFunctionReturnsFalse() {
   isTrue no
   assertLastResultEquals 1
   isTrue NO
   assertLastResultEquals 1
   isTrue No
   assertLastResultEquals 1
   isTrue 0
   assertLastResultEquals 1
   isTrue
   assertLastResultEquals 1
   isTrue n
   assertLastResultEquals 1
   isTrue N
   assertLastResultEquals 1
   isTrue false
   assertLastResultEquals 1
   isTrue FALSE
   assertLastResultEquals 1
   isTrue False
   assertLastResultEquals 1
}

function testIsTrueFunctionReturnsFalseButProducesWarning() {
   isTrue invalidValue 2>/dev/null
   assertLastResultEquals 1
   assertEquals "Warning: Invalid boolean value. False assumed." "$(isTrue invalidValue 2>&1)"
}

function testIsFunction() {
   no ""
   assertLastResultEquals 0
   no "x"
   assertLastResultEquals 1
}

function testNoFunction() {
   is ""
   assertLastResultEquals 1
   is "x"
   assertLastResultEquals 0
}

. ../arglist/arglist.sh

. test-utils.sh
. lib/shunit/src/shunit2
