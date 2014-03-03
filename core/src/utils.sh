#!/bin/bash

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

function is-true() {
   case "$1" in
   1|[tT][rR][uU][eE]|[yY]|[yY][eE][sS]) return 0 ;;
   0|[fF][aA][lL][sS][eE]|[nN]|[nN][oO]|"") return 1 ;;
   esac
   error "Warning: Invalid boolean value. False assumed."
   return 1
}
export -f is-true

function is() {
   [[ -n "$1" ]]
}
export -f is

function no() {
   [[ -z "$1" ]]
}
export -f no

function is-num() {
   [ -n "$1" ] && [ -z "${1//[0-9]}" ]
}
export -f is-num

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
export -f is-int


function is-utf() {
   [[ "${LANG}" == *UTF-8 ]]
}
export -f is-utf

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


ON_EXIT=":"
trap "${ON_EXIT}" EXIT


USER_SESSIONS_DIR="/tmp/sessions/${USER}/"
function _create-session()
{
   mkdir -p "${USER_SESSIONS_DIR}"
   export SESSION_DIR=$(mktemp -p "${USER_SESSIONS_DIR}")
}
function _destroy-session()
{
   rm -rf "${SESSION_DIR}"
}
_create-session
ON_EXIT="${ON_EXIT};_destroy-session"


function sponge() {
   file=${1}
   local tmp=${file}.tmp
   cat >"${tmp}"
   mv "${tmp}" "${file}"
}

# ReMove CR from line endings
rmcr() {
   for file in $@
   do
      if [ -f "${file}" ]
      then
         tr -d "\r" < "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}"
      fi
   done
}

type cygpath >/dev/null 2>/dev/null || { sed -e 's/^\(\w\):[\/\\]*/\/cygdrive\/\L\1\//' -e 's/\\/\//g' <<<$1; }

function debug-array() {
   local arr=${1}
   local count=0
   debug -n "${arr}=( "
   for e in ${!arr[@]}
   do
      debug -n "[$(( count++ ))]=${e} "
   done
   debug ")"
}
export -f debug-array
