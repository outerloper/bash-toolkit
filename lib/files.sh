#!/bin/bash

# Creates a file $1 if it does not exist. If $1 does not exist and $2 provided then $2 must be a file and its content is copied to $1.
# If $1 not specified, temporary file is created and its name is printed to stdout.
# If -f option used, the file is re-created even when exists.
file-new() {
    -0 $# && { mktemp --tmpdir; return; }

    local force
    -eq "$1" -f && { force=1; shift; }
    local dest="${1:?'Missing file name'}"
    -f "$dest" && if is "$force"
    then
        path-remove "$dest" || return 1
    else
        return 0
    fi
    -d "$dest" && err "$dest is a directory" && return 1
    local destAbsolute="$(readlink -m "$dest")"
    local destParent="${destAbsolute%/*}"
    mkdir -p "$destParent"
    if -n "$2"
    then
        local template="$2"
        ! -f "$template" && err "$template - no such file" && return 1
        cp --preserve "$template" "$dest"
    else
        touch "$dest"
    fi
}

# Creates a directory $1 if it does not exist. If $1 does not exist and $2 provided then $2 must be a directory and its content is copied to $1.
# Faster than mkdir -p when dir exists. If $1 not specified, temporary dir is created and its name is printed to stdout.
# If -f option used, the dir is re-created even when exists.
dir-new() {
    -0 $# && { mktemp --tmpdir -d; return; }

    local force
    -eq "$1" -f && { force=1; shift; }
    local dest="${1:?'Missing file name'}"
    -d "$dest" && if is "$force"
    then
        path-remove "$dest" || return 1
    else
        return 0
    fi
    local dest="${1?'Missing directory name'}"
    -d "$dest" && { return 0; }
    -f "$dest" && { err "$dest is a file"; return 1; }
    mkdir -p "$dest"
    if -n "$template"
    then
         local template="$2"
         ! -d "$template" && { err "$template - no such directory"; return 1; }
         cp --preserve -r -T "$template" "$dest"
    fi
}

# deletes dirs if necessary. Fails when $1 is a file
dir-clear() {
    local dest="${1?'Missing directory name'}"
    if -d "$dest"
    then
        path-remove "$dest"/*
    else
        -e "$dest" && { err "$dest already exists and is not a directory"; return 1; }
        mkdir -p "$dest"
    fi
}

# ensures $1 will be now under name of $2. $2 is removed if required. Does nothing if $1 is a file or $2 does not exist.
# prompting before removing/overwriting if BT_SAFE_REMOVALS=true
dir-replace() {
    local source="${1:?Missing source dir}"
    local dest="${2:?Missing target dir}"
    ! -d "$source" && { err "$FUNCNAME: $source is not a directory"; return 1; }
    -f "$dest" && { err "$FUNCNAME: $dest is a file"; return 1; }
    -d "$dest" && { path-remove "$dest"/* || return 1; }
    is "$BT_SAFE_REMOVALS" && {
        echo "Replacing $dest with $source"
        local options=-iv
    }
    mv $options -T "$source" "$dest"
    ! -e "$source"
}

# rm -rf unless BT_SAFE_REMOVALS=true which means prompting before removal - non-zero exit status if user decided not to remove.
path-remove() {
    local options=-r
    if is "$BT_SAFE_REMOVALS" ;then
        echo "Removing $@"
        options+=Iv
    else
        options+=f
    fi
    rm $options $@
    ! -e $1
}

# pushd without printing on stdout
dir-push() {
    pushd "$1" >/dev/null
}

# popd without printing on stdout
dir-pop() {
    popd >/dev/null
}
