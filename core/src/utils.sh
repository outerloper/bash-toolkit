#!/bin/bash

export txtNormal="\033[0m"
export txtUnderscore="\033[4m"
export fgBlack="\033[30m" #TODO rename more friendly
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

# is not empty
function -n() { [ -n "$1" ]; }
export -f -- -n
# is empty
function -z() { [ -z "$1" ]; }
export -f -- -z
# is file
function -f() { [ -f "$1" ]; }
export -f -- -f
# is not file
function -nf() { ! [ -f "$1" ]; }
export -f -- -nf
# is executable
function -x() { [ -x "$1" ]; }
export -f -- -x
# is not executable
function -nx() { ! -x "$1"; }
export -f -- -nx
# is directory
function -d() { [ -d "$1" ]; }
export -f -- -d
# is not directory
function -nd() { ! -d "$1"; }
export -f -- -nd
# empty dir
function -ed() { local dir="${1:-.}"; [ "${dir}" = "$(find "${dir}")" ]; }
export -f -- -ed
# not empty dir
function -ned() { ! -ed "$1"; }
export -f -- -ned
# file exists
function -e() { [ -e "$1" ]; }
export -f -- -e
# file does not exist
function -ne() { [ "$2" ] && stderr "-ne: [WARNING] redundant 2nd parameter: $2 (did you mean -neq?)"; ! -e "$1"; }
export -f -- -ne
# equal
function -eq() { [ "$1" == "$2" ]; }
export -f -- -eq
# not equal
function -neq() { [[ "$1" != "$2" ]]; }
export -f -- -neq
# $1 is less or equal number than $2
function -le() { [ "$1" -le "$2" ]; }
export -f -- -le
# $1 is greater or equal number than $2
function -ge() { [ "$1" -ge "$2" ]; }
export -f -- -ge
# $1 is less number than $2
function -lt() { [ "$1" -lt "$2" ]; }
export -f -- -lt
# $1 is greater number than $2
function -gt() { [ "$1" -gt "$2" ]; }
export -f -- -gt
# $1 matches $2: [[ $1 =~ $2 ]]
function -m() { : "${2:?-m: Missing pattern}"; [[ "$1" =~ $2 ]]; }
export -f -- -m
# all $1 matches $2: [[ $1 =~ ^($2)$ ]]
function -ma() { [[ "$1" =~ ^($2)$ ]]; }
export -f -- -ma
# last exit code is 0
function -ok() { return $?; }
export -f -- -ok
# last exit code is not 0
function -nok() { return ! -ok; }
export -f -- -nok
# is unsigned integer
function -num() { [[ "$1" =~ ^[0-9]+$ ]]; }
export -f -- -num
# is signed integer
function -int() { [[ "$1" =~ ^[+-]?[0-9]+$ ]]; }
export -f -- -int
# can be interpreted as boolean value: 1 t true y yes 0 f false n no (case insensitive)
function -bool() { [[ "$1" =~ ^(1|[tT]|[tT][rR][uU][eE]|[yY]|[yY][eE][sS]|0|[fF]|[fF][aA][lL][sS][eE]|[nN]|[nN][oO])$ ]]; }
export -f -- -bool
# means true
function -true() { [[ "$1" =~ ^(1|[tT]|[tT][rR][uU][eE]|[yY]|[yY][eE][sS])$ ]]; }
export -f -- -true
# means false (negation of -true function)
function -false() { ! -true; }
export -f -- -false
# is UTF encoding
function -utf() { [[ "${LANG}" == *UTF-8 ]]; }
export -f -- -utf
# is $1 a function name
function -fun() { : "${1:?-fun: Missing function name.}"; [[ "$(type -t "$1")" == "function" ]]; }
export -f -- -fun

# echo to stdout
function stderr() { echo $@ >&2; }
function put() { echo -e -n "${@} "; }
function say() {
    echo -e "$fgWhite${@}$txtNormal";
}
function say-warn() { echo -e "$fgYellow${@:-WARNING}$txtNormal"; }
function say-ok() { echo -e "$fgGreen${@:-OK}$txtNormal"; }
function say-fail() { echo -e "$fgRed${@:-FAILED}$txtNormal"; }

function push-dir() {
   pushd "$1" >/dev/null
}

function pop-dir() {
   popd >/dev/null
}

function replace-dir() {
    local from="${1:?Missing source dir}"
    local to="${2:?Missing target dir}"
    -nd "$from" && stderr "${FUNCNAME[0]}: $from is not a directory" && return 1
    -f "$to" && stderr "${FUNCNAME[0]}: $to is a file" && return 1
    -d "$to" && { rm -rf "$to" || return 1; }
    mv "$from" "$to"; return $?;
}

function trail-slash() {
   : "${1:?Missing var name}"
   local val="${!1}"
   [ "$val" ] && printf -v "$1" -- "${val%/}/"
}

# prints message informing about exit status of last command. $1 - custom success command, $2 - custom failure command
function ok() {
    OK=$?
    if [ "$OK" -eq 0 ] ; then
        say-ok "$1"
    else
        say-fail "$2"
    fi
    return "$OK"
}

# asks for user's confirmation. Waits $1 seconds (10+1 by default) or proceeds automatically.
function proceed() {
  local timeout="${1:-11}"
  local message="Press ENTER to proceed, other key to abort. "
  -num "$timeout" || timeout=0
  if (( timeout == 0 )) ; then
      printf "$message"
      read -n 1 -s key
      echo
      -ok && -z "$key" && return 0
      return 1
  else
      message="\r${message}Proceed automatically in %s secs"
      while (( timeout-- )) ; do
        printf "$message" "$timeout"
        read -t 1 -n 1 -s key
        -ok && {
            -z "$key" && return 0
            return 1
        }
        message+=.
      done
      echo
      return 0
  fi
}

# assign $2 to a variable with name $1. $1 can represent array cell e.g. "a[1]"
function set-var() { printf -v "$1" -- "$2"; }

# if variable with name $1 contains ${..} or $(..) placeholders, they are expanded to variable values and script outputs respectively
function eval-var() { [[ "${!1}" =~ \$\{.+\} ]] || [[ "${!1}" =~ \$\(.+\) ]] && eval "$1=\"${!1}\""; }


ON_EXIT=":"
trap "${ON_EXIT}" EXIT


function _create-session()
{
   mkdir -p "${TMP}"
   export SESSION_TMP=$(mktemp -p "${TMP}")
}
function _destroy-session()
{
   rm -rf "${SESSION_TMP}"
}
_create-session
ON_EXIT+=";_destroy-session"


# sponge emulator. Provide file name as a parameter.
type sponge >/dev/null 2>/dev/null || function sponge() {
   file=${1}
   local tmp=${file}.tmp
   cat >"${tmp}"
   chmod --reference "${file}" "${tmp}"
   mv "${tmp}" "${file}"
}

# removes \r chars from line endings in provided files
function rr() {
   for file in $@ ;do
      -f "$file" && tr -d "\r" < "$file" | sponge "$file"
   done
}

# windows to cygwin path converter
type cygpath >/dev/null 2>/dev/null || function cygpath() { sed -e 's/^\(\w\):[\/\\]*/\/cygdrive\/\L\1\//' -e 's/\\/\//g' <<<$1; }

# windows start command
type cygstart >/dev/null 2>/dev/null && ! type start >/dev/null 2>/dev/null && alias start=cygstart

# prints var with name $1 in readable form and also as valid bash code for recreating such variable
function print-var() {
    local _arr=$1
    local decl="$(declare -p $_arr)" >/dev/null
    [ -z "$decl" ] && {
        echo "No such variable: \$$_arr" >&2
        return 1
    }
    echo $decl
    if [[ "$decl" =~ ^declare' '-[^' ']*[Aa] ]] ;then
        local keys="$(eval "echo \${!$_arr[@]}" | tr ' ' "\n" | sort | tr "\n" ' ')"
        [[ "$decl" =~ ^declare' '-[^' ']*A ]] && echo -n 'declare -A '
        echo "$_arr=( "
        for index in $keys
        do
            eval "echo \"  [$index]=\${$_arr[$index]} \""
        done
        echo ")"
    else
        echo "$_arr=${!_arr}"
    fi
}
export -f print-var
