#!/bin/bash

bt-require stack.sh

# syntactic sugar for test methods to avoid "[", "]" and adding few more tests ###############################################

# $1 is a directory
-d() {
    [[ -d "$1" ]]
}
# path $1 exists
-e() {
    [[ -e "$1" ]]
}
# file or directory $1 is empty
-E() {
    [[ "$1" = "$(find -L "$1" -maxdepth 0 -empty -print -quit 2>/dev/null)" ]]
}
# $1 is a regular file
-f() {
    [[ -f "$1" ]]
}
# $1 is a symbolic link
-h() {
    [[ -h "$1" ]]
}
# $1 is not empty
-n() {
    [[ -n "$1" ]]
}
# file $1 is non-zero size
-s() {
    [[ -s "$1" ]]
}
# file descriptor $1 is open and refers to a terminal
-t() {
    [[ -t "$1" ]]
}
# $1 is a variable
-v() {
    [[ -v "$1" ]]
}
# $1 is a path to an executable file
-x() {
    [[ -x "$1" ]]
}
# $1 is empty (zero-length)
-z() {
    [[ -z "$1" ]]
}
# $1 is equal to zero
-0() {
    -eq "$1" 0
}
# $1 equals $2 as text. Exact match, no processing wildcards.
-eq() {
    (( $# == 2 )) || { err "Invalid parameters for $FUNCNAME: [$*]"; return 1; }
    [[ "$1" == "$2" ]]
}
# $1 <= $2 and both arguments are integers. If $2 not provided, 0 implied.
-le() {
    local rhs="${2-0}"
    is-int "$1" && is-int "$rhs" && (( $# <= 2 )) || { err "Invalid parameters for $FUNCNAME: [$*]"; return 1; }
    (( "$1" <= "$rhs" ))
}
# $1 >= $2 and both arguments are integers. If $2 not provided, 0 implied.
-ge() {
    local rhs="${2-0}"
    is-int "$1" && is-int "$rhs" && (( $# <= 2 )) || { err "Invalid parameters for $FUNCNAME: [$*]"; return 1; }
    (( "$1" >= "$rhs" ))
}
# $1 < $2 and both arguments are integers. If $2 not provided, 0 implied.
-lt() {
    local rhs="${2-0}"
    is-int "$1" && is-int "$rhs" && (( $# <= 2 )) || { err "Invalid parameters for $FUNCNAME: [$*]"; return 1; }
    (( "$1" < "$rhs" ))
}
# $1 > $2 and both arguments are integers. If $2 not provided, 0 implied.
-gt() {
    local rhs="${2-0}"
    is-int "$1" && is-int "$rhs" && (( $# <= 2 )) || { err "Invalid parameters for $FUNCNAME: [$*]"; return 1; }
    (( "$1" > "$rhs" ))
}
# $1 contains $2, wildcards in $2 are processed
contains() {
    : "${2?$FUNCNAME: Missing pattern}"
    -gt $# 2 && err "Too many parameters, 2 expected but $# given: $*" && return 1
    [[ "$1" == *$2* ]]
}
# $1 is equal to $2 or $1 matches to $2 - wildcards in $2 are processed
matches() {
    : "${2?$FUNCNAME: Missing pattern}"
    -gt $# 2 && err "Too many parameters, 2 expected but $# given: $*" && return 1
    [[ "$1" == $2 ]]
}
# $1 contains substring that matches the regular expression $2
contains-regex() {
    : "${2?$FUNCNAME: Missing pattern}"
    -gt $# 2 && err "Too many parameters, 2 expected but $# given: $*" && return 1
    [[ "$1" =~ $2 ]]
}
# $1 matches the regular expression $2
matches-regex() {
    : "${2?$FUNCNAME: Missing pattern}"
    -gt $# 2 && err "Too many parameters, 2 expected but $# given: $*" && return 1
    [[ "$1" =~ ^$2$ ]]
}

# tests if last command exited with zero status. If parameter specified, it is used instead of last exit code.
is-success() {
    return "${1:-$?}"
}
# tests if last command exited with non-zero status
is-error() {
    ! is-success
}
# is unsigned integer
is-uint()
{
    : "${1?-$FUNCNAME: Missing parameter}"; [[ "$1" =~ ^[0-9]+$ ]]
}
# is signed integer
is-int()
{
    [[ "$1" =~ ^[+-]?[0-9]+$ ]]; }
# can be interpreted as boolean value: 1 t true y yes 0 f false n no (case insensitive)
is-bool()
{
    [[ "$1" =~ ^(1|[tT]|[tT][rR][uU][eE]|[yY]|[yY][eE][sS]|0|[fF]|[fF][aA][lL][sS][eE]|[nN]|[nN][oO])$ ]]
}
# $1 represents true: 1, true, yes (case insensitive)
is()
{
    [[ "$1" =~ ^(1|[tT]|[tT][rR][uU][eE]|[yY]|[yY][eE][sS])$ ]]
}
# is UTF encoding
is-encoding()
{
    : "${1?"$FUNCNAME: Missing encoding value"}"
    matches "$LANG" "$1"
}
# is $1 a function name
is-function()
{
    : "${1:"?$FUNCNAME: Missing function name."}"; [[ "$(type -t "$1")" == "function" ]]
}
# is $1 a command line option switch (not empty and starting from '-')
is-option()
{
    -n "$1" && matches "$1" '-*'
}
# when $@ or $1 provided within function definition or script, the function tests if there was help request (--help of -h as first parameter)
is-help() {
    [[ "$1" == '--help' ]] || [[ "$1" == '-h' ]]
}
# tests if $1 is valid variable name
is-valid-var-name() {
    [[ "$1" =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ ]]
}
# tests if $1 is a zip archive
is-zip() {
    -eq "$(file -b --mime-type "${1?"Missing file name"}")" 'application/zip'
}

# echo to stderr
err() {
    if -t 2
    then
        echo -e "$styleFailure$1$styleOff" >&2
    else
        echo -e "$1" >&2
    fi
    is "$BT_VERBOSE" && print-stack-trace
    return 0
}

set-window-title() {
    echo -en "\033]0;$@\007"
}

# increment value named $1 by 1
var-inc() {
    (( ++ ${1?Missing var name} ))
}

# decrement value named $1 by 1
var-dec() {
    (( -- ${1?Missing var name} ))
}

# removes slash from the end of variable named $1 (variable is changed)
var-remove-trailing-slash() {
   : "${1:?Missing var name}"
   local val="${!1}"
   -n "$val" && var-set "$1" "${val%/}"
}

# ensures first letter of variable named $1 is upper-case
var-capitalize() {
   : "${1:?Missing var name}"
   local val="${!1}"
   first="${val:0:1}"
   val="${first^^}${val:1}"
   -n "$val" && var-set "$1" "${val}"
}

# prints message informing about exit status of last command. $1 - custom success command, $2 - custom failure command
print-status() {
    OK=$?
    if [ "$OK" -eq 0 ] ; then
        success "$1"
    else
        failure "$2"
    fi
    return "$OK"
}

ask-for-confirmation() { # TODO review
    -eq "$1" '--help' && echo "Asks user whether to proceed with some action. When <timeout> specified, proceeds automatically within the provided amount of seconds.
Usage: $FUNCNAME [<action-description>] [-c <cancellation-description>] [-t [<timeout>]]" && return
    local arg message proceed='proceed' cancel='cancel' confirmed canceled timeout
    is-option "$1" || {
        if contains-regex "$1" '^[[:lower:]]'; then
            proceed="$1"
            confirmed="$1"
        else
            message="$1"
        fi
        shift
    }
    while ! -0 $# ;do
        arg="$1"
        case "$arg" in
        -t)
            if -n "$2" && ! is-option "$2"; then
                is-uint "$2" || {
                    err "-t: Number expected. Was: $2" && return 1
                }
                timeout="$2"
                shift
            else
                timeout=10
            fi
            ;;
        -c)
            if -n "$2" && ! is-option "$2"; then
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
    local text="\r$message""Press ENTER $proceed, other key to $cancel"
    if -z "$timeout" ; then
        printf "$text.. "
        read -n 1 -s key
        is-success && {
            _proceed_handleKey
            return $?
        }
    else
        local timerText="$text. Will $proceed in %s secs"
        var-inc timeout
        while var-dec timeout && ! -0 "$timeout"
        do
            printf "$timerText " "$timeout"
            read -t 1 -n 1 -s key && {
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

# assign value ($2) to a variable (with name $1). $1 can represent array cell e.g. "a[1]"
# when these parameters are preceeded by -e flag, value's escape sequences are interpreted
var-set() {
    local escape
    -eq "$1" -e && { escape=1; shift; }
    : "${1?"Missing variable name"}"
    if is "$escape"; then
        eval "$1=$'${2-${!1}}'"
    elif -z "$2"; then
        eval "$1="
    else
        printf -v "$1" -- "$2"
    fi
}

# copies the value of variable with name $2 to the variable with name $1. $1 and $2 can be arrays with indexes like a[0]
var-copy() {
    var-set "$1" "${!2}"
}

__var_count=0

# Remembers the values provided as parameters in internal variables to be consumed by var-in function.
# Use together with var-in to effectively pass function outcomes.
var-out() {
    local i=1
    if -gt $# 1; then
        for var in "$@"; do
            var-set __var_$i "$var"
            var-inc i
        done
    else
        var-set __var_1 "$1"
        var-inc i
    fi
    local newCount=$i
    while -ge $__var_count $i; do
        unset __var_$i
        var-inc i
    done
    __var_count=$newCount
}

# Assigns respective variables from the last call of var-out function to the variable names provided.
# Use together with var-out to effectively pass function outcomes.
var-in() {
    if -gt $# 1; then
        local i=0
        for var in "$@"; do
            var-inc i
            var-copy "$var" __var_$i
        done
    else
        var-set "$var" "$__var_1"
    fi
}

# removes \r chars from line endings in provided files
rmcr() {
   for file in $@ ;do
      -f "$file" && tr -d "\r" < "$file" | sponge "$file"
   done
}

# sponge polyfill. Provide file name as a parameter. Handles BT_SAFE_REMOVALS.
type sponge >/dev/null 2>/dev/null || sponge() {
    local file="$1"
    local tmp="$file.tmp"
    cat >"$tmp"
    if is "$BT_SAFE_REMOVALS"; then
        echo "Sponge - replacing $tmp with $file:" >&2
        diff "$tmp" "$file" >&2
        ask-for-confirmation >&2
        is-success || return 1
    fi
    chmod --reference "$file" "$tmp"
    mv -f "$tmp" "$file"
}

# windows to cygwin path converter
type cygpath >/dev/null 2>/dev/null || cygpath() {
    sed -e 's/^\(\w\):[\/\\]*/\/cygdrive\/\L\1\//' -e 's/\\/\//g' <<<$1
}

# windows start command
type cygstart >/dev/null 2>/dev/null && ! type start >/dev/null 2>/dev/null && alias start=cygstart

# prints array entries in key=value lines, keys are sorted
array-print() {
    : "${1?"Missing array name"}"
    local options indexes=()
    local declaration="$(declare -p "$1" | sed 's/declare -\([^ ]*\) \([^=]*\)\(=.*\)/declare -\1 array\3; local options=\1/')"
    eval "$declaration"
    if contains "$options" a; then
        indexes=( $(seq 0 $(( ${#array[@]} - 1 ))) )
    elif contains "$options" A; then
        indexes=( $(echo ${!array[@]} | tr ' ' "\n" | sort -n) )
    else
        err "$1 is not an array"
        return 1
    fi
    for i in ${indexes[@]}; do
        echo "$i=${array[$i]}"
    done
}


finally() {
    stack-push SIGINT_TRAPS "$*"
    trap "finalize ${FUNCNAME[1]}; -n \"\$FUNCNAME\" && return 130" SIGINT
}

finalize() {
    local onSigInt stackSize
    -n "$1" && ! -eq "$1" "${FUNCNAME[1]}" && return
    stack-pop SIGINT_TRAPS onSigInt 2>/dev/null && {
        eval "$onSigInt"
        stack-size SIGINT_TRAPS stackSize
        if ! -0 "$stackSize"; then
            stack-pop SIGINT_TRAPS onSigInt 2>/dev/null
            finally "$onSigInt"
        else
            trap -- SIGINT
        fi
    }
}

stack-remove SIGINT_TRAPS
stack-new SIGINT_TRAPS
