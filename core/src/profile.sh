#!/bin/bash

export EDITOR=${EDITOR:-vim}
PS1='\[\033[1;33m\]\u@\h:\w\$\[\033[0m\] '

alias bpe="${EDITOR} ~/.bash_profile" # Bash Profile Edit
alias bpr="source ~/.bash_profile" # Bash Profile Reload
alias l="ls --color -al"
alias la="ls --color -al"
alias lt="ls --color -altr"
alias lc="ls --color"
alias g="grep --color=always"
alias s="sed"
alias t="tail -F"
alias vi=vim

for util in ${HOME}/.bash-toolkit/core/src/utils*.sh
do
   source "${util}"
done
source "${HOME}/.bash-toolkit/core/src/inputrc.sh"
