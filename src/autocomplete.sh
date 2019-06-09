#!/bin/bash

bt-require utils.sh

# Generates autocompletion values. Use in completion functions provided in 'complete -F'. Usage examples:
# autocomplete aa bb bbbb cc     # takes completion straight from the parameters provided
# autocomplete < <(cd ~; ls)     # takes completion options from lines of the redirected command
autocomplete()
{
    local args="$@"
    if ! -t 0; then
        while read line; do
            args+=" ${line// /\\ }"
        done <&0
    fi

    COMPREPLY=()
    while read line; do
        COMPREPLY+=( "$line" )
    done < <( compgen -W "$args" -- "${COMP_WORDS[COMP_CWORD]}" || true )
}

bind "set completion-ignore-case on"
bind "set completion-map-case on"
bind "set show-all-if-ambiguous on"
bind "set completion-query-items 1000"
bind "set page-completions off"
#bind "set colored-stats on"                # slow
#bind "set colored-completion-prefix on"    # slow
