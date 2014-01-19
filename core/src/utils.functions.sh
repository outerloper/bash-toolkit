#!/bin/bash

function is-function() {
   local functionName="${1:?Missing function name.}"
   [[ $(type -t "${functionName}") == "function" ]]
}
export -f is-function

function rename-function() {
   local oldFunctionName="${1:?Missing old function name.}"
   if ! is-function "${oldFunctionName}"
   then
      error "No such function: ${oldFunctionName}"
      return 1
   fi
   local oldFunction="$(declare -f "${oldFunctionName}")"
   local newFunction="${2:?Missing new function name.}${oldFunction#$oldFunctionName}"
   eval "${newFunction}"
   unset -f "${oldFunctionName}"
}
export -f rename-function

function echo-function-body() {
   local functionName="${1:?Missing function name}"
   declare -f "${functionName}" | sed -e '1,2 d' -e '$ d'
}
export -f echo-function-body
