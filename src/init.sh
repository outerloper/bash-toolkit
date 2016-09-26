#!/bin/bash


! [ "${BASH_VERSION}" ] && echo "Bush requires Bash shell to run." && return 1
[[ "${BASH_VERSION}" = 2.* ]] || [[ "${BASH_VERSION}" = 3.* ]] || [[ "${BASH_VERSION}" = 4.0.* ]] &&
    echo "Bush requires Bash v4.1 or higher to run. ${BASH_VERSION} found." && return 1


BUSH_INIT="$(readlink -f "$BASH_SOURCE")"
BUSH_HOME="${BUSH_INIT%/*}"
BUSH_CONFIG="${BUSH_HOME%/*}/config"
BUSH_PATH=( $BUSH_HOME )

BUSH_DEPENDENCIES=' '
BUSH_INCLUDES=" $BUSH_INIT "
GLOBAL_ASSOC=":"

declare -A BUSH_ON_EXIT
BUSH_ON_EXIT_INDEX=0
declare -A BUSH_ON_PROMPT
BUSH_ON_PROMPT_INDEX=0

BUSH_PROMPT_STATUS=


function _bush_exit() {
    echo
    for exitTrap in "${BUSH_ON_EXIT[@]}" ;do
        eval "$exitTrap"
    done
}

function on-exit() {
    [ "$1" == '--help' ] && echo -en "Usage: $FUNCNAME COMMAND [ID]
Adds code to be executed just before closing shell.
When ID is specified instruction added previously with given ID will be replaced. If no ID, COMMAND is just added and cannot be removed.
" && return
    local index="$BUSH_ON_EXIT_INDEX" command="${1?}"
    [ -n "$2" ] && index="$2" || (( BUSH_ON_EXIT_INDEX++ ))
    [ -n "$3" ] && echo "$FUNCNAME: [WARNING] Unexpected parameter: $3 (ignored)"
    BUSH_ON_EXIT["$index"]="$command"
}

function on-prompt() {
    [ "$1" == '--help' ] && echo -en "Usage: $FUNCNAME COMMAND [ID]
Adds code to be executed just before displaying the prompt.
When ID is specified instruction added previously with given ID will be replaced. If no ID, COMMAND is just added and cannot be removed.
" && return
    local index="$BUSH_ON_PROMPT_INDEX" command="${1?}"
    [ -n "$2" ] && index="$2" || (( BUSH_ON_PROMPT_INDEX++ ))
    [ -n "$3" ] && echo "$FUNCNAME: [WARNING] Unexpected parameter: $3 (ignored)"
    BUSH_ON_PROMPT["$index"]="$command"
    PROMPT_COMMAND='BUSH_PROMPT_STATUS=$?;'
    for command in "${BUSH_ON_PROMPT[@]}" ;do
        PROMPT_COMMAND+="$command;"
    done
}


# TODO autocomplete for try and require, if try autocompleted, require extension
# TODO facilitate autocompletion

function print-stack-trace() {
    local exitCode=$? routine params="$*"
    -nez "$exitCode" && echo "Shell command finished with code $exitCode. Params: ${params:-"(no params)"}" >&2
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
    if [[ "${1}" =~ ^/.* ]] ;then
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

# if you want to reuse associative array in other scripts you have to declare it with the line exactly like: $GLOBAL_ASSOC arrayName
# or, for portability of your script: ${GLOBAL_ASSOC:-"declare -A"} arrayName
[ -z "$(echo "${BUSH_HOME}"/*.sh)" ] && echo "Warning: no scripts found in $BUSH_HOME"
eval "$(sed -n 's/^\s*\${*GLOBAL_ASSOC\(:-"declare -A"\)*}*\s*\(\w*\)/declare -A \2/p' $BUSH_HOME/*.sh)"

for path in ${BUSH_PATH[@]} ;do
    for script in "$path"/*.sh ;do
        require "$script"
    done
done

source "$_profileScript"

unset _configScript
unset _profileScript