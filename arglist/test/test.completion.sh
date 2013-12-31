#!/bin/bash

. ../../common/src/test-utils.sh
. common.sh

DISPLAY_INSTANT_HELP=1

function assertCompletion() {
   local completedArgs
   if [ -z "${2//[0-9]}" ]
   then
      completedArgs=$2
      shift
   fi

   getCompletion "$1" "${completedArgs}" >${STDOUT} 2>${STDERR}
   assertOutput "$2" "${3:+$(echo -e "\n\e[1;30m$3\e[0m")}"
}

function getCompletion() {
   local optionsSpec=$1
   local COMPREPLY
   local COMP_CWORD=${2:-$((${#COMP_WORDS[@]} - 1))}
   "__argComp_${COMP_WORDS[0]}" ${optionsSpec}
   echo "${COMPREPLY[@]}"
}


function testCompletionWIthoutAnyParametersGiven() {
   COMP_WORDS=(greet '')
   assertCompletion options '--times --loud --persons hello salut privet ciao serwus ahoj' 'phrase: Greeting phrase.'
}


function testNAryParamCompletion() {
   COMP_WORDS=(greet hello --persons '')
   assertCompletion options 'john bob alice world' '--persons: Persons to greet.'
}

function testNAryParamCompletionWhenOneOptionProvided() {
   COMP_WORDS=(greet hello --persons john b)
   assertCompletion options 'bob' ''
}

function testSwitchesCompletion() {
   COMP_WORDS=(greet hello '')
   assertCompletion options '--times --loud --persons' 'phrase: Greeting phrase.'
}

function testCompletionAfterBinaryOption() {
   COMP_WORDS=(greet --loud '')
   assertCompletion options '--times --persons' '--loud: Whether to greet loudly.'
}

function testNoCompletionWhenNotSpecified() {
   COMP_WORDS=(greet --times '')
   assertCompletion options '' ''
}

function testNoCompletionWhenAllOptionsUsedAndFlagIsLast() {
   COMP_WORDS=(greet --persons world --times 5 --loud '')
   assertCompletion options '' ''
}

function testNoCompletionWhenAllOptionsUsedAndUnaryOptionIsLast() {
   COMP_WORDS=(greet --persons world --loud --times 5 '')
   assertCompletion options '' ''
}

function testCompletionWhenAllOptionsUsedButLastIsMultiArg() {
   COMP_WORDS=(greet --times 5 --loud --persons world '')
   assertCompletion options 'john bob alice world' '--persons: Persons to greet.'
}

function testCompletionWhenQuotedArgWithSpaces() {
   COMP_WORDS=(greet --times 5 --loud --persons world '')
 assertCompletion options 'john bob alice world' '--persons: Persons to greet.'
}

function testFunctionalCompletion() {
   COMP_WORDS=(list-dir --dir '')
   assertCompletion options 'dir1 dir2 dir3' ''
}

if false # execute manually to see the result for writing tests
then
   COMP_WORDS=(greet --times '')
   getCompletion options
fi

. ../../common/lib/shunit/src/shunit2

