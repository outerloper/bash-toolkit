#!/bin/bash

require macros.sh


DIRS_HISTORY_FILE="$BUSH_CONFIG/dirs.history" # TODO change this dir
DIRS_HISTORY_SIZE=50


function _dirs_ensureHistoryExists() { # TODO ensure-file
   if -nf "$DIRS_HISTORY_FILE"
   then
      _dirs_initEmptyHistory
   fi
}

function _dirs_historyPrint() {
   _dirs_ensureHistoryExists
   nl -w 5 "$DIRS_HISTORY_FILE"
}

function _dirs_initEmptyHistory() {
   echo -n > "$DIRS_HISTORY_FILE"
}

function _dirs_historyFetch() {
   _dirs_ensureHistoryExists
   local nr=${1:-'$'}
   [[ "$nr" != "0" ]] && sed -n "$nr p" < "$DIRS_HISTORY_FILE"
}

function _dirs_historyAddPwd() {
   _dirs_ensureHistoryExists
   local dir="$(dirs +0)"
   grep -v "^$dir\$" <"$DIRS_HISTORY_FILE" | tail "-$((DIRS_HISTORY_SIZE - 1))" | sponge "$DIRS_HISTORY_FILE"
   echo "$dir" >>"$DIRS_HISTORY_FILE"
}


function chdir() {
   [ "$1" == "--help" ] && {
      \cd --help 2>&1 | sed '1 d'
      echo "       or: cd -c
Options:
  -P   Do not follow symbolic links
  -L   Follow symbolic links (default)
  -c   Clear dir history
Special values for dir:
  -    Go to previous directory
  --   Print dir history
  -N   Go to dir with index N in history
"
      return 127
   }

   [ "$1" == "--" ] && {
      _dirs_historyPrint
      return 0
   }

   [ "$1" == "-c" ] && {
      _dirs_initEmptyHistory
      return 0
   }

   local option="$1"
   local dir="${1-"~"}"
   if [[ "$dir" =~ ^-[0-9]+$ ]]
   then
      dir="$(_dirs_historyFetch "${dir:1}")"
      -n "$dir" || {
         err 'No dir with such index in history.'
         return 1
      }
      option=''
   else
      dir="${2:-"~"}"
   fi
   local tildeExpandedDir="${dir/\~/$HOME}"
   \cd $option "$tildeExpandedDir" || return $?
   _dirs_historyAddPwd
   return 0
}

function _histdir-tab-completion() {
   local cword=${#COMP_WORDS[@]}
   local arg=${COMP_WORDS[1]}
   if (( COMP_CWORD == 1 )) && (( cword == 2 )) && [[ "$arg" =~ ^- ]]
   then
      COMPREPLY=( '-NR<tab>' '-REGEX<tab>' )
      if -num "${arg:1}"
      then
         local pattern="^\s*${arg:1}\s*\s"
         COMPREPLY=( "$(chdir -- | sed -n "/$pattern/ {s/$pattern//; p}")" )
      else
         local phrase
         local completeIfOne
         if [ "${arg:1:1}" = "-" ]
         then
            phrase="${arg:2}"
         else
            phrase="${arg:1}"
            completeIfOne=1
         fi
         local lines=$(chdir -- | grep -i "$phrase" | wc -l)
         if [ "$lines" = "1" ] && [ "$completeIfOne" ]
         then
            COMPREPLY=( "$(chdir -- | grep "$phrase" | sed "s/^\s*\w*\s*//")" )
         else
            for line in "$(chdir -- | egrep --color=always -i "$phrase")"
            do
                echo -ne "\n$line"
            done
         fi
      fi
   fi
}



def-macro filter-dir-history @backward-word @unix-line-discard 'cd -' @end-of-line '\t'
bind-macro filter-dir-history Alt-PgUp Alt-PgDown Ctrl-PgUp Ctrl-PgDown

alias cd=chdir
complete -o nospace -o dirnames -F _histdir-tab-completion cd
