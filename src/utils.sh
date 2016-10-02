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
# is symbolic link
function -h() { [ -h "$1" ]; }
# is not symbolic link
function -nh() { ! -h "$1"; }
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
# tests if last command exited with zero status. If parameter specified, it is used instead of last exit code.
function -ok() { return "${1:-$?}"; }
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
# tests if $1 is a zip archive
function -zip() { -eq "$(file -b --mime-type "${1?"Missing file name"}")" 'application/zip'; }

# echo to stdout
function err() {
    if -t 2 ;then
        echo -e "$styleFailure$1$styleOff" >&2
    else
        echo -e "$1" >&2
    fi
    [ "$BUSH_VERBOSE" ] && print-stack-trace
    return 0
}

function set-window-title() {
    echo -en "\033]0;$@\007"
}

# pushd without printing on stdout
function push-dir() {
    pushd "$1" >/dev/null
}

# popd without printing on stdout
function pop-dir() {
    popd >/dev/null
}


# creates a file $1 if it does not exist. If $1 does not exist and $2 provided then $2 must be a file and its content is copied to $1.
function ensure-file() {
    local dest="${1?'Missing file name'}"
    -f "$dest" && { return 0; }
    -d "$dest" && { err "$dest is a directory"; return 1; }
    local destAbsolute="$(readlink -f "$dest")"
    local destParent="${destParent%/*}"
    mkdir -p "$destParent"
    if -n "$2" ;then
        local template="$2"
        -nf "$template" && { err "$template - no such file"; return 1; }
        cp --preserve "$template" "$dest"
    else
        touch "$dest"
    fi
}

# creates a directory $1 if it does not exist. If $1 does not exist and $2 provided then $2 must be a directory and its content is copied to $1.
# faster than mkdir -p when dir exists.
function ensure-dir() {
    local dest="${1?'Missing directory name'}"
    -d "$dest" && { return 0; }
    -f "$dest" && { err "$dest is a file"; return 1; }
    mkdir -p "$dest"
    if -n "$template" ;then
         local template="$2"
         -nd "$template" && { err "$template - no such directory"; return 1; }
         cp --preserve -r -T "$template" "$dest"
    fi
}

# deletes dirs if necessary. Fails when $1 is a file
function ensure-empty-dir() {
    local dest="${1?'Missing directory name'}"
    if -d "$dest" ;then
        remove-dir "$dest"/*
    else
        -e "$dest" && {
            err "$dest already exists and is not a directory"
            return 1
        }
        mkdir -p "$dest"
    fi
}

# ensures $1 will be now under name of $2. $2 is removed if required. Does nothing if $1 is a file or $2 does not exist.
# prompting before removing/overwriting if BUSH_SAFE_REMOVALS=true
function replace-dir() {
    local source="${1:?Missing source dir}"
    local dest="${2:?Missing target dir}"
    -nd "$source" && { err "$FUNCNAME: $source is not a directory"; return 1; }
    -f "$dest" && { err "$FUNCNAME: $dest is a file"; return 1; }
    -d "$dest" && { remove "$dest"/* || return 1; }
    -true "$BUSH_SAFE_REMOVALS" && {
        echo "Replacing $dest with $source"
        local options=-iv
    }
    mv $options -T "$source" "$dest"
    -ne "$source"
}

# rm -rf unless BUSH_SAFE_REMOVALS=true which means prompting before removal - non-zero exit status if user decided not to remove.
function remove() {
    local options=-r
    if -true "$BUSH_SAFE_REMOVALS" ;then
        echo "Removing $@"
        options+=Iv
    else
        options+=f
    fi
    rm $options $@
    -ne $1
}

# creates temporary directory which will be automatically cleaned up when closing shell and prints its path
function temp-dir() {
    mktemp --tmpdir -d
}

# creates temporary file which will be automatically cleaned up when closing shell and prints its path
function temp-file() {
    mktemp --tmpdir
}

# TODO remove configured with option whether to use rm -rI with printing what is being deleted
# TODO configurable interactive mv

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

# removes slash from the end of variable named $1 (variable is changed)
function strip-trailing-slash() {
   : "${1:?Missing var name}"
   local val="${!1}"
   -n "$val" && set-var "$1" "${val%/}"
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
function set-var() {
    : "${1?"Missing variable name"}"
    printf -v "$1" -- "$2"
}

# Parameters: VAR [EXPR]
# If EXPR is not provided it is set to value of VAR variable. EXPR is evaluated and the result is stored in VAR
function eval-var() {
    : "${1?"Missing variable name"}"
    eval "$1=\"${2-${!1}}\""
}

# Parameters: VAR [EXPR]
# Escape sequences in EXPR are evaluated and the result is stored in VAR. If EXPR is not provided, VAR value is used instead.
function unescape-var() {
    : "${1?"Missing variable name"}"
    eval "$1=$'${2-${!1}}'"
}

# sponge emulator. Provide file name as a parameter. Handles BUSH_SAFE_REMOVALS.
function sponge() {
    local file="$1"
    local tmp="$file.tmp"
    cat >"$tmp"
    if -true "$BUSH_SAFE_REMOVALS" ;then
        echo "Sponge - replacing $tmp with $file:"
        diff "$tmp" "$file"
        proceed || return 1
    fi
    chmod --reference "$file" "$tmp"
    mv "$tmp" "$file"
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


# TODO doc, mention about not to nest in one function
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
            stack_pop SIGINT_TRAPS onSigInt 2>/dev/null
            finally "$onSigInt"
        else
            trap -- SIGINT
        fi
    }
}

function show() {
    -n "$BUSH_SHOW"
    for item in $BUSH_SHOW ;do
        echo start "$item"
        start "$item"
    done
}

stack_destroy SIGINT_TRAPS
stack_new SIGINT_TRAPS
