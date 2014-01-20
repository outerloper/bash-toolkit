#!/bin/bash

source ../src/utils.sh
source ../src/utils.tests.sh

function setUp() {
   chdir /tmp/
   dirs -c
   rm -rf test-chdir
   mkdir test-chdir
   chdir -- >"${STDOUT}"
}

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

function testIsTrueReturnsFalseButProducesWarningOnInvalidValue() {
   is-true invalidValue 2>/dev/null
   assertResult 1
   assertEquals "Warning: Invalid boolean value. False assumed." "$(is-true invalidValue 2>&1)"
}

function testIs() {
   no ""
   assertResult 0
   no "x"
   assertResult 1
}

function testNo() {
   is ""
   assertResult 1
   is "x"
   assertResult 0
}

function testIsUtfReturnsOk() {
   local LANG="pl_PL.UTF-8"
   is-utf
   assertOk
}

function testIsUtfReturnsNotOk() {
   local LANG="en_US.ISO-8859-1"
   is-utf
   assertNotOk
}

function testIsDirEmpty() {
   dir="/tmp/testIsDirEmpty"
   rm -rf "${dir}"
   mkdir "${dir}"
   is-dir-empty "${dir}"
   assertOk 'New dir is empty'

   touch "${dir}/f"
   is-dir-empty "${dir}"
   assertNotOk 'Dir with file is not empty'

   rm "${dir}/f"
   is-dir-empty "${dir}"
   assertOk 'Dir with only file deleted is empty'

   mkdir "${dir}/d"
   is-dir-empty "${dir}"
   assertNotOk 'Dir with subdir is not empty'

   rm -rf "${dir}"
}

function testChdirHelp() {
   chdir --help >"${STDOUT}"
   assertStdOut 'cd: usage: cd [-L|-P] [dir]
Options:
  -P   Do not follow symbolic links
  -L   Follow symbolic links (default)
Special values for dir:
  -    Previous directory
  -N   Directory with stack index N=0..9
  --   Print dir stack'
}

function testChdirPrintStack() {
   assertStdOut ' 0  /tmp'
   assertPwd /tmp

   chdir test-chdir
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  /tmp/test-chdir
 1  /tmp'
   assertPwd /tmp/test-chdir
}

function testChdirExisting() {
   chdir /
   assertOk
  chdir -- >"${STDOUT}"
   assertStdOut ' 0  /
 1  /tmp'
   assertPwd /

   chdir /tmp
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  /tmp
 1  /'
   assertPwd /tmp
}

function testChdirParent() {
   chdir ..
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  /
 1  /tmp'
   assertPwd /
}

function testChdirSelf() {
   chdir .
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  /tmp'
   assertPwd /tmp
}

function testChdirPrevious() {
   chdir test-chdir
   chdir -
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  /tmp
 1  /tmp/test-chdir'
   assertPwd /tmp

   chdir -
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  /tmp/test-chdir
 1  /tmp'
   assertPwd /tmp/test-chdir
}

function testChdirHome() {
   local HOME="/tmp/test-chdir/home"
   mkdir $HOME
   chdir ~
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  ~
 1  /tmp';
}

function testChdirNoParameters() {
   local HOME="/tmp/test-chdir/home"
   mkdir ${HOME}
   chdir
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  ~
 1  /tmp';
   assertPwd ${HOME}
}

function testChdirIndex() {
   local HOME="/tmp/test-chdir/home"
   mkdir $HOME
   chdir ~
   chdir ..
   chdir ..
   chdir ..
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  /
 1  /tmp
 2  /tmp/test-chdir
 3  ~';
   assertPwd /

   chdir -0
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  /
 1  /tmp
 2  /tmp/test-chdir
 3  ~';
   assertPwd /

   chdir -3
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  ~
 1  /
 2  /tmp
 3  /tmp/test-chdir';
   assertPwd ${HOME}

   chdir -2
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  /tmp
 1  ~
 2  /
 3  /tmp/test-chdir';
   assertPwd /tmp
}

function testChdirNonExistingIndex() {
   local pwd=$(pwd)
   chdir -5 2>/dev/null
   assertNotOk
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  /tmp';
   assertPwd "${pwd}"
}

function testChdirNonExistingDir() {
   local pwd=$(pwd)
   chdir "/tmp/test-chdir/non-existing" 2>/dev/null
   assertNotOk
   chdir -- >"${STDOUT}"
   assertStdOut ' 0  /tmp';
   assertPwd "${pwd}"
}

source ../../core/lib/shunit/src/shunit2
