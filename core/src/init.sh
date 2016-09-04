#!/bin/bash

# below line is a workaround for lack of support for global associative arrays.
# if you want an associative array in your script to be visible for other scripts you should not declare it with 'declare -A' syntax but instead:
#    MY_ARRAY=( # @global-assoc
#       ...
#    )
# or:
#    MY_ARRAY=() # @global-assoc
# comment and assignment is important
eval "$(sed -n 's/^\s*\(\w\w*\)=(.*#.*@global-assoc.*/declare -A \1/p' ${HOME}/.bash-toolkit/*/src/*.sh | tr "\n" ';')"

declare BASH_TOOLKIT_DEPENDENCIES=' ' BASH_TOOLKIT_INCLUDES=" $BASH_SOURCE "
function require() {
    local script="${1:?Missing script name}"
    [[ "$BASH_TOOLKIT_INCLUDES" =~ " $1 " ]] && return 0
    [[ "$BASH_TOOLKIT_DEPENDENCIES" =~ " $1 " ]] && echo "Cyclic dependency:$(echo "$BASH_TOOLKIT_DEPENDENCIES" | sed 's/ / -> /2g')$1" >&2 && return 1
    BASH_TOOLKIT_DEPENDENCIES+="$1 "
    #echo -e "$script" # TODO verbose global option
    source "$script"
    BASH_TOOLKIT_DEPENDENCIES="${BASH_TOOLKIT_DEPENDENCIES/"$1 "/}"
    BASH_TOOLKIT_INCLUDES+="$1 "
}

require ${HOME}/.bash-toolkit/core/src/utils.sh
for script in ${HOME}/.bash-toolkit/*/src/*.sh
do
   require "${script}"
done

unset require

#TODO deploy task