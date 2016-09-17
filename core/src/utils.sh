#!/bin/bash

require stack.sh

export plainText="\e[0m"
export underscore="\e[4m"
export colorBlack="\e[30m"
export colorGray="\e[37m"
export colorRed="\e[1;31m"
export colorGreen="\e[1;32m"
export colorYellow="\e[1;33m"
export colorBlue="\e[1;34m"
export colorMagenta="\e[1;35m"
export colorCyan="\e[1;36m"
export colorWhite="\e[1;37m"
export colorLightRed="\e[31m"
export colorLightGreen="\e[32m"
export colorLightYellow="\e[33m"
export colorLightBlue="\e[34m"
export colorLightMagenta="\e[35m"
export colorLightCyan="\e[36m"
export colorDarkGray="\e[1;30m"
export backgroundBlack="\e[40m"
export backgroundRed="\e[41m"
export backgroundGreen="\e[42m"
export backgroundYellow="\e[43m"
export backgroundBlue="\e[44m"
export backgroundMagenta="\e[45m"
export backgroundCyan="\e[46m"
export backgroundWhite="\e[47m"

# syntactic sugar to avoid "[", "]" and keep notation more compact

# is not empty
function -n() { [ -n "$1" ]; }
# is empty
function -z() { [ -z "$1" ]; }
# is file
function -v() { [ -v "$1" ]; }
# is not file
function -nv() { ! [ -v "$1" ]; }
# is file
function -f() { [ -f "$1" ]; }
# is not file
function -nf() { ! [ -f "$1" ]; }
# is executable
function -x() { [ -x "$1" ]; }
# is not executable
function -nx() { ! -x "$1"; }
# file has contents
function -s() { [ -x "$1" ]; }
# file is empty
function -ns() { ! -s "$1"; }
# is directory
function -d() { [ -d "$1" ]; }
# is not directory
function -nd() { ! -d "$1"; }
# empty dir
function -ed() { local dir="${1:-.}"; [ "${dir}" = "$(find "${dir}")" ]; }
# not empty dir
function -ned() { ! -ed "$1"; }
# file exists
function -e() { [ -e "$1" ]; }
# file does not exist
function -ne() { [ "$2" ] && stderr "-ne: [WARNING] redundant 2nd parameter: $2 (did you mean -neq?)"; ! -e "$1"; }
# equal
function -eq() { [ "$1" == "$2" ]; }
# equal to zero
function -ez() { [ "$1" == 0 ]; }
# not equal
function -neq() { [[ "$1" != "$2" ]]; }
# not equal to zero
function -nez() { ! -ez "$1"; }
# $1 is less or equal number than $2
function -le() { [ "$1" -le "$2" ]; }
# $1 is greater or equal number than $2
function -ge() { [ "$1" -ge "$2" ]; }
# $1 is greater or equal 0
function -gez() { [ "$1" -ge 0 ]; }
# $1 is less number than $2
function -lt() { [ "$1" -lt "$2" ]; }
# $1 is greater number than $2
function -gt() { [ "$1" -gt "$2" ]; }
# $1 is greater than 0
function -gz() { [ "$1" -gt 0 ]; }
# '-m' like 'matches' $1 matches $2: [[ $1 = *$2* ]] ; $2 can contain wildcard characters but must be quoted
function -has() { : "${2?$FUNCNAME: Missing pattern}"; [[ "$1" = *$2* ]]; }
# '-am' like 'all matches' $1 matches $2: [[ $1 = $2 ]] ; $2 can contain wildcard characters but must be quoted
function -like() { : "${2?$FUNCNAME: Missing pattern}"; [[ "$1" = $2 ]]; }
# '-mr' like 'matches regexp' $1 matches $2: [[ $1 =~ $2 ]] ; $2 can be interpreted as regexp but must be quoted
function -rhas() { : "${2?$FUNCNAME: Missing pattern}"; [[ "$1" =~ $2 ]]; }
# '-amr' like 'all matches regexp' all $1 matches $2: [[ $1 =~ ^($2)$ ]] ; $2 can be interpreted as regexp but must be quoted
function -rlike() { : "${2?$FUNCNAME: Missing pattern}"; [[ "$1" =~ ^($2)$ ]]; }
# last exit code is 0
function -ok() { return $?; }
# last exit code is not 0
function -nok() { return ! -ok; }
# is unsigned integer
function -num() { : "${1?-num: Missing parameter}"; [[ "$1" =~ ^[0-9]+$ ]]; }
# is signed integer
function -int() { [[ "$1" =~ ^[+-]?[0-9]+$ ]]; }
# can be interpreted as boolean value: 1 t true y yes 0 f false n no (case insensitive)
function -bool() { [[ "$1" =~ ^(1|[tT]|[tT][rR][uU][eE]|[yY]|[yY][eE][sS]|0|[fF]|[fF][aA][lL][sS][eE]|[nN]|[nN][oO])$ ]]; }
# means true
function -true() { [[ "$1" =~ ^(1|[tT]|[tT][rR][uU][eE]|[yY]|[yY][eE][sS])$ ]]; }
# means false (negation of -true function)
function -false() { ! -true "$1"; }
# is UTF encoding
function -utf() { [[ "${LANG}" == *UTF-8 ]]; }
# is $1 a function name
function -fun() { : "${1:?-fun: Missing function name.}"; [[ "$(type -t "$1")" == "function" ]]; }
# is $1 a command line option value (not empty and not starting from '-')
function -optval() { -n "$1" && ! -like "$1" '-*'; }

# echo to stdout
function stderr() { echo $@ >&2; }
function put() { echo -e -n "${@} "; }
function say() { echo -e "$colorWhite${@}$plainText"; }
function say-warn() { echo -e "$colorYellow${@:-WARNING}$plainText"; }
function say-ok() { echo -e "$colorGreen${@:-OK}$plainText"; }
function say-fail() { echo -e "$colorRed${@:-FAILED}$plainText"; }

stack_destroy SIGINT_TRAPS
stack_new SIGINT_TRAPS

function push-dir() {
    pushd "$1" >/dev/null
}

function pop-dir() {
    popd >/dev/null
}

function finally() {
    stack_push SIGINT_TRAPS "$*"
    trap "finalize ${FUNCNAME[1]}; -n \"\$FUNCNAME\" && return 130" SIGINT
}

function finalize() {
    local onSigInt stackSize
    -n "$1" && -neq "$1" "${FUNCNAME[1]}" && return
    stack_pop SIGINT_TRAPS onSigInt 2>/dev/null && {
        eval "$onSigInt"
        stack_size SIGINT_TRAPS stackSize
        if -gz "$stackSize" ;then
            stack_pop SIGINT_TRAPS onSigInt
            finally "$onSigInt"
        else
            trap -- SIGINT
        fi
    }
}

function replace-dir() {
    local from="${1:?Missing source dir}"
    local to="${2:?Missing target dir}"
    -nd "$from" && stderr "${FUNCNAME[0]}: $from is not a directory" && return 1
    -f "$to" && stderr "${FUNCNAME[0]}: $to is a file" && return 1
    -d "$to" && { rm -rf "$to" || return 1; }
    mv "$from" "$to"; return $?;
}

# ensures there will be "/" at the end of variable named $1
function trail-slash() {
   : "${1:?Missing var name}"
   local val="${!1}"
   -n "$val" && set-var "$1" "${val%/}/"
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

function proceed() {
    -eq "$1" '--help' && echo "Asks user if to proceed with <action> or to <cancel>. Can proceed automatically after <timeout> seconds.\nUsage: $FUNCNAME [<action>] [-c <cancel>] [-t [<timeout>]]" && return
    local arg message proceed='proceed' cancel='cancel' confirmed canceled timeout
    -optval "$1" && {
        if -rhas "$1" '^[[:lower:]]' ;then
            proceed="$1"
            confirmed="$1"
        else
            message="$1"
        fi
        shift
    }
    while -gz $# ;do
        arg="$1"
        case "$arg" in
        -t)
            if -optval "$2" ;then
                -num "$2" || {
                    stderr "-t: Number expected. Was: $2" && return 1
                }
                timeout="$2"
                shift
            else
                timeout=10
            fi
            ;;
        -c)
            if -optval "$2" ;then
                cancel="$2"
                canceled="$2"
                shift 1
            else
                stderr '-c: Value expected' && return 1
            fi
            ;;
        *)
            stderr "proceed: unexpected argument: $arg" && return 1
        esac
        shift
    done
    local key
    -n "$message" && message="$message.$plainText "
    local text="\r$message""Press ENTER to $proceed, other key to $cancel"
    if -z "$timeout" ; then
        printf "$text.. "
        read -n 1 -s key
        -ok && {
            _proceed_handleKey
            return $?
        }
    else
        local timerText="$text. Will $proceed in %s secs"
        (( timeout++ ))
        while (( --timeout )) ; do
            printf "$timerText " "$timeout"
            read -t 1 -n 1 -s key
            -ok && {
                _proceed_handleKey
                return $?
            }
            timerText+='.'
        done
        printf "$timerText\n" "$timeout"
        sleep 1
        return 0
    fi
}

_proceed_handleKey() {
    -z "$key" && {
        echo "<${confirmed-"user confirmed"}>"
        return 0
    }
    echo "<${canceled-"user canceled"}>"
    return 130
}

# assign $2 to a variable with name $1. $1 can represent array cell e.g. "a[1]"
function set-var() { printf -v "$1" -- "$2"; }

# if variable with name $1 contains ${..} or $(..) placeholders, they are expanded to variable values and script outputs respectively
function eval-var() { [[ "${!1}" =~ \$\{.+\} ]] || [[ "${!1}" =~ \$\(.+\) ]] && eval "$1=\"${!1}\""; }


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

# prints array entries in key=value lines, keys are sorted
function print-array() {
    : "${1?"Missing array name"}"
    local options indexes
    local declaration="$(declare -p "$1" | sed 's/\(declare -\([^ ]*\) \)\([^=]*\)\(=.*\)/\1array\4; local options=\2/')"
    eval "$declaration"
    if -has "$options" a ;then
        indexes=( $(seq 0 $(( ${#array[@]} - 1 ))) )
    elif -has "$options" A ;then
        indexes=( $(echo ${!array[@]} | tr ' ' "\n" | sort -n) )
    else
        stderr "$1 is not an array"
        return 1
    fi
    for i in ${indexes[@]} ;do
        echo "$i=${array[$i]}"
    done
}
