#!/usr/bin/env bash

color @252 -v styleSuccess
color @554 -v styleWarning
color @533 -v styleFailure

EDITOR=${EDITOR:-vim}

bt-on-prompt 'var-set -e PROMPT_COLOR "$red"; -0 "$BT_PROMPT_STATUS" && var-set -e PROMPT_COLOR "$green"'

PS1="\[$yellow\]\u@\h:\w\[\${PROMPT_COLOR}\]\$\[$plain\] "
PS2=': '
PS4="\[$lightGrayBackground\]  \[$plain\] "

keymap-macro-def reload-bash-profile @clear-line " exec bash" @accept-line
keymap-bind reload-bash-profile F6
keymap-macro-def edit-bash-profile @clear-line " ${EDITOR} ~/.bash_profile" @accept-line
keymap-bind edit-bash-profile F7


alias rm='rm -i' # interactive
alias cp='cp -i' # interactive
alias mv='mv -i' # interactive

alias df='df -h' # human readable figures
alias du='du -h' # human readable figures

alias ls='ls -h --color=tty'
alias ll='ls -l'                # long list
alias la='ls -A'                # all but . and ..
alias lt="ls --color -Altr"

alias se="sed -E"
alias tf="tail -F"
alias vi="vim"

alias less='less -rf'           # process raw control characters
alias whence='type -a'
alias grep='grep --color=auto'
alias ge='grep -E'
alias gf='grep -F'
alias gn='grep -E -n -H'

les() {
  local lineNumber=${1//*:/}
  local fileName=${1//:*/}
  less -r -f "+$lineNumber" "$fileName"
}

shopt -s expand_aliases

# put openSSH private key in .ssh/id_rsa
_initSsh()
{
  -z "$SSH_AUTH_SOCK" && ps | grep ssh-agent | awk '{print $1}' | xargs kill -9 2> /dev/null && eval "$(ssh-agent -s)" && ssh-add
}

ssh() {
  _initSsh
  eval "$(which ssh)" $@
}

scp() {
  _initSsh
  eval "$(which scp)" $@
}

! -e ~/.vimrc && {
    echo 'Initializing vimrc' &&
        touch ~/.vimrc &&
        echo -e '\nsource ~/.bush/src/resources/vimrc.sh' >> ~/.vimrc &&
        success
}

bt-require text.sh


alias fail="return 1"
alias params-get='get-args "$@" || return 1'

