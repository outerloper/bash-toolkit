#!/bin/bash

export EDITOR=vim
export HISTCONTROL=erasedups
export HISTSIZE=1000


alias bpe="${EDITOR:-vim} ~/.bash_profile" # Bash Profile Edit
alias bpr="source ~/.bash_profile" # Bash Profile Reload
alias ls="ls --color -l" # funkified ls
alias grep="grep --color" # funkified grep
alias g="grep" # Grep
alias hg="history | grep" # History Grep
alias pg="ps aux | grep" # Processes Grep
alias jpg="jps -l -m | grep" # Java Processes Grep


ffp() { find . -regex ".*$1.*" 2>/dev/null; } # simple Find Files in Path
rmcr() {
   for file in $@ ; do
      if [ -f "$file" ] ; then
         sed -e 's/\r//' < "$file" > "$file.tmp" && mv "$file.tmp" "$file"
         if [ -f "$file.tmp" ] ; then
            rm "$file.tmp"
         fi
      fi
   done
} # ReMove CR from file - convert Windows line endings to POSIX
trp() { sed -e 's/^\(\w\):[\/\\]*/\/cygdrive\/\L\1\//' -e 's/\\/\//g' <<<$1; } # TRanslate Path from Windows to POSIX

PS1='\[\033[1;33m\]\u@\h:\w\$\[\033[0m\] '


source "${HOME}/.bash-toolkit/init/inputrc.sh"
