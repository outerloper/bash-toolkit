#!/bin/bash

source ../src/utils.text-files.sh
source ../src/utils.tests.sh

function setUp() {
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

function tearDown() {
   rm -rf "${dir}"
}

function testRenderTemplateWithVarDefsFile() {
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
   render-template "${templateFile}" "${varDefsFile}" >"${STDOUT}"
   assertStdOut 'Her name is Alice Smith.
Alice is 20 years old.
John shouted: Alice, Alice!
But she replied: %#&@ you!
10'
   rm -rf "${dir}"
}

function testRenderTemplateWithShellVars() {
   local dir="/tmp/testRenderTemplate"
   rm -rf "${dir}"
   mkdir "${dir}"
   local templateFile=$(mktemp -p "${dir}")
   cat >"${templateFile}" <<< 'Her name is ${name} ${surname}.
Alice is ${age} years old.
John shouted: ${name}, ${name}!
But she replied: ${curse} you!
${a}'
   local a=10
   local name=Alice
   local surname=Smith
   local age=$(( a << 1 ))
   local curse="%#&@"
   render-template "${templateFile}" >"${STDOUT}"
   assertStdOut 'Her name is Alice Smith.
Alice is 20 years old.
John shouted: Alice, Alice!
But she replied: %#&@ you!
10'
   rm -rf "${dir}"
}

function testEchoRegion() {
   echo-region region "${file}" >"${STDOUT}"
   assertStdOut 'Third line
Fourth line'

   echo-region footer "${file}" >"${STDOUT}"
   assertStdOut 'Fifth line'

   echo-region non-existing "${file}" >"${STDOUT}"
   assertStdOut ''
}

function testDeleteRegion() {
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
