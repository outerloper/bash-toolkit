#!/bin/bash
# TODO delete
declare -A ARGLISTS=(

)

function arglist() {
   ARGLIST_NAME="${1:?Missing arglistName}"

   shift
   while [[ "$1" ]]
   do
      case $1 in
      --desc)
         shift
         ARGLISTS[${ARGLIST_NAME}:desc]="${1?"Missing desc"}"
         shift
      ;;
      *)
         echo "Unexpected: '$1'"
         return 127
      esac
   done
}

function arglist-param() {
   if [[ -z "${ARGLIST_NAME}" ]]
   then
      echo "Missing ARGLIST_NAME. You must invoke 'arglist' function first to use 'arg'."
      return 1;
   fi
   local optionName="${1:?Missing optionName}"
   shift
   local optionSpec="${1}"
   ARGLISTS[${ARGLIST_NAME}:params]="${ARGLISTS[${ARGLIST_NAME}:params]} ${optionName}"
   ARGLISTS[${ARGLIST_NAME}.${optionName}]="${optionSpec}"
}

function arglist-option() {
# TODO extract from it and from arglist-param
   if [[ -z "${ARGLIST_NAME}" ]]
   then
      echo "Missing ARGLIST_NAME. You must invoke 'arglist' function first to use 'arg'."
      return 1;
   fi
   local optionName="${1:?Missing optionName}"
   shift
   local optionSpec="${1}"
   ARGLISTS[${ARGLIST_NAME}:options]="${ARGLISTS[${ARGLIST_NAME}:options]} ${optionName}"
   ARGLISTS[${ARGLIST_NAME}.${optionName}]="${optionSpec}"
}

function arglist-register() {
   debug-array ARGLISTS
   A=( ${ARGLISTS[greet]} )
   debug-array A
}

function arglist-print-help() {
   local desc="${ARGLISTS[${ARGLIST_NAME}:desc]}"
   if is "${desc}"
   then
      echo "${desc}"
   fi

   echo "Usage:"
   echo -n "  ${arglistName}"
   if [[ -n "${ARGLISTS[${arglistName}:params]}" ]] # TODO extract var
   then
      _arglist_printParamsHeader
   fi
   if [[ -n "${ARGLISTS[${arglistName}:options]}" ]]
   then
      echo -n " OPTIONS"
   fi
   echo
   if [[ -n "${ARGLISTS[${arglistName}:params]}" ]]
   then
      echo "Parameters:"
      _arglist_printParamsDesc
   fi
   if [[ -n "${ARGLISTS[${arglistName}:options]}" ]]
   then
      echo "Options:"
      _arglist_printOptionsDesc
   fi
   echo
}

function _arglist_printParamsHeader() {
   for arg in ${ARGLISTS[${arglistName}:params]}
   do
      echo -n " <${arg}>"
   done
}

function _arglist_printParamsDesc() {
   for arg in ${ARGLISTS[$arglistName:params]}
   do
      _arglist_setArg ${arg}
      local desc
      type-get desc desc
      printf "  %-30s   %s\n" "<${arg}>" "${desc}" # TODO
   done
}

function _arglist_printOptionsDesc() {
   for arg in ${ARGLISTS[$arglistName:options]}
   do
      _arglist_setArg ${arg}
      local desc
      type-get desc desc
      local optionSignature="--${arg} <value>"
      printf "  %-30s   %s\n" "${optionSignature}" "${desc}" # TODO
   done
}

function _arglist_setArg() {
   local arg="${1:?Missing arg}"

   VALSPEC_ASK=()
   VALSPEC_CURRENT=VALSPEC_ASK
   TYPE_CURRENT=${arg}
   eval "type-def VALSPEC_ASK.${arg} ${ARGLISTS[${arglistName}.${arg}]}"
}

function arglist-get() {
   local arglistName=$1
   shift
   local args=( "$@" )
   if _arglist_isHelpRequest ${arglistName}
   then
      arglist-print-help ${arglistName}
      return 127
   fi

   return 0
}

function _arglist_isHelpRequest() {
   for arg in ${args[@]}
   do
      if [[ "${arg}" == "--help" ]]
      then
         return 0
      fi
   done
   return 1
}

function greet() {
   local name surname times
   if arglist-get greet "$@"
   then
      echo "name=${name}" # DEBUG
      echo "surname=${surname}" # DEBUG
      echo "times=${times}" # DEBUG
   fi
}

function scenario() {
   ARGLIST_NAME=
   ARGLISTS=()

   arglist greet --desc 'Says hello to somebody.'
   arglist-param name "string --desc 'Name to greet'"
   arglist-param surname "string --desc 'Surname to greet'"
   arglist-option times "int --desc 'How many times'"
   arglist-register

   greet --help

#   eval "ask-for string ${ARGLISTS[name]}"
}