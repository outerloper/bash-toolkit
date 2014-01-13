#!/bin/bash

export EDITOR=vim
export HISTCONTROL=erasedups
export HISTSIZE=1000


alias bpe="${EDITOR:-vim} ~/.bash_profile" # Bash Profile Edit
alias bpr="source ~/.bash_profile" # Bash Profile Reload
alias ls="ls --color -l" # funkified ls
alias grep="grep --color=always" # funkified grep
alias g="grep" # Grep
alias hg="history | grep" # History Grep
alias pg="ps aux | grep" # Processes Grep
alias jpg="jps -l -m" # Java Processes

# ReMove CR from file - convert Windows line endings to POSIX
rmcr() {
   for file in $@ ; do
      if [ -f "$file" ] ; then
         sed -e 's/\r//' < "$file" > "$file.tmp" && mv "$file.tmp" "$file"
         if [ -f "$file.tmp" ] ; then
            rm "$file.tmp"
         fi
      fi
   done
}

# TRanslate Path from Windows to POSIX
trp() { sed -e 's/^\(\w\):[\/\\]*/\/cygdrive\/\L\1\//' -e 's/\\/\//g' <<<$1; }


PS1='\[\033[1;33m\]\u@\h:\w\$\[\033[0m\] '

source "${HOME}/.bash-toolkit/common/utils.sh"
source "${HOME}/.bash-toolkit/init/inputrc.sh"
