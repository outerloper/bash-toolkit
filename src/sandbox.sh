#!/bin/bash

function sandbox() { # TODO enhance
    -help "$@" && {
        echo "Usage: $FUNCNAME SCRIPT
"
        return 0
    }
    ensure-dir "$BUSH_CONFIG/sandbox"
    script="$BUSH_CONFIG/sandbox/${1:-'sandbox'}.sh"
    if -f "$script" ;then
        source "$script" "${@:2}"
    else
        echo -e "#!/usr/bin/env bash\n\n" > "$script"
        echo "$script created."
    fi
}
