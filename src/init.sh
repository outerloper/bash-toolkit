#!/bin/bash


! [[ "${BASH_VERSION}" ]] && echo "Bash Toolkit (BT) requires Bash shell to run." && return 1
[[ "${BASH_VERSION}" = 2.* ]] || [[ "${BASH_VERSION}" = 3.* ]] || [[ "${BASH_VERSION}" = 4.0.* ]] &&
    echo "Bash Toolkit (BT) requires Bash v4.1 or higher to run. ${BASH_VERSION} found." && return 1


BT_INIT="$(readlink -f "$BASH_SOURCE")"
BT_HOME="${BT_INIT%/*}"
BT_CONFIG="${BT_HOME%/*}/config"
BT_PROFILE="$BT_CONFIG/profile.sh"
BT_PATH=( $BT_HOME "${BT_HOME}/../lib" )

BT_DEPENDENCIES=' '
BT_INCLUDES=" $BT_INIT "
BT_GLOBAL_ASSOC=":"

declare -A BT_ON_EXIT
BT_ON_EXIT_INDEX=0
declare -A BT_ON_PROMPT
BT_ON_PROMPT_INDEX=0

BT_PROMPT_STATUS=


_bt_exit() {
    echo
    for exitTrap in "${BT_ON_EXIT[@]}"
    do
        eval "$exitTrap"
    done
}

bt-on-exit() {
   [[ "$1" == '--help' ]] &&
   echo -en "Usage: $FUNCNAME COMMAND [ID]
Adds code to be executed just before closing shell.
When ID is specified instruction added previously with given ID will be replaced. If no ID, COMMAND is just added and cannot be removed.
" && return || true
    local index="$BT_ON_EXIT_INDEX" command="${1?}"
    [[ -n "$2" ]] && index="$2" || (( BT_ON_EXIT_INDEX++ )) || true
    [[ -n "$3" ]] && echo "$FUNCNAME: [WARNING] Unexpected parameter: $3 (ignored)" || true
    BT_ON_EXIT["$index"]="$command"
}

bt-on-prompt() {
    [[ "$1" == '--help' ]] && echo -en "Usage: $FUNCNAME COMMAND [ID]
Adds code to be executed just before displaying the prompt.
When ID is specified instruction added previously with given ID will be replaced. If no ID, COMMAND is just added and cannot be removed.
" && return || true
    local index="$BT_ON_PROMPT_INDEX" command="${1?}"
    [[ -n "$2" ]] && index="$2" || (( BT_ON_PROMPT_INDEX++ )) || true
    [[ -n "$3" ]] && echo "$FUNCNAME: [WARNING] Unexpected parameter: $3 (ignored)" || true
    BT_ON_PROMPT["$index"]="$command"
    PROMPT_COMMAND='BT_PROMPT_STATUS=$?;'
    for command in "${BT_ON_PROMPT[@]}"
    do
        PROMPT_COMMAND+="$command;"
    done
}

print-stack-trace() {
    local exitCode=$? routine params="$*"
    ! -0 "$exitCode" && echo "  Shell command finished with code $exitCode. Params: ${params:-"(no params)"}" >&2
    for (( i = 1 ; i < ${#FUNCNAME[@]}; i++ )) ;do
        routine="${FUNCNAME[$i]}"
        if [[ source = "$routine" ]]
        then
            routine=
        else
            routine="#$routine()"
        fi
        echo "    at ${BASH_SOURCE[$i]}$routine:${BASH_LINENO[$i-1]}" >&2
    done
}

bt-set-trace-errors() {
    set -o errtrace
    trap 'print-stack-trace "$@"' ERR
}

bt-unset-trace-errors() {
    set +o errtrace
    trap '' ERR
}

bt-require() {
    local path script found
    if [[ "${1}" =~ ^/.* ]] ;then
        found=1
        script="$1"
    else
        for path in ${BT_PATH[@]} ;do
            script="$path/$1"
            [ -f "$script" ] && {
                found=1
                break
            }
        done
    fi
    [[ -z "$found" ]] && echo "$script not found" >&2 && return 1
    [[ "$BT_INCLUDES" =~ " $script " ]] && return 0
    [[ "$BT_DEPENDENCIES" =~ " $script " ]] && echo -e "[WARNING] Cyclic dependency:\n$(echo "$BT_DEPENDENCIES" | sed 's/ / -> /2g')$script" >&2 && return 1
    BT_DEPENDENCIES+="$script "
    [[ "$BT_VERBOSE" ]] && echo "Loading $script"
    source "$script"
    [[ "$BT_VERBOSE" ]] && echo "Loaded $script"
    BT_DEPENDENCIES="${BT_DEPENDENCIES/"$script "/}"
    BT_INCLUDES+="$script "
}



# NOTE causes completion not to work on centos
# workaround: temporarily unset and set nullglob around /usr/share/bash-completion/bash_completion#init_completion()
# disabling to test what would be the impact
# shopt -s nullglob
mkdir -p "$BT_CONFIG"
cp -n "$BT_HOME/resources/profile.sh" "$BT_PROFILE"

trap "_bt_exit" EXIT
[[ "$TMPDIR" ]] && rm -rf "$TMPDIR"
export TMPDIR=$(mktemp -d -p "${TMP:-"/tmp"}")

bt-on-exit "rm -rf '$TMPDIR'"

# if you want to reuse associative array in other scripts you have to declare it with the line exactly like: $BT_GLOBAL_ASSOC arrayName
# or, for portability of your script: ${BT_GLOBAL_ASSOC:-"declare -A"} arrayName
[[ -z "$(echo "${BT_HOME}"/*.sh)" ]] && echo "Warning: no scripts found in $BT_HOME"
eval "$(sed -n 's/^\s*\${*BT_GLOBAL_ASSOC\(:-"declare -A"\)*}*\s*\(\w*\)/declare -A \2/p' $BT_HOME/*.sh)"

for path in ${BT_PATH[@]}
do
    for script in "$path"/*.sh
    do
        bt-require "$script"
    done
done

source "$BT_PROFILE"
