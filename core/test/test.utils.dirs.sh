#!/bin/bash

source ../src/utils.sh
source ../src/utils.dirs.sh
source ../src/utils.tests.sh

function setUp() {
   rm -rf /tmp/test-chdir
   mkdir /tmp/test-chdir
   DIRHISTFILE=/tmp/test-chdir/.dir_history
   chdir /tmp/
   dirs -c
   chdir -- >"${STDOUT}"
}

function testChdirHelp() {
   chdir --help >"${STDOUT}"
   assertStdOut 'cd: usage: cd [-L|-P] [dir]
       or: cd -c
Options:
  -P   Do not follow symbolic links
  -L   Follow symbolic links (default)
  -c   Clear dir history
Special values for dir:
  -    Go to previous directory
  --   Print dir history
  -N   Go to dir with index N in history'
}

function testChdirPrintStack() {
   assertStdOut "    1	/tmp"
   assertPwd /tmp

   chdir test-chdir
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp
    2	/tmp/test-chdir'
   assertPwd /tmp/test-chdir
}

function testChdirExisting() {
   chdir /
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp
    2	/'
   assertPwd /

   chdir /tmp
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/
    2	/tmp'
   assertPwd /tmp
}

function testChdirParent() {
   chdir ..
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp
    2	/'
   assertPwd /
}

function testChdirSelf() {
   chdir .
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp'
   assertPwd /tmp
}

function testChdirPrevious() {
   chdir test-chdir
   chdir - >"${STDOUT}"
   assertOk
   assertStdOut '/tmp'
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp/test-chdir
    2	/tmp'
   assertPwd /tmp

   chdir - >"${STDOUT}"
   assertOk
   assertStdOut '/tmp/test-chdir'
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp
    2	/tmp/test-chdir'
   assertPwd /tmp/test-chdir
}

function testChdirHome() {
   local HOME="/tmp/test-chdir/home"
   mkdir $HOME
   chdir ~
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp
    2	~'
}

function testChdirNoParameters() {
   local HOME="/tmp/test-chdir/home"
   mkdir ${HOME}
   chdir
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp
    2	~'
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
   assertStdOut '    1	~
    2	/tmp/test-chdir
    3	/tmp
    4	/'
   assertPwd /

   chdir -1
   assertOk
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp/test-chdir
    2	/tmp
    3	/
    4	~'
   assertPwd ${HOME}

   chdir -4
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp/test-chdir
    2	/tmp
    3	/
    4	~'
   assertPwd ${HOME}

   chdir -2
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp/test-chdir
    2	/
    3	~
    4	/tmp'
   assertPwd /tmp
}

function testChdirZeroIndex() {
   local pwd=$(pwd)
   chdir -0 2>"${STDERR}"
   assertNotOk
   assertStdErr 'No dir with such index in history.'
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp'
   assertPwd "${pwd}"
}

function testChdirNonExistingIndex() {
   local pwd=$(pwd)
   chdir -5 2>"${STDERR}"
   assertNotOk
   assertStdErr 'No dir with such index in history.'
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp'
   assertPwd "${pwd}"
}

function testChdirNonExistingDir() {
   local pwd=$(pwd)
   chdir "/tmp/test-chdir/non-existing" 2>/dev/null
   assertNotOk
   chdir -- >"${STDOUT}"
   assertStdOut '    1	/tmp'
   assertPwd "${pwd}"
}

source ../../core/lib/shunit/src/shunit2
