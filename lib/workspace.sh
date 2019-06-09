#!/bin/bash

# @experimental

WORKSPACE_ROOT_DIR=~/d

-d "$WORKSPACE_ROOT_DIR" || { err "Unable to initialize workspace - no such directory: $WORKSPACE_ROOT_DIR"; return 1; }

_workspace_list()
{
    autocomplete < <( cd "$WORKSPACE_ROOT_DIR"; ls -d */ | grep -E '^[a-zA-Z0-9_.]*/?$' )
}

workspace()
{
    : "{1?"Missing workspace name"}"
    local name="${1%/}"
    name="${name//[^a-zA-Z0-9_.]/_}"

    echo "$WORKSPACE_ROOT_DIR/$name"

    -d "$WORKSPACE_ROOT_DIR/$name" && {
        cd "$WORKSPACE_ROOT_DIR/$name"
        echo "Using workspace '$name'"
        bash || true
        return
    }

    echo "Workspace '$name' does not exist."
    ask-for-confirmation "to create one" &&
        mkdir -p "$WORKSPACE_ROOT_DIR/$name/.bt" &&
        touch "$WORKSPACE_ROOT_DIR/$name/.bt/init.sh" &&
        chmod u+x "$WORKSPACE_ROOT_DIR/$name/.bt/init.sh" &&
        touch "$WORKSPACE_ROOT_DIR/$name/notes.sh" &&
        success "Workspace '$name' created" && workspace "$name"
}

complete -o nospace -F _workspace_list workspace
