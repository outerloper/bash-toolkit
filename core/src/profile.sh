#!/bin/bash

export EDITOR=${EDITOR:-vim}
PS1='\[\033[1;33m\]\u@\h:\w\$\[\033[0m\] '

alias bpe="${EDITOR} ~/.bash_profile" # Bash Profile Edit
alias bpr="source ~/.bash_profile" # Bash Profile Reload
alias l="ls --color -al"
alias la="ls --color -al"
alias lt="ls --color -altr"
alias g="grep --color=always"
alias s="sed -n"
alias vi=vim

# ReMove CR from line endings
rmcr() {
   for file in $@
   do
      if [ -f "${file}" ]
      then
         tr -d "\r" < "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}" && rm "${file}.tmp"
      fi
   done
}

type cygpath >/dev/null 2>/dev/null || { sed -e 's/^\(\w\):[\/\\]*/\/cygdrive\/\L\1\//' -e 's/\\/\//g' <<<$1; }

for util in ${HOME}/.bash-toolkit/core/src/utils*.sh
do
   source "${util}"
done
source "${HOME}/.bash-toolkit/core/src/inputrc.sh"
