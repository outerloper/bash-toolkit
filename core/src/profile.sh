#!/bin/bash

export EDITOR=${EDITOR:-vim}
PS1='\[\033[1;33m\]\u@\h:\w\$\[\033[0m\] '

alias bpe="${EDITOR} ~/.bash_profile" # Bash Profile Edit
alias bpr="source ~/.bash_profile" # Bash Profile Reload
alias l="ls --color"
alias la="ls --color -al"
alias lt="ls --color -altr"
alias g="grep --color=always"
alias s="sed"
alias h="head"
alias t="tail"
alias tf="tail -F"
alias vi=vim

shopt -s expand_aliases
for util in ${HOME}/.bash-toolkit/core/src/utils*.sh
do
   source "${util}"
done
source "${HOME}/.bash-toolkit/core/src/inputrc.sh"
