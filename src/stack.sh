#!/bin/bash

# A stack, using bash arrays.
#
# by Brian Clapper
# ---------------------------------------------------------------------------

# Create a new stack.
#
# Usage: stack-new name
#
# Example: stack-new x
stack-new()
{
    : ${1?'Missing stack name'}
    if stack-exists $1
    then
        echo "Stack already exists -- $1" >&2
        return 1
    fi

    eval "_stack_$1=()"
    eval "_stack_$1_i=0"
    return 0
}

# Destroy a stack
#
# Usage: stack-remove name
stack-remove()
{
    : ${1?'Missing stack name'}
    eval "unset _stack_$1 _stack_$1_i"
    return 0
}

# Push one or more items onto a stack.
#
# Usage: stack-push stack item ...
stack-push()
{
    : ${1?'Missing stack name'}
    : ${2?'Missing item(s) to push'}

    if _stack_missingStack $1
    then
        echo "No such stack -- $1" >&2
        return 1
    fi

    stack=$1
    shift 1

    while (( $# > 0 ))
    do
        eval '_i=$'"_stack_${stack}_i"
        eval "_stack_${stack}[$_i]='$1'"
        eval "let _stack_${stack}_i+=1"
        shift 1
    done

    unset _i
    return 0
}

# Print a stack to stdout.
#
# Usage: stack-print name
stack-print()
{
    : ${1?'Missing stack name'}

    if _stack_missingStack $1
    then
        echo "No such stack -- $1" >&2
        return 1
    fi

    tmp=""
    eval 'let _i=$'_stack_$1_i
    while (( $_i > 0 ))
    do
        let _i=${_i}-1
        eval 'e=$'"{_stack_$1[$_i]}"
        tmp="$tmp $e"
    done
    echo "(" $tmp ")"
}

# Get the size of a stack
#
# Usage: stack-size name var
#
# Example:
#    stack-size mystack n
#    echo "Size is $n"
stack-size()
{
    : ${1?'Missing stack name'}
    : ${2?'Missing name of variable for stack size result'}
    if _stack_missingStack $1
    then
        echo "No such stack -- $1" >&2
        return 1
    fi
    eval "$2"='$'"{#_stack_$1[*]}"
}

# Pop the top element from the stack.
#
# Usage: stack-pop name var
#
# Example:
#    stack-pop mystack top
#    echo "Got $top"
stack-pop()
{
    : ${1?'Missing stack name'}
    : ${2?'Missing name of variable for popped result'}

    eval 'let _i=$'"_stack_$1_i"
    if _stack_missingStack $1
    then
        echo "No such stack -- $1" >&2
        return 1
    fi

    if [[ "$_i" -eq 0 ]]
    then
        echo "Empty stack -- $1" >&2
        return 1
    fi

    let _i-=1
    eval "$2"='$'"{_stack_$1[$_i]}"
    eval "unset _stack_$1[$_i]"
    eval "_stack_$1_i=$_i"
    unset _i
    return 0
}

_stack_missingStack()
{
    : ${1?'Missing stack name'}
    stack-exists $1
    ret=$?
    declare -i x
    let x="1-$ret"
    return $x
}

stack-exists()
{
    : ${1?'Missing stack name'}

    eval '_i=$'"_stack_$1_i"
    if [[ -z "$_i" ]]
    then
        return 1
    else
        return 0
    fi
}
