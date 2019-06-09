#!/bin/bash

sandbox() {
    is-help "$@" && {
        echo "Usage: $FUNCNAME SCRIPT
"
        return 0
    }
    mkdir -p "$BT_CONFIG/sandbox"
    script="$BT_CONFIG/sandbox/${1:-sandbox}.sh"
    if -f "$script"; then
        source "$script" "${@:2}"
    else
        echo -e "#!/usr/bin/env bash\n\n" > "$script"
        chmod u+x "$script"
        echo "$script created."
    fi
}
