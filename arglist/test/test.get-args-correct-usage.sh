#!/bin/bash

. ../../common/src/test-utils.sh
. common.sh

function testWithoutMainParam() {
   greet --persons bob --times 2 >${STDOUT} 2>${STDERR}
   assertResult 0
   assertOutput "            main: 'Hello'
           times: '2'
         persons: 'bob'
Hello bob
Hello bob" ''
}

function testWithMainParam() {
   greet Hi --persons bob --times 2 >${STDOUT} 2>${STDERR}
   assertResult 0
   assertOutput "            main: 'Hi'
           times: '2'
         persons: 'bob'
Hi bob
Hi bob" ''
}

function testWithMultipleNAryParam() {
   greet Hi --persons john bob --times 2 >${STDOUT} 2>${STDERR}
   assertResult 0
   assertOutput "            main: 'Hi'
           times: '2'
         persons: 'john bob'
Hi john bob
Hi john bob" ''
}

function testWithFlag() {
   greet Hi --persons bob --times 2 --loud >${STDOUT} 2>${STDERR}
   assertResult 0
   assertOutput "            main: 'Hi'
           times: '2'
            loud: '1'
         persons: 'bob'
Hi bob!!
Hi bob!!" ''
}

function testWithMultipleWordParameters() {
   greet "Good 'morning'" --persons 'Billy "xxx" Jean' --times 2 --loud >${STDOUT} 2>${STDERR}
   assertResult 0
   assertOutput "            main: 'Good 'morning''
           times: '2'
            loud: '1'
         persons: 'Billy \"xxx\" Jean'
Good 'morning' Billy \"xxx\" Jean!!
Good 'morning' Billy \"xxx\" Jean!!" ''
}

function testNAryMainParameter() {
   calculator add 23 --to 45 >${STDOUT} 2>${STDERR}
   assertResult 0
   assertOutput "            main: 'add 23'
              to: '45'
68" ''
}

function testClearParameterValueBetweenInvocations() {
   list-dir --include-hidden >${STDOUT} 2>${STDERR}
   assertResult 0
   assertOutput "          hidden: '1'
file1 file2 .file3" ''

   list-dir >${STDOUT} 2>${STDERR}
   assertResult 0
   assertOutput "file1 file2" ''

   list-dir --include-hidden >${STDOUT} 2>${STDERR}
   assertResult 0
   assertOutput "          hidden: '1'
file1 file2 .file3" ''

}

. ../../common/lib/shunit/src/shunit2
