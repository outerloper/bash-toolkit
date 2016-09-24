#!/bin/bash

shopt -s nullglob

declare -A BUSH_ON_EXIT=()
BUSH_ON_EXIT_INDEX=0

trap "_doExit" EXIT
export TMPDIR=$(mktemp -d -p "$TMP")

function _doExit() {
    echo
    for exitTrap in "${BUSH_ON_EXIT[@]}" ;do
        eval "$exitTrap"
    done
}

function on-exit() {
    [ "$1" == '--help' ] && echo -en "Usage: $FUNCNAME COMMAND [ID]
Adds code to be executed when closing shell.
When ID is not specified, COMMAND is just added. Otherwise instruction added previously with given ID will be overwritten.
" && return
    local index="$BUSH_ON_EXIT_INDEX" command="${1?}"
    [ -n "$2" ] && index="$2" || (( BUSH_ON_EXIT_INDEX++ ))
    [ -n "$3" ] && echo "$FUNCNAME: [WARNING] Unexpected parameter: $3 (ignored)"
    BUSH_ON_EXIT["$index"]="$command"
}

on-exit "rm -rf '$TMPDIR'"


declare -A BUSH_ON_PROMPT=()
BUSH_ON_PROMPT_INDEX=0

function on-prompt() {
    [ "$1" == '--help' ] && echo -en "Usage: $FUNCNAME COMMAND [ID]
Adds code to be executed when displaying the prompt.
When ID is not specified, COMMAND is just added. Otherwise instruction added previously with given ID will be overwritten.
" && return
    local index="$BUSH_ON_PROMPT_INDEX" command="${1?}"
    [ -n "$2" ] && index="$2" || (( BUSH_ON_PROMPT_INDEX++ ))
    [ -n "$3" ] && echo "$FUNCNAME: [WARNING] Unexpected parameter: $3 (ignored)"
    BUSH_ON_PROMPT["$index"]="$command"
    PROMPT_COMMAND='_bush_promptCommand;'
    for command in "${BUSH_ON_PROMPT[@]}" ;do
        PROMPT_COMMAND+="$command;"
    done
}

function _bush_promptCommand() {
    local lastExitCode=$? lastExitCodeColor=$green
    -nez $lastExitCode && lastExitCodeColor=$red
    PS1="${PS1_TPL//\\c/\\[$lastExitCodeColor\\]}"
}

# standard error codes: ok, negative check, error, user cancelled...
# TODO for scripts run by./ - non-interactive entry for sourcing inside of such script -> function for this: bush-init - checking bash version, sourcing required files
# TODO naming conventions public-function _namespace_privateFunction $_result variable, context variables
# TODO prompt symbol: >/! depending on result of last command
# TODO minimal version for bash 3.2
# TODO autocomplete for try and require, if try autocompleted, require extension
# TODO facilitate autocompletion
# TODO hist browse

# if you want to reuse associative array in other scripts you have to declare it with the line exactly like: $BUSH_ASSOC arrayName
# or, for portability of your script: ${BUSH_ASSOC:-"declare -A"} arrayName
BUSH_HOME="$(dirname "$BASH_SOURCE")"
BUSH_PATH=()

function print-stack-trace() {
    local exitCode=$? routine params="$*"
    echo "Shell command finished with code $exitCode. Params: ${params:-"(no params)"}" >&2
    for (( i = 1 ; i < ${#FUNCNAME[@]}; i++ )) ;do
        routine="${FUNCNAME[$i]}"
        if [ source = "$routine" ] ;then
            routine=
        else
            routine=" $routine()"
        fi
        echo " at ${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]}$routine" >&2
    done
}
function bush-set-trace-errors() {
    set -o errtrace
    trap 'print-stack-trace "$@"' ERR
}

function bush-unset-trace-errors() {
    set +o errtrace
    trap '' ERR
}

source "$BUSH_HOME/config/config.sh"

BUSH_ASSOC=":"
BUSH_DEPENDENCIES=' '
BUSH_INCLUDES=" $BASH_SOURCE "
BUSH_PATH+=( "$BUSH_HOME" )

[ -z "$(echo "${BUSH_HOME}"/*.sh)" ] && echo "Warning: no scripts found in ${BUSH_HOME}"
eval "$(sed -n 's/^\s*\${*BUSH_ASSOC\(:-"declare -A"\)*}*\s*\(\w*\)/declare -A \2/p' ${BUSH_HOME}/*.sh)"
function require() {
    local path script found
    if [ "${1}" != "${1#/}" ] ;then # if path is absolute
        found=1
        script="$1"
    else
        for path in ${BUSH_PATH[@]} ;do
            script="$path/$1"
            [ -f "$script" ] && {
                found=1
                break
            }
        done
    fi
    [ -z "$found" ] && echo "$script not found" >&2 && return 1
    [[ "$BUSH_INCLUDES" =~ " $script " ]] && return 0
    [[ "$BUSH_DEPENDENCIES" =~ " $script " ]] && echo -e "[WARNING] Cyclic dependency:\n$(echo "$BUSH_DEPENDENCIES" | sed 's/ / -> /2g')$script" >&2 && return 1
    BUSH_DEPENDENCIES+="$script "
    [ "$BUSH_VERBOSE" ] && echo "Loading $script"
    source "$script"
    [ "$BUSH_VERBOSE" ] && echo "Loaded $script"
    BUSH_DEPENDENCIES="${BUSH_DEPENDENCIES/"$script "/}"
    BUSH_INCLUDES+="$script "
}

for path in ${BUSH_PATH[@]} ;do
    for script in "$path"/*.sh ;do
        require "$script" # TODO option allowing include more than once
    done
done

function sandbox() {
    script="$BUSH_HOME/sandbox/${1:-'sandbox'}.sh"
    if -f "$script" ;then
        source "$script"
    else
        echo -e "#!/usr/bin/env bash\n\n" > "$script"
        echo "$script created."
    fi
}