#!/bin/bash

require utils.sh
require macros.sh

EDITOR=${EDITOR:-vim}

on-prompt 'unescape-var PROMPT_COLOR "$red"; -ez "$BUSH_PROMPT_STATUS" && unescape-var PROMPT_COLOR "$green"'

PS1="\[$yellow\]\u@\h:\w\[\${PROMPT_COLOR}\]\$\[$plain\] "
PS2='  '
PS4="\[$lightGrayBackground\]  \[$plain\] "

def-macro reload-bash-profile @clear-line " source ~/.bash_profile" @accept-line
bind-macro reload-bash-profile F6
def-macro edit-bash-profile @clear-line " ${EDITOR} ~/.bash_profile" @accept-line
bind-macro edit-bash-profile F7

alias l="ls --color"
alias la="ls --color -al"
alias lt="ls --color -altr"
alias g="egrep --color=always"
alias s="sed"
alias h="head"
alias t="tail"
alias f="tail -F"
alias vi=vim

shopt -s expand_aliases

function ssh() {
  -z "$SSH_AUTH_SOCK" && ps | grep ssh-agent | awk '{print $1}' | xargs kill -9  && eval "$(ssh-agent -s)" && ssh-add
  eval "$(which ssh)" $@
}

function scp() {
  -z "$SSH_AUTH_SOCK" && ps | grep ssh-agent | awk '{print $1}' | xargs kill -9 &&  eval "$(ssh-agent -s)" && ssh-add
  eval "$(which scp)" $@
}
