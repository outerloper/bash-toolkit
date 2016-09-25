#!/bin/bash

require stack.sh

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
# file descriptor fd is open and refers to a terminal
function -t() { [ -t "$1" ]; }
# file descriptor fd is not open or does not refer to a terminal
function -nt() { ! -t "$1"; }
# empty dir
function -ed() { local dir="${1:-.}"; [ "${dir}" = "$(find "${dir}")" ]; }
# not empty dir
function -ned() { ! -ed "$1"; }
# file exists
function -e() { [ -e "$1" ]; }
# file does not exist
function -ne() { [ "$2" ] && err "-ne: [WARNING] redundant 2nd parameter: $2 (did you mean -neq?)"; ! -e "$1"; }
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
function -rlike() { : "${2?$FUNCNAME: Missing pattern}"; [[ "$1" =~ ^$2$ ]]; }
# returns last exit code
function -ok() { return $?; }
# tests if last command exited with non-zero status
function -nok() { ! -ok; }
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
# is $1 a command line option switch (not empty and starting from '-')
function -opt() { -n "$1" && -like "$1" '-*'; }
# is $1 a command line option value (not empty and not starting from '-')
function -optval() { -n "$1" && ! -like "$1" '-*'; }
# when $@ or $1 provided within function definition or script, the function tests if there was help request (--help of -h as first parameter)
function -help() { [[ "$1" == '--help' ]] || [[ "$1" == '-h' ]]; }
# tests if $1 is valid variable name
function -varname() { [[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ ]]; }

# echo to stdout
function err() {
    if -t 2 ;then
        echo -en "$styleFailure"
        echo -e $@ >&2
        echo -en "$styleOff"
    else
        echo -e $@ >&2
    fi
}

# pushd without printing on stdout
function push-dir() {
    pushd "$1" >/dev/null
}

# popd without printing on stdout
function pop-dir() {
    popd >/dev/null
}

# faster than mkdir -p when dir exists
function ensure-dir() {
    : "${1?'Missing directory name'}"
    -d "$1" || mkdir -p "$1"
}

# deletes files if necessary
function ensure-empty-dir() {
    : "${1?'Missing directory name'}"
    if -d "$1" ;then
        rm -rf "$1"/*
    else
        -e "$1" && rm "$1"
        mkdir -p "$1"
    fi
}

function replace-dir() {
    local from="${1:?Missing source dir}"
    local to="${2:?Missing target dir}"
    -nd "$from" && err "$FUNCNAME: $from is not a directory" && return 1
    -f "$to" && err "$FUNCNAME: $to is a file" && return 1
    -d "$to" && { rm -rf "$to" || return 1; }
    mv "$from" "$to"; return $?;
}

# increment value named $1 by 1, returns changed value, prefix equivalent to (( ++$1 ))
function inc() {
    (( ++ ${1?Missing var name} ))
    (( $1 != 0 ))
}

# decrement value named $1 by 1, returns changed value, prefix equivalent to (( --$1 ))
function dec() {
    (( -- ${1?Missing var name} ))
    (( $1 != 0 ))
}

# ensures there will be "/" at the end of variable named $1
function trail-slash() {
   : "${1:?Missing var name}"
   local val="${!1}"
   -n "$val" && set-var "$1" "${val%/}/"
}

# ensures first letter of variable named $1 is upper-case
function capitalize() {
   : "${1:?Missing var name}"
   local val="${!1}"
   first="${val:0:1}"
   val="${first^^}${val:1}"
   -n "$val" && set-var "$1" "${val}"
}

# prints message informing about exit status of last command. $1 - custom success command, $2 - custom failure command
function ok() {
    OK=$?
    if [ "$OK" -eq 0 ] ; then
        success "$1"
    else
        failure "$2"
    fi
    return "$OK"
}

function proceed() {
    -eq "$1" '--help' && echo "Asks user if to proceed with <action> or to <cancel>. Can proceed automatically after <timeout> seconds.\nUsage: $FUNCNAME [<action>] [-c <cancel>] [-t [<timeout>]]" && return
    local arg message proceed='proceed' cancel='cancel' confirmed canceled timeout
    -opt "$1" || {
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
                    err "-t: Number expected. Was: $2" && return 1
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
                err '-c: Value expected' && return 1
            fi
            ;;
        *)
            err "proceed: unexpected argument: $arg" && return 1
        esac
        shift
    done
    local key
    -n "$message" && message="$message.$plain "
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
        inc timeout
        while dec timeout ; do
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
function eval-var() { -has "${!1}" '\$\{.+\}' || -has "${!1}" '\$\(.+\)' && eval "$1=\"${!1}\""; }


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
        err "$1 is not an array"
        return 1
    fi
    for i in ${indexes[@]} ;do
        echo "$i=${array[$i]}"
    done
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

stack_destroy SIGINT_TRAPS
stack_new SIGINT_TRAPS
