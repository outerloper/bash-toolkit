#!/bin/bash

declare BUSH_HOME="$(dirname "$BASH_SOURCE")"
declare BUSH_CONFIG="$(readlink -f "$BUSH_HOME/../config/")"
declare BUSH_PATH=( $BUSH_HOME )

declare BUSH_DEPENDENCIES=' '
declare BUSH_INCLUDES=" $BASH_SOURCE "
declare DECLARE_ASSOC=":"

declare -A BUSH_ON_EXIT
declare BUSH_ON_EXIT_INDEX=0
declare -A BUSH_ON_PROMPT
declare BUSH_ON_PROMPT_INDEX=0


function _bush_exit() {
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

# TODO standard error codes: ok, negative check, error, user cancelled...
# TODO for scripts run by./ - non-interactive entry for sourcing inside of such script -> function for this: bush-init - checking bash version, sourcing required files
# TODO naming conventions public-function _namespace_privateFunction $_result variable, context variables
# TODO prompt symbol: >/! depending on result of last command
# TODO minimal version for bash 3.2
# TODO autocomplete for try and require, if try autocompleted, require extension
# TODO facilitate autocompletion
# TODO hist browse

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



shopt -s nullglob
declare _configScript="$BUSH_CONFIG/config.sh"
declare _profileScript="$BUSH_CONFIG/profile.sh"
! [ -d "$BUSH_CONFIG" ] && mkdir "$BUSH_CONFIG"
! [ -f "$_configScript" ] && cp "$BUSH_HOME/resources/config.sh" "$_configScript"
! [ -f "$_profileScript" ] && cp "$BUSH_HOME/resources/profile.sh"  "$_profileScript"

source "$_configScript"

trap "_bush_exit" EXIT
TMPDIR=$(mktemp -d -p "$TMP")

on-exit "rm -rf '$TMPDIR'"

# if you want to reuse associative array in other scripts you have to declare it with the line exactly like: $DECLARE_ASSOC arrayName
# or, for portability of your script: ${DECLARE_ASSOC:-"declare -A"} arrayName
[ -z "$(echo "${BUSH_HOME}"/*.sh)" ] && echo "Warning: no scripts found in $BUSH_HOME"
eval "$(sed -n 's/^\s*\${*DECLARE_ASSOC\(:-"declare -A"\)*}*\s*\(\w*\)/declare -A \2/p' $BUSH_HOME/*.sh)"

for path in ${BUSH_PATH[@]} ;do
    for script in "$path"/*.sh ;do
        require "$script"
    done
done

source "$_profileScript"

unset _configScript
unset _profileScript