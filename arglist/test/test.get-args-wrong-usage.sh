#!/bin/bash

source ../../core/src/utils.tests.sh
source common.sh

function testNoParams() {
   greet >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput '' 'Missing mandatory option: --times.
Missing mandatory option: --persons.'
}

function testOnlyPrimaryParam() {
   greet hello >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput '' 'Missing mandatory option: --times.
Missing mandatory option: --persons.'
}

function testOnlyPrimaryParamAndOptionWithoutRequiredNAryParameter() {
   greet --persons >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput '' 'Missing required parameter for --persons.
Missing mandatory option: --times.'
}

function testWithPrimaryParamAndWithoutOneMandatoryOption() {
   greet --persons john bob >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput '' 'Missing mandatory option: --times.'
}

function testWithOptionWithoutMandatoryUnaryParameter() {
   greet --persons john bob --times >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput '' 'Missing required parameter for --times.'
}

function testUnexpectedOptionParam() {
   greet --persons john bob --times 4 --loud loud >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput '' 'Unexpected value: loud.'
}

function test2UnexpectedMainParams() {
   greet hello beautiful world --persons john bob --times 4 >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput '' 'Unexpected value: beautiful.
Unexpected value: world.'
}

function testUnknownOption() {
   greet --persons john bob --times 4 --silent >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput '' 'Unknown option: --silent.'
}

function testDuplicateOptions() {
   greet --persons john bob --persons a b c --times 4 --times >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput '' 'Duplicate usage of option --persons.
Duplicate usage of option --times.'
}

function testMissingNAryMainParameter() {
   calculator --to 45 >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput '' 'Missing operation-and-first-arg.'
}

function testMissingNAryMainParameter() {
   calculator --to 45 >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput '' 'Missing operation-and-first-arg.'
}

source ../../core/lib/shunit/src/shunit2

