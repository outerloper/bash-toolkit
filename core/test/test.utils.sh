#!/bin/bash

source ../src/utils.sh
source ../../core/src/test-utils.sh

function testIsNumReturnsTrueForNaturalNumbers() {
   is-num 0
   assertOk
   is-num 4
   assertOk
   is-num 45665644
   assertOk
}

function testIsNumReturnsTrueForNotNaturalNumbersAndEmptyValue() {
   is-num xxx
   assertNotOk
   is-num 61x
   assertNotOk
   is-num x45
   assertNotOk
   is-num 666g666
   assertNotOk
   is-num ''
   assertNotOk
}

function testIsIntReturnsTrueForIntegerNumbers() {
   is-int 0
   assertOk
   is-int 4
   assertOk
   is-int 45665644
   assertOk
   is-int -4
   assertOk
   is-int -45665644
   assertOk
}

function testIsIntReturnsTrueForNotIntegerNumbersAndEmptyValue() {
   is-int xxx
   assertNotOk xxx
   is-int 61x
   assertNotOk 61x
   is-int x45
   assertNotOk x45
   is-int 666g666
   assertNotOk 666g666
   is-int -xxx
   assertNotOk -xxx
   is-int -61x
   assertNotOk -61x
   is-int -x45
   assertNotOk -x45
   is-int -666g666
   assertNotOk -666g666
   is-int 3-
   assertNotOk 3-
   is-int -
   assertNotOk -
   is-int ''
   assertNotOk 'empty string'
}

function testIsFunction() {
   function _testFunction() {
      :
   }
   is-function _testFunction || fail 'is-function should return true when function exists'

   unset -f _testFunction
   is-function _testFunction && fail 'is-function should return false when function does not exist'
}

function testRenameFunction() {
   function _testFunction() {
      :
   }
   is-function _renamedFunction && unset -f _renamedFunction
   is-function _renamedFunction && fail '_renamedFunction should not exist'
   is-function _testFunction || fail '_testFunction should exist'

   rename-function _testFunction _renamedFunction
   is-function _testFunction && fail '_testFunction should not exist'
   is-function _renamedFunction || fail '_renamedFunction should exist'
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

function testRenderTemplate() {
   local dir="/tmp/testRenderTemplate"
   rm -rf "${dir}"
   mkdir "${dir}"
   local templateFile=$(mktemp -p "${dir}")
   local varDefsFile=$(mktemp -p "${dir}")
   cat >"${templateFile}" <<< 'Her name is ${name} ${surname}.
Alice is ${age} years old.
John shouted: ${name}, ${name}!
But she replied: ${curse} you!
${a}'
   cat >"${varDefsFile}" <<< '
 a=10
name=Alice
 # xxx
surname=Smith
age=$(( a << 1 ))
curse="%#&@"
'
   render-template "${templateFile}" <"${varDefsFile}" >"${STDOUT}"
   assertStdOut 'Her name is Alice Smith.
Alice is 20 years old.
John shouted: Alice, Alice!
But she replied: %#&@ you!'
   rm -rf "${dir}"
}

function initRegionTest() {
   dir="/tmp/testRenderTemplate"
   rm -rf "${dir}"
   mkdir "${dir}"
   file=$(mktemp -p "${dir}")
   cat >"${file}" <<< 'First line
Second line
#begin region
Third line
Fourth line
#end region
#begin footer
Fifth line
#end footer'
}

function testEchoRegion() {
   local dir file
   initRegionTest

   echo-region region "${file}" >"${STDOUT}"
   assertStdOut 'Third line
Fourth line'

   echo-region footer "${file}" >"${STDOUT}"
   assertStdOut 'Fifth line'

   echo-region non-existing "${file}" >"${STDOUT}"
   assertStdOut ''

   rm -rf "${dir}"
}

function testDeleteRegion() {
   local dir file
   initRegionTest

   delete-region region "${file}" >"${STDOUT}"
   assertStdOut 'First line
Second line
#begin footer
Fifth line
#end footer'

   delete-region footer "${file}" >"${STDOUT}"
   assertStdOut 'First line
Second line
#begin region
Third line
Fourth line
#end region'

   delete-region non-existing "${file}" >"${STDOUT}"
   assertStdOut 'First line
Second line
#begin region
Third line
Fourth line
#end region
#begin footer
Fifth line
#end footer'

   rm -rf "${dir}"
}

function testSetRegion() {
   local dir file
   initRegionTest

   set-region region "${file}" >"${STDOUT}" <<< ''
   assertStdOut 'First line
Second line
#begin footer
Fifth line
#end footer
#begin region

#end region'

   set-region footer "${file}" >"${STDOUT}" <<< "Foo
Bar"
   assertStdOut 'First line
Second line
#begin region
Third line
Fourth line
#end region
#begin footer
Foo
Bar
#end footer'

   set-region non-existing "${file}" >"${STDOUT}" <<< "Foo
Bar"
   assertStdOut 'First line
Second line
#begin region
Third line
Fourth line
#end region
#begin footer
Fifth line
#end footer
#begin non-existing
Foo
Bar
#end non-existing'

   rm -rf "${dir}"
}

source ../../core/lib/shunit/src/shunit2
