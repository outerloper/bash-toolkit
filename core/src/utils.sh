#!/bin/bash

export txtNormal="\033[0m"
export txtUnderscore="\033[4m"
export fgBlack="\033[30m"
export fgGray="\033[37m"
export fgRed="\033[1;31m"
export fgGreen="\033[1;32m"
export fgYellow="\033[1;33m"
export fgBlue="\033[1;34m"
export fgMagenta="\033[1;35m"
export fgCyan="\033[1;36m"
export fgWhite="\033[1;37m"
export fgRed2="\033[31m"
export fgGreen2="\033[32m"
export fgYellow2="\033[33m"
export fgBlue2="\033[34m"
export fgMagenta2="\033[35m"
export fgCyan2="\033[36m"
export fgGray2="\033[1;30m"
export bgBlack="\033[40m"
export bgRed="\033[41m"
export bgGreen="\033[42m"
export bgYellow="\033[43m"
export bgBlue="\033[44m"
export bgMagenta="\033[45m"
export bgCyan="\033[46m"
export bgWhite="\033[47m"

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
function warn() { echo -e "${fgYellow}$1${txtNormal}"; }
function error() { echo -e "$1" >&2; }
function debug() { echo -e "${fgBlue}$1${txtNormal}" >&2; } # TODO test
function success() { echo -e "${fgGreen}$1${txtNormal}";}


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
   echo -n "${arr}=( "
   for index in $(eval 'echo ${!'"${arr}"'[@]}')
   do
      eval 'echo -n "['"${index}"']=${'"${arr}"'['"${index}"']} "'
   done
   echo ")"
}
export -f debug-array
