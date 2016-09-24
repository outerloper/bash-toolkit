#!/bin/bash

source ../../core/src/utils.tests.sh
source common.sh

function testGreet() {
   greet --help >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput "This is arglist.sh demo.
Usage:
  greet [<phrase>] <options>...
Parameters:
  <phrase>                         Greeting phrase. Default is 'Hello'.
Options:
  --times <value>                  REQUIRED. How many times to greet.
  --loud                           Whether to greet loudly.
  --persons <value> [...]          REQUIRED. Persons to greet." ''
}

function testCalculator() {
   calculator --help >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput "This is arglist.sh demo - integer calculator.
Usage:
  calculator <operation-and-first-arg> [...] <options>...
Parameters:
  <operation-and-first-arg>        Operation name and first numeric argument
Options:
  --to <value>                     REQUIRED. Second numeric argument" ''
}

function testListDir() {
   list-dir --help >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput "This is arglist.sh demo.
Usage:
  list-dir <options>...
Options:
  --include-hidden                 ""
  --dir <value>                    " ''
}

function testListDirWithRedundantOptions() {
   list-dir --dir --help >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput "This is arglist.sh demo.
Usage:
  list-dir <options>...
Options:
  --include-hidden                 ""
  --dir <value>                    " ''
}

function testListDirWithRedundantOptions2() {
   list-dir --dir --help --include--hidden x y z --ddd >${STDOUT} 2>${STDERR}
   assertResult 1
   assertOutput "This is arglist.sh demo.
Usage:
  list-dir <options>...
Options:
  --include-hidden                 ""
  --dir <value>                    " ''
}

source ../lib/shunit/src/shunit2

