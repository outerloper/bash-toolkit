#!/bin/bash

function is-true() {
   case "$1" in
   1|[tT][rR][uU][eE]|[yY]|[yY][eE][sS]) return 0 ;;
   0|[fF][aA][lL][sS][eE]|[nN]|[nN][oO]|"") return 1 ;;
   esac
   error "Warning: Invalid boolean value. False assumed."
   return 1
}

function is() {
   [[ -n "$1" ]]
}

function no() {
   [[ -z "$1" ]]
}

function is-num() {
   [ -n "$1" ] && [ -z "${1//[0-9]}" ]
}

function is-int() {
   if [ -z "$1" ] || [ "$1" = "-" ]
   then
      return 1
   fi
   local v="$1"
   v="${v##-}"
   v="${v//[0-9]}"
   [ -z "$v" ]
}

function is-function() {
   local functionName="${1:?Missing function name.}"
   [[ $(type -t "${functionName}") == "function" ]]
}

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

function echo-function() {
   local functionName="${1:?Missing function name}"
   declare -f "${functionName}"
}

function echo-function-body() {
   local functionName="${1:?Missing function name}"
   declare -f "${functionName}" | sed -e '1,2 d' -e '$ d'
}

function is-utf() {
   [[ "${LANG}" == *UTF-8 ]]
}

function echo-region() {
   local regionName="${1:?Missing region name}"
   local fileName="${2:?Missing input file name}"

   local beginTag="#begin ${regionName}"
   local endTag="#end ${regionName}"

   sed -n -e "/${beginTag}/,/${endTag}/ {/${beginTag}/ d; /${endTag}/ d; p}" <"${fileName}"
}

function delete-region() {
   local regionName="${1:?Missing region name}"
   local fileName="${2:?Missing input file name}"

   local beginTag="#begin ${regionName}"
   local endTag="#end ${regionName}"

   sed -e "/${beginTag}/,/${endTag}/ d" <"${fileName}"
}

function set-region() {
   local regionName="${1:?Missing region name}"
   local fileName="${2:?Missing input file name}"

   local beginTag="#begin ${regionName}"
   local endTag="#end ${regionName}"

   tmp="$(mktemp)"
   sed -e "/${beginTag}/,/${endTag}/ d" <"${fileName}" > "${tmp}"
   cat "${tmp}"
   echo "${beginTag}"
   cat <&0
   echo "${endTag}"
   rm "${tmp}"
}

export nc="\033[0m"
export underscore="\033[4m"
export black="\033[30m"
export gray="\033[37m"
export red="\033[1;31m"
export green="\033[1;32m"
export yellow="\033[1;33m"
export blue="\033[1;34m"
export magenta="\033[1;35m"
export cyan="\033[1;36m"
export white="\033[1;37m"
export Red="\033[31m"
export Green="\033[32m"
export Yellow="\033[33m"
export Blue="\033[34m"
export Magenta="\033[35m"
export Cyan="\033[36m"
export Gray="\033[1;30m"
export BLACK="\033[40m"
export RED="\033[41m"
export GREEN="\033[42m"
export YELLOW="\033[43m"
export BLUE="\033[44m"
export MAGENTA="\033[45m"
export CYAN="\033[46m"
export WHITE="\033[47m"

function put() { echo -ne "$1"; }
function say() { echo -e "$1";}
function warn() { echo -e "${yellow}$1${nc}"; }
function error() { echo -e "$1" >&2; }
function debug() { echo -e "${blue}$1${nc}" >&2; }
function success() { echo -e "${green}$1${nc}";}

function ask() {
   local var=${1:?'Missed variable name.'}
   local value
   local desc="${2:-$1}"
   local default=$3

   prompt="Provide ${desc}${default:+" (default is $default)"}: "
   while [ -z "${value}" ]
   do
      read -p "${prompt}" value
      if [ -z "${value}" ] && [ -n "${default}" ]
      then
         value="${default}"
      fi
   done
   printf -v ${var} -- "${value}"
}

function is-dir-empty() {
   local dir="${1:-.}"
   [ "${dir}" = "$(find "${dir}")" ]
}

function render-template() {
   local varDefsFile="$(mktemp)"
   declare -A vars
   cat <&0 >"${varDefsFile}"
   local varDecl="^\([a-Z_][a-Z0-9_]*\)=.*"
   (
      source "${varDefsFile}"
      for var in $(sed -n -e "/${varDecl}/ {s/${varDecl}/\1/; p}" < "${varDefsFile}")
      do
         vars[$var]="${!var}"
      done
      while read -r line
      do
         while [[ "${line}" =~ \$\{([a-Z_][a-Z0-9_]*)\} ]]
         do
            placeholder=${BASH_REMATCH[0]}
            value=${vars[${BASH_REMATCH[1]}]}
            line=${line//${placeholder}/${value}}
         done
         echo "${line}"
      done <"${1}"
   )
   rm "${varDefsFile}"
}

export -f is-true
export -f is
export -f no
export -f is-num
export -f is-int
export -f is-function
export -f rename-function
export -f is-utf
export -f render-template
export -f is-dir-empty
