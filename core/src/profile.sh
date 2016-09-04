#!/bin/bash

export EDITOR=${EDITOR:-vim}
PS1='\[\033[1;33m\]\u@\h:\w\$\[\033[0m\] '

alias bpe="${EDITOR} ~/.bash_profile" # Bash Profile Edit
alias bpr="source ~/.bash_profile" # Bash Profile Reload

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

ssh() {
  [ -z ${SSH_AUTH_SOCK} ] && ps | grep ssh-agent | awk '{print $1}' | xargs kill -9  && eval "$(ssh-agent -s)" && ssh-add
  eval $(which ssh) $@
}

scp() {
  [ -z ${SSH_AUTH_SOCK} ] && ps | grep ssh-agent | awk '{print $1}' | xargs kill -9 &&  eval "$(ssh-agent -s)" && ssh-add
  eval $(which scp) $@
}
