#!/bin/bash

. ../src/utils.sh
. ../../common/src/test-utils.sh

function testIsNumReturnsTrueForNaturalNumbersAndEmptyValue() {
   isNum 0
   assertOk
   isNum 4
   assertOk
   isNum 45665644
   assertOk
   isNum ''
   assertOk
}

function testIsNumReturnsTrueForNotNaturalNumbers() {
   isNum xxx
   assertNotOk
   isNum 61x
   assertNotOk
   isNum x45
   assertNotOk
   isNum 666g666
   assertNotOk
}

. ../../common/lib/shunit/src/shunit2
