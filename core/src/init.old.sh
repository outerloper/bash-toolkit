#!/bin/bash


function source-once() {
   SOURCE=$(realpath "$1")
   if ! [[ "${SOURCES}" =~ ":${SOURCE}:" ]]
   then
      [[ -z "${SOURCES}" ]] && SOURCES=":"
      SOURCES="${SOURCES}${SOURCE}:"
      source "${SOURCE}"
   fi
}
export -f source-once


function testSourceOnce() {
   rm -f /tmp/script1.sh
   rm -f /tmp/script2.sh
   rm -f /tmp/script3.sh

   echo "echo 1" >/tmp/script1.sh
   echo "echo 2" >/tmp/script2.sh
   ln -s /tmp/script2.sh /tmp/script3.sh

   SOURCES=''
   source-once /tmp/script1.sh >"${STDOUT}"
   assertStdOut '1'
   source-once /tmp/script1.sh >"${STDOUT}"
   assertStdOut ''
   source-once /tmp/script1.sh >"${STDOUT}"
   assertStdOut ''
   source-once /tmp/script2.sh >"${STDOUT}"
   assertStdOut '2'
   source-once /tmp/script3.sh >"${STDOUT}"
   assertStdOut ''
   cd /tmp
   source-once script2.sh >"${STDOUT}"
   assertStdOut ''
   source-once ../tmp/script2.sh >"${STDOUT}"
   assertStdOut ''
}
