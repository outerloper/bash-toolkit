#!/bin/bash

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
    [ "$1" == '--help' ] && echo -en "Adds code to be executed when closing shell.
  Usage: $BASHFUNC <instruction> [<id>]
When <id> is not specified, <instruction> is just added. Otherwise instruction added previously with given <id> will be overwritten.
" && return
    local index="$BUSH_ON_EXIT_INDEX" command="${1?}"
    [ -n "$2" ] && index="$2" || (( BUSH_ON_EXIT_INDEX++ ))
    [ -n "$3" ] && echo "$BASHFUNC: [WARNING] Unexpected parameter: $3 (ignored)"
    BUSH_ON_EXIT["$index"]="$command"
}

on-exit "rm -rf '$TMPDIR'"

# TODO minimal version for bash 3.2
# TODO autocomplete for try and require, if try autocompleted, require extension
# TODO facilitate autocompletion
# TODO hist browse

# if you want to reuse associative array in other scripts you have to declare it with the line exactly like: $BUSH_ASSOC arrayName
# or, for portability of your script: ${BUSH_ASSOC:-"declare -A"} arrayName
BUSH_HOME="$(dirname "$BASH_SOURCE")"
BUSH_PATH=()

source "$BUSH_HOME/config/config.sh"

BUSH_ASSOC=":"
BUSH_DEPENDENCIES=' '
BUSH_INCLUDES=" $BASH_SOURCE "
BUSH_PATH+=( "$BUSH_HOME" )
eval "$(sed -n 's/^\s*\${*BUSH_ASSOC\(:-"declare -A"\)*}*\s*\(\w*\)/declare -A \2/p' ${HOME}/.bash-toolkit/*/src/*.sh)"
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
        require "$script"
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
